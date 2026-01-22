import 'package:feather_ledger/core/domain/entities/enums.dart';

import '../entities/ledger_entities.dart';

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
