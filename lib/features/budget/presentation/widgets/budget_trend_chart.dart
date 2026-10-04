import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';

import '../models/budget_ui_models.dart';

class BudgetTrendChart extends StatelessWidget {
  final List<BudgetTrendPointUiModel> points;
  final double? threeMonthAvgChartValue;
  final bool wrappedInCard;

  const BudgetTrendChart({
    super.key,
    required this.points,
    this.threeMonthAvgChartValue,
    this.wrappedInCard = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.spacing;

    final maxVal = points.fold<double>(
      threeMonthAvgChartValue ?? 0.0,
      (prev, p) => math.max(
        prev,
        math.max(p.budgetChartValue, p.actualChartValue),
      ),
    );
    final chartMaxY = maxVal <= 0 ? 100.0 : maxVal * 1.18;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.budgetTrendTitle,
                style: AppTypography.sectionTitle(context),
              ),
            ),
            _LegendDot(
              color: scheme.outlineVariant,
              label: l10n.budgetTotal,
            ),
            SizedBox(width: spacing.sm),
            _LegendDot(
              color: scheme.primary,
              label: l10n.budgetActualSpent,
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
              extraLinesData: threeMonthAvgChartValue != null &&
                      threeMonthAvgChartValue! > 0
                  ? ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: threeMonthAvgChartValue!,
                          color: scheme.secondary.withValues(alpha: 0.75),
                          strokeWidth: 1.5,
                          dashArray: [5, 4],
                        ),
                      ],
                    )
                  : null,
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
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= points.length) {
                        return const SizedBox.shrink();
                      }
                      final p = points[idx];
                      return SideTitleWidget(
                        meta: meta,
                        space: 4,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              p.shortLabel,
                              style: AppTypography.compactLabel(context)
                                  .copyWith(color: scheme.onSurfaceVariant),
                            ),
                            if (p.hasReviewNote)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: points.asMap().entries.map((entry) {
                final idx = entry.key;
                final p = entry.value;
                final over =
                    p.budgetMinor != null && p.actualMinor > p.budgetMinor!;
                return BarChartGroupData(
                  x: idx,
                  barsSpace: 4,
                  barRods: [
                    if (p.budgetMinor != null)
                      BarChartRodData(
                        toY: p.budgetChartValue,
                        width: 10,
                        color: scheme.outlineVariant.withValues(alpha: 0.75),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    BarChartRodData(
                      toY: p.actualChartValue,
                      width: 10,
                      color: over ? context.colors.expense : scheme.primary,
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

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: context.metrics.legendBorderRadius,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.compactLabel(context)
              .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
