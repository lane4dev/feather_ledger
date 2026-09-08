import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/transaction_dao.dart';
import 'package:feather_ledger/core/data/database/daos/recurring_dao.dart';

import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
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
  Stream<List<TransactionEntity>> watchTransactions(DateTime datetime) {
    return _transactionsDao.watchTransactionsByMonth(datetime).map((rows) {
      return _toTransactionEntities(rows);
    });
  }

  @override
  Future<TransactionEntity?> getTransaction(String transactionId) async {
    final rows = await _transactionsDao.getTransactionRows(transactionId);
    if (rows.isEmpty) return null;
    return _toTransactionEntities(rows).single;
  }

  /// Aggregates the posting-level join rows into one entity per
  /// transaction: a transfer's two postings collapse into a single row
  /// (spec 003, US5/T042).
  List<TransactionEntity> _toTransactionEntities(
      List<TransactionWithDetails> rows) {
    final grouped = <String, List<TransactionWithDetails>>{};
    for (final row in rows) {
      grouped
          .putIfAbsent(row.transaction.transactionId, () => [])
          .add(row);
    }
    return grouped.values.map(_toTransactionEntity).toList();
  }

  TransactionEntity _toTransactionEntity(List<TransactionWithDetails> rows) {
    final tx = rows.first.transaction;
    final posting = rows.first.posting;
    final categoryType = tx.kind == TransactionKind.income
        ? CategoryType.income
        : CategoryType.expense;
    final category = CategoryEntity(
      id: posting.categoryId ?? '',
      // Write-time snapshot (T033/T037): history renders the archived
      // category without joining the live row. Transfers have no category.
      name: tx.categoryName ?? '',
      iconKey: tx.categoryIcon ?? '',
      colorInt: tx.categoryColorInt == null
          ? 0
          : int.parse(tx.categoryColorInt!, radix: 16),
      type: categoryType,
    );

    AccountEntity? toAccount;
    var amount = postingSignedImpact(posting);
    if (tx.kind == TransactionKind.transfer) {
      final debit =
          rows.firstWhere((r) => r.posting.direction == PostingDirection.debit);
      final credit = rows
          .firstWhere((r) => r.posting.direction == PostingDirection.credit);
      amount = debit.posting.amountMinor; // positive; direction is separate
      toAccount = _toAccountEntity(credit.account);
      // The debit side is the "from" account shown as the primary account.
      return _buildEntity(tx, debit, amount, category, toAccount);
    }

    return _buildEntity(tx, rows.first, amount, category, null);
  }

  TransactionEntity _buildEntity(
    TransactionViewRow tx,
    TransactionWithDetails row,
    int amount,
    CategoryEntity category,
    AccountEntity? toAccount,
  ) {
    return TransactionEntity(
      id: tx.transactionId,
      amount: amount,
      type: tx.kind,
      date: tx.occurredAt,
      note: tx.description,
      category: category,
      account: _toAccountEntity(row.account),
      toAccount: toAccount,
      isReversed: tx.isReversed,
      eventId: tx.originalEventId,
    );
  }

  AccountEntity _toAccountEntity(AccountViewRow row) => AccountEntity(
        id: row.id,
        name: row.name,
        type: row.type,
        currencyCode: row.currencyCode,
        balanceMinor: row.balanceMinor,
        archived: row.archived,
        lastUpdatedEventId: row.lastUpdatedEventId,
      );

  @override
  Stream<List<ScheduledTransactionEntity>> watchScheduledTransactions() {
    return _recurringDao.watchAllScheduled().asyncMap((rows) async {
      final result = <ScheduledTransactionEntity>[];
      for (var row in rows) {
        final seriesRow = await _recurringDao.getSeries(row.seriesId);
        if (seriesRow != null) {
          result.add(ScheduledTransactionEntity(
            id: row.id,
            amountMinor: row.amountMinor,
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
              amountMinor: seriesRow.amountMinor,
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
      amountMinor: scheduledRow.amountMinor,
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
        amountMinor: seriesRow.amountMinor,
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
      amountMinor: seriesRow.amountMinor,
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
        amountMinor: seriesRow.amountMinor,
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
        amountMinor: Value(scheduled.amountMinor),
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
