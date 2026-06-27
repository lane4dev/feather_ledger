// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The active filter (spec 004, US3).
///
/// Holds a [TransactionFilter] rather than taking one as a family argument:
/// a family would rebuild the whole provider graph per keystroke, where a
/// notifier just mutates. Auto-disposed, so leaving the search screen clears
/// the search rather than restoring a stale result set next visit.

@ProviderFor(SearchViewModel)
final searchViewModelProvider = SearchViewModelProvider._();

/// The active filter (spec 004, US3).
///
/// Holds a [TransactionFilter] rather than taking one as a family argument:
/// a family would rebuild the whole provider graph per keystroke, where a
/// notifier just mutates. Auto-disposed, so leaving the search screen clears
/// the search rather than restoring a stale result set next visit.
final class SearchViewModelProvider
    extends $NotifierProvider<SearchViewModel, TransactionFilter> {
  /// The active filter (spec 004, US3).
  ///
  /// Holds a [TransactionFilter] rather than taking one as a family argument:
  /// a family would rebuild the whole provider graph per keystroke, where a
  /// notifier just mutates. Auto-disposed, so leaving the search screen clears
  /// the search rather than restoring a stale result set next visit.
  SearchViewModelProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'searchViewModelProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$searchViewModelHash();

  @$internal
  @override
  SearchViewModel create() => SearchViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionFilter>(value),
    );
  }
}

String _$searchViewModelHash() => r'063af027da41e296dbb3fa7c58553f5164aeda73';

/// The active filter (spec 004, US3).
///
/// Holds a [TransactionFilter] rather than taking one as a family argument:
/// a family would rebuild the whole provider graph per keystroke, where a
/// notifier just mutates. Auto-disposed, so leaving the search screen clears
/// the search rather than restoring a stale result set next visit.

abstract class _$SearchViewModel extends $Notifier<TransactionFilter> {
  TransactionFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TransactionFilter, TransactionFilter>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<TransactionFilter, TransactionFilter>,
        TransactionFilter,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(searchResults)
final searchResultsProvider = SearchResultsProvider._();

final class SearchResultsProvider extends $FunctionalProvider<
        AsyncValue<SearchResults>, SearchResults, Stream<SearchResults>>
    with $FutureModifier<SearchResults>, $StreamProvider<SearchResults> {
  SearchResultsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'searchResultsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$searchResultsHash();

  @$internal
  @override
  $StreamProviderElement<SearchResults> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<SearchResults> create(Ref ref) {
    return searchResults(ref);
  }
}

String _$searchResultsHash() => r'da0464be63cf9224dc7872c7b95439484fea6bbe';
