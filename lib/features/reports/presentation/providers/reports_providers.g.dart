// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$heatmapDataHash() => r'3dccd03f45588c9abaf57fc802f780e8a62022d4';

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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
