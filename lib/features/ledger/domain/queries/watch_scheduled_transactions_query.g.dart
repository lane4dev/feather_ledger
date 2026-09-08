// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_scheduled_transactions_query.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(watchScheduledTransactionsQuery)
final watchScheduledTransactionsQueryProvider =
    WatchScheduledTransactionsQueryProvider._();

final class WatchScheduledTransactionsQueryProvider extends $FunctionalProvider<
        WatchScheduledTransactionsQuery,
        WatchScheduledTransactionsQuery,
        WatchScheduledTransactionsQuery>
    with $Provider<WatchScheduledTransactionsQuery> {
  WatchScheduledTransactionsQueryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'watchScheduledTransactionsQueryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$watchScheduledTransactionsQueryHash();

  @$internal
  @override
  $ProviderElement<WatchScheduledTransactionsQuery> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WatchScheduledTransactionsQuery create(Ref ref) {
    return watchScheduledTransactionsQuery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchScheduledTransactionsQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<WatchScheduledTransactionsQuery>(value),
    );
  }
}

String _$watchScheduledTransactionsQueryHash() =>
    r'8f5d34091166841d60ff078e1ed878167581955e';
