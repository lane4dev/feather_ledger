// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_transactions_query.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(watchTransactionsQuery)
final watchTransactionsQueryProvider = WatchTransactionsQueryProvider._();

final class WatchTransactionsQueryProvider extends $FunctionalProvider<
    WatchTransactionsQuery,
    WatchTransactionsQuery,
    WatchTransactionsQuery> with $Provider<WatchTransactionsQuery> {
  WatchTransactionsQueryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'watchTransactionsQueryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$watchTransactionsQueryHash();

  @$internal
  @override
  $ProviderElement<WatchTransactionsQuery> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WatchTransactionsQuery create(Ref ref) {
    return watchTransactionsQuery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchTransactionsQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchTransactionsQuery>(value),
    );
  }
}

String _$watchTransactionsQueryHash() =>
    r'616123886feb5bcc40c1bbba252426f4059c72b2';
