import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart'; // New import

part 'get_recurring_series_query.g.dart';

class GetRecurringSeriesQuery {
  final RecurringRepository _recurringRepository;

  GetRecurringSeriesQuery(this._recurringRepository);

  Future<RecurringTransactionSeriesEntity?> execute(String id) async {
    final seriesRow = await _recurringRepository.getSeries(id);
    if (seriesRow == null) return null;

    return RecurringTransactionSeriesEntity(
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
    );
  }
}

@riverpod
GetRecurringSeriesQuery getRecurringSeriesQuery(Ref ref) {
  return GetRecurringSeriesQuery(ref.watch(recurringRepositoryProvider));
}
