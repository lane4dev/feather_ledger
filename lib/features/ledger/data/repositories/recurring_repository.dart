import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/account_dao.dart';
import 'package:feather_ledger/core/data/database/daos/categories_dao.dart';
import 'package:feather_ledger/core/data/database/daos/recurring_dao.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/repositories/recurring_repository.dart';

export 'package:feather_ledger/features/ledger/domain/repositories/recurring_repository.dart';

part 'recurring_repository.g.dart';

class RecurringRepositoryImpl implements RecurringRepository {
  final RecurringDao _recurringDao;

  // Kept for source compatibility with callers passing DAOs; reads now reuse
  // the single joined SQL query on [_recurringDao] with zero N+1 follow-ups.
  RecurringRepositoryImpl(
    this._recurringDao, [
    CategoriesDao? categoriesDao,
    AccountDao? accountsDao,
  ]);

  @override
  Future<T> transaction<T>(Future<T> Function() action) =>
      _recurringDao.transaction(action);

  @override
  Future<ScheduledTransactionViewRow?> getScheduled(String id) {
    return _recurringDao.getScheduled(id);
  }

  @override
  Future<ScheduledTransactionEntity?> getScheduledEntity(String id) async {
    final row = await _recurringDao.getScheduledJoined(id);
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<RecurringSeriesRow?> getSeries(String id) {
    return _recurringDao.getSeries(id);
  }

  @override
  Future<List<ScheduledTransactionViewRow>> scheduledForSeries(
      String seriesId) {
    return _recurringDao.scheduledForSeries(seriesId);
  }

  @override
  Future<void> insertOrUpdateScheduled(
      ScheduledTransactionsViewCompanion entry) {
    return _recurringDao.insertOrUpdateScheduled(entry);
  }

  @override
  Stream<List<ScheduledTransactionEntity>> watchAllScheduled({
    String? currencyCode,
  }) {
    return _recurringDao
        .watchAllScheduledJoined(currencyCode: currencyCode)
        .map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Stream<List<ScheduledTransactionEntity>> watchPendingScheduled({
    String? currencyCode,
  }) {
    return _recurringDao
        .watchAllScheduledJoined(
          currencyCode: currencyCode,
          pendingOnly: true,
        )
        .map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Stream<List<ScheduledTransactionEntity>> watchScheduledInRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
    String? currencyCode,
    bool pendingOnly = false,
  }) {
    return _recurringDao
        .watchAllScheduledJoined(
          currencyCode: currencyCode,
          pendingOnly: pendingOnly,
          startInclusive: startInclusive,
          endExclusive: endExclusive,
        )
        .map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<void> deletePending(String seriesId, {DateTime? from}) {
    return _recurringDao.deleteScheduledForSeries(
      seriesId,
      from: from,
      status: ScheduledTransactionStatus.scheduled.toStorage(),
    );
  }

  @override
  Future<void> deletePendingForSeries(String seriesId) {
    return _recurringDao.deletePendingScheduledForSeries(seriesId);
  }

  @override
  Future<void> deletePendingAndSkippedForSeries(String seriesId) {
    return _recurringDao.deletePendingAndSkippedScheduledForSeries(seriesId);
  }

  @override
  Future<void> restoreSkippedBill(String id, {required DateTime now}) {
    return _recurringDao.restoreSkippedIfValid(id, now: now);
  }

  @override
  Future<void> deleteScheduledById(String id) {
    return _recurringDao.deleteScheduledById(id);
  }

  @override
  Future<void> deleteAllScheduledForSeries(String seriesId) {
    return _recurringDao.deleteScheduledForSeries(seriesId);
  }

  @override
  Future<void> deleteSeriesWithInstances(String seriesId) async {
    await _recurringDao.transaction(() async {
      await _recurringDao.deleteScheduledForSeries(seriesId);
      await _recurringDao.deleteSeries(seriesId);
    });
  }

  ScheduledTransactionEntity _toEntity(ScheduledBillJoinedRow joined) {
    final row = joined.scheduled;
    final seriesRow = joined.series;
    final category = joined.category;
    return ScheduledTransactionEntity(
      id: row.id,
      seriesId: row.seriesId,
      occurrenceKey: row.occurrenceKey,
      scheduledDate: row.scheduledDate,
      amountOverrideMinor: row.amountOverrideMinor,
      dateOverride: row.dateOverride,
      memoOverride: row.memoOverride,
      status: decodeScheduledStatus(row.status),
      manualOnly: row.manualOnly,
      transactionId: row.transactionId,
      recurringTransactionSeries: _toSeriesEntity(seriesRow),
      kind: seriesRow.type.toTransactionKind,
      category: category == null ? null : _toCategoryEntity(category),
      account: _toAccountEntity(joined.account),
    );
  }

  CategoryEntity _toCategoryEntity(CategoryViewRow row) => CategoryEntity(
        id: row.id,
        name: row.name,
        iconKey: row.iconKey,
        colorInt: row.colorInt,
        type: row.type,
      );

  AccountEntity _toAccountEntity(AccountViewRow row) => AccountEntity(
        id: row.id,
        name: row.name,
        type: row.type,
        currencyCode: row.currencyCode,
        balanceMinor: row.balanceMinor,
        archived: row.archived,
        includeInTotals: row.includeInTotals,
        lastUpdatedEventId: row.lastUpdatedEventId,
      );

  @override
  Future<int> skipIfScheduled(String id) => _recurringDao.skipIfScheduled(id);

  @override
  Future<void> markManualOnly(String id) => _recurringDao.markManualOnly(id);

  @override
  Future<int> markManualOnlyBatch(List<String> ids) =>
      _recurringDao.markManualOnlyBatch(ids);

  @override
  Future<void> markSeriesManualOnlyBefore(String seriesId, DateTime cutoff) =>
      _recurringDao.markSeriesManualOnlyBefore(seriesId, cutoff);

  @override
  Future<int> markAllScheduledManualOnlyBefore(DateTime cutoff) =>
      _recurringDao.markAllScheduledManualOnlyBefore(cutoff);

  @override
  Future<int> resetFailedToScheduledForSeries(String seriesId) =>
      _recurringDao.resetFailedToScheduledForSeries(seriesId);

  @override
  Future<List<RecurringSeriesRow>> getAllRecurringSeries() {
    return _recurringDao.getAllSeries();
  }

  @override
  Future<List<RecurringSeriesRow>> getMaterializableRecurringSeries() =>
      _recurringDao.getMaterializableSeries();

  @override
  Future<void> insertMaterializedIfActive(
          ScheduledTransactionsViewCompanion entry) =>
      _recurringDao.insertMaterializedIfActive(entry);

  @override
  Future<bool> insertMaterializedBatchIfActive(
    String seriesId,
    List<ScheduledTransactionsViewCompanion> entries,
  ) =>
      _recurringDao.insertMaterializedBatchIfActive(seriesId, entries);

  @override
  Future<void> saveSeries(RecurringSeriesCompanion entry) {
    return _recurringDao.saveSeries(entry);
  }

  RecurringTransactionSeriesEntity _toSeriesEntity(RecurringSeriesRow row) =>
      RecurringTransactionSeriesEntity(
        id: row.id,
        description: row.description,
        startDate: row.startDate,
        endDate: row.endDate,
        amountMinor: row.amountMinor,
        categoryId: row.categoryId,
        accountId: row.accountId,
        type: row.type,
        frequency: row.frequency,
        rrule: row.rrule,
        interval: row.interval,
        limit: row.countLimit,
        autoPost: row.autoPost,
        reminderMinutes: row.reminderMinutes,
        mode: row.mode,
        isActive: row.isActive,
        materializeFrom: row.materializeFrom,
        completedCountOffset: row.completedCountOffset,
      );
}

@riverpod
RecurringRepository recurringRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return RecurringRepositoryImpl(
    RecurringDao(db),
    CategoriesDao(db),
    AccountDao(db),
  );
}
