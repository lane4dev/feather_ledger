// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_projector.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ledgerProjector)
final ledgerProjectorProvider = LedgerProjectorProvider._();

final class LedgerProjectorProvider extends $FunctionalProvider<LedgerProjector,
    LedgerProjector, LedgerProjector> with $Provider<LedgerProjector> {
  LedgerProjectorProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'ledgerProjectorProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$ledgerProjectorHash();

  @$internal
  @override
  $ProviderElement<LedgerProjector> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LedgerProjector create(Ref ref) {
    return ledgerProjector(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LedgerProjector value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LedgerProjector>(value),
    );
  }
}

String _$ledgerProjectorHash() => r'143af705d3611d4ee1748e20105590ec01de338b';
