// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_monthly_pending_bills_query.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(watchMonthlyPendingBillsQuery)
final watchMonthlyPendingBillsQueryProvider =
    WatchMonthlyPendingBillsQueryProvider._();

final class WatchMonthlyPendingBillsQueryProvider extends $FunctionalProvider<
        WatchMonthlyPendingBillsQuery,
        WatchMonthlyPendingBillsQuery,
        WatchMonthlyPendingBillsQuery>
    with $Provider<WatchMonthlyPendingBillsQuery> {
  WatchMonthlyPendingBillsQueryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'watchMonthlyPendingBillsQueryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$watchMonthlyPendingBillsQueryHash();

  @$internal
  @override
  $ProviderElement<WatchMonthlyPendingBillsQuery> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WatchMonthlyPendingBillsQuery create(Ref ref) {
    return watchMonthlyPendingBillsQuery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchMonthlyPendingBillsQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<WatchMonthlyPendingBillsQuery>(value),
    );
  }
}

String _$watchMonthlyPendingBillsQueryHash() =>
    r'968676e975e80295793f7c79f2dedf555c41e33c';
