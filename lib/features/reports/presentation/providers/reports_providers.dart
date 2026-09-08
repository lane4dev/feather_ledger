import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';

import '../../data/repositories/reports_repository.dart';
import '../../domain/entities/reports_entities.dart';

part 'reports_providers.g.dart';

enum HeatmapMode { frequency, amount }

@riverpod
class HeatmapModeState extends _$HeatmapModeState {
  @override
  HeatmapMode build() => HeatmapMode.frequency;

  void setMode(HeatmapMode mode) {
    state = mode;
  }
}

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
Stream<Map<DateTime, int>> heatmapData(Ref ref) {
  final repo = ref.watch(reportsRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  final mode = ref.watch(heatmapModeStateProvider);

  return mode == HeatmapMode.frequency
      ? repo.watchHeatmapData(date)
      : repo.watchHeatmapAmountData(date);
}

@riverpod
Stream<List<ReportCategoryTotal>> incomeChartData(Ref ref) {
  final repo = ref.watch(reportsRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  return repo.watchCategoryBreakdown(date, CategoryType.income);
}

@riverpod
Stream<List<ReportCategoryTotal>> expenseChartData(Ref ref) {
  final repo = ref.watch(reportsRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  return repo.watchCategoryBreakdown(date, CategoryType.expense);
}

/// Monthly income/expense/balance from the snapshot projection (spec 003,
/// US9/T065) — the same source the ledger header reads.
@riverpod
Stream<ReportMonthlyTotals> monthlyTotals(Ref ref) {
  final repo = ref.watch(reportsRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  final currencyCode = ref.watch(currencyControllerProvider).value ??
      AppCurrencies.defaultCurrency.code;
  return repo.watchMonthlyTotals(date, currencyCode: currencyCode);
}
