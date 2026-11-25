import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:feather_ledger/app/design_system/app_receipt_sheet.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/router/card_page_transition.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';

import 'pending_bill_sheet.dart';
import 'show_transaction_detail_sheet.dart';
import '../models/ledger_expense_trend.dart';
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
  final GlobalKey? summaryCardKey;

  const LedgerTransactionList({
    super.key,
    required this.month,
    required this.currency,
    required this.l10n,
    required this.controller,
    required this.headerHeight,
    this.summaryCardKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync =
        ref.watch(ledgerMonthlyTransactionsProvider(month));
    final days = transactionsAsync.asData?.value;
    final isEmpty = days?.isEmpty ?? false;
    final hasTransactions = days != null && days.isNotEmpty;
    final fabHeight =
        Theme.of(context).floatingActionButtonTheme.sizeConstraints?.minHeight ??
            56.0;
    final fabMargin = context.spacing.md;
    final tailClearance = math.max(88.0, fabHeight + fabMargin + fabMargin);

    // The empty state asks two different questions. Accounts exist but have
    // no transactions → point at the + button. No accounts in this currency
    // → a transaction cannot exist, so point at account creation instead.
    final currencyCode = ref.watch(currencyControllerProvider).value ??
        AppCurrencies.defaultCurrency.code;
    final accounts = ref.watch(accountListProvider).value ?? const [];
    final hasAccounts = accounts.any((a) => a.currencyCode == currencyCode);

    // Wrap in a container with background color to prevent transparency issues during slide
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: CustomScrollView(
        controller: controller,
        key: PageStorageKey(month),
        physics: isEmpty ? const NeverScrollableScrollPhysics() : null,
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: headerHeight,
              child: LedgerHeader(
                  cardKey: summaryCardKey,
                  month: month,
                  expenseTrend: LedgerExpenseTrend.fromDays(
                    days ?? const [],
                  ),
                  onTap: () => context.push('/ledger/reports',
                      extra: CardPageOrigin(month, summaryCardKey)),
                  summaryAsync: ref.watch(ledgerMonthlySummaryProvider(month))),
            ),
          ),
          transactionsAsync.when(
            data: (days) {
              if (days.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: LedgerEmpty(
                    onCreateAccount: hasAccounts
                        ? null
                        : () => context.push('/accounts_management'),
                  ),
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
          if (hasTransactions)
            SliverToBoxAdapter(
              child: SizedBox(
                height: (NavigationBarTheme.of(context).height ?? 80) +
                    MediaQuery.viewPaddingOf(context).bottom +
                    tailClearance,
              ),
            ),
        ],
      ),
    );
  }
}
