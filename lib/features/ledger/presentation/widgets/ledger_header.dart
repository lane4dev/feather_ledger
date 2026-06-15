import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/core/presentation/providers/balance_visibility_provider.dart';
import 'package:feather_ledger/shared/presentation/money_format.dart';

import '../../domain/queries/watch_monthly_snapshot_query.dart';
import '../theme/ledger_theme.dart';

class LedgerHeader extends StatelessWidget {
  final DateTime selectedDate;
  final AsyncValue<MonthlySnapshotTotals> summaryAsync;
  final ValueChanged<DateTime>? onMonthChanged;
  final VoidCallback? onMonthTap;
  final String? currencySymbol;

  const LedgerHeader({
    super.key,
    required this.selectedDate,
    required this.summaryAsync,
    this.onMonthChanged,
    this.onMonthTap,
    this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final currencySymbol =
        this.currencySymbol ?? AppCurrencies.defaultCurrency.symbol;

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
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _BalanceSummary(
              summaryAsync: summaryAsync,
              currency: currencySymbol,
            ),
          ),
        ],
      ),
    );
  }
}

class LedgerHeaderCompact extends ConsumerWidget {
  final DateTime selectedDate;
  final AsyncValue<MonthlySnapshotTotals> summaryAsync;
  final String? currencySymbol;

  const LedgerHeaderCompact({
    super.key,
    required this.selectedDate,
    required this.summaryAsync,
    this.currencySymbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).toString();
    final showBalance =
        ref.watch(balanceVisibilityControllerProvider).value ?? true;

    final currencySymbol =
        this.currencySymbol ?? AppCurrencies.defaultCurrency.symbol;

    return Row(
      children: [
        Text(
          DateFormat.yMMM(locale).format(selectedDate),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(width: context.spacing.md),
        summaryAsync.when(
          data: (summary) => Text(
            showBalance
                ? '$currencySymbol${formatMinor(summary.balanceMinor)}'
                : '******',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          loading: () => Container(
            width: 60,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          error: (_, __) => const SizedBox(),
        ),
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

class _BalanceSummary extends ConsumerWidget {
  final AsyncValue<MonthlySnapshotTotals> summaryAsync;
  final String currency;

  const _BalanceSummary({
    required this.summaryAsync,
    required this.currency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showBalance =
        ref.watch(balanceVisibilityControllerProvider).value ?? true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(LedgerTheme.cardRadius),
      ),
      child: summaryAsync.when(
        data: (summary) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Main Balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.totalBalance,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => ref
                          .read(balanceVisibilityControllerProvider.notifier)
                          .toggle(),
                      child: Icon(
                        showBalance
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  showBalance
                      ? '$currency${formatMinor(summary.balanceMinor)}'
                      : '******',
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
                  amountMinor: summary.incomeMinor.abs(),
                  color: context.colors.income,
                  currency: currency,
                  icon: Icons.arrow_downward_rounded,
                  showBalance: showBalance,
                ),
                const SizedBox(height: 8),
                _IncomeExpenseCompact(
                  label: l10n.expense,
                  amountMinor: summary.expenseMinor.abs(),
                  color: context.colors.expense,
                  currency: currency,
                  icon: Icons.arrow_upward_rounded,
                  showBalance: showBalance,
                ),
              ],
            ),
          ],
        ),
        loading: () => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeleton(width: 60, height: 12),
                const SizedBox(height: 8),
                _skeleton(width: 120, height: 28),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _skeleton(width: 80, height: 24),
                const SizedBox(height: 8),
                _skeleton(width: 80, height: 24),
              ],
            ),
          ],
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _skeleton({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _IncomeExpenseCompact extends StatelessWidget {
  final String label;
  final int amountMinor;
  final Color color;
  final String currency;
  final IconData icon;
  final bool showBalance;

  const _IncomeExpenseCompact({
    required this.label,
    required this.amountMinor,
    required this.color,
    required this.currency,
    required this.icon,
    required this.showBalance,
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
              showBalance ? '$currency${formatMinor(amountMinor)}' : '******',
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
