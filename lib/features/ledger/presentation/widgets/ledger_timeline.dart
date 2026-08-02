import 'package:flutter/material.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';

import '../models/ledger_day_group.dart';
import '../models/transaction_tile_ui_model.dart';
import '../theme/ledger_theme.dart';

import 'time_anchor.dart';
import 'transaction_tile.dart';
import 'ledger_day_section.dart';

class LedgerTimeline extends StatelessWidget {
  /// Already grouped, already totalled, already written out — see
  /// [LedgerDayGroup]. This widget decides only how a day looks.
  final List<LedgerDayGroup> days;
  final String? currencySymbol;
  final SliverOverlapAbsorberHandle? overlapHandle;

  final Function(TransactionTileUiModel)? onTransactionTap;

  const LedgerTimeline({
    super.key,
    required this.days,
    this.currencySymbol,
    this.onTransactionTap,
    this.overlapHandle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveCurrencySymbol =
        currencySymbol ?? AppCurrencies.defaultCurrency.symbol;

    // We wrap everything in a SliverMainAxisGroup so it acts as a single sliver unit
    // This allows us to use it inside the CustomScrollView's slivers list cleanly.
    return SliverMainAxisGroup(
      slivers: days
          .map((day) => _DayGroup(
                day: day,
                currencySymbol: effectiveCurrencySymbol,
                onTransactionTap: onTransactionTap,
                overlapHandle: overlapHandle,
              ))
          .toList(),
    );
  }
}

class _DayGroup extends StatelessWidget {
  final LedgerDayGroup day;
  final String currencySymbol;
  final Function(TransactionTileUiModel)? onTransactionTap;
  final SliverOverlapAbsorberHandle? overlapHandle;

  const _DayGroup({
    required this.day,
    required this.currencySymbol,
    this.onTransactionTap,
    this.overlapHandle,
  });

  @override
  Widget build(BuildContext context) {
    final date = day.date;
    final transactions = day.transactions;

    return LedgerDaySection(
      overlapHandle: overlapHandle,
      headerWidth: LedgerTheme.colAnchorWidth,
      header: IgnorePointer(
        child: SizedBox(
          height: 56,
          child: TimeAnchor(date: date),
        ),
      ),
      sliver: SliverList.builder(
        // +1 for the summary row
        itemCount: transactions.length + 1,
        itemBuilder: (context, index) {
          if (index == transactions.length) {
            return _DailySummary(
              displayIncome: day.displayIncome,
              displayExpense: day.displayExpense,
            );
          }

          final tx = transactions[index];

          return TransactionTile(
            transaction: tx,
            currencySymbol: currencySymbol,
            onTap: () => onTransactionTap?.call(tx),
          );
        },
      ),
    );
  }
}

/// The day's totals, in the strings the model already wrote.
class _DailySummary extends StatelessWidget {
  final String? displayIncome;
  final String? displayExpense;

  const _DailySummary({this.displayIncome, this.displayExpense});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: LedgerTheme.colAnchorWidth + context.spacing.md,
        right: context.spacing.md,
        bottom: context
            .spacing.lg, // Increased bottom spacing for better group separation
        top: context.spacing.sm, // Increased top spacing
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FeatherDivider(),
          Padding(
            padding: EdgeInsets.only(top: context.spacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Income
                if (displayIncome != null) ...[
                  Text(
                    '${l10n.income}: ',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    displayIncome!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.income,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
                // Expense
                if (displayExpense != null) ...[
                  SizedBox(width: context.spacing.md),
                  Text(
                    '${l10n.expense}: ',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    displayExpense!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.expense,
                          fontWeight: FontWeight.bold,
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
