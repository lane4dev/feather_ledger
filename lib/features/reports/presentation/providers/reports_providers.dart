import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:feather_ledger/core/database/tables.dart';
import 'package:feather_ledger/features/ledger/presentation/providers/ledger_providers.dart';
import 'package:feather_ledger/features/reports/data/repositories/reports_repository.dart';
import 'package:feather_ledger/features/reports/domain/reports_entities.dart';

part 'reports_providers.g.dart';

@riverpod
Stream<Map<DateTime, int>> heatmapData(Ref ref) {
  final repo = ref.watch(reportsRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  return repo.watchHeatmapData(date);
}

@riverpod
Stream<List<ReportCategoryTotal>> incomeChartData(Ref ref) {
  final repo = ref.watch(reportsRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  return repo.watchCategoryBreakdown(date, TransactionType.income);
}

@riverpod
Stream<List<ReportCategoryTotal>> expenseChartData(Ref ref) {
  final repo = ref.watch(reportsRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  return repo.watchCategoryBreakdown(date, TransactionType.expense);
}