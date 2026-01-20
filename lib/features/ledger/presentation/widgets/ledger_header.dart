import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      padding: const EdgeInsets.fromLTRB(0, 0, LedgerTheme.gapMd, LedgerTheme.gapMd),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row to align with list content (Left spacer)
          Row(
            children: [
              const SizedBox(width: LedgerTheme.colAnchorWidth),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month Switcher
                    _MonthSwitcher(
                      selectedDate: selectedDate,
                      onChanged: onMonthChanged,
                      onTap: onMonthTap,
                    ),
                    const SizedBox(height: LedgerTheme.gapMd),
                    // Balance Summary
                    if (summary != null)
                      _BalanceSummary(
                        summary: summary!,
                        currency: currencySymbol,
                      ),
                  ],
                ),
              ),
            ],
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
          DateFormat.yMMM().format(selectedDate),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (summary != null) ...[
          const SizedBox(width: LedgerTheme.gapMd),
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
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onChanged == null
              ? null
              : () => onChanged!(DateTime(selectedDate.year, selectedDate.month - 1)),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Text(
              DateFormat.yMMMM().format(selectedDate),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onChanged == null
              ? null
              : () => onChanged!(DateTime(selectedDate.year, selectedDate.month + 1)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Balance',
          style: LedgerTheme.balanceLabel(context),
        ),
        Text(
          '$currency${summary.runningBalance.toStringAsFixed(2)}',
          style: LedgerTheme.balanceText(context),
        ),
        const SizedBox(height: LedgerTheme.gapSm),
        Row(
          children: [
            _IncomeExpenseItem(
              label: 'Income',
              amount: summary.totalIncome,
              color: LedgerTheme.incomeColor(context),
              currency: currency,
            ),
            const SizedBox(width: LedgerTheme.gapLg),
            _IncomeExpenseItem(
              label: 'Expense',
              amount: summary.totalExpense,
              color: LedgerTheme.expenseColor(context),
              currency: currency,
            ),
          ],
        ),
      ],
    );
  }
}

class _IncomeExpenseItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String currency;

  const _IncomeExpenseItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            Text(
              '$currency${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
