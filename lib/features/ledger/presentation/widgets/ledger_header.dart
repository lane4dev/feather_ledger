import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';

import '../../domain/entities/ledger_entities.dart';
import '../theme/ledger_theme.dart';

class LedgerHeader extends StatelessWidget {
  final DateTime selectedDate;
  final MonthlySummary? summary;
  final ValueChanged<DateTime>? onMonthChanged;
  final VoidCallback? onMonthTap;
  final String currencySymbol;

  const LedgerHeader({
    super.key,
    required this.selectedDate,
    this.summary,
    this.onMonthChanged,
    this.onMonthTap,
    this.currencySymbol = '\$',
  });

  @override
  Widget build(BuildContext context) {
    // Expanded State
    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.spacing.md, 0, context.spacing.md, context.spacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Switcher - Still aligned with list content
          Row(
            children: [
              const SizedBox(
                  width: LedgerTheme.colAnchorWidth -
                      16), // Adjusted for outer padding
              Expanded(
                child: _MonthSwitcher(
                  selectedDate: selectedDate,
                  onChanged: onMonthChanged,
                  onTap: onMonthTap,
                ),
              ),
            ],
          ),
          // Balance Summary - Full Width
          if (summary != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _BalanceSummary(
                summary: summary!,
                currency: currencySymbol,
              ),
            ),
        ],
      ),
    );
  }
}

class LedgerHeaderCompact extends StatelessWidget {
  final DateTime selectedDate;
  final MonthlySummary? summary;
  final String currencySymbol;

  const LedgerHeaderCompact({
    super.key,
    required this.selectedDate,
    this.summary,
    this.currencySymbol = '\$',
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return Row(
      children: [
        // We might NOT want the spacer in the AppBar title if the Back button or leading icon is there?
        // But the design says "Month Switcher + Balance... coexist without overlap".
        // If this is a SliverAppBar, the `leading` widget (back button) usually takes the left space.
        // If we are at root, maybe no leading?
        // Let's assume standard AppBar behavior. We don't force 72dp spacer here because AppBar handles leading.
        // But visual alignment with the list (which has 72dp spacer) is nice.
        // Let's just show the content.

        Text(
          DateFormat.yMMM(locale).format(selectedDate),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (summary != null) ...[
          SizedBox(width: context.spacing.md),
          Text(
            '$currencySymbol${summary!.runningBalance.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ],
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime>? onChanged;
  final VoidCallback? onTap;

  const _MonthSwitcher({
    required this.selectedDate,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onChanged == null
              ? null
              : () => onChanged!(
                  DateTime(selectedDate.year, selectedDate.month - 1)),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Text(
              DateFormat.yMMMM(locale).format(selectedDate),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onChanged == null
              ? null
              : () => onChanged!(
                  DateTime(selectedDate.year, selectedDate.month + 1)),
        ),
      ],
    );
  }
}

class _BalanceSummary extends StatelessWidget {
  final MonthlySummary summary;
  final String currency;

  const _BalanceSummary({
    required this.summary,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(LedgerTheme.cardRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Main Balance
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.total_balance,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$currency${summary.runningBalance.toStringAsFixed(2)}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          // Income & Expense Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _IncomeExpenseCompact(
                label: l10n.income,
                amount: summary.totalIncome,
                color: context.colors.income,
                currency: currency,
                icon: Icons.arrow_downward_rounded,
              ),
              const SizedBox(height: 8),
              _IncomeExpenseCompact(
                label: l10n.expense,
                amount: summary.totalExpense,
                color: context.colors.expense,
                currency: currency,
                icon: Icons.arrow_upward_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomeExpenseCompact extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String currency;
  final IconData icon;

  const _IncomeExpenseCompact({
    required this.label,
    required this.amount,
    required this.color,
    required this.currency,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 12,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$currency${amount.toStringAsFixed(2)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
