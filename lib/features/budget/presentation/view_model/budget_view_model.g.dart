// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BudgetViewModel)
final budgetViewModelProvider = BudgetViewModelProvider._();

final class BudgetViewModelProvider
    extends $NotifierProvider<BudgetViewModel, BudgetUiState> {
  BudgetViewModelProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'budgetViewModelProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$budgetViewModelHash();

  @$internal
  @override
  BudgetViewModel create() => BudgetViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BudgetUiState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BudgetUiState>(value),
    );
  }
}

String _$budgetViewModelHash() => r'474dc233d1b29fd154c774b8a2c1555b82f77188';

abstract class _$BudgetViewModel extends $Notifier<BudgetUiState> {
  BudgetUiState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BudgetUiState, BudgetUiState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<BudgetUiState, BudgetUiState>,
        BudgetUiState,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(budgetMonthSummary)
final budgetMonthSummaryProvider = BudgetMonthSummaryFamily._();

final class BudgetMonthSummaryProvider extends $FunctionalProvider<
        AsyncValue<MonthBudgetSummary>,
        MonthBudgetSummary,
        Stream<MonthBudgetSummary>>
    with
        $FutureModifier<MonthBudgetSummary>,
        $StreamProvider<MonthBudgetSummary> {
  BudgetMonthSummaryProvider._(
      {required BudgetMonthSummaryFamily super.from,
      required YearMonth super.argument})
      : super(
          retry: null,
          name: r'budgetMonthSummaryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$budgetMonthSummaryHash();

  @override
  String toString() {
    return r'budgetMonthSummaryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<MonthBudgetSummary> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<MonthBudgetSummary> create(Ref ref) {
    final argument = this.argument as YearMonth;
    return budgetMonthSummary(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BudgetMonthSummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$budgetMonthSummaryHash() =>
    r'17913bef09633c91e5d242e172e9dcd7d8adbb1b';

final class BudgetMonthSummaryFamily extends $Family
    with $FunctionalFamilyOverride<Stream<MonthBudgetSummary>, YearMonth> {
  BudgetMonthSummaryFamily._()
      : super(
          retry: null,
          name: r'budgetMonthSummaryProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  BudgetMonthSummaryProvider call(
    YearMonth month,
  ) =>
      BudgetMonthSummaryProvider._(argument: month, from: this);

  @override
  String toString() => r'budgetMonthSummaryProvider';
}
