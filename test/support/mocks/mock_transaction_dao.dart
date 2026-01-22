import 'dart:async';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/transaction_dao.dart';
import 'package:feather_ledger/core/domain/entities/enums.dart';

/// Mock TransactionDao for testing purposes
class MockTransactionDao implements TransactionDao {
  final StreamController<List<TransactionWithDetails>> _transactionsController =
      StreamController<List<TransactionWithDetails>>.broadcast(sync: true);
  final StreamController<Map<String, double>> _totalsController =
      StreamController<Map<String, double>>.broadcast(sync: true);
  final StreamController<Map<DateTime, int>> _heatmapController =
      StreamController<Map<DateTime, int>>.broadcast(sync: true);
  final StreamController<List<CategoryTotal>> _categoryTotalsController =
      StreamController<List<CategoryTotal>>.broadcast(sync: true);

  double _runningBalance = 0.0;

  @override
  Stream<List<TransactionWithDetails>> watchTransactionsByMonth(
      DateTime month) {
    return _transactionsController.stream;
  }

  @override
  Stream<Map<String, double>> watchMonthlyTotals(DateTime month) {
    return _totalsController.stream;
  }

  @override
  Future<double> getRunningBalance(DateTime monthEnd) async {
    return _runningBalance;
  }

  @override
  Future<int> addTransaction(TransactionsCompanion entry) async {
    // Return a fake ID
    return 1;
  }

  @override
  Future<int> deleteTransaction(int id) async {
    return 1; // Return number of deleted rows
  }

  @override
  Stream<Map<DateTime, int>> watchDailyTransactionCounts(DateTime month) {
    return _heatmapController.stream;
  }

  @override
  Stream<List<CategoryTotal>> watchCategoryTotals(
      DateTime month, TransactionType type) {
    return _categoryTotalsController.stream;
  }

  // Helper methods for testing
  void emitTransactions(List<TransactionWithDetails> transactions) {
    _transactionsController.add(transactions);
  }

  void emitMonthlyTotals(double income, double expense) {
    _totalsController.add({'income': income, 'expense': expense});
  }

  void emitHeatmapData(Map<DateTime, int> data) {
    _heatmapController.add(data);
  }

  void emitCategoryTotals(List<CategoryTotal> totals) {
    _categoryTotalsController.add(totals);
  }

  void setRunningBalance(double balance) {
    _runningBalance = balance;
  }

  void dispose() {
    _transactionsController.close();
    _totalsController.close();
    _heatmapController.close();
    _categoryTotalsController.close();
  }

  // Unimplemented methods from TransactionDao
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
