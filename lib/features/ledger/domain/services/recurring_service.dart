import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

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

  RecurringService(
    this._createSeries,
    this._deleteBill,
    this._updateBill,
    this._postInstance,
    this._projectInstances,
    this._watchScheduled,
  );

  Stream<List<ScheduledTransactionEntity>> watchScheduled() =>
      _watchScheduled.execute();

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
  }) {
    return guard(() async {
      await _createSeries.execute(
        id: const Uuid().v4(),
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
      );
      await materialize();
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
      await _updateBill.execute(
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

  /// Launch catch-up for 订阅 series: every `scheduled` instance of an
  /// auto-posting series whose date has passed becomes a real transaction.
  ///
  /// Idempotent twice over: the status flip rides the append transaction, and
  /// the deterministic commandId (`'autopost-<instanceId>'`) is deduped at
  /// append time. A failed post leaves the instance `scheduled` and visible in
  /// the ledger list — that pending tile is the report — and does not stop the
  /// other instances. Runs after [materialize], which is what puts the due
  /// instances on the table.
  Future<void> catchUpAutoPosted() async {
    final instances = await _watchScheduled.execute().first;
    final now = DateTime.now();
    for (final instance in instances) {
      if (instance.recurringTransactionSeries?.autoPost != true) continue;
      if (instance.status != ScheduledTransactionStatus.scheduled) continue;
      if (instance.date.isAfter(now)) continue;
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
  );
}
