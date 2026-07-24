// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_monthly_snapshot_query.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(watchMonthlySnapshotQuery)
final watchMonthlySnapshotQueryProvider = WatchMonthlySnapshotQueryProvider._();

final class WatchMonthlySnapshotQueryProvider extends $FunctionalProvider<
    WatchMonthlySnapshotQuery,
    WatchMonthlySnapshotQuery,
    WatchMonthlySnapshotQuery> with $Provider<WatchMonthlySnapshotQuery> {
  WatchMonthlySnapshotQueryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'watchMonthlySnapshotQueryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$watchMonthlySnapshotQueryHash();

  @$internal
  @override
  $ProviderElement<WatchMonthlySnapshotQuery> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WatchMonthlySnapshotQuery create(Ref ref) {
    return watchMonthlySnapshotQuery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchMonthlySnapshotQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchMonthlySnapshotQuery>(value),
    );
  }
}

String _$watchMonthlySnapshotQueryHash() =>
    r'bcd45038d9615dee57031e1d7335b4ba981d40ae';
