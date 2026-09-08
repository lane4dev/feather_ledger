// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ledgerService)
final ledgerServiceProvider = LedgerServiceProvider._();

final class LedgerServiceProvider
    extends $FunctionalProvider<LedgerService, LedgerService, LedgerService>
    with $Provider<LedgerService> {
  LedgerServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'ledgerServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$ledgerServiceHash();

  @$internal
  @override
  $ProviderElement<LedgerService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LedgerService create(Ref ref) {
    return ledgerService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LedgerService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LedgerService>(value),
    );
  }
}

String _$ledgerServiceHash() => r'33e6160701aab34750bc3692795b771f16a54cce';
