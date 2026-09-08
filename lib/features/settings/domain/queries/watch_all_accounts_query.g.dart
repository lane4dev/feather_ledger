// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_all_accounts_query.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(watchAllAccountsQuery)
final watchAllAccountsQueryProvider = WatchAllAccountsQueryProvider._();

final class WatchAllAccountsQueryProvider extends $FunctionalProvider<
    WatchAllAccountsQuery,
    WatchAllAccountsQuery,
    WatchAllAccountsQuery> with $Provider<WatchAllAccountsQuery> {
  WatchAllAccountsQueryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'watchAllAccountsQueryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$watchAllAccountsQueryHash();

  @$internal
  @override
  $ProviderElement<WatchAllAccountsQuery> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WatchAllAccountsQuery create(Ref ref) {
    return watchAllAccountsQuery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchAllAccountsQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchAllAccountsQuery>(value),
    );
  }
}

String _$watchAllAccountsQueryHash() =>
    r'565fe6d2e3a49c72d5af1d05661550de23d5cee6';
