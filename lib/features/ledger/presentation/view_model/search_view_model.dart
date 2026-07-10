import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/result/result.dart';

import '../../domain/entities/ledger_entities.dart';
import '../../domain/queries/search_transactions_query.dart';
import '../../domain/services/transaction_export_service.dart';
import '../../domain/value_objects/transaction_filter.dart';
import '../mappers/transaction_ui_mapper.dart';
import '../models/ledger_day_group.dart';
import '../models/transaction_tile_ui_model.dart';
import 'ledger_view_model.dart';

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

  /// Writes [rows] out as CSV and offers them to the share sheet.
  ///
  /// A method rather than a provider: a family keyed on a `List` would key on
  /// identity, so every rebuild would construct a new provider.
  Future<Result<void>> export(List<TransactionEntity> rows) async {
    final service = await ref.read(transactionExportServiceProvider.future);
    return service.exportCsv(rows);
  }
}

/// One search's results, in both shapes the screen needs.
///
/// [tiles] is what gets rendered; [entities] is what gets exported. Both come
/// from a single stream so the file a user exports cannot disagree with the
/// list they were looking at.
class SearchResults {
  final List<TransactionEntity> entities;
  final List<TransactionTileUiModel> tiles;

  /// The same rows, grouped by day with each day's totals written out — the
  /// shape the timeline renders, built here so the screen has nothing to
  /// compute.
  final List<LedgerDayGroup> days;

  const SearchResults({
    required this.entities,
    required this.tiles,
    required this.days,
  });

  bool get isEmpty => tiles.isEmpty;
}

@riverpod
Stream<SearchResults> searchResults(Ref ref) {
  final filter = ref.watch(searchViewModelProvider);
  const mapper = TransactionUiMapper();

  final symbol = ref.watch(displayCurrencySymbolProvider);

  return ref.watch(searchTransactionsQueryProvider).execute(filter).map((rows) {
    final tiles = rows.map(mapper.toTile).toList();
    return SearchResults(
      entities: rows,
      tiles: tiles,
      days: LedgerDayGroup.group(tiles, currencySymbol: symbol),
    );
  });
}
