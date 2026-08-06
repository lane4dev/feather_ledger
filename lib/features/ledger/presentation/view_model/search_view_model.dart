import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/queries/search_transactions_query.dart';
import '../../domain/value_objects/transaction_filter.dart';
import '../mappers/transaction_ui_mapper.dart';
import '../models/transaction_tile_ui_model.dart';

part 'search_view_model.g.dart';

/// The active filter (spec 004, US3).
///
/// Holds a [TransactionFilter] rather than taking one as a family argument:
/// a family would rebuild the whole provider graph per keystroke, where a
/// notifier just mutates. Auto-disposed, so leaving the search screen clears
/// the search rather than restoring a stale result set next visit.
@riverpod
class SearchViewModel extends _$SearchViewModel {
  @override
  TransactionFilter build() => TransactionFilter.empty;

  void setQuery(String query) => state = state.withQuery(query);

  /// Applies a whole new filter, as the filter sheet's Apply button does.
  void apply(TransactionFilter filter) => state = filter;

  void clear() => state = TransactionFilter.empty;
}

/// Search results ready for the list to render.
class SearchResults {
  final List<TransactionTileUiModel> tiles;

  const SearchResults({
    required this.tiles,
  });

  bool get isEmpty => tiles.isEmpty;
}

@riverpod
Stream<SearchResults> searchResults(Ref ref) {
  final filter = ref.watch(searchViewModelProvider);
  // An empty field is the initial search state, not a request for the whole
  // ledger. Do not open a database subscription until there is search text.
  if (filter.query?.trim().isNotEmpty != true) {
    return Stream.value(const SearchResults(tiles: []));
  }
  const mapper = TransactionUiMapper();

  return ref.watch(searchTransactionsQueryProvider).execute(filter).map((rows) {
    final tiles = rows.map(mapper.toTile).toList();
    return SearchResults(
      tiles: tiles,
    );
  });
}
