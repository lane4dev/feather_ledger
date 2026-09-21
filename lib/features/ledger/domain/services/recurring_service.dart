import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/domain/commands/convert_scheduled_to_posted_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/create_recurring_series_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/delete_recurring_bill_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/project_recurring_events_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/update_recurring_bill_command.dart';
import 'package:feather_ledger/features/ledger/domain/entities/automatic_posting_batch.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_scheduled_transactions_query.dart';
import 'package:feather_ledger/features/settings/domain/models/restore_confirmation_batch.dart';

part 'recurring_service.g.dart';

/// The write/read seam for recurring bills (spec 004, US2).
///
/// This is the only bridge between the two halves of the recurring model:
/// `recurring_series` / `scheduled_transactions_view` are CRUD-exempt tables
/// that no event touches, and posting an instance is the one action that
/// crosses into the event-sourced ledger. Everything the screens do goes
/// through here, so a unit test wires one service rather than five commands.
class RecurringService {
  /// How many bills to settle before yielding to the event loop, so the first
  /// frame and the ledger UI keep updating during a large catch-up (US46).
  static const int _batchChunk = 8;

  final CreateRecurringSeriesCommand _createSeries;
  final DeleteRecurringBillCommand _deleteBill;
  final UpdateRecurringBillCommand _updateBill;
  final ConvertScheduledToPostedCommand _postInstance;
  final ProjectRecurringEventsCommand _projectInstances;
  final WatchScheduledTransactionsQuery _watchScheduled;

  /// The release gate (ticket 48): auto-posting is enabled in production
  /// after the eligibility rules and the restore confirmation barrier landed
  /// (tickets 28–47). Tests that want a closed gate pass
  /// [autoPostEnabled] explicitly; every autopost entry (launch, account
  /// restore, notification responses) funnels through [catchUpAutoPosted].
  /// Manual posting is unaffected — [postInstance] never consults this flag.
  final bool autoPostEnabled;

  /// The per-mode auto-post switches and their eligibility boundaries
  /// (ticket 31). Null means the switches are not loaded yet, which is
  /// treated exactly like "every switch off": nothing auto-posts.
  final PreferencesRepository? preferences;

  /// Injectable wall clock (spec 003, P1). The catch-up cutoff and the
  /// "created already due" latch both read it instead of `DateTime.now()`.
  final DomainClock _clock;

  RecurringService(
    this._createSeries,
    this._deleteBill,
    this._updateBill,
    this._postInstance,
    this._projectInstances,
    this._watchScheduled, {
    this.autoPostEnabled = true,
    this.preferences,
    DomainClock clock = const SystemClock(),
  }) : _clock = clock;

  Stream<List<ScheduledTransactionEntity>> watchScheduled(
          {String? currencyCode}) =>
      _watchScheduled.execute(currencyCode: currencyCode);

  /// Creates a series and immediately materializes it, so a new series shows
  /// up as pending instances instead of only after the next launch.
  ///
  /// [autoPost] marks a 订阅 series: due instances post themselves at launch
  /// (see [catchUpAutoPosted]) instead of waiting for the user's 记入.
  Future<Result<void>> createSeries({
    required RecurringSeriesKind type,
    required int amountMinor,
    required String accountId,
    required String categoryId,
    required String description,
    required String frequency,
    required int interval,
    required DateTime startDate,
    DateTime? endDate,
    int? countLimit,
    List<int> weekdays = const [],
    bool autoPost = false,
    int? reminderMinutes,
    RecurringSeriesMode mode = RecurringSeriesMode.repeating,
  }) {
    return guard(() async {
      final id = const Uuid().v4();
      await _createSeries.execute(
        id: id,
        type: type,
        amountMinor: amountMinor,
        accountId: accountId,
        categoryId: categoryId,
        description: description,
        frequency: frequency,
        interval: interval,
        startDate: startDate,
        endDate: endDate,
        countLimit: countLimit,
        weekdays: weekdays,
        autoPost: autoPost,
        reminderMinutes: reminderMinutes,
        mode: mode,
      );
      await materialize();
      // A series created already past its first due date must never auto-post
      // those bills (spec 006, US32): they were due before the user even had
      // the rule.
      await _watchScheduled.markSeriesIneligibleBefore(id, _clock.now());
    });
  }

  /// Deletes pending bills, at one of the three scopes. Writes no event and
  /// moves no money; see [DeleteRecurringBillCommand] for what each scope
  /// does to the series behind them.
  Future<Result<void>> deleteBill(
    String scheduledId, {
    required RecurringScope scope,
  }) {
    return guard(() => _deleteBill.execute(scheduledId, scope: scope));
  }

  /// Edits a pending bill at one of the three scopes, then rolls the window
  /// so the bills it changed exist. Moves no money: a bill already recorded
  /// is a movement with its own event, and this never touches one.
  ///
  /// [categoryId], [accountId] and [description] are read only by the series
  /// scopes — a single instance row has nowhere to keep them.
  Future<Result<void>> updateBill(
    String scheduledId, {
    required RecurringScope scope,
    required int amountMinor,
    required DateTime date,
    required String categoryId,
    required String accountId,
    required String description,
  }) {
    return guard(() async {
      final toLatch = await _updateBill.execute(
        scheduledId,
        scope: scope,
        amountMinor: amountMinor,
        date: date,
        categoryId: categoryId,
        accountId: accountId,
        description: description,
      );
      // The series scopes drop rows and expect them back at their new dates;
      // materialization is what puts them there.
      await materialize();
      // A real edit of an already-due (or moved-to-past) bill turns it manual
      // (spec 006, US32). The series scopes rebuild rows, so latch their
      // re-materialized ids *after* the window is rebuilt.
      for (final id in toLatch) {
        await _watchScheduled.markAutoPostIneligible(id);
      }
    });
  }

  /// Posts a due instance into the ledger: one `TransactionRecorded`, with the
  /// status flip riding the same append transaction.
  ///
  /// [commandId] is normally left null and minted per call. It stays a
  /// parameter so a caller that already owns an idempotency key — a retry, or
  /// a test asserting on one — can supply its own.
  Future<Result<void>> postInstance(String scheduledId,
      {String? commandId}) async {
    final result = await guard(() => _postInstance.execute(scheduledId,
        commandId: commandId ?? const Uuid().v4()));
    if (result is Success<void>) {
      // The transaction has committed; a refill failure must not report the
      // already-posted transaction as failed. The next launch retries it.
      try {
        await materialize();
      } catch (_) {
        // Materialization is also retried on launch.
      }
    }
    return result;
  }

  /// Rolls the 90-day window forward for every series. Idempotent, so it is
  /// safe on every launch and after every series creation.
  Future<void> materialize() => _projectInstances.execute();

  /// Launch catch-up for auto-posting series: every `scheduled` instance of
  /// an eligible series whose date has passed becomes a real transaction.
  ///
  /// Eligibility (ticket 31) is per instance: its mode's auto-post switch
  /// must be on, and its due time must be *strictly* after both the last time
  /// that switch turned on and the last time its currency became current —
  /// "already due", or due the same millisecond, is latched permanently manual
  /// and never auto-posts again, even after the switch or the currency comes
  /// back. A previously latched bill stays latched.
  ///
  /// Batch (tickets 38–40): the run freezes a cutoff, resumes any members an
  /// earlier interrupted run left pending or failed (settling them inside
  /// their ORIGINAL batch), then claims newly-due eligible bills into a fresh
  /// batch. Each settled member records one terminal result — succeeded,
  /// failed, user-handled or manual. Processing yields to the event loop every
  /// [_batchChunk] bills so the first frame and the ledger UI keep updating.
  ///
  /// Idempotent twice over: the status flip rides the append transaction, and
  /// the deterministic commandId (`'autopost-<instanceId>'`) is deduped at
  /// append time. A failed post leaves the instance `scheduled` and visible in
  /// the ledger list — that pending tile is the report — and does not stop the
  /// other instances. Runs after [materialize], which is what puts the due
  /// instances on the table.
  Future<void> catchUpAutoPosted({String? accountId}) async {
    if (!autoPostEnabled) return;
    final prefs = preferences;
    if (prefs == null) return;

    // Fixed startup cutoff (spec 006, US37/46): anything due after this
    // instant is not part of this run's batch — it waits for the next launch.
    final now = _clock.now();

    final instances = await _watchScheduled.execute().first;
    final byId = {for (final i in instances) i.id: i};

    // Restore barrier (spec 006, US58): bills that were not yet due when the
    // backup was exported but fell due before it was applied here must await
    // explicit confirmation — another device may already have recorded them.
    final pendingRestore =
        await _watchScheduled.latestPendingRestoreConfirmationBatch();

    await _resumeUnsettledMembers(prefs, byId, accountId);

    final batchId = await _watchScheduled.createAutomaticPostingBatch(now);
    final due = instances.where((i) => !i.date.isAfter(now)).toList();

    var index = 0;
    for (final instance in due) {
      // A bill already claimed by an earlier batch is settled by that batch
      // (via the resume above or a previous run) — it never joins a new one
      // (spec 006, US39: existing batches keep their scope and results).
      if (await _watchScheduled.isAutomaticPostingMember(instance.id)) {
        continue;
      }

      // Bills inside a pending restore's confirmation window wait behind the
      // barrier ONLY while they are still eligible (spec 006, US65): when the
      // target device's switch is off (or the currency is away), the bill must
      // be latched manual instead of preserved for confirmation.
      final eligible = _isEligible(prefs, instance);
      if (pendingRestore != null &&
          pendingRestore.contains(instance.date) &&
          eligible) {
        continue;
      }

      final result =
          await _settleMember(prefs, instance, byId, accountId);
      if (result != null) {
        // Claim once: a bill interrupted mid-run was already claimed by its
        // earlier batch; a fresh bill joins this one. The idempotent upsert
        // makes the claim safe to repeat (US52).
        await _watchScheduled.setAutomaticPostingMemberResult(
            batchId, instance.id, result);
      }

      // Bounded batch: yield to the event loop so the first frame and the
      // ledger UI keep updating (US46).
      if (++index % _batchChunk == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }
  }

  /// Confirms one restore batch (spec 006, US63): posts every eligible
  /// candidate in its window, then marks the batch confirmed. Candidates that
  /// fail to post stay `scheduled` and are retried the next launch (US51).
  Future<void> confirmRestoreBatch(String batchId) async {
    if (!autoPostEnabled) return;
    final prefs = preferences;
    if (prefs == null) return;

    final candidates = await restoreConfirmationEligible(batchId);
    for (final candidate in candidates) {
      await guard(() => _postInstance.execute(candidate.id,
          commandId: 'restore-confirm-${candidate.id}'));
    }
    await _watchScheduled.updateRestoreConfirmationStatus(
        batchId, RestoreConfirmationStatus.confirmed);
  }

  /// Rejects one restore batch (spec 006, US63): latches every candidate in
  /// its window as permanently manual, then marks the batch rejected.
  Future<void> rejectRestoreBatch(String batchId) async {
    final candidates =
        await _watchScheduled.restoreConfirmationCandidates(batchId);
    for (final candidate in candidates) {
      await _watchScheduled.markAutoPostIneligible(candidate.id);
    }
    await _watchScheduled.updateRestoreConfirmationStatus(
        batchId, RestoreConfirmationStatus.rejected);
  }

  /// Latches every pending restore candidate of [mode] as permanently manual
  /// (spec 006, US65). Called when the user turns that mode's auto-post switch
  /// OFF after a restore: bills that were waiting behind the confirmation
  /// barrier must not keep waiting — the switch says "don't post these". The
  /// batch itself stays pending until the user confirms or rejects it.
  Future<void> latchRestoreCandidatesForMode(RecurringSeriesMode mode) async {
    final batches = await _watchScheduled.pendingRestoreConfirmationBatches();
    for (final batch in batches) {
      final candidates =
          await _watchScheduled.restoreConfirmationCandidates(batch.id);
      for (final candidate in candidates
          .where((c) => c.recurringTransactionSeries?.mode == mode)) {
        await _watchScheduled.markAutoPostIneligible(candidate.id);
      }
    }
  }

  /// The candidates a confirmation would actually post: inside [batchId]'s
  /// window, still scheduled, still eligible, with their mode switch on and
  /// their currency current (spec 006, US63).
  Future<List<ScheduledTransactionEntity>> restoreConfirmationEligible(
      String batchId) async {
    final prefs = preferences;
    if (prefs == null) return const [];
    final candidates =
        await _watchScheduled.restoreConfirmationCandidates(batchId);
    return candidates.where((c) => _isEligible(prefs, c)).toList();
  }

  /// Resolves a stale notification's bill id to its current id (or
  /// "deleted"), via the persisted redirect chain (spec 006, US45).
  Future<ScheduledBillRedirect?> resolveScheduledRedirect(String oldId) =>
      _watchScheduled.resolveScheduledRedirect(oldId);

  /// Settles members an earlier interrupted run left `pending` or `failed`,
  /// updating their ORIGINAL batch in place (US51/53). A retried failure that
  /// now succeeds replaces the failed result rather than adding a second one.
  Future<void> _resumeUnsettledMembers(
    PreferencesRepository prefs,
    Map<String, ScheduledTransactionEntity> byId,
    String? accountId,
  ) async {
    final members = await _watchScheduled.unsettledAutomaticPostingMembers();
    for (final member in members) {
      final instance = byId[member.scheduledId];
      if (instance == null) {
        // The bill was deleted outright — count it as user-handled.
        await _watchScheduled.setAutomaticPostingMemberResult(
            member.batchId,
            member.scheduledId,
            AutomaticPostingMemberResult.userHandled);
        continue;
      }
      final result = await _settleMember(prefs, instance, byId, accountId);
      if (result == null) continue;
      await _watchScheduled.setAutomaticPostingMemberResult(
          member.batchId, member.scheduledId, result);
    }
  }

  /// Classifies one due instance into a terminal batch result, performing the
  /// post when it is eligible. Returns null when the instance is outside this
  /// run's scope (wrong account or an archived account) and must be left
  /// alone entirely.
  Future<AutomaticPostingMemberResult?> _settleMember(
    PreferencesRepository prefs,
    ScheduledTransactionEntity instance,
    Map<String, ScheduledTransactionEntity> byId,
    String? accountId,
  ) async {
    if (instance.account?.archived != false) return null;
    if (accountId != null && instance.account?.id != accountId) return null;
    if (instance.status != ScheduledTransactionStatus.scheduled) {
      // The user posted, skipped or deleted it themselves (US54).
      return AutomaticPostingMemberResult.userHandled;
    }

    // Away currency (spec 006, US33/34): auto-post pauses for any currency
    // the user is not currently looking at, and a bill that fell due while
    // its currency was away is latched manual — it never retro-posts. The
    // switch-on / activation boundaries above are about *when* the currency
    // became eligible; this is about whether it still is.
    final currentCurrency =
        prefs.getCurrency() ?? AppCurrencies.defaultCurrency.code;
    if (instance.account?.currencyCode != currentCurrency) {
      if (instance.autoPostEligible) {
        await _watchScheduled.markAutoPostIneligible(instance.id);
      }
      return AutomaticPostingMemberResult.manual;
    }

    final eligible = _isEligible(prefs, instance);
    if (!eligible) {
      // Latch once, then leave the bill scheduled for the user's 记入.
      if (instance.autoPostEligible) {
        await _watchScheduled.markAutoPostIneligible(instance.id);
      }
      return AutomaticPostingMemberResult.manual;
    }

    final result = await guard(() => _postInstance.execute(instance.id,
        commandId: 'autopost-${instance.id}'));
    return result.when(
      success: (_) => AutomaticPostingMemberResult.succeeded,
      failure: (code, _) {
        // A concurrent user action on the same bill means the user handled
        // it; everything else is a retryable failure (US53/54).
        if (code == LedgerErrorCode.scheduledAlreadyPosted ||
            code == LedgerErrorCode.transactionNotFound) {
          return AutomaticPostingMemberResult.userHandled;
        }
        return AutomaticPostingMemberResult.failed;
      },
    );
  }

  bool _isEligible(
      PreferencesRepository prefs, ScheduledTransactionEntity instance) {
    final series = instance.recurringTransactionSeries;
    if (series == null) return false;
    final mode = series.mode;
    final enabled = prefs.getAutoPostEnabled(mode);
    final enabledSince = prefs.getAutoPostEnabledSince(mode);
    final currency = instance.account?.currencyCode;
    final currencySince =
        currency == null ? null : prefs.getCurrencyActiveSince(currency);
    return enabled &&
        (enabledSince == null || instance.date.isAfter(enabledSince)) &&
        (currencySince == null || instance.date.isAfter(currencySince)) &&
        instance.autoPostEligible;
  }
}

@riverpod
RecurringService recurringService(Ref ref) {
  return RecurringService(
    ref.watch(createRecurringSeriesCommandProvider),
    ref.watch(deleteRecurringBillCommandProvider),
    ref.watch(updateRecurringBillCommandProvider),
    ref.watch(convertScheduledToPostedCommandProvider),
    ref.watch(projectRecurringEventsCommandProvider),
    ref.watch(watchScheduledTransactionsQueryProvider),
    autoPostEnabled: true,
    preferences: ref.watch(preferencesRepositoryProvider).value,
  );
}
