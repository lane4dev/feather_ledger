import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';

import '../models/budget_ui_models.dart';

/// How the actual bars are coloured.
enum BudgetTrendChartMode {
  /// Whole-month spend: bars are always primary, even above the budget line,
  /// because they include unbudgeted categories.
  total,

  /// One category's spend: a bar takes the overrun colour only when that month
  /// has a budget and actual spend strictly exceeds it.
  category,
}

/// Shared six-month budget-vs-actual chart.
///
/// Bars are always the actual spend; each month's own budget sits behind its bar
/// as a wider ghost column, so six different budgets draw six different heights
/// and a month without a budget draws none. A single average line can be laid
/// over the bars, and category overrun colour still comes from the same
/// per-month budget. The block hides itself entirely when fewer than
/// [minValidMonths] months have data, so callers must gate the spacing around
/// it with [shouldShow].
///
/// A true budget *polyline* would need `LineChart`, which cannot share a
/// category axis with [BarChart]; the background rod is the closest faithful
/// rendering because fl_chart aligns it to the bar's own x slot exactly.
class BudgetTrendChart extends StatelessWidget {
  static const int minValidMonths = 2;
  static const double _chartHeight = 156;

  final List<BudgetTrendPointUiModel> points;
  final double? threeMonthAvgChartValue;
  final BudgetTrendChartMode mode;
  final bool wrappedInCard;

  const BudgetTrendChart({
    super.key,
    required this.points,
    this.threeMonthAvgChartValue,
    this.mode = BudgetTrendChartMode.total,
    this.wrappedInCard = true,
  });

  /// Months that carry information: a positive budget or any actual spend in a
  /// month that has already started. Padded empty months, a future month whose
  /// only content is a budget rule, and a lone review-note marker do not count.
  static int validMonthCount(List<BudgetTrendPointUiModel> points) =>
      points.where(_isValidMonth).length;

  static bool shouldShow(List<BudgetTrendPointUiModel> points) =>
      validMonthCount(points) >= minValidMonths;

  static bool _isValidMonth(BudgetTrendPointUiModel point) =>
      !point.isFuture &&
      ((point.budgetMinor != null && point.budgetMinor! > 0) ||
          point.actualMinor != 0);

  static bool _hasBudget(List<BudgetTrendPointUiModel> points) =>
      points.any((p) => p.budgetChartValue > 0);

  @override
  Widget build(BuildContext context) {
    if (!shouldShow(points)) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.spacing;
    final hasBudget = _hasBudget(points);
    final averageLine =
        threeMonthAvgChartValue != null && threeMonthAvgChartValue! > 0
            ? threeMonthAvgChartValue
            : null;

    final maxVal = points.fold<double>(
      averageLine ?? 0.0,
      (prev, p) =>
          math.max(prev, math.max(p.actualChartValue, p.budgetChartValue)),
    );
    // Y-axis ticks are rounded to 1/2/5 x 10^n steps so the axis reads
    // 0 / 100 / 200 / 300 instead of thirds of an arbitrary maximum.
    final target = maxVal <= 0 ? 100.0 : maxVal * 1.08;
    final axisInterval = _niceStep(target / 3);
    final chartMaxY = (target / axisInterval).ceil() * axisInterval;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.budgetTrendTitle,
          style: AppTypography.sectionTitle(context),
        ),
        SizedBox(height: spacing.sm),
        Wrap(
          spacing: spacing.md,
          runSpacing: spacing.xs,
          children: [
            _LegendItem(
              color: scheme.primary,
              label: mode == BudgetTrendChartMode.category
                  ? l10n.budgetTrendLegendCategoryActual
                  : l10n.budgetTrendLegendActual,
            ),
            if (hasBudget)
              _LegendItem(
                color: scheme.outline.withValues(alpha: 0.35),
                label: mode == BudgetTrendChartMode.category
                    ? l10n.budgetTrendLegendCategoryBudget
                    : l10n.budgetTrendLegendBudget,
              ),
            if (averageLine != null)
              _LegendItem(
                color: scheme.secondary,
                label: l10n.budgetTrendLegendAverage,
                isLine: true,
              ),
          ],
        ),
        SizedBox(height: spacing.md),
        SizedBox(
          height: _chartHeight,
          child: BarChart(
            BarChartData(
              maxY: chartMaxY,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => scheme.surfaceContainerHighest,
                  tooltipBorderRadius:
                      BorderRadius.circular(context.metrics.chipRadius),
                  tooltipPadding: EdgeInsets.symmetric(
                    horizontal: spacing.sm,
                    vertical: spacing.xs,
                  ),
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final point = points[groupIndex];
                    final lines = [
                      l10n.budgetTrendTooltipActual(point.actualDisplay),
                      if (point.budgetDisplay != null)
                        l10n.budgetTrendTooltipBudget(point.budgetDisplay!),
                    ];
                    return BarTooltipItem(
                      '${point.shortLabel}\n${lines.join('\n')}',
                      TextStyle(
                        color: scheme.onSurface,
                        fontSize: 11,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.start,
                    );
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: axisInterval,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  if (averageLine != null)
                    HorizontalLine(
                      y: averageLine,
                      color: scheme.secondary.withValues(alpha: 0.75),
                      strokeWidth: 1.5,
                      dashArray: const [5, 4],
                    ),
                ],
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    interval: axisInterval,
                    getTitlesWidget: (value, meta) {
                      // Three light ticks at the grid lines; zero stays bare.
                      if (value <= 0) return const SizedBox.shrink();
                      return SideTitleWidget(
                        meta: meta,
                        space: 4,
                        child: Text(
                          _compactTick(value),
                          style: TextStyle(
                            color: scheme.outline,
                            fontSize: 11,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= points.length) {
                        return const SizedBox.shrink();
                      }
                      final point = points[idx];
                      return SideTitleWidget(
                        meta: meta,
                        space: 4,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              point.shortLabel,
                              style: AppTypography.compactLabel(context)
                                  .copyWith(color: scheme.onSurfaceVariant),
                            ),
                            if (point.hasReviewNote) ...[
                              const SizedBox(height: 2),
                              Container(
                                key: ValueKey(
                                  'budget-trend-note-marker-${point.ym}',
                                ),
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: points.asMap().entries.map((entry) {
                final point = entry.value;
                final overrun = mode == BudgetTrendChartMode.category &&
                    point.budgetMinor != null &&
                    point.budgetMinor! > 0 &&
                    point.actualMinor > point.budgetMinor!;
                final budget = point.budgetChartValue;
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: point.actualChartValue,
                      width: 10,
                      color: overrun ? context.colors.expense : scheme.primary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                      // Each month's own budget, drawn as a wider ghost column
                      // behind its bar: exactly aligned with that month's slot,
                      // absent when the month has no budget.
                      backDrawRodData: BackgroundBarChartRodData(
                        show: budget > 0,
                        toY: budget,
                        color: scheme.outline.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );

    return wrappedInCard ? AppCard(child: content) : content;
  }
}

/// A 1/2/5 x 10^n step at least as large as [rough].
double _niceStep(double rough) {
  if (rough <= 0) return 1;
  final magnitude =
      math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
  final normalized = rough / magnitude;
  final step = normalized <= 1
      ? 1.0
      : normalized <= 2
          ? 2.0
          : normalized <= 5
              ? 5.0
              : 10.0;
  return step * magnitude;
}

/// A short axis tick: whole units below a thousand, then `k`.
String _compactTick(double majorUnits) {
  if (majorUnits >= 1000) {
    final thousands = majorUnits / 1000;
    return '${thousands.toStringAsFixed(thousands >= 10 ? 0 : 1)}k';
  }
  return majorUnits.toStringAsFixed(0);
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isLine;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isLine ? 12 : 8,
          height: isLine ? 2 : 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: context.metrics.legendBorderRadius,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            softWrap: true,
            style: AppTypography.compactLabel(context).copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
