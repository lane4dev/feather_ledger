import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/services/ledger_service.dart';

import 'transaction_detail_sheet.dart';

import 'ledger_empty.dart';
import 'ledger_skeleton.dart';
import 'ledger_timeline.dart';

class LedgerTransactionList extends ConsumerWidget {
  final AsyncValue<Map<DateTime, List<TransactionEntity>>> transactionsAsync;
  final String currency;
  final AppLocalizations l10n;

  const LedgerTransactionList({
    super.key,
    required this.transactionsAsync,
    required this.currency,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wrap in a container with background color to prevent transparency issues during slide
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: CustomScrollView(
        // NestedScrollView injects the PrimaryScrollController
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          transactionsAsync.when(
            data: (grouped) {
              if (grouped.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: LedgerEmpty(),
                );
              }
              return LedgerTimeline(
                groupedTransactions: grouped,
                currencySymbol: currency,
                onTransactionTap: (tx) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useRootNavigator: true,
                    useSafeArea: true,
                    builder: (context) => TransactionDetailSheet(
                      transaction: tx,
                      currencySymbol: currency,
                      onEdit: () {
                        Navigator.of(context).pop();
                        context.push('/ledger/edit', extra: tx);
                      },
                      onDelete: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('${l10n.delete}?'),
                            content: Text(l10n.deleteTransactionConfirmation),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(l10n.cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.error,
                                ),
                                child: Text(l10n.delete),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && context.mounted) {
                          Navigator.of(context).pop(); // Close sheet
                          try {
                            await ref
                                .read(ledgerServiceProvider)
                                .deleteTransaction(tx.id);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        }
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: LedgerSkeleton(),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
