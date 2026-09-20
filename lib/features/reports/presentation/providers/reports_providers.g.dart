// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HeatmapModeState)
final heatmapModeStateProvider = HeatmapModeStateProvider._();

final class HeatmapModeStateProvider
    extends $NotifierProvider<HeatmapModeState, HeatmapMode> {
  HeatmapModeStateProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'heatmapModeStateProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$heatmapModeStateHash();

  @$internal
  @override
  HeatmapModeState create() => HeatmapModeState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HeatmapMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HeatmapMode>(value),
    );
  }
}

String _$heatmapModeStateHash() => r'febb32e728028c50cc8afc264eb02b0b4150984f';

abstract class _$HeatmapModeState extends $Notifier<HeatmapMode> {
  HeatmapMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<HeatmapMode, HeatmapMode>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<HeatmapMode, HeatmapMode>, HeatmapMode, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(SelectedDate)
final selectedDateProvider = SelectedDateProvider._();

final class SelectedDateProvider
    extends $NotifierProvider<SelectedDate, DateTime> {
  SelectedDateProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'selectedDateProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$selectedDateHash();

  @$internal
  @override
  SelectedDate create() => SelectedDate();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$selectedDateHash() => r'cc9b319722e2f967ffe36ff1184e0e14a6d96cf6';

abstract class _$SelectedDate extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<DateTime, DateTime>, DateTime, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(heatmapData)
final heatmapDataProvider = HeatmapDataProvider._();

final class HeatmapDataProvider extends $FunctionalProvider<
        AsyncValue<Map<DateTime, int>>,
        Map<DateTime, int>,
        Stream<Map<DateTime, int>>>
    with
        $FutureModifier<Map<DateTime, int>>,
        $StreamProvider<Map<DateTime, int>> {
  HeatmapDataProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'heatmapDataProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$heatmapDataHash();

  @$internal
  @override
  $StreamProviderElement<Map<DateTime, int>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Map<DateTime, int>> create(Ref ref) {
    return heatmapData(ref);
  }
}

String _$heatmapDataHash() => r'10f7e7d967c36af4983ae770aba1571d987f075a';

@ProviderFor(incomeChartData)
final incomeChartDataProvider = IncomeChartDataProvider._();

final class IncomeChartDataProvider extends $FunctionalProvider<
        AsyncValue<List<ReportCategoryTotal>>,
        List<ReportCategoryTotal>,
        Stream<List<ReportCategoryTotal>>>
    with
        $FutureModifier<List<ReportCategoryTotal>>,
        $StreamProvider<List<ReportCategoryTotal>> {
  IncomeChartDataProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'incomeChartDataProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$incomeChartDataHash();

  @$internal
  @override
  $StreamProviderElement<List<ReportCategoryTotal>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<ReportCategoryTotal>> create(Ref ref) {
    return incomeChartData(ref);
  }
}

String _$incomeChartDataHash() => r'8eb0ec86b07856b08cfbb3c7a9516f754f6f2a32';

@ProviderFor(expenseChartData)
final expenseChartDataProvider = ExpenseChartDataProvider._();

final class ExpenseChartDataProvider extends $FunctionalProvider<
        AsyncValue<List<ReportCategoryTotal>>,
        List<ReportCategoryTotal>,
        Stream<List<ReportCategoryTotal>>>
    with
        $FutureModifier<List<ReportCategoryTotal>>,
        $StreamProvider<List<ReportCategoryTotal>> {
  ExpenseChartDataProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'expenseChartDataProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$expenseChartDataHash();

  @$internal
  @override
  $StreamProviderElement<List<ReportCategoryTotal>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<ReportCategoryTotal>> create(Ref ref) {
    return expenseChartData(ref);
  }
}

String _$expenseChartDataHash() => r'b59f76d66cefa12a932e62a8807222e1a22ce127';

/// Monthly income/expense/balance from the snapshot projection (spec 003,
/// US9/T065) — the same source the ledger header reads.

@ProviderFor(monthlyTotals)
final monthlyTotalsProvider = MonthlyTotalsProvider._();

/// Monthly income/expense/balance from the snapshot projection (spec 003,
/// US9/T065) — the same source the ledger header reads.

final class MonthlyTotalsProvider extends $FunctionalProvider<
        AsyncValue<ReportMonthlyTotals>,
        ReportMonthlyTotals,
        Stream<ReportMonthlyTotals>>
    with
        $FutureModifier<ReportMonthlyTotals>,
        $StreamProvider<ReportMonthlyTotals> {
  /// Monthly income/expense/balance from the snapshot projection (spec 003,
  /// US9/T065) — the same source the ledger header reads.
  MonthlyTotalsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'monthlyTotalsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$monthlyTotalsHash();

  @$internal
  @override
  $StreamProviderElement<ReportMonthlyTotals> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<ReportMonthlyTotals> create(Ref ref) {
    return monthlyTotals(ref);
  }
}

String _$monthlyTotalsHash() => r'3eadd0c7763ec38256da3781be69c4a794c6f89d';

/// The same totals, written out where the currency is known.

@ProviderFor(monthlySummary)
final monthlySummaryProvider = MonthlySummaryProvider._();

/// The same totals, written out where the currency is known.

final class MonthlySummaryProvider extends $FunctionalProvider<
        AsyncValue<MonthlySummaryUiModel>,
        AsyncValue<MonthlySummaryUiModel>,
        AsyncValue<MonthlySummaryUiModel>>
    with $Provider<AsyncValue<MonthlySummaryUiModel>> {
  /// The same totals, written out where the currency is known.
  MonthlySummaryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'monthlySummaryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$monthlySummaryHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<MonthlySummaryUiModel>> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AsyncValue<MonthlySummaryUiModel> create(Ref ref) {
    return monthlySummary(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<MonthlySummaryUiModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<MonthlySummaryUiModel>>(value),
    );
  }
}

String _$monthlySummaryHash() => r'b03c03a499cb080b1c5b1d9ac3563bfb047a68cf';
