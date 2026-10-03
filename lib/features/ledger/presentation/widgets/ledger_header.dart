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
  final VoidCallback? onTap;
  final GlobalKey? cardKey;

  const LedgerHeader(
      {super.key, required this.summaryAsync, this.onTap, this.cardKey});

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
              summaryAsync: summaryAsync, onTap: onTap, cardKey: cardKey),
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
          Flexible(
              child: Text(
            DateFormat.yMMM(locale).format(selectedDate),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ))
        else
          Expanded(
              child: LedgerMonthSwitcher(
            selectedDate: selectedDate,
            onChanged: onMonthChanged,
            onTap: onMonthTap,
          )),
        if (collapsed) ...[
          SizedBox(width: context.spacing.md),
          Flexible(
              child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: LedgerCompactBalance(summaryAsync: summaryAsync))),
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
        style: AppTypography.amount(context),
      ),
      loading: () => Text(
        showBalance ? '—' : '******',
        style: AppTypography.amount(context),
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
        AppIconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: onChanged == null
              ? null
              : () => onChanged!(
                  DateTime(selectedDate.year, selectedDate.month - 1)),
        ),
        Expanded(
            child: InkWell(
          onTap: onTap,
          borderRadius: context.metrics.chipBorderRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  DateFormat.yMMMM(locale).format(selectedDate),
                  style: Theme.of(context).textTheme.titleLarge,
                )),
          ),
        )),
        AppIconButton(
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
  const _BalanceSummary({required this.summaryAsync, this.onTap, this.cardKey});
  final AsyncValue<MonthlySummaryUiModel> summaryAsync;
  final VoidCallback? onTap;
  final GlobalKey? cardKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final showBalance =
        ref.watch(balanceVisibilityControllerProvider).value ?? true;
    Widget summaryContent(MonthlySummaryUiModel? summary) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Expanded(
                  child: Text(l10n.totalBalance,
                      style: AppTypography.meta(context), maxLines: 2)),
              if (onTap != null)
                Icon(LucideIcons.chevronRight,
                    size: context.metrics.iconSize,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              AppIconButton(
                icon: Icon(showBalance ? LucideIcons.eye : LucideIcons.eyeOff),
                tooltip: l10n.totalBalance,
                onPressed: () => ref
                    .read(balanceVisibilityControllerProvider.notifier)
                    .toggle(),
              ),
            ]),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                  showBalance ? summary?.displayBalance ?? '—' : '******',
                  style: AppTypography.balance(context)),
            ),
            SizedBox(height: context.spacing.md),
            Row(children: [
              Expanded(
                  child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _IncomeExpenseCompact(
                        label: l10n.income,
                        displayAmount: summary?.displayIncome ?? '—',
                        color: context.colors.income,
                        icon: LucideIcons.arrowDown,
                        showBalance: showBalance,
                      ))),
              SizedBox(width: context.spacing.md),
              Expanded(
                  child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: _IncomeExpenseCompact(
                        label: l10n.expense,
                        displayAmount: summary?.displayExpense ?? '—',
                        color: context.colors.expense,
                        icon: LucideIcons.arrowUp,
                        showBalance: showBalance,
                      ))),
            ]),
          ],
        );
    return Semantics(
      label: onTap == null ? null : l10n.viewReports,
      button: onTap != null,
      explicitChildNodes: true,
      child: AppCard(
          key: cardKey,
          onTap: onTap,
          child: summaryAsync.when(
            data: summaryContent,
            loading: () => summaryContent(null),
            error: (error, _) => Text(l10n.errorPrefix('$error')),
          )),
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
    return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
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
                  style: AppTypography.amount(context)
                      .copyWith(color: theme.colorScheme.onSurface),
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
        ));
  }
}
