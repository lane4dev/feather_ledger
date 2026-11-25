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

String _$budgetViewModelHash() => r'3cc9897701d368edd7fdba17d72102de8c17a379';

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

/// The home page's view model for one month: the mapper's output, derived from
/// the month stream, the display currency and the locale.
///
/// A provider rather than a call in `build`, so the page never re-maps on a
/// rebuild that changed none of those three, and so every consumer of the same
/// month shares one model.

@ProviderFor(budgetScreenUiModel)
final budgetScreenUiModelProvider = BudgetScreenUiModelFamily._();

/// The home page's view model for one month: the mapper's output, derived from
/// the month stream, the display currency and the locale.
///
/// A provider rather than a call in `build`, so the page never re-maps on a
/// rebuild that changed none of those three, and so every consumer of the same
/// month shares one model.

final class BudgetScreenUiModelProvider extends $FunctionalProvider<
        AsyncValue<BudgetScreenUiModel>,
        AsyncValue<BudgetScreenUiModel>,
        AsyncValue<BudgetScreenUiModel>>
    with $Provider<AsyncValue<BudgetScreenUiModel>> {
  /// The home page's view model for one month: the mapper's output, derived from
  /// the month stream, the display currency and the locale.
  ///
  /// A provider rather than a call in `build`, so the page never re-maps on a
  /// rebuild that changed none of those three, and so every consumer of the same
  /// month shares one model.
  BudgetScreenUiModelProvider._(
      {required BudgetScreenUiModelFamily super.from,
      required ({
        String locale,
        YearMonth month,
      })
          super.argument})
      : super(
          retry: null,
          name: r'budgetScreenUiModelProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$budgetScreenUiModelHash();

  @override
  String toString() {
    return r'budgetScreenUiModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<BudgetScreenUiModel>> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AsyncValue<BudgetScreenUiModel> create(Ref ref) {
    final argument = this.argument as ({
      String locale,
      YearMonth month,
    });
    return budgetScreenUiModel(
      ref,
      argument,
    );
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<BudgetScreenUiModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<BudgetScreenUiModel>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BudgetScreenUiModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$budgetScreenUiModelHash() =>
    r'9a982c2e965bf9e90aa3196f1461a7683e0070f8';

/// The home page's view model for one month: the mapper's output, derived from
/// the month stream, the display currency and the locale.
///
/// A provider rather than a call in `build`, so the page never re-maps on a
/// rebuild that changed none of those three, and so every consumer of the same
/// month shares one model.

final class BudgetScreenUiModelFamily extends $Family
    with
        $FunctionalFamilyOverride<
            AsyncValue<BudgetScreenUiModel>,
            ({
              String locale,
              YearMonth month,
            })> {
  BudgetScreenUiModelFamily._()
      : super(
          retry: null,
          name: r'budgetScreenUiModelProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// The home page's view model for one month: the mapper's output, derived from
  /// the month stream, the display currency and the locale.
  ///
  /// A provider rather than a call in `build`, so the page never re-maps on a
  /// rebuild that changed none of those three, and so every consumer of the same
  /// month shares one model.

  BudgetScreenUiModelProvider call(
    ({
      String locale,
      YearMonth month,
    }) request,
  ) =>
      BudgetScreenUiModelProvider._(argument: request, from: this);

  @override
  String toString() => r'budgetScreenUiModelProvider';
}

/// The category detail page's view model: one row out of the month's model,
/// or null once that category has no row in this month.

@ProviderFor(budgetCategoryDetail)
final budgetCategoryDetailProvider = BudgetCategoryDetailFamily._();

/// The category detail page's view model: one row out of the month's model,
/// or null once that category has no row in this month.

final class BudgetCategoryDetailProvider extends $FunctionalProvider<
        AsyncValue<BudgetCategoryDetailUiModel?>,
        AsyncValue<BudgetCategoryDetailUiModel?>,
        AsyncValue<BudgetCategoryDetailUiModel?>>
    with $Provider<AsyncValue<BudgetCategoryDetailUiModel?>> {
  /// The category detail page's view model: one row out of the month's model,
  /// or null once that category has no row in this month.
  BudgetCategoryDetailProvider._(
      {required BudgetCategoryDetailFamily super.from,
      required ({
        String categoryId,
        String locale,
        YearMonth month,
      })
          super.argument})
      : super(
          retry: null,
          name: r'budgetCategoryDetailProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$budgetCategoryDetailHash();

  @override
  String toString() {
    return r'budgetCategoryDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<BudgetCategoryDetailUiModel?>> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AsyncValue<BudgetCategoryDetailUiModel?> create(Ref ref) {
    final argument = this.argument as ({
      String categoryId,
      String locale,
      YearMonth month,
    });
    return budgetCategoryDetail(
      ref,
      argument,
    );
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<BudgetCategoryDetailUiModel?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<BudgetCategoryDetailUiModel?>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BudgetCategoryDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$budgetCategoryDetailHash() =>
    r'd6b61a34f27f29f3d5d2dab39af963ea8053d746';

/// The category detail page's view model: one row out of the month's model,
/// or null once that category has no row in this month.

final class BudgetCategoryDetailFamily extends $Family
    with
        $FunctionalFamilyOverride<
            AsyncValue<BudgetCategoryDetailUiModel?>,
            ({
              String categoryId,
              String locale,
              YearMonth month,
            })> {
  BudgetCategoryDetailFamily._()
      : super(
          retry: null,
          name: r'budgetCategoryDetailProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// The category detail page's view model: one row out of the month's model,
  /// or null once that category has no row in this month.

  BudgetCategoryDetailProvider call(
    ({
      String categoryId,
      String locale,
      YearMonth month,
    }) request,
  ) =>
      BudgetCategoryDetailProvider._(argument: request, from: this);

  @override
  String toString() => r'budgetCategoryDetailProvider';
}
