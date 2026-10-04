// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(budgetClock)
final budgetClockProvider = BudgetClockProvider._();

final class BudgetClockProvider
    extends $FunctionalProvider<DomainClock, DomainClock, DomainClock>
    with $Provider<DomainClock> {
  BudgetClockProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'budgetClockProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$budgetClockHash();

  @$internal
  @override
  $ProviderElement<DomainClock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DomainClock create(Ref ref) {
    return budgetClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DomainClock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DomainClock>(value),
    );
  }
}

String _$budgetClockHash() => r'6c175dce3010eef81179d054c6027c88b1c3e453';

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
