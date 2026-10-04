// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(budgetService)
final budgetServiceProvider = BudgetServiceProvider._();

final class BudgetServiceProvider
    extends $FunctionalProvider<BudgetService, BudgetService, BudgetService>
    with $Provider<BudgetService> {
  BudgetServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'budgetServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$budgetServiceHash();

  @$internal
  @override
  $ProviderElement<BudgetService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BudgetService create(Ref ref) {
    return budgetService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BudgetService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BudgetService>(value),
    );
  }
}

String _$budgetServiceHash() => r'9ef1193d7a2a1c30f6f557ce8d756ac6bbb7a588';
