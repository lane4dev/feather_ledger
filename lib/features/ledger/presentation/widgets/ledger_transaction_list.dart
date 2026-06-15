import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';

import 'transaction_detail_sheet.dart';
import '../view_model/ledger_view_model.dart';

import 'ledger_empty.dart';
import 'ledger_skeleton.dart';
import 'ledger_timeline.dart';

class LedgerTransactionList extends ConsumerWidget {
  final DateTime month;
  final String currency;
  final AppLocalizations l10n;

  const LedgerTransactionList({
    super.key,
    required this.month,
    required this.currency,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(ledgerMonthlyTransactionsProvider(month));

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
                          final result = await ref
                              .read(ledgerViewModelProvider.notifier)
                              .deleteTransaction(tx.id);
                          if (result case final Failure<void> failure) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        failure.code.message(l10n))),
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
