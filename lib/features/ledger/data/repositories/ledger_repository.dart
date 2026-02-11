import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/transaction_dao.dart';
import 'package:feather_ledger/core/data/database/daos/recurring_dao.dart';

import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/value_objects/monthly_summary.dart';
import 'package:feather_ledger/features/ledger/domain/repositories/ledger_repository.dart';

export 'package:feather_ledger/features/ledger/domain/repositories/ledger_repository.dart';

part 'ledger_repository.g.dart';

class LedgerRepositoryImpl implements LedgerRepository {
  final TransactionsDao _transactionsDao;
  final RecurringDao _recurringDao;

  LedgerRepositoryImpl(
    this._transactionsDao,
    this._recurringDao,
  );

  @override
  Stream<MonthlySummary> watchMonthlySummary(DateTime datetime) {
    final monthEnd = DateTime(datetime.year, datetime.month + 1, 0, 23, 59, 59);

    return _transactionsDao
        .watchMonthlyTotals(datetime)
        .asyncMap((totals) async {
      final runningBalanceCents =
          await _transactionsDao.getRunningBalance(monthEnd);

      return MonthlySummary(
        datetime: datetime,
        totalIncome: totals['income'] ?? 0,
        totalExpense: totals['expense'] ?? 0,
        runningBalance: runningBalanceCents / 100.0,
      );
    });
  }

  @override
  Stream<List<TransactionEntity>> watchTransactions(DateTime datetime) {
    return _transactionsDao.watchTransactionsByMonth(datetime).map((rows) {
      return rows.map((row) {
        return TransactionEntity(
          id: row.transaction.transactionId,
          amount: row.transaction.amount,
          type: row.category.type == TransactionType.income
              ? TransactionType.income
              : TransactionType.expense,
          date: row.transaction.date,
          note: row.transaction.description,
          category: CategoryEntity(
            id: row.category.id,
            name: row.category.name,
            iconKey: row.category.iconKey,
            colorInt: row.category.colorInt,
            type: row.category.type,
            isDefault: row.category.isDefault,
          ),
          account: AccountEntity(
            id: row.account.id,
            name: row.account.name,
            type: row.account.type,
            postedBalance: row.account.postedBalance,
            availableBalance: row.account.availableBalance,
            lastUpdatedEventId: row.account.lastUpdatedEventId,
          ),
          isReversed: row.transaction.isReversed,
          eventId: row.transaction.originalEventId,
        );
      }).toList();
    });
  }

  @override
  Future<TransactionEntity?> getTransaction(String transactionId) async {
    final row = await _transactionsDao.getTransaction(transactionId);
    if (row == null) return null;

    return TransactionEntity(
      id: row.transaction.transactionId,
      amount: row.transaction.amount,
      type: row.category.type == TransactionType.income
          ? TransactionType.income
          : TransactionType.expense,
      date: row.transaction.date,
      note: row.transaction.description,
      category: CategoryEntity(
        id: row.category.id,
        name: row.category.name,
        iconKey: row.category.iconKey,
        colorInt: row.category.colorInt,
        type: row.category.type,
        isDefault: row.category.isDefault,
      ),
      account: AccountEntity(
        id: row.account.id,
        name: row.account.name,
        type: row.account.type,
        postedBalance: row.account.postedBalance,
        availableBalance: row.account.availableBalance,
        lastUpdatedEventId: row.account.lastUpdatedEventId,
      ),
      isReversed: row.transaction.isReversed,
      eventId: row.transaction.originalEventId,
    );
  }

  @override
  Future<void> insertOrUpdateTransaction(TransactionEntity transaction) async {
    await _transactionsDao.insertOrReplace(
      TransactionsViewCompanion(
          id: Value(transaction.id),
          transactionId: Value(transaction.id),
          amount: Value(transaction.amount),
          date: Value(transaction.date),
          description: Value(transaction.note ?? ''),
          categoryId: Value(transaction.category.id),
          accountId: Value(transaction.account.id),
          isReversed: Value(transaction.isReversed),
          originalEventId: Value(transaction.eventId)),
    );
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    // Mark the transaction as reversed
    await _transactionsDao.markTransactionAsReversed(transactionId);
  }

  @override
  Stream<List<ScheduledTransactionEntity>> watchScheduledTransactions() {
    return _recurringDao.watchAllScheduled().asyncMap((rows) async {
      final result = <ScheduledTransactionEntity>[];
      for (var row in rows) {
        final seriesRow = await _recurringDao.getSeries(row.seriesId);
        if (seriesRow != null) {
          result.add(ScheduledTransactionEntity(
            id: row.id,
            amount: row.amount / 100.0,
            date: row.date,
            seriesId: row.seriesId,
            status: ScheduledTransactionStatus.values.firstWhere(
              (e) => e.toString().split('.').last == row.status,
              orElse: () => ScheduledTransactionStatus.scheduled,
            ),
            transactionId: row.transactionId,
            recurringTransactionSeries: RecurringTransactionSeriesEntity(
              id: seriesRow.id,
              description: seriesRow.description,
              amount: seriesRow.amount / 100.0,
              type: seriesRow.type,
              categoryId: seriesRow.categoryId,
              accountId: seriesRow.accountId,
              frequency: seriesRow.frequency,
              startDate: seriesRow.startDate,
              endDate: seriesRow.endDate,
              interval: seriesRow.interval,
              limit: seriesRow.countLimit,
            ),
          ));
        }
      }
      return result;
    });
  }

  @override
  Future<ScheduledTransactionEntity?> getScheduledTransaction(
      String scheduledId) async {
    final scheduledRow = await _recurringDao.getScheduled(scheduledId);
    if (scheduledRow == null) return null;

    final seriesRow = await _recurringDao.getSeries(scheduledRow.seriesId);
    if (seriesRow == null) return null;

    return ScheduledTransactionEntity(
      id: scheduledRow.id,
      amount: scheduledRow.amount / 100.0,
      date: scheduledRow.date,
      seriesId: scheduledRow.seriesId,
      status: ScheduledTransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == scheduledRow.status,
        orElse: () => ScheduledTransactionStatus.scheduled,
      ),
      transactionId: scheduledRow.transactionId,
      recurringTransactionSeries: RecurringTransactionSeriesEntity(
        id: seriesRow.id,
        description: seriesRow.description,
        amount: seriesRow.amount / 100.0,
        type: seriesRow.type,
        categoryId: seriesRow.categoryId,
        accountId: seriesRow.accountId,
        frequency: seriesRow.frequency,
        startDate: seriesRow.startDate,
        endDate: seriesRow.endDate,
        interval: seriesRow.interval,
        limit: seriesRow.countLimit,
      ),
    );
  }

  @override
  Future<RecurringTransactionSeriesEntity?> getRecurringTransactionSeries(
      String seriesId) async {
    final seriesRow = await _recurringDao.getSeries(seriesId);
    if (seriesRow == null) return null;

    return RecurringTransactionSeriesEntity(
      id: seriesRow.id,
      description: seriesRow.description,
      amount: seriesRow.amount / 100.0,
      type: seriesRow.type,
      categoryId: seriesRow.categoryId,
      accountId: seriesRow.accountId,
      frequency: seriesRow.frequency,
      startDate: seriesRow.startDate,
      endDate: seriesRow.endDate,
      interval: seriesRow.interval,
      limit: seriesRow.countLimit,
    );
  }

  @override
  Future<List<RecurringTransactionSeriesEntity>> getAllRecurringSeries() async {
    final rows = await _recurringDao.getAllSeries();
    return rows.map((seriesRow) {
      return RecurringTransactionSeriesEntity(
        id: seriesRow.id,
        description: seriesRow.description,
        amount: seriesRow.amount / 100.0,
        type: seriesRow.type,
        categoryId: seriesRow.categoryId,
        accountId: seriesRow.accountId,
        frequency: seriesRow.frequency,
        startDate: seriesRow.startDate,
        endDate: seriesRow.endDate,
        interval: seriesRow.interval,
        limit: seriesRow.countLimit,
      );
    }).toList();
  }

  @override
  Future<void> insertOrUpdateScheduledTransaction(
      ScheduledTransactionEntity scheduled) async {
    await _recurringDao.insertOrUpdateScheduled(
      ScheduledTransactionsViewCompanion(
        id: Value(scheduled.id),
        amount: Value((scheduled.amount * 100).toInt()),
        date: Value(scheduled.date),
        seriesId: Value(scheduled.seriesId),
        status: Value(scheduled.status.toString().split('.').last),
        transactionId: Value(scheduled.transactionId),
      ),
    );
  }
}

@Riverpod(keepAlive: true)
LedgerRepository ledgerRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return LedgerRepositoryImpl(db.transactionsDao, db.recurringDao);
}
