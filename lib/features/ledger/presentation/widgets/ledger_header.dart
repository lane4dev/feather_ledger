import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/core/presentation/providers/balance_visibility_provider.dart';

import 'package:feather_ledger/shared/presentation/models/balance_display_parts.dart';
import 'package:feather_ledger/shared/presentation/models/monthly_summary_ui_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/ledger_expense_trend.dart';
import '../theme/ledger_theme.dart';
import 'ledger_balance_sparkline.dart';

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

  /// The month's daily spending, for the card's sparkline. Already reduced —
  /// see [LedgerExpenseTrend]: this widget decides how the shape looks, not
  /// what the days add up to.
  final LedgerExpenseTrend expenseTrend;

  const LedgerHeader({
    super.key,
    required this.summaryAsync,
    this.month,
    this.onTap,
    this.cardKey,
    this.expenseTrend = const LedgerExpenseTrend.empty(),
  });

  @override
  Widget build(BuildContext context) {
    // The card sits at the top of the header slot, not at the bottom of it.
    // Bottom-aligning it (which is what this used to do) put all the slot's
    // slack in one place: a gap above the card, and a card that grew upwards
    // whenever hiding the balance made its contents shorter.
    return Padding(
      padding: context.pagePadding.add(
        EdgeInsets.only(
          top: context.spacing.xs,
          bottom: context.spacing.md,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BalanceSummary(
            summaryAsync: summaryAsync,
            month: month ?? DateTime.now(),
            expenseTrend: expenseTrend,
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
/// the toolbar's line with the search action — the two are one row of controls.
/// It hugs the leading edge (as the budget tab's does, so switching tabs does
/// not shift it). Collapsed, the steppers give way to plain text so the balance
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
    required this.expenseTrend,
    this.onTap,
    this.cardKey,
  });
  final AsyncValue<MonthlySummaryUiModel> summaryAsync;
  final DateTime month;
  final LedgerExpenseTrend expenseTrend;
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
    final scheme = Theme.of(context).colorScheme;

    Widget summaryContent(MonthlySummaryUiModel? summary) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                context.spacing.md,
                context.spacing.sm,
                context.spacing.md,
                context.spacing.sm + context.spacing.xs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // The label, its eye and the chevron are one
                            // cluster at the start of the row. The chevron
                            // used to be pushed to the card's far edge, where
                            // it floated alone above the sparkline — an arrow
                            // with nothing to its left reads as decoration,
                            // not as "this opens something".
                            Flexible(
                              child: Text(
                                l10n.totalBalance,
                                style: AppTypography.meta(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            AppIconButton(
                              icon: Icon(showBalance
                                  ? LucideIcons.eye
                                  : LucideIcons.eyeOff),
                              iconSize: 18,
                              tooltip: visibilityLabel,
                              onPressed: () => ref
                                  .read(balanceVisibilityControllerProvider
                                      .notifier)
                                  .toggle(),
                            ),
                            // Decorative only: the whole card is the target,
                            // so the chevron needs no box of its own.
                            if (onTap != null)
                              Icon(
                                LucideIcons.chevronRight,
                                size: LedgerTheme.overviewChevronSize,
                                color: scheme.onSurfaceVariant,
                              ),
                          ],
                        ),
                        _OverviewBalance(
                          display: summary?.displayBalance ?? '—',
                          showBalance: showBalance,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: context.spacing.sm),
                  Padding(
                    // The curve sits on the amount's baseline rather than the
                    // card's centre: it is the balance's companion, not a
                    // separate thing in the corner.
                    padding: EdgeInsets.only(bottom: context.spacing.xs),
                    child: LedgerBalanceSparkline(
                      trend: expenseTrend,
                      lineColor: context.colors.expense,
                      axisHintColor: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            _IncomeExpenseBar(
              monthLabel: monthLabel,
              income: summary?.displayIncome ?? '—',
              expense: summary?.displayExpense ?? '—',
              showBalance: showBalance,
            ),
          ],
        );

    return Semantics(
      label: onTap == null ? null : l10n.viewReports,
      button: onTap != null,
      explicitChildNodes: true,
      child: _OverviewCardSurface(
        key: cardKey,
        onTap: onTap,
        child: summaryAsync.when(
          data: summaryContent,
          loading: () => summaryContent(null),
          error: (error, _) => Padding(
            padding: EdgeInsets.all(context.spacing.md),
            child: Text(l10n.errorPrefix('$error')),
          ),
        ),
      ),
    );
  }
}

/// The card itself: a tinted, softly lit plate rather than a flat rectangle.
///
/// The layering is the point of it — a diagonal wash, a glow that runs out
/// before it reaches an edge, and a one-pixel line catching the top. Each is
/// quiet on its own; together they read as a card with a surface you could
/// touch, which a single grey fill could not.
class _OverviewCardSurface extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _OverviewCardSurface({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.metrics.overviewCardRadius);
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LedgerTheme.overviewBackdrop(context),
          border: Border.all(
            color: LedgerTheme.overviewBorder(context),
            width: LedgerTheme.overviewBorderWidth,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LedgerTheme.overviewGlow(context),
                  ),
                ),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: radius,
                splashColor: scheme.primary.withValues(alpha: 0.06),
                highlightColor: scheme.primary.withValues(alpha: 0.03),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The balance in three sizes: symbol, whole units, decimals.
///
/// The size change is what makes a balance feel like an amount of money rather
/// than a number: the digits you read at a glance are the ones that carry the
/// magnitude, and the cents step back into the supporting colour.
class _OverviewBalance extends StatelessWidget {
  final String display;
  final bool showBalance;

  const _OverviewBalance({required this.display, required this.showBalance});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final parts = BalanceDisplayParts.parse(display);
    final features = const [FontFeature.tabularFigures()];

    final symbolStyle = TextStyle(
      fontSize: LedgerTheme.balanceSymbolSize,
      fontWeight: FontWeight.w500,
      color: scheme.onSurfaceVariant,
      height: 1.25,
      fontFeatures: features,
    );
    final wholeStyle = TextStyle(
      fontSize: LedgerTheme.balanceWholeSize,
      fontWeight: FontWeight.w700,
      letterSpacing: LedgerTheme.balanceWholeTracking,
      color: scheme.onSurface,
      height: 1.1,
      fontFeatures: features,
    );
    final fractionStyle = TextStyle(
      fontSize: LedgerTheme.balanceFractionSize,
      fontWeight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
      height: 1.1,
      fontFeatures: features,
    );

    // A non-numeric display (`—`, or an error's text) has no symbol and no
    // decimas to step down; painting it all at the headline size is the honest
    // rendering of a value that is not a number.
    if (!parts.isNumeric) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text(display, style: wholeStyle, strutStyle: _strut),
      );
    }

    // One string, one Text: the mask keeps the symbol so the card does not
    // rearrange itself when the balance is hidden, and loses the decimal point
    // rather than splitting an asterisk run across two sizes.
    final hidden = !showBalance;
    // Asterisks ride above the baseline of the size they are set in, so a mask
    // at headline size floats; at the decimals' size it sits where the value
    // sat, and reads unmistakably as "something is here, and it is hidden".
    final maskStyle = fractionStyle.copyWith(fontWeight: FontWeight.w600);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '${parts.sign}${parts.symbol}', style: symbolStyle),
            TextSpan(
              text: hidden ? ' ****' : parts.whole,
              style: hidden ? maskStyle : wholeStyle,
            ),
            if (!hidden && parts.fraction.isNotEmpty)
              TextSpan(text: parts.fraction, style: fractionStyle),
          ],
        ),
        maxLines: 1,
        softWrap: false,
        // The line box is the whole-units size no matter which spans are
        // present, so hiding the balance cannot make the card shorter. Without
        // this the masked run (set at the decimals' size) collapses the line
        // and the card shrinks under the finger that just pressed the eye.
        strutStyle: _strut,
      ),
    );
  }

  static const _strut = StrutStyle(
    fontSize: LedgerTheme.balanceWholeSize,
    forceStrutHeight: true,
  );
}

/// The month's income and expense, fused into the card's lower edge.
///
/// They used to be two small rounded boxes floating inside the card, which is
/// a card inside a card inside a card. One translucent band across the full
/// width, divided by a hairline, says the same thing with one surface instead
/// of three — the figures read as the card's footer rather than as guests.
class _IncomeExpenseBar extends StatelessWidget {
  final String monthLabel;
  final String income;
  final String expense;
  final bool showBalance;

  const _IncomeExpenseBar({
    required this.monthLabel,
    required this.income,
    required this.expense,
    required this.showBalance,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(
          alpha: dark
              ? LedgerTheme.footerBarAlphaDark
              : LedgerTheme.footerBarAlpha,
        ),
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _IncomeExpenseColumn(
                label: l10n.monthIncome(monthLabel),
                displayAmount: showBalance ? income : '******',
                containerColor: context.colors.incomeContainer,
                onContainerColor: context.colors.onIncomeContainer,
                icon: LucideIcons.arrowDown,
              ),
            ),
            Container(
              width: 1,
              color: scheme.outlineVariant
                  .withValues(alpha: LedgerTheme.footerDividerAlpha),
            ),
            Expanded(
              child: _IncomeExpenseColumn(
                label: l10n.monthExpense(monthLabel),
                displayAmount: showBalance ? expense : '******',
                containerColor: context.colors.expenseContainer,
                onContainerColor: context.colors.onExpenseContainer,
                icon: LucideIcons.arrowUp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomeExpenseColumn extends StatelessWidget {
  final String label;

  /// Written out, symbol and all.
  final String displayAmount;
  final Color containerColor;
  final Color onContainerColor;
  final IconData icon;

  const _IncomeExpenseColumn({
    required this.label,
    required this.displayAmount,
    required this.containerColor,
    required this.onContainerColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.md,
        vertical: LedgerTheme.footerVerticalPadding,
      ),
      child: Row(
        children: [
          Container(
            width: LedgerTheme.footerIconSize,
            height: LedgerTheme.footerIconSize,
            decoration: BoxDecoration(
              color: containerColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: onContainerColor),
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
                  style: AppTypography.compactLabel(context)
                      .copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    displayAmount,
                    maxLines: 1,
                    style: AppTypography.amount(context).copyWith(
                      fontSize: 15.5,
                      color: scheme.onSurface,
                    ),
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
