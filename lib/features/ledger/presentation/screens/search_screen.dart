import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/shared/presentation/money_format.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/value_objects/transaction_filter.dart';
import '../models/transaction_tile_ui_model.dart';
import '../view_model/ledger_view_model.dart';
import '../view_model/search_view_model.dart';
import '../widgets/search_transaction_tile.dart';
import '../widgets/show_transaction_detail_sheet.dart';
import '../widgets/transaction_filter_sheet.dart';

/// Search and filter across the whole ledger (spec 004, US3).
///
/// Results are grouped by month into one surface per month: a hit is a row,
/// not a card, so a long result set stays scannable.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final resultsAsync = ref.watch(searchResultsProvider);
    final filter = ref.watch(searchViewModelProvider);
    final currency = ref.watch(displayCurrencySymbolProvider);
    final hasQuery = filter.query?.trim().isNotEmpty == true;

    return Scaffold(
      appBar: AppBar(
        leading: AppIconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        actions: [
          AppIconButton(
            icon: const Icon(LucideIcons.filter),
            tooltip: l10n.filterTitle,
            onPressed: () => _openFilterSheet(filter),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.spacing.md,
                context.spacing.sm,
                context.spacing.md,
                context.spacing.sm,
              ),
              child: _SearchField(
                controller: _queryController,
                hintText: l10n.searchHint,
                clearTooltip: l10n.searchClear,
                onChanged: (value) =>
                    ref.read(searchViewModelProvider.notifier).setQuery(value),
                onClear: () {
                  _queryController.clear();
                  ref.read(searchViewModelProvider.notifier).setQuery('');
                },
              ),
            ),
            Expanded(
              child: !hasQuery
                  ? const SizedBox.shrink()
                  : resultsAsync.when(
                      data: (results) {
                        if (results.isEmpty) {
                          return Center(child: Text(l10n.noSearchResults));
                        }
                        return _ResultsList(
                          ref: ref,
                          tiles: results.tiles,
                          currencySymbol: currency,
                          query: filter.query!,
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(
                        child: Text(l10n.errorPrefix(error.toString())),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFilterSheet(TransactionFilter current) async {
    final applied = await showModalBottomSheet<TransactionFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => TransactionFilterSheet(initial: current),
    );
    if (applied == null) return;
    ref.read(searchViewModelProvider.notifier).apply(applied);
  }
}

/// The M3 search field: a tonal pill, no outline, and its own clear button.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hintText,
    required this.clearTooltip,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final String clearTooltip;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(28);
    final border = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide.none,
    );

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: scheme.surfaceContainerHigh,
          border: border,
          enabledBorder: border,
          focusedBorder: border,
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.spacing.md,
            vertical: context.spacing.sm + 4,
          ),
          prefixIcon: Icon(LucideIcons.search,
              size: context.metrics.iconSize, color: scheme.onSurfaceVariant),
          prefixIconConstraints: const BoxConstraints(minWidth: 44),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  key: const ValueKey('search-clear'),
                  onPressed: onClear,
                  tooltip: clearTooltip,
                  icon: Icon(LucideIcons.x,
                      size: context.metrics.iconSize,
                      color: scheme.onSurfaceVariant),
                ),
          suffixIconConstraints: const BoxConstraints(minWidth: 44),
        ),
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.ref,
    required this.tiles,
    required this.currencySymbol,
    required this.query,
  });

  final WidgetRef ref;
  final List<TransactionTileUiModel> tiles;
  final String currencySymbol;
  final String query;

  @override
  Widget build(BuildContext context) {
    final groups = _groupByMonth(tiles);

    return ListView.builder(
      padding:
          context.pagePadding.add(EdgeInsets.only(bottom: context.spacing.md)),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: groups.length + 1,
      itemBuilder: (context, index) => index == 0
          ? _SummaryBar(tiles: tiles, currencySymbol: currencySymbol)
          : _MonthGroup(
              ref: ref,
              group: groups[index - 1],
              currencySymbol: currencySymbol,
              query: query,
            ),
    );
  }

  /// Keeps the query's ordering: the stream returns newest first, and the map
  /// preserves first-seen order, so groups stay newest-first too.
  static List<_MonthTiles> _groupByMonth(List<TransactionTileUiModel> tiles) {
    final byMonth = <String, _MonthTiles>{};
    for (final tile in tiles) {
      final key = '${tile.date.year}-${tile.date.month}';
      byMonth.putIfAbsent(key, () => _MonthTiles(tile.date)).add(tile);
    }
    return byMonth.values.toList(growable: false);
  }
}

class _MonthTiles {
  _MonthTiles(this.anchor);

  final DateTime anchor;
  final List<TransactionTileUiModel> tiles = [];

  void add(TransactionTileUiModel tile) => tiles.add(tile);
}

class _MonthGroup extends StatelessWidget {
  const _MonthGroup({
    required this.ref,
    required this.group,
    required this.currencySymbol,
    required this.query,
  });

  final WidgetRef ref;
  final _MonthTiles group;
  final String currencySymbol;
  final String query;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final header = DateFormat.yMMMM(locale).format(group.anchor);

    return Padding(
      padding: EdgeInsets.only(top: context.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.spacing.xs),
            child: Text(
              header,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          SizedBox(height: context.spacing.sm),
          AppCard.day(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < group.tiles.length; i++) ...[
                  if (i > 0)
                    FeatherDivider(
                      indent: context.metrics.compactGutter,
                      endIndent: context.metrics.compactGutter,
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  SearchTransactionTile(
                    key: ValueKey(group.tiles[i].id),
                    transaction: group.tiles[i],
                    currencySymbol: currencySymbol,
                    highlightQuery: query,
                    onTap: () => showTransactionDetailSheet(
                      context: context,
                      ref: ref,
                      transaction: group.tiles[i],
                      currencySymbol: currencySymbol,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One line over the results: how many hits, and what they add up to.
class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.tiles, required this.currencySymbol});

  final List<TransactionTileUiModel> tiles;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    var expenseMinor = 0;
    var incomeMinor = 0;
    for (final tile in tiles) {
      if (tile.type == TransactionKind.expense) {
        expenseMinor += tile.amount.abs();
      } else if (tile.type == TransactionKind.income) {
        incomeMinor += tile.amount.abs();
      }
    }

    final parts = [
      l10n.searchSummaryCount(tiles.length),
      if (expenseMinor > 0)
        l10n.searchSummaryExpense(
            formatMinorWithSymbol(expenseMinor, currencySymbol)),
      if (incomeMinor > 0)
        l10n.searchSummaryIncome(
            formatMinorWithSymbol(incomeMinor, currencySymbol)),
    ];

    return Padding(
      padding: EdgeInsets.only(
        top: context.spacing.sm,
        bottom: context.spacing.xs,
      ),
      child: Text(
        parts.join(' · '),
        style: AppTypography.meta(context),
      ),
    );
  }
}
