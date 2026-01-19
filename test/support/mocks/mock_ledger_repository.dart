import 'dart:async';

import 'package:feather_ledger/core/database/tables.dart';
import 'package:feather_ledger/features/ledger/data/repositories/ledger_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

/// Mock LedgerRepository for testing purposes
class MockLedgerRepository implements LedgerRepository {
  final StreamController<List<TransactionEntity>> _transactionsController =
      StreamController<List<TransactionEntity>>.broadcast(sync: true);
  final StreamController<MonthlySummary> _summaryController =
      StreamController<MonthlySummary>.broadcast(sync: true);

  int addTransactionCallCount = 0;
  double? lastAmount;
  TransactionType? lastType;
  DateTime? lastDate;
  int? lastCategoryId;
  int? lastAccountId;
  String? lastNote;

  int deleteTransactionCallCount = 0;
  int? lastDeletedId;

  @override
  Stream<List<TransactionEntity>> watchTransactions(DateTime month) {
    return _transactionsController.stream;
  }

  @override
  Stream<MonthlySummary> watchMonthlySummary(DateTime month) {
    return _summaryController.stream;
  }

  @override
  Future<void> addTransaction({
    required double amount,
    required TransactionType type,
    required DateTime date,
    required int categoryId,
    required int accountId,
    String? note,
  }) async {
    addTransactionCallCount++;
    lastAmount = amount;
    lastType = type;
    lastDate = date;
    lastCategoryId = categoryId;
    lastAccountId = accountId;
    lastNote = note;
    // Simulate async operation
    await Future.delayed(Duration.zero);
  }

  @override
  Future<void> deleteTransaction(int id) async {
    deleteTransactionCallCount++;
    lastDeletedId = id;
    // Simulate async operation
    await Future.delayed(Duration.zero);
  }

  // Helper methods for testing
  void emitTransactions(List<TransactionEntity> transactions) {
    _transactionsController.add(transactions);
  }

  void emitSummary(MonthlySummary summary) {
    _summaryController.add(summary);
  }

  void dispose() {
    _transactionsController.close();
    _summaryController.close();
  }

  void reset() {
    addTransactionCallCount = 0;
    lastAmount = null;
    lastType = null;
    lastDate = null;
    lastCategoryId = null;
    lastAccountId = null;
    lastNote = null;
    deleteTransactionCallCount = 0;
    lastDeletedId = null;
  }
}
