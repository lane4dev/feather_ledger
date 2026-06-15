// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drift_event_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(driftEventStore)
final driftEventStoreProvider = DriftEventStoreProvider._();

final class DriftEventStoreProvider
    extends $FunctionalProvider<EventStore, EventStore, EventStore>
    with $Provider<EventStore> {
  DriftEventStoreProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'driftEventStoreProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$driftEventStoreHash();

  @$internal
  @override
  $ProviderElement<EventStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EventStore create(Ref ref) {
    return driftEventStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventStore>(value),
    );
  }
}

String _$driftEventStoreHash() => r'cd75cd0f8c0e5b78ae484c7313e10c3b49d08a7f';
