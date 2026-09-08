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

String _$heatmapDataHash() => r'dd2560d27c908ed6e37aab4b69c15933b832d394';

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

String _$incomeChartDataHash() => r'25343c078ec6acda546cb799bfa141afd4467e18';

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

String _$expenseChartDataHash() => r'7207403f533776485ef05a7e0b67cca3f2a074a2';

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
