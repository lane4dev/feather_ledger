import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feather_ledger/app/design_system/app_receipt_sheet.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';

import 'pending_bill_sheet.dart';
import 'show_transaction_detail_sheet.dart';
import '../view_model/ledger_view_model.dart';

import 'ledger_empty.dart';
import 'ledger_skeleton.dart';
import 'ledger_timeline.dart';
import 'ledger_header.dart';

class LedgerTransactionList extends ConsumerWidget {
  final DateTime month;
  final String currency;
  final AppLocalizations l10n;
  final ScrollController controller;
  final double headerHeight;

  const LedgerTransactionList({
    super.key,
    required this.month,
    required this.currency,
    required this.l10n,
    required this.controller,
    required this.headerHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync =
        ref.watch(ledgerMonthlyTransactionsProvider(month));

    // Wrap in a container with background color to prevent transparency issues during slide
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: CustomScrollView(
        controller: controller,
        key: PageStorageKey(month),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: headerHeight,
              child: LedgerHeader(
                  summaryAsync: ref.watch(ledgerMonthlySummaryProvider(month))),
            ),
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
                currencySymbol: currency,
                onTransactionTap: (tx) {
                  // Pending bills retain their own post/edit/delete flow.
                  if (tx.isPending) {
                    showAppReceiptSheet(
                      context: context,
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
          SliverToBoxAdapter(
            child: SizedBox(
                height: (NavigationBarTheme.of(context).height ?? 80) +
                    MediaQuery.viewPaddingOf(context).bottom),
          ),
        ],
      ),
    );
  }
}
