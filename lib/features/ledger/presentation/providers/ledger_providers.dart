import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/services/ledger_service.dart';

part 'ledger_providers.g.dart';

@riverpod
class SelectedDate extends _$SelectedDate {
  @override
  DateTime build() {
    return DateTime.now();
  }

  void setMonth(DateTime date) {
    state = date;
  }
}

@riverpod
Stream<List<TransactionEntity>> ledgerTransactions(Ref ref) {
  final service = ref.watch(ledgerServiceProvider);
  final date = ref.watch(selectedDateProvider);
  return service.watchTransactions(date);
}

@riverpod
Stream<MonthlySummary> ledgerSummary(Ref ref) {
  final service = ref.watch(ledgerServiceProvider);
  final date = ref.watch(selectedDateProvider);
  return service.watchMonthlySummary(date);
}

@riverpod
Future<List<Category>> allCategories(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.transactionDao.getAllCategories();
}

@riverpod
Future<List<Account>> allAccounts(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.transactionDao.getAllAccounts();
}

@riverpod
Future<Map<DateTime, List<TransactionEntity>>> dailyTransactions(
    Ref ref) async {
  final transactions = await ref.watch(ledgerTransactionsProvider.future);

  final grouped = <DateTime, List<TransactionEntity>>{};

  for (final tx in transactions) {
    // Strip time to get date only
    final dateKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
    if (!grouped.containsKey(dateKey)) {
      grouped[dateKey] = [];
    }
    grouped[dateKey]!.add(tx);
  }

  // No need to sort if the repository already returns sorted transactions.
  // Assuming repo sorts DESC. If not, we might need to sort keys.
  // But Maps iterate in insertion order in Dart (mostly), so if input is sorted, output keys are sorted.

  return grouped;
}
