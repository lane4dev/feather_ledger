// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$heatmapDataHash() => r'dd2560d27c908ed6e37aab4b69c15933b832d394';

/// See also [heatmapData].
@ProviderFor(heatmapData)
final heatmapDataProvider =
    AutoDisposeStreamProvider<Map<DateTime, int>>.internal(
  heatmapData,
  name: r'heatmapDataProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$heatmapDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HeatmapDataRef = AutoDisposeStreamProviderRef<Map<DateTime, int>>;
String _$incomeChartDataHash() => r'27de51d3e732243b98d000898224e33cdefbcdff';

/// See also [incomeChartData].
@ProviderFor(incomeChartData)
final incomeChartDataProvider =
    AutoDisposeStreamProvider<List<ReportCategoryTotal>>.internal(
  incomeChartData,
  name: r'incomeChartDataProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$incomeChartDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IncomeChartDataRef
    = AutoDisposeStreamProviderRef<List<ReportCategoryTotal>>;
String _$expenseChartDataHash() => r'b3340e5e0517994e1e289a4f79fc427aec53806c';

/// See also [expenseChartData].
@ProviderFor(expenseChartData)
final expenseChartDataProvider =
    AutoDisposeStreamProvider<List<ReportCategoryTotal>>.internal(
  expenseChartData,
  name: r'expenseChartDataProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$expenseChartDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ExpenseChartDataRef
    = AutoDisposeStreamProviderRef<List<ReportCategoryTotal>>;
String _$heatmapModeStateHash() => r'febb32e728028c50cc8afc264eb02b0b4150984f';

/// See also [HeatmapModeState].
@ProviderFor(HeatmapModeState)
final heatmapModeStateProvider =
    AutoDisposeNotifierProvider<HeatmapModeState, HeatmapMode>.internal(
  HeatmapModeState.new,
  name: r'heatmapModeStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$heatmapModeStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$HeatmapModeState = AutoDisposeNotifier<HeatmapMode>;
String _$selectedDateHash() => r'cc9b319722e2f967ffe36ff1184e0e14a6d96cf6';

/// See also [SelectedDate].
@ProviderFor(SelectedDate)
final selectedDateProvider =
    AutoDisposeNotifierProvider<SelectedDate, DateTime>.internal(
  SelectedDate.new,
  name: r'selectedDateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$selectedDateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedDate = AutoDisposeNotifier<DateTime>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
