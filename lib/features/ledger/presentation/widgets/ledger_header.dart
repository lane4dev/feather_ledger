import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/core/presentation/providers/balance_visibility_provider.dart';

import 'package:feather_ledger/shared/presentation/models/monthly_summary_ui_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/ledger_theme.dart';

/// The expanded part of the header: the month's figures.
///
/// The month itself is not here — it sits in the app bar's title slot, on the
/// search action's line, so this is only the card.
/// Whether the header has finished collapsing at [offset].
///
/// The comparison is the whole story here: a pinned [SliverAppBar]'s scroll
/// extent is exactly `expandedHeight - kToolbarHeight`, so the outer
/// controller's offset *stops* at that value. `>` never fires, and the
/// collapsed bar stays empty.
bool isHeaderCollapsed(double offset, double expandedHeight) =>
    offset >= expandedHeight - kToolbarHeight;

class LedgerHeader extends StatelessWidget {
  /// Already written out — see [MonthlySummaryUiModel]. Without that this
  /// widget would be formatting money, which is the currency's business and
  /// not the header's.
  final AsyncValue<MonthlySummaryUiModel> summaryAsync;

  const LedgerHeader({super.key, required this.summaryAsync});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.spacing.md, 0, context.spacing.md, context.spacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Summary - Full Width
          _BalanceSummary(summaryAsync: summaryAsync),
        ],
      ),
    );
  }
}

/// The app bar's title: the month, and once the bar has collapsed, the balance
/// beside it.
///
/// The month lives up here rather than down in the expanded area so it shares
/// the toolbar's centre line with the search action — the two are one row of
/// controls. Collapsed, the steppers give way to plain text so the balance
/// fits next to it.
class LedgerAppBarTitle extends StatelessWidget {
  final DateTime selectedDate;
  final AsyncValue<MonthlySummaryUiModel> summaryAsync;
  final bool collapsed;
  final ValueChanged<DateTime>? onMonthChanged;
  final VoidCallback? onMonthTap;

  const LedgerAppBarTitle({
    super.key,
    required this.selectedDate,
    required this.summaryAsync,
    required this.collapsed,
    this.onMonthChanged,
    this.onMonthTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (collapsed)
          Text(
            DateFormat.yMMM(locale).format(selectedDate),
            style: Theme.of(context).textTheme.titleMedium,
          )
        else
          LedgerMonthSwitcher(
            selectedDate: selectedDate,
            onChanged: onMonthChanged,
            onTap: onMonthTap,
          ),
        if (collapsed) ...[
          SizedBox(width: context.spacing.md),
          LedgerCompactBalance(summaryAsync: summaryAsync),
        ],
      ],
    );
  }
}

/// The balance as it reads in the collapsed bar — masked when the user has
/// hidden balances, which is the same rule the card below follows.
class LedgerCompactBalance extends ConsumerWidget {
  final AsyncValue<MonthlySummaryUiModel> summaryAsync;

  const LedgerCompactBalance({super.key, required this.summaryAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showBalance =
        ref.watch(balanceVisibilityControllerProvider).value ?? true;

    return summaryAsync.when(
      data: (summary) => Text(
        showBalance ? summary.displayBalance : '******',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      loading: () => Container(
        width: 60,
        height: 16,
        decoration: BoxDecoration(
          color: LedgerTheme.skeletonFill(context),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      error: (_, __) => const SizedBox(),
    );
  }
}

class LedgerMonthSwitcher extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime>? onChanged;
  final VoidCallback? onTap;

  const LedgerMonthSwitcher({
    super.key,
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
          icon: const Icon(LucideIcons.chevronLeft),
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
          icon: const Icon(LucideIcons.chevronRight),
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
  final AsyncValue<MonthlySummaryUiModel> summaryAsync;

  const _BalanceSummary({required this.summaryAsync});

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
                            ? LucideIcons.eye
                            : LucideIcons.eyeOff,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  showBalance ? summary.displayBalance : '******',
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
                  displayAmount: summary.displayIncome,
                  color: context.colors.income,
                  icon: LucideIcons.arrowDown,
                  showBalance: showBalance,
                ),
                const SizedBox(height: 8),
                _IncomeExpenseCompact(
                  label: l10n.expense,
                  displayAmount: summary.displayExpense,
                  color: context.colors.expense,
                  icon: LucideIcons.arrowUp,
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
                _skeleton(context, width: 60, height: 12),
                const SizedBox(height: 8),
                _skeleton(context, width: 120, height: 28),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _skeleton(context, width: 80, height: 24),
                const SizedBox(height: 8),
                _skeleton(context, width: 80, height: 24),
              ],
            ),
          ],
        ),
        error: (e, _) => Center(child: Text(l10n.errorPrefix('$e'))),
      ),
    );
  }

  Widget _skeleton(BuildContext context,
      {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: LedgerTheme.skeletonFill(context),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _IncomeExpenseCompact extends StatelessWidget {
  final String label;

  /// Written out, symbol and all.
  final String displayAmount;
  final Color color;
  final IconData icon;
  final bool showBalance;

  const _IncomeExpenseCompact({
    required this.label,
    required this.displayAmount,
    required this.color,
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
              showBalance ? displayAmount : '******',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              label,
              style: LedgerTheme.denseLabel(context).copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
