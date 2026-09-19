import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';

import '../../data/repositories/reports_repository.dart';
import 'package:feather_ledger/shared/presentation/models/monthly_summary_ui_model.dart';

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
  // Reports have no independent currency switch (spec 006): they follow the
  // setting's currency like the ledger and search.
  final currencyCode = ref.watch(currencyControllerProvider).value ??
      AppCurrencies.defaultCurrency.code;

  return mode == HeatmapMode.frequency
      ? repo.watchHeatmapFrequencyData(date, currencyCode: currencyCode)
      : repo.watchHeatmapAmountData(date, currencyCode: currencyCode);
}

@riverpod
Stream<List<ReportCategoryTotal>> incomeChartData(Ref ref) {
  final repo = ref.watch(reportsRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  final currencyCode = ref.watch(currencyControllerProvider).value ??
      AppCurrencies.defaultCurrency.code;
  return repo.watchCategoryBreakdown(date, CategoryType.income,
      currencyCode: currencyCode);
}

@riverpod
Stream<List<ReportCategoryTotal>> expenseChartData(Ref ref) {
  final repo = ref.watch(reportsRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  final currencyCode = ref.watch(currencyControllerProvider).value ??
      AppCurrencies.defaultCurrency.code;
  return repo.watchCategoryBreakdown(date, CategoryType.expense,
      currencyCode: currencyCode);
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

/// The same totals, written out where the currency is known.
@riverpod
AsyncValue<MonthlySummaryUiModel> monthlySummary(Ref ref) {
  final symbol = AppCurrencies.getSymbol(
      ref.watch(currencyControllerProvider).value ??
          AppCurrencies.defaultCurrency.code);
  return ref
      .watch(monthlyTotalsProvider)
      .whenData((totals) => MonthlySummaryUiModel.of(
            balanceMinor: totals.balanceMinor,
            incomeMinor: totals.incomeMinor,
            expenseMinor: totals.expenseMinor,
            currencySymbol: symbol,
          ));
}
