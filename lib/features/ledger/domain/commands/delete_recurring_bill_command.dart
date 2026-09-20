import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

part 'delete_recurring_bill_command.g.dart';

/// Deletes pending recurring bills (spec 004, US2).
///
/// Three scopes, and what separates them is what happens to the *series* —
/// because that, not the row, is what decides whether a deleted bill can come
/// back. Materialization re-derives every instance from the rule, so a bill
/// deleted by dropping its row alone would reappear on the next run.
///
/// - [RecurringScope.thisOnly] marks the instance `skipped`. That status
///   is the tombstone `ProjectRecurringEventsCommand` refuses to resurrect,
///   which is what makes "deleted" stay deleted while the rule lives on.
/// - [RecurringScope.thisAndFollowing] ends the series the day before
///   this bill, so the rule produces nothing further, and then clears the
///   pending instances from here on.
/// - [RecurringScope.all] removes the series and every instance row
///   belonging to it. Bills already *recorded* are untouched: those are
///   `TransactionRecorded` events that stand on their own, and only the
///   scheduling envelope around them goes.
///
/// Writes no event and moves no money in any scope, so it takes no
/// `commandId` — the same reasoning as the other CRUD-exempt writes here.
class DeleteRecurringBillCommand {
  final RecurringRepository _recurringRepository;

  DeleteRecurringBillCommand(this._recurringRepository);

  Future<void> execute(
    String scheduledId, {
    required RecurringScope scope,
  }) async {
    final scheduled = await _recurringRepository.getScheduled(scheduledId);
    if (scheduled == null) {
      throw CommandRejected(LedgerErrorCode.transactionNotFound,
          'Scheduled instance $scheduledId not found');
    }
    // A recorded bill is a real movement. Deleting it is a reversal, not a
    // scheduling decision, and that is a different action on a different
    // screen.
    if (decodeScheduledStatus(scheduled.status) ==
        ScheduledTransactionStatus.posted) {
      throw const CommandRejected(LedgerErrorCode.scheduledAlreadyPosted,
          'Scheduled instance already posted');
    }

    switch (scope) {
      case RecurringScope.thisOnly:
        if (await _recurringRepository.skipIfScheduled(scheduledId) == 0) {
          final current = await _recurringRepository.getScheduled(scheduledId);
          if (current != null &&
              decodeScheduledStatus(current.status) ==
                  ScheduledTransactionStatus.posted) {
            throw const CommandRejected(LedgerErrorCode.scheduledAlreadyPosted,
                'Scheduled instance already posted');
          }
          throw const CommandRejected(LedgerErrorCode.transactionNotFound,
              'Scheduled instance no longer pending');
        }
        // A shown notification still holds this id. Record that the bill was
        // deleted so its click reports deleted, not unavailable (US45).
        await _recurringRepository.recordScheduledRedirect(scheduledId);
      case RecurringScope.thisAndFollowing:
        await _truncate(scheduled);
      case RecurringScope.all:
        await _recordDeletedRedirects(
          scheduled.seriesId,
          (row) => decodeScheduledStatus(row.status) ==
              ScheduledTransactionStatus.scheduled,
        );
        await _recurringRepository
            .deleteSeriesWithInstances(scheduled.seriesId);
    }
  }

  /// Records a "deleted" redirect for every pending bill of [seriesId]
  /// matching [include], so notifications shown before the deletion still
  /// report deleted after a restart or restore (spec 006, US45).
  Future<void> _recordDeletedRedirects(
    String seriesId,
    bool Function(ScheduledTransactionViewRow) include,
  ) async {
    final rows = (await _recurringRepository.scheduledForSeries(seriesId))
        .where(include)
        .toList();
    for (final row in rows) {
      await _recurringRepository.recordScheduledRedirect(row.id);
    }
  }

  /// Ends the series so nothing further is materialized, then clears the
  /// pending bills it had already produced from [scheduled] on.
  Future<void> _truncate(ScheduledTransactionViewRow scheduled) async {
    final series = await _recurringRepository.getSeries(scheduled.seriesId);
    if (series == null) {
      throw CommandRejected(LedgerErrorCode.transactionNotFound,
          'Series ${scheduled.seriesId} not found');
    }

    await _recurringRepository.saveSeries(
      RecurringSeriesCompanion(
        id: Value(series.id),
        rrule: Value(series.rrule),
        startDate: Value(series.startDate),
        // The day before, not the same day: `until` is inclusive, so ending
        // on this bill's date would let the next run materialize it straight
        // back. If this is the first bill, the end now precedes the start,
        // and the rule yields nothing — also correct.
        endDate: Value(_dayBefore(scheduled.date)),
        frequency: Value(series.frequency),
        interval: Value(series.interval),
        countLimit: Value(series.countLimit),
        amountMinor: Value(series.amountMinor),
        description: Value(series.description),
        categoryId: Value(series.categoryId),
        accountId: Value(series.accountId),
        type: Value(series.type),
      ),
    );

    await _recurringRepository.deletePending(scheduled.seriesId,
        from: scheduled.date);

    // Record the bills this truncation removed (including the cut bill
    // itself, which `deletePending(from:)` deletes) so their stale
    // notifications still report deleted (US45).
    await _recordDeletedRedirects(
      scheduled.seriesId,
      (row) =>
          !row.date.isBefore(scheduled.date) &&
          decodeScheduledStatus(row.status) ==
              ScheduledTransactionStatus.scheduled,
    );
  }

  static DateTime _dayBefore(DateTime date) =>
      DateTime(date.year, date.month, date.day - 1);
}

@riverpod
DeleteRecurringBillCommand deleteRecurringBillCommand(Ref ref) {
  return DeleteRecurringBillCommand(ref.watch(recurringRepositoryProvider));
}
