import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

part 'delete_recurring_bill_command.g.dart';

/// Removes a pending bill across one of the two v15 scopes:
/// - `thisOnly`: marks the occurrence `skipped` so materialization never
///   re-creates it.
/// - `updateRule`: for `planned`, physically deletes the one-shot series and
///   its instance; for `repeating`, sets `isActive = false` and deletes all
///   non-posted (`scheduled`/`failed`/`skipped`) instances while keeping
///   posted history.
class DeleteRecurringBillCommand {
  final RecurringRepository _recurringRepository;

  DeleteRecurringBillCommand(this._recurringRepository);

  Future<void> execute({
    required String scheduledId,
    required RecurringScope scope,
  }) async {
    final row = await _recurringRepository.getScheduled(scheduledId);
    if (row == null) {
      throw const CommandRejected(
        LedgerErrorCode.transactionNotFound,
        'Scheduled bill not found',
      );
    }
    if (row.status == ScheduledTransactionStatus.posted.toStorage()) {
      throw const CommandRejected(
        LedgerErrorCode.scheduledAlreadyPosted,
        'Posted bills cannot be deleted from here; reverse the transaction instead',
      );
    }

    switch (scope) {
      case RecurringScope.thisOnly:
        await _recurringRepository.skipIfScheduled(row.id);
      case RecurringScope.updateRule:
        final series = await _recurringRepository.getSeries(row.seriesId);
        if (series == null || series.mode == RecurringSeriesMode.planned) {
          await _recurringRepository.deleteSeriesWithInstances(row.seriesId);
          return;
        }
        await _recurringRepository.saveSeries(
          series.toCompanion(true).copyWith(isActive: const Value(false)),
        );
        await _recurringRepository.deletePendingAndSkippedForSeries(series.id);
    }
  }
}

@riverpod
DeleteRecurringBillCommand deleteRecurringBillCommand(Ref ref) {
  return DeleteRecurringBillCommand(ref.watch(recurringRepositoryProvider));
}
