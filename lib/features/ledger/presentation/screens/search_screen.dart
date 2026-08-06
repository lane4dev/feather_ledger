import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:feather_ledger/app/design_system/app_text_field.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/value_objects/transaction_filter.dart';
import '../view_model/ledger_view_model.dart';
import '../view_model/search_view_model.dart';
import '../widgets/search_transaction_tile.dart';
import '../widgets/show_transaction_detail_sheet.dart';
import '../widgets/transaction_filter_sheet.dart';

/// Search and filter across the whole ledger (spec 004, US3).
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
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        title: AppTextField(
          controller: _queryController,
          hintText: l10n.searchHint,
          onChanged: (value) =>
              ref.read(searchViewModelProvider.notifier).setQuery(value),
        ),
        actions: [
          IconButton(
            icon: Icon(
                filter.isNotEmpty ? LucideIcons.filter : LucideIcons.filter),
            tooltip: l10n.filterTitle,
            onPressed: () => _openFilterSheet(filter),
          ),
        ],
      ),
      body: !hasQuery
          ? const SizedBox.expand()
          : resultsAsync.when(
              data: (results) {
                if (results.isEmpty) {
                  return Center(child: Text(l10n.noSearchResults));
                }
                return ListView.separated(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: results.tiles.length,
                  separatorBuilder: (context, index) => const FeatherDivider(),
                  itemBuilder: (_, index) {
                    final transaction = results.tiles[index];
                    return SearchTransactionTile(
                      key: ValueKey(transaction.id),
                      transaction: transaction,
                      currencySymbol: currency,
                      onTap: () => showTransactionDetailSheet(
                        context: context,
                        ref: ref,
                        transaction: transaction,
                        currencySymbol: currency,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(l10n.errorPrefix(error.toString())),
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
