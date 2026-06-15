// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_recurring_series_query.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(getRecurringSeriesQuery)
final getRecurringSeriesQueryProvider = GetRecurringSeriesQueryProvider._();

final class GetRecurringSeriesQueryProvider extends $FunctionalProvider<
    GetRecurringSeriesQuery,
    GetRecurringSeriesQuery,
    GetRecurringSeriesQuery> with $Provider<GetRecurringSeriesQuery> {
  GetRecurringSeriesQueryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'getRecurringSeriesQueryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$getRecurringSeriesQueryHash();

  @$internal
  @override
  $ProviderElement<GetRecurringSeriesQuery> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetRecurringSeriesQuery create(Ref ref) {
    return getRecurringSeriesQuery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetRecurringSeriesQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetRecurringSeriesQuery>(value),
    );
  }
}

String _$getRecurringSeriesQueryHash() =>
    r'5adeffedbd479061bba7897896c1e69567600f68';
