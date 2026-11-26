// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ledgerClock)
final ledgerClockProvider = LedgerClockProvider._();

final class LedgerClockProvider
    extends $FunctionalProvider<DomainClock, DomainClock, DomainClock>
    with $Provider<DomainClock> {
  LedgerClockProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'ledgerClockProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$ledgerClockHash();

  @$internal
  @override
  $ProviderElement<DomainClock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DomainClock create(Ref ref) {
    return ledgerClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DomainClock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DomainClock>(value),
    );
  }
}

String _$ledgerClockHash() => r'fe97b246c07e2f097a711d8835d517b70e138f94';

@ProviderFor(recurringService)
final recurringServiceProvider = RecurringServiceProvider._();

final class RecurringServiceProvider extends $FunctionalProvider<
    RecurringService,
    RecurringService,
    RecurringService> with $Provider<RecurringService> {
  RecurringServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'recurringServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$recurringServiceHash();

  @$internal
  @override
  $ProviderElement<RecurringService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecurringService create(Ref ref) {
    return recurringService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecurringService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecurringService>(value),
    );
  }
}

String _$recurringServiceHash() => r'53fe2aa0dea1d5678300c485bad3bf45d9bd2936';
