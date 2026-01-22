import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/transaction_dao.dart';
import 'package:feather_ledger/core/domain/entities/enums.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';

import '../../domain/entities/ledger_entities.dart';

part 'ledger_repository.g.dart';

abstract class LedgerRepository {
  Stream<List<TransactionEntity>> watchTransactions(DateTime month);
  Stream<MonthlySummary> watchMonthlySummary(DateTime month);
  Future<void> addTransaction({
    required double amount,
    required TransactionType type, // Removed db_tables. prefix
    required DateTime date,
    required int categoryId,
    required int accountId,
    String? note,
  });
  Future<void> updateTransaction({
    required int id,
    required double amount,
    required TransactionType type, // Removed db_tables. prefix
    required DateTime date,
    required int categoryId,
    required int accountId,
    String? note,
  });
  Future<void> deleteTransaction(int id);
}

class LedgerRepositoryImpl implements LedgerRepository {
  final TransactionDao _dao;

  LedgerRepositoryImpl(this._dao);

  @override
  Stream<List<TransactionEntity>> watchTransactions(DateTime month) {
    return _dao.watchTransactionsByMonth(month).map((rows) {
      return rows.map((row) {
        return TransactionEntity(
          id: row.transaction.id,
          amount: row.transaction.amount,
          type: row.transaction.type,
          date: row.transaction.date,
          note: row.transaction.note,
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
            initialBalance: row.account.initialBalance,
          ),
        );
      }).toList();
    });
  }

  @override
  Stream<MonthlySummary> watchMonthlySummary(DateTime month) async* {
    final totalsStream = _dao.watchMonthlyTotals(month);

    await for (final totals in totalsStream) {
      final endOfMonth = DateTime(month.year, month.month + 1, 1)
          .subtract(const Duration(seconds: 1));
      final balance = await _dao.getRunningBalance(endOfMonth);

      yield MonthlySummary(
        month: month,
        totalIncome: totals['income']!,
        totalExpense: totals['expense']!,
        runningBalance: balance,
      );
    }
  }

  @override
  Future<void> addTransaction({
    required double amount,
    required TransactionType type, // Removed db_tables. prefix
    required DateTime date,
    required int categoryId,
    required int accountId,
    String? note,
  }) {
    return _dao.addTransaction(TransactionsCompanion(
      amount: Value(amount),
      type: Value(type),
      date: Value(date),
      categoryId: Value(categoryId),
      accountId: Value(accountId),
      note: Value(note),
    ));
  }

  @override
  Future<void> updateTransaction({
    required int id,
    required double amount,
    required TransactionType type, // Removed db_tables. prefix
    required DateTime date,
    required int categoryId,
    required int accountId,
    String? note,
  }) {
    return _dao.updateTransaction(TransactionsCompanion(
      id: Value(id),
      amount: Value(amount),
      type: Value(type),
      date: Value(date),
      categoryId: Value(categoryId),
      accountId: Value(accountId),
      note: Value(note),
    ));
  }

  @override
  Future<void> deleteTransaction(int id) {
    return _dao.deleteTransaction(id);
  }
}

@riverpod
LedgerRepository ledgerRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return LedgerRepositoryImpl(db.transactionDao);
}
