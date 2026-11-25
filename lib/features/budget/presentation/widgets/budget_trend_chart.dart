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
/// Bars are always the actual spend. The budget is a dashed reference line at
/// the selected month's budget (the last point), while per-month budgets only
/// decide category overrun colour. The block hides itself entirely when fewer
/// than [minValidMonths] months have data, so callers must gate the spacing
/// around it with [shouldShow].
class BudgetTrendChart extends StatelessWidget {
  static const int minValidMonths = 2;

  final List<BudgetTrendPointUiModel> points;
  final double? threeMonthAvgChartValue;
  final double? budgetLineChartValue;
  final BudgetTrendChartMode mode;
  final bool wrappedInCard;

  const BudgetTrendChart({
    super.key,
    required this.points,
    this.threeMonthAvgChartValue,
    this.budgetLineChartValue,
    this.mode = BudgetTrendChartMode.total,
    this.wrappedInCard = true,
  });

  /// Months that carry information: a positive budget or any actual spend.
  /// Padded empty months and a lone review-note marker do not count.
  static int validMonthCount(List<BudgetTrendPointUiModel> points) =>
      points.where(_isValidMonth).length;

  static bool shouldShow(List<BudgetTrendPointUiModel> points) =>
      validMonthCount(points) >= minValidMonths;

  static bool _isValidMonth(BudgetTrendPointUiModel point) =>
      (point.budgetMinor != null && point.budgetMinor! > 0) ||
      point.actualMinor != 0;

  double? get _budgetLine {
    final explicit = budgetLineChartValue;
    if (explicit != null) return explicit > 0 ? explicit : null;
    if (points.isEmpty) return null;
    final lastBudget = points.last.budgetMinor;
    if (lastBudget == null || lastBudget <= 0) return null;
    return lastBudget / 100.0;
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldShow(points)) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.spacing;
    final budgetLine = _budgetLine;
    final averageLine = threeMonthAvgChartValue != null &&
            threeMonthAvgChartValue! > 0
        ? threeMonthAvgChartValue
        : null;

    final maxVal = points.fold<double>(
      math.max(budgetLine ?? 0.0, averageLine ?? 0.0),
      (prev, p) => math.max(prev, p.actualChartValue),
    );
    final chartMaxY = maxVal <= 0 ? 100.0 : maxVal * 1.18;

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
              label: l10n.budgetTrendLegendActual,
            ),
            if (budgetLine != null)
              _LegendItem(
                color: scheme.outline,
                label: l10n.budgetTrendLegendBudget,
                isLine: true,
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
          height: 156,
          child: BarChart(
            BarChartData(
              maxY: chartMaxY,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              barTouchData: const BarTouchData(enabled: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: chartMaxY / 3,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  if (budgetLine != null)
                    HorizontalLine(
                      y: budgetLine,
                      color: scheme.outline,
                      strokeWidth: 1.5,
                      dashArray: const [5, 4],
                    ),
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
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
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
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= points.length) {
                        return const SizedBox.shrink();
                      }
                      final point = points[idx];
                      return SideTitleWidget(
                        meta: meta,
                        space: 4,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (point.hasReviewNote) ...[
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
                              const SizedBox(width: 2),
                            ],
                            Text(
                              point.shortLabel,
                              style: AppTypography.compactLabel(context)
                                  .copyWith(color: scheme.onSurfaceVariant),
                            ),
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
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: point.actualChartValue,
                      width: 10,
                      color:
                          overrun ? context.colors.expense : scheme.primary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
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
