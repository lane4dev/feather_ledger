import 'package:flutter/material.dart';

import 'package:feather_ledger/app/design_system/app_badge.dart';
import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/shared/presentation/models/balance_display_parts.dart';

import '../../domain/value_objects/budget_value_objects.dart';
import '../models/budget_ui_models.dart';
import 'budget_hatch.dart';

/// The month's headline: one amount, one bar, three figures.
///
/// The card answers one question and shows the evidence for it, and which
/// question that is depends on the month: a month in progress reports what is
/// left after what is spent and billed, a closed month reports what it ended
/// with, and a month that has not started reports how much of the budget is
/// still uncommitted. Those are three readings of the same budget, so they are
/// three states of one card rather than three cards.
///
/// Everything measured here covers the **budgeted** categories only; spending
/// in categories without a budget belongs to the section below, not to a
/// denominator it was never part of.
class BudgetOverviewCard extends StatelessWidget {
  const BudgetOverviewCard({
    super.key,
    required this.overview,
  });

  final BudgetOverviewUiModel overview;

  /// Long enough to read as a change of state, short enough that swiping
  /// between months never waits on it.
  static const Duration transitionDuration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.spacing;
    final metrics = context.metrics;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : transitionDuration;
    final mainLabel = _mainLabel(l10n);

    final badges = <Widget>[
      if (overview.mode != BudgetMode.track)
        AppBadge(
          label: overview.mode == BudgetMode.review
              ? l10n.budgetModeReview
              : l10n.budgetModePlan,
          color: scheme.primary,
          compact: true,
        ),
      AppBadge(
        label: '${l10n.budgetCompliance} ${overview.complianceDisplay}',
        compact: true,
      ),
    ];

    return AppCard.overview(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                key: const ValueKey('budget-overview-surface'),
                duration: duration,
                curve: Curves.easeInOut,
                decoration: _surfaceDecoration(context, overview.mode),
                child: overview.mode == BudgetMode.plan
                    ? CustomPaint(
                        key: const ValueKey('budget-overview-dashed-outline'),
                        painter: _DashedRoundedBorderPainter(
                          color: scheme.outline.withValues(alpha: 0.55),
                          radius: metrics.overviewCardRadius,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          Padding(
            padding: metrics.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      // The label names the number below it, so the two change
                      // together: a month switch or a mode switch fades the pair
                      // rather than swapping one of them mid-fade.
                      child: AnimatedSwitcher(
                        duration: duration,
                        child: Text(
                          mainLabel,
                          key: ValueKey('budget-overview-label-$mainLabel'),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall!
                              .copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                    SizedBox(width: spacing.sm),
                    Flexible(
                      // The slot is filled and the badges are pushed to its end;
                      // a bare shrink-wrapping Wrap would sit at the slot's
                      // start and lose the right alignment.
                      child: Align(
                        alignment: AlignmentDirectional.topEnd,
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: spacing.xs,
                          runSpacing: spacing.xs,
                          children: badges,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.xs),
                AnimatedSwitcher(
                  duration: duration,
                  // [_OverviewAmount] keeps no key of its own, so without a
                  // content-derived key the switcher would reuse the old child
                  // and nothing would cross-fade.
                  child: _OverviewAmount(
                    key: ValueKey(
                      'budget-overview-amount-$mainLabel-'
                      '${overview.mainAmount.sign}'
                      '${overview.mainAmount.whole}'
                      '${overview.mainAmount.fraction}',
                    ),
                    parts: overview.mainAmount,
                    color: overview.isMainAmountNegative
                        ? context.colors.expense
                        : scheme.onSurface,
                  ),
                ),
                SizedBox(height: spacing.sm),
                _OverviewBar(overview: overview),
                SizedBox(height: spacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < overview.footerMetrics.length; i++) ...[
                      if (i > 0) SizedBox(width: spacing.sm),
                      Expanded(
                        child: _FooterMetric(
                          metric: overview.footerMetrics[i],
                          alignment: i == overview.footerMetrics.length - 1
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _mainLabel(AppLocalizations l10n) => switch (overview.mainLabel) {
        BudgetOverviewMainLabel.projectedRemaining =>
          l10n.budgetProjectedRemaining,
        BudgetOverviewMainLabel.projectedOver => l10n.budgetProjectedOver,
        BudgetOverviewMainLabel.monthlySurplus =>
          l10n.budgetOverviewMonthlySurplus,
        BudgetOverviewMainLabel.monthlyOverspend =>
          l10n.budgetOverviewMonthlyOverspend,
        BudgetOverviewMainLabel.availableToSpend =>
          l10n.budgetOverviewAvailable,
      };

  /// The backplate, which is the only thing that changes kind with the month.
  ///
  /// Track keeps the tinted gradient and hairline of a live number, review
  /// drops the tint to a near-neutral wash (a closed month is a reading, not a
  /// signal), and plan keeps a lighter gradient plus the dashed outline that
  /// says "not yet": nothing below it has happened.
  BoxDecoration _surfaceDecoration(BuildContext context, BudgetMode mode) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = scheme.surfaceContainerHigh;

    final tintAlpha = switch (mode) {
      BudgetMode.track => dark ? 0.42 : 0.5,
      BudgetMode.review => dark ? 0.10 : 0.06,
      BudgetMode.plan => dark ? 0.24 : 0.3,
    };
    final floorAlpha = switch (mode) {
      BudgetMode.track => 0.06,
      BudgetMode.review => 0.02,
      BudgetMode.plan => 0.04,
    };

    return BoxDecoration(
      borderRadius: context.metrics.overviewCardBorderRadius,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(
            scheme.primaryContainer.withValues(alpha: tintAlpha),
            base,
          ),
          base,
          Color.alphaBlend(
            scheme.primary.withValues(alpha: floorAlpha),
            scheme.surfaceContainer,
          ),
        ],
        stops: const [0.0, 0.55, 1.0],
      ),
      border: mode == BudgetMode.track
          ? Border.all(
              // The track card's own surface is near-white in light mode; the
              // hairline is white-derived by intent, so take the surface's
              // foreground partner rather than a literal.
              color: scheme.onPrimary.withValues(alpha: dark ? 0.07 : 0.65),
            )
          : null,
    );
  }
}

/// The main amount in three sizes: symbol, whole units, decimals.
///
/// Same typesetting as the ledger header (`AppTypography.overview*Size`), so
/// the two hero numbers in the app read as the same kind of thing.
class _OverviewAmount extends StatelessWidget {
  const _OverviewAmount({
    super.key,
    required this.parts,
    required this.color,
  });

  final BalanceDisplayParts parts;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const features = <FontFeature>[FontFeature.tabularFigures()];

    final symbolStyle = TextStyle(
      fontSize: AppTypography.overviewSymbolSize,
      fontWeight: FontWeight.w500,
      color: scheme.onSurfaceVariant,
      height: 1.25,
      fontFeatures: features,
    );
    final wholeStyle = TextStyle(
      fontSize: AppTypography.overviewWholeSize,
      fontWeight: FontWeight.w700,
      letterSpacing: AppTypography.overviewWholeTracking,
      color: color,
      height: 1.1,
      fontFeatures: features,
    );
    final fractionStyle = TextStyle(
      fontSize: AppTypography.overviewFractionSize,
      fontWeight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
      height: 1.1,
      fontFeatures: features,
    );

    // `—` is not a number: there is no symbol and no decimals to step down, so
    // it is set whole at the headline size.
    if (!parts.isNumeric) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          parts.whole,
          key: const ValueKey('budget-overview-main-amount'),
          style: wholeStyle,
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text.rich(
        key: const ValueKey('budget-overview-main-amount'),
        TextSpan(
          children: [
            TextSpan(text: '${parts.sign}${parts.symbol}', style: symbolStyle),
            TextSpan(text: parts.whole, style: wholeStyle),
            TextSpan(text: parts.fraction, style: fractionStyle),
          ],
        ),
      ),
    );
  }
}

/// The bar under the amount: how much of the budget this mode's number is
/// measured against.
///
/// Track draws what is spent and what is billed but not yet paid, and marks
/// where today sits in the month — the two together are what makes a bar
/// readable before the month ends. Review draws only what was spent. Plan
/// draws the fixed baseline, because in a month that has not started the only
/// thing in the budget is the commitments already inside it.
class _OverviewBar extends StatelessWidget {
  const _OverviewBar({required this.overview});

  final BudgetOverviewUiModel overview;

  /// The bar itself, and the strip it sits in — tall enough for the tick to
  /// poke out above and below without moving the layout.
  static const double _barHeight = 8;
  static const double _stripHeight = 14;
  static const double _tickWidth = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final frequency = context.colors.frequency;
    final mode = overview.mode;
    final tickRatio = overview.todayTickRatio;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final actualWidth = width * overview.actualRatio;
        final pendingWidth = width * overview.pendingRatio;
        final baselineWidth = width * overview.fixedBaselineRatio;

        return SizedBox(
          height: _stripHeight,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: (_stripHeight - _barHeight) / 2,
                bottom: (_stripHeight - _barHeight) / 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: scheme.surfaceContainerHighest),
                      if (mode == BudgetMode.plan) ...[
                        if (baselineWidth > 0)
                          Positioned(
                            left: 0,
                            width: baselineWidth,
                            top: 0,
                            bottom: 0,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ColoredBox(
                                  key: const ValueKey(
                                      'budget-overview-bar-baseline'),
                                  color: frequency.withValues(alpha: 0.16),
                                ),
                                BudgetHatch(
                                  key: const ValueKey(
                                      'budget-hero-baseline-hatch'),
                                  color: frequency.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                      ] else ...[
                        if (actualWidth > 0)
                          Positioned(
                            left: 0,
                            width: actualWidth,
                            top: 0,
                            bottom: 0,
                            child: ColoredBox(
                              key: const ValueKey('budget-overview-bar-actual'),
                              color: scheme.primary,
                            ),
                          ),
                        if (mode == BudgetMode.track && pendingWidth > 0)
                          Positioned(
                            left: actualWidth,
                            width: pendingWidth,
                            top: 0,
                            bottom: 0,
                            child: ColoredBox(
                              key:
                                  const ValueKey('budget-overview-bar-pending'),
                              color: frequency.withValues(alpha: 0.65),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              if (tickRatio != null)
                Positioned(
                  left: width * tickRatio - _tickWidth / 2,
                  width: _tickWidth,
                  top: 0,
                  bottom: 0,
                  child: Semantics(
                    label: l10n.today,
                    container: true,
                    child: DecoratedBox(
                      key: const ValueKey('budget-overview-today-tick'),
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(_tickWidth / 2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FooterMetric extends StatelessWidget {
  const _FooterMetric({required this.metric, required this.alignment});

  final BudgetOverviewMetricUiModel metric;

  /// The first two columns read from the left, the budget closes the row on
  /// the right.
  final CrossAxisAlignment alignment;

  /// Room for one line at the given font size, with the leading the text
  /// styles actually use — larger than 1 so 1× text is never scaled.
  static const double _lineBoxFactor = 1.6;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = metric.tone == BudgetOverviewMetricTone.pending
        ? context.colors.frequency
        : Theme.of(context).colorScheme.onSurface;
    final labelStyle = AppTypography.meta(context);
    final valueStyle = AppTypography.amount(context).copyWith(color: color);

    // Three columns have to stay one row at 320dp and at 1.6× text, so each
    // cell scales down instead of wrapping. Both cells are given the same
    // height and are top-aligned, which is what keeps the three labels and the
    // three values on two shared lines when they shrink by different amounts.
    final scaler = MediaQuery.textScalerOf(context);
    final crossAlignment = alignment == CrossAxisAlignment.end
        ? AlignmentDirectional.topEnd
        : AlignmentDirectional.topStart;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        SizedBox(
          height: scaler.scale(labelStyle.fontSize!) * _lineBoxFactor,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: crossAlignment,
            child: Text(_label(l10n), style: labelStyle),
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: scaler.scale(valueStyle.fontSize!) * _lineBoxFactor,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: crossAlignment,
            child: Text(metric.value, style: valueStyle),
          ),
        ),
      ],
    );
  }

  String _label(AppLocalizations l10n) => switch (metric.metric) {
        BudgetOverviewMetric.spent => l10n.budgetActualSpent,
        BudgetOverviewMetric.pending => l10n.budgetPendingShort,
        BudgetOverviewMetric.totalBudget => l10n.budgetTotal,
        BudgetOverviewMetric.budgetUsage => l10n.budgetOverviewBudgetUsage,
        BudgetOverviewMetric.committedBaseline =>
          l10n.budgetCommittedBaseline,
        BudgetOverviewMetric.baselineShare =>
          l10n.budgetOverviewBaselineShare,
      };
}

/// A 1dp dashed rounded outline, inset by half its stroke so the dashes sit
/// inside the card's clip instead of half outside it.
class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({
    required this.color,
    required this.radius,
  });

  /// 1dp outline, 5dp dashes with 4dp gaps.
  static const double _strokeWidth = 1;
  static const double _dashLength = 5;
  static const double _gapLength = 4;

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    ).deflate(_strokeWidth / 2);
    final path = Path()..addRRect(rect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + _dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedBorderPainter oldDelegate) =>
      color != oldDelegate.color || radius != oldDelegate.radius;
}
