import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';

import 'pending_bill_sheet.dart';
import 'show_transaction_detail_sheet.dart';
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
    final transactionsAsync =
        ref.watch(ledgerMonthlyTransactionsProvider(month));

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
            data: (days) {
              if (days.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: LedgerEmpty(),
                );
              }
              return LedgerTimeline(
                days: days,
                overlapHandle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                currencySymbol: currency,
                onTransactionTap: (tx) {
                  // Pending bills retain their own post/edit/delete flow.
                  if (tx.isPending) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useRootNavigator: true,
                      useSafeArea: true,
                      builder: (context) => PendingBillSheet(
                        transaction: tx,
                        currencySymbol: currency,
                      ),
                    );
                    return;
                  }

                  showTransactionDetailSheet(
                    context: context,
                    ref: ref,
                    transaction: tx,
                    currencySymbol: currency,
                  );
                },
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: LedgerSkeleton(),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text(l10n.errorPrefix('$e'))),
            ),
          ),
        ],
      ),
    );
  }
}
