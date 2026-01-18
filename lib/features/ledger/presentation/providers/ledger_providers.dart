import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/database/app_database.dart';
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
