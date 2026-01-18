import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/database/tables.dart';
import 'package:feather_ledger/features/ledger/data/repositories/ledger_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

part 'ledger_service.g.dart';

class LedgerService {
  final LedgerRepository _repository;

  LedgerService(this._repository);

  Stream<List<TransactionEntity>> watchTransactions(DateTime month) {
    return _repository.watchTransactions(month);
  }

  Stream<MonthlySummary> watchMonthlySummary(DateTime month) {
    return _repository.watchMonthlySummary(month);
  }

  Future<void> addTransaction({
    required double amount,
    required TransactionType type,
    required DateTime date,
    required int categoryId,
    required int accountId,
    String? note,
  }) {
    if (amount <= 0) {
      throw Exception('Amount must be positive');
    }
    return _repository.addTransaction(
      amount: amount,
      type: type,
      date: date,
      categoryId: categoryId,
      accountId: accountId,
      note: note,
    );
  }

  Future<void> deleteTransaction(int id) {
    return _repository.deleteTransaction(id);
  }
}

@riverpod
LedgerService ledgerService(Ref ref) {
  final repository = ref.watch(ledgerRepositoryProvider);
  return LedgerService(repository);
}
