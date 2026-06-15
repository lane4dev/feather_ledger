import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart'; // New import
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';

part 'get_scheduled_transaction_query.g.dart';

class GetScheduledTransactionQuery {
  final RecurringRepository _recurringRepository;

  GetScheduledTransactionQuery(this._recurringRepository);

  Future<ScheduledTransactionEntity?> execute(String id) async {
    final scheduledRow = await _recurringRepository.getScheduled(id);
    if (scheduledRow == null) return null;

    final seriesRow =
        await _recurringRepository.getSeries(scheduledRow.seriesId);
    if (seriesRow == null) {
      return null; // Should not happen if data integrity holds
    }

    return ScheduledTransactionEntity(
      id: scheduledRow.id,
      seriesId: scheduledRow.seriesId,
      date: scheduledRow.date,
      amountMinor: scheduledRow.amountMinor,
      status: ScheduledTransactionStatus.values.firstWhere(
          (e) => e.toString().split('.').last == scheduledRow.status),
      transactionId: scheduledRow.transactionId,
      recurringTransactionSeries: RecurringTransactionSeriesEntity(
        id: seriesRow.id,
        description: seriesRow.description,
        startDate: seriesRow.startDate,
        endDate: seriesRow.endDate,
        amountMinor: seriesRow.amountMinor,
        categoryId: seriesRow.categoryId,
        accountId: seriesRow.accountId,
        type: seriesRow.type,
        frequency: seriesRow.frequency,
        interval: seriesRow.interval,
        limit: seriesRow.countLimit,
      ),
    );
  }
}

@riverpod
GetScheduledTransactionQuery getScheduledTransactionQuery(Ref ref) {
  return GetScheduledTransactionQuery(ref.watch(recurringRepositoryProvider));
}
