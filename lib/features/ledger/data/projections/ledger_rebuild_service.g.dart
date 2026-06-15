// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_rebuild_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ledgerRebuildService)
final ledgerRebuildServiceProvider = LedgerRebuildServiceProvider._();

final class LedgerRebuildServiceProvider extends $FunctionalProvider<
    LedgerRebuildService,
    LedgerRebuildService,
    LedgerRebuildService> with $Provider<LedgerRebuildService> {
  LedgerRebuildServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'ledgerRebuildServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$ledgerRebuildServiceHash();

  @$internal
  @override
  $ProviderElement<LedgerRebuildService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LedgerRebuildService create(Ref ref) {
    return ledgerRebuildService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LedgerRebuildService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LedgerRebuildService>(value),
    );
  }
}

String _$ledgerRebuildServiceHash() =>
    r'0ce8613ceb1309a02c45aa3999bfc6565ece21b6';
