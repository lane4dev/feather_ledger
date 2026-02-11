import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/recurring_dao.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/repositories/recurring_repository.dart';

export 'package:feather_ledger/features/ledger/domain/repositories/recurring_repository.dart';

part 'recurring_repository.g.dart';

class RecurringRepositoryImpl implements RecurringRepository {
  final RecurringDao _recurringDao;

  RecurringRepositoryImpl(this._recurringDao);

  @override
  Future<ScheduledTransactionViewRow?> getScheduled(String id) {
    return _recurringDao.getScheduled(id);
  }

  @override
  Future<RecurringSeriesRow?> getSeries(String id) {
    return _recurringDao.getSeries(id);
  }

  @override
  Future<void> insertOrUpdateScheduled(
      ScheduledTransactionsViewCompanion entry) {
    return _recurringDao.insertOrUpdateScheduled(entry);
  }

  @override
  Stream<List<ScheduledTransactionEntity>> watchAllScheduled() {
    return _recurringDao.watchAllScheduled().asyncMap((rows) async {
      final entities = <ScheduledTransactionEntity>[];
      for (final row in rows) {
        final seriesRow = await _recurringDao.getSeries(row.seriesId);
        if (seriesRow != null) {
          entities.add(
            ScheduledTransactionEntity(
              id: row.id,
              seriesId: row.seriesId,
              date: row.date,
              amount: row.amount / 100.0,
              status: ScheduledTransactionStatus.values.firstWhere(
                  (e) => e.toString().split('.').last == row.status),
              transactionId: row.transactionId,
              recurringTransactionSeries: RecurringTransactionSeriesEntity(
                id: seriesRow.id,
                description: seriesRow.description,
                startDate: seriesRow.startDate,
                endDate: seriesRow.endDate,
                amount: seriesRow.amount / 100.0,
                categoryId: seriesRow.categoryId,
                accountId: seriesRow.accountId,
                type: seriesRow.type,
                frequency: seriesRow.frequency,
                interval: seriesRow.interval,
                limit: seriesRow.countLimit,
              ),
            ),
          );
        }
      }
      return entities;
    });
  }

  @override
  Future<List<RecurringSeriesRow>> getAllRecurringSeries() {
    return _recurringDao.getAllSeries();
  }
}

@riverpod
RecurringRepository recurringRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return RecurringRepositoryImpl(RecurringDao(db));
}
