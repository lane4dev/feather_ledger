import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/domain/commands/convert_scheduled_to_posted_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/create_recurring_series_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/delete_recurring_bill_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/project_recurring_events_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/update_recurring_bill_command.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_scheduled_transactions_query.dart';

part 'recurring_service.g.dart';

/// The write/read seam for recurring bills (spec 004, US2).
///
/// This is the only bridge between the two halves of the recurring model:
/// `recurring_series` / `scheduled_transactions_view` are CRUD-exempt tables
/// that no event touches, and posting an instance is the one action that
/// crosses into the event-sourced ledger. Everything the screens do goes
/// through here, so a unit test wires one service rather than five commands.
class RecurringService {
  final CreateRecurringSeriesCommand _createSeries;
  final DeleteRecurringBillCommand _deleteBill;
  final UpdateRecurringBillCommand _updateBill;
  final ConvertScheduledToPostedCommand _postInstance;
  final ProjectRecurringEventsCommand _projectInstances;
  final WatchScheduledTransactionsQuery _watchScheduled;

  /// Ticket 28 safety gate: auto-posting is disabled until the eligibility
  /// rules and the restore confirmation barrier land. It is closed by default
  /// and only opened under a controlled test configuration; every autopost
  /// entry (launch, account restore, notification responses) funnels through
  /// [catchUpAutoPosted], so a closed gate blocks them all. Manual posting is
  /// unaffected — [postInstance] never consults this flag.
  final bool autoPostEnabled;

  /// The per-mode auto-post switches and their eligibility boundaries
  /// (ticket 31). Null means the switches are not loaded yet, which is
  /// treated exactly like "every switch off": nothing auto-posts.
  final PreferencesRepository? preferences;

  RecurringService(
    this._createSeries,
    this._deleteBill,
    this._updateBill,
    this._postInstance,
    this._projectInstances,
    this._watchScheduled, {
    this.autoPostEnabled = false,
    this.preferences,
  });

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
      await _watchScheduled.markSeriesIneligibleBefore(id, DateTime.now());
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
    final instances = await _watchScheduled.execute().first;
    final now = DateTime.now();
    for (final instance in instances) {
      if (instance.account?.archived != false) continue;
      if (accountId != null && instance.account?.id != accountId) continue;
      if (instance.status != ScheduledTransactionStatus.scheduled) continue;
      if (instance.date.isAfter(now)) continue;

      final series = instance.recurringTransactionSeries;
      if (series == null) continue;

      final mode = series.mode;
      final enabled = prefs.getAutoPostEnabled(mode);
      final enabledSince = prefs.getAutoPostEnabledSince(mode);
      final currency = instance.account?.currencyCode;
      final currencySince =
          currency == null ? null : prefs.getCurrencyActiveSince(currency);

      final eligible = enabled &&
          (enabledSince == null || instance.date.isAfter(enabledSince)) &&
          (currencySince == null || instance.date.isAfter(currencySince)) &&
          instance.autoPostEligible;

      if (!eligible) {
        // Latch once, then leave the bill scheduled for the user's 记入.
        if (instance.autoPostEligible) {
          await _watchScheduled.markAutoPostIneligible(instance.id);
        }
        continue;
      }

      // postInstance returns Result and never throws; ignoring it *is* the
      // "continue on failure" policy above.
      await guard(() => _postInstance.execute(instance.id,
          commandId: 'autopost-${instance.id}'));
    }
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
    preferences: ref.watch(preferencesRepositoryProvider).value,
  );
}
