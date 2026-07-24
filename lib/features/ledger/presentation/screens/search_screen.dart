import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:feather_ledger/app/design_system/app_text_field.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/value_objects/transaction_filter.dart';
import '../models/transaction_tile_ui_model.dart';
import '../view_model/ledger_view_model.dart';
import '../view_model/search_view_model.dart';
import '../widgets/ledger_skeleton.dart';
import '../widgets/ledger_timeline.dart';
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
    final results = resultsAsync.value;
    final canExport = results != null && !results.isEmpty;

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
            icon: Icon(filter.isNotEmpty
                ? LucideIcons.filter
                : LucideIcons.filter),
            tooltip: l10n.filterTitle,
            onPressed: () => _openFilterSheet(filter),
          ),
          IconButton(
            icon: const Icon(LucideIcons.share2),
            tooltip: l10n.exportCsv,
            // Exporting what is on screen: with nothing found there is
            // nothing to export, and a file that disagrees with the list
            // would be worse than no button.
            onPressed: canExport ? () => _export(results) : null,
          ),
        ],
      ),
      body: resultsAsync.when(
        data: (results) {
          if (results.isEmpty) {
            return Center(child: Text(l10n.noSearchResults));
          }
          // The ledger's own day grouping and timeline widget, so a result
          // renders exactly as it does in the month list.
          return CustomScrollView(
            slivers: [
              LedgerTimeline(
                days: results.days,
                currencySymbol: currency,
                onTransactionTap: _showDetail,
              ),
            ],
          );
        },
        loading: () => const LedgerSkeleton(),
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

  Future<void> _export(SearchResults results) async {
    final l10n = AppLocalizations.of(context)!;
    final result =
        await ref.read(searchViewModelProvider.notifier).export(results.entities);
    if (!mounted) return;

    if (result case Failure(:final code)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(code.message(l10n))));
    }
  }

  void _showDetail(TransactionTileUiModel transaction) {
    // The same edit route the month list pushes — it already dispatches on
    // the kind, so a transfer result opens the transfer form.
    context.push('/ledger/edit', extra: transaction);
  }
}
