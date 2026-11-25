import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/design_system/app_icon_button.dart';
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
  final DateTime? month;
  final VoidCallback? onTap;
  final GlobalKey? cardKey;

  const LedgerHeader({
    super.key,
    required this.summaryAsync,
    this.month,
    this.onTap,
    this.cardKey,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          context.pagePadding.add(EdgeInsets.only(bottom: context.spacing.md)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Summary - Full Width
          _BalanceSummary(
            summaryAsync: summaryAsync,
            month: month ?? DateTime.now(),
            onTap: onTap,
            cardKey: cardKey,
          ),
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
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    if (!collapsed) {
      return LedgerMonthSwitcher(
        selectedDate: selectedDate,
        onChanged: onMonthChanged,
        onTap: onMonthTap,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            DateFormat.yMMM(locale).format(selectedDate),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LedgerTheme.collapsedTitle(context),
          ),
        ),
        SizedBox(width: context.spacing.sm),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.sm + context.spacing.xs,
                  vertical: context.spacing.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (l10n != null) ...[
                      Text(
                        l10n.balance,
                        style: AppTypography.compactLabel(context).copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(width: context.spacing.xs),
                    ],
                    LedgerCompactBalance(summaryAsync: summaryAsync),
                  ],
                ),
              ),
            ),
          ),
        ),
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
    final style = AppTypography.compactAmount(context).copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return summaryAsync.when(
      data: (summary) => Text(
        showBalance ? summary.displayBalance : '******',
        style: style,
      ),
      loading: () => Text(
        showBalance ? '—' : '******',
        style: style,
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
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          tooltip: l10n?.previousMonth,
          onPressed: onChanged == null
              ? null
              : () => onChanged!(
                  DateTime(selectedDate.year, selectedDate.month - 1)),
        ),
        Flexible(
          child: InkWell(
            onTap: onTap,
            borderRadius: context.metrics.chipBorderRadius,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.xs,
                vertical: context.spacing.sm,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  DateFormat.yMMMM(locale).format(selectedDate),
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
          ),
        ),
        AppIconButton(
          icon: const Icon(LucideIcons.chevronRight),
          tooltip: l10n?.nextMonth,
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
  const _BalanceSummary({
    required this.summaryAsync,
    required this.month,
    this.onTap,
    this.cardKey,
  });
  final AsyncValue<MonthlySummaryUiModel> summaryAsync;
  final DateTime month;
  final VoidCallback? onTap;
  final GlobalKey? cardKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final monthLabel = DateFormat.MMM(locale).format(month);
    final showBalance =
        ref.watch(balanceVisibilityControllerProvider).value ?? true;
    final visibilityLabel =
        showBalance ? l10n.hideOverviewAmounts : l10n.showOverviewAmounts;

    Widget summaryContent(MonthlySummaryUiModel? summary) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Expanded(
                child: Row(children: [
                  Flexible(
                    child: Text(
                      l10n.totalBalance,
                      style: AppTypography.meta(context),
                      maxLines: 2,
                    ),
                  ),
                  AppIconButton(
                    icon: Icon(
                        showBalance ? LucideIcons.eye : LucideIcons.eyeOff),
                    iconSize: 18,
                    tooltip: visibilityLabel,
                    onPressed: () => ref
                        .read(balanceVisibilityControllerProvider.notifier)
                        .toggle(),
                  ),
                ]),
              ),
              if (onTap != null)
                SizedBox(
                  width: kMinInteractiveDimension,
                  height: kMinInteractiveDimension,
                  child: Center(
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: context.metrics.iconSize,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ]),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                showBalance ? summary?.displayBalance ?? '—' : '******',
                style: LedgerTheme.overviewBalance(context),
              ),
            ),
            SizedBox(height: context.spacing.md),
            Row(
              children: [
                Expanded(
                  child: _IncomeExpenseTile(
                    label: l10n.monthIncome(monthLabel),
                    displayAmount: summary?.displayIncome ?? '—',
                    containerColor: context.colors.incomeContainer,
                    onContainerColor: context.colors.onIncomeContainer,
                    icon: LucideIcons.arrowDown,
                    showBalance: showBalance,
                  ),
                ),
                SizedBox(width: context.spacing.sm + context.spacing.xs),
                Expanded(
                  child: _IncomeExpenseTile(
                    label: l10n.monthExpense(monthLabel),
                    displayAmount: summary?.displayExpense ?? '—',
                    containerColor: context.colors.expenseContainer,
                    onContainerColor: context.colors.onExpenseContainer,
                    icon: LucideIcons.arrowUp,
                    showBalance: showBalance,
                  ),
                ),
              ],
            ),
          ],
        );
    return Semantics(
      label: onTap == null ? null : l10n.viewReports,
      button: onTap != null,
      explicitChildNodes: true,
      child: AppCard.overview(
        key: cardKey,
        onTap: onTap,
        child: summaryAsync.when(
          data: summaryContent,
          loading: () => summaryContent(null),
          error: (error, _) => Text(l10n.errorPrefix('$error')),
        ),
      ),
    );
  }
}

class _IncomeExpenseTile extends StatelessWidget {
  final String label;

  /// Written out, symbol and all.
  final String displayAmount;
  final Color containerColor;
  final Color onContainerColor;
  final IconData icon;
  final bool showBalance;

  const _IncomeExpenseTile({
    required this.label,
    required this.displayAmount,
    required this.containerColor,
    required this.onContainerColor,
    required this.icon,
    required this.showBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.sm + context.spacing.xs,
        vertical: context.spacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: context.metrics.controlBorderRadius,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: onContainerColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 15,
              color: onContainerColor,
            ),
          ),
          SizedBox(width: context.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LedgerTheme.denseLabel(context)
                      .copyWith(color: onContainerColor),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    showBalance ? displayAmount : '******',
                    maxLines: 1,
                    style: AppTypography.compactAmount(context)
                        .copyWith(color: onContainerColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
