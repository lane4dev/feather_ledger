import 'package:flutter/material.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
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
          height: LedgerTheme.rowMinHeight,
          child: TimeAnchor(date: date),
        ),
      ),
      sliver: SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(
            left: LedgerTheme.colAnchorWidth,
            right: context.spacing.md,
            bottom: LedgerTheme.dayCardGap,
          ),
          child: AppCard.day(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final tx in transactions)
                  TransactionTile(
                    transaction: tx,
                    currencySymbol: currencySymbol,
                    onTap: () => onTransactionTap?.call(tx),
                  ),
                if (day.hasSubtotal)
                  _DailySummary(
                    displayIncome: day.displayIncome,
                    displayExpense: day.displayExpense,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The day's totals, in the strings the model already wrote.
class _DailySummary extends StatelessWidget {
  final String? displayIncome;
  final String? displayExpense;

  const _DailySummary({
    this.displayIncome,
    this.displayExpense,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FeatherDivider(
          indent: context.spacing.md,
          endIndent: context.spacing.md,
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: LedgerTheme.subtotalDividerAlpha),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.md,
            vertical: LedgerTheme.subtotalVerticalPadding,
          ),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: context.spacing.md,
            runSpacing: context.spacing.xs,
            children: [
              if (displayIncome != null)
                _SubtotalItem(
                  label: '${l10n.income}: ',
                  amount: displayIncome!,
                  color: context.colors.income,
                ),
              if (displayExpense != null)
                _SubtotalItem(
                  label: '${l10n.expense}: ',
                  amount: displayExpense!,
                  color: context.colors.expense,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubtotalItem extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _SubtotalItem({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          label,
          style: LedgerTheme.transactionMeta(context),
        ),
        Text(
          amount,
          style: AppTypography.compactAmount(context).copyWith(color: color),
        ),
      ],
    );
  }
}
