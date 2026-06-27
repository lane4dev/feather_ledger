// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_transactions_query.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(searchTransactionsQuery)
final searchTransactionsQueryProvider = SearchTransactionsQueryProvider._();

final class SearchTransactionsQueryProvider extends $FunctionalProvider<
    SearchTransactionsQuery,
    SearchTransactionsQuery,
    SearchTransactionsQuery> with $Provider<SearchTransactionsQuery> {
  SearchTransactionsQueryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'searchTransactionsQueryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$searchTransactionsQueryHash();

  @$internal
  @override
  $ProviderElement<SearchTransactionsQuery> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SearchTransactionsQuery create(Ref ref) {
    return searchTransactionsQuery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchTransactionsQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchTransactionsQuery>(value),
    );
  }
}

String _$searchTransactionsQueryHash() =>
    r'20077340ccf8eec1177fa9b0d24b64355d3cdbc0';
