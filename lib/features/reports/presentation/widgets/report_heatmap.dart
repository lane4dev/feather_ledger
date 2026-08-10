import 'package:flutter/material.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';

import '../models/report_heatmap_ui_model.dart';
import '../theme/report_theme.dart';

/// A self-contained weekly calendar grid. It consumes display data only;
/// Riverpod, report queries, and currency formatting belong to its caller.
class ReportHeatmap extends StatelessWidget {
  const ReportHeatmap({
    super.key,
    required this.model,
    this.onDayTap,
  });

  final ReportHeatmapUiModel model;
  final ValueChanged<DateTime>? onDayTap;

  @override
  Widget build(BuildContext context) {
    final size = ReportTheme.heatmapCellSize(context);
    final gap = context.spacing.xs;
    final step = size + gap;
    final width = model.weeks.length * step - gap;
    final style = Theme.of(context).textTheme.labelSmall;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(right: context.spacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(height: step),
                  for (final label in model.weekdays)
                    Padding(
                      padding: EdgeInsets.only(bottom: gap),
                      child: SizedBox(
                        height: size,
                        child: Center(child: Text(label, style: style)),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('report-heatmap-scroll'),
                scrollDirection: Axis.horizontal,
                // Match the previous chart: open at the selected month's end.
                reverse: true,
                child: SizedBox(
                  width: width,
                  child: Column(
                    children: [
                      SizedBox(
                        height: step,
                        child: Stack(
                          children: [
                            for (var i = 0; i < model.months.length; i++)
                              PositionedDirectional(
                                start: model.months[i].column * step,
                                width: ((i + 1 < model.months.length
                                                ? model.months[i + 1].column
                                                : model.weeks.length) -
                                            model.months[i].column) *
                                        step -
                                    gap,
                                child: Text(
                                  model.months[i].label,
                                  style: style,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var column = 0;
                              column < model.weeks.length;
                              column++) ...[
                            if (column > 0) SizedBox(width: gap),
                            Column(
                              children: [
                                for (final day in model.weeks[column])
                                  Padding(
                                    padding: EdgeInsets.only(bottom: gap),
                                    child: SizedBox.square(
                                      dimension: size,
                                      child: day == null
                                          ? null
                                          : _HeatmapDay(
                                              day: day,
                                              scale: model.scale,
                                              onTap: onDayTap == null
                                                  ? null
                                                  : () => onDayTap!(day.date),
                                            ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacing.sm),
        Align(
          alignment: Alignment.bottomRight,
          child: _HeatmapLegend(
            key: const ValueKey('report-heatmap-legend'),
            startLabel: model.scale == ReportHeatmapScale.frequency
                ? model.frequencyLegendLabels.first
                : l10n.heatmapNetInflow,
            endLabel: model.scale == ReportHeatmapScale.frequency
                ? model.frequencyLegendLabels.last
                : l10n.heatmapNetOutflow,
            colors: model.scale == ReportHeatmapScale.frequency
                ? [
                    for (var level = 0;
                        level < model.frequencyLegendLabels.length;
                        level++)
                      ReportTheme.heatmapColor(
                        context,
                        level == 0
                            ? ReportHeatmapDirection.zero
                            : ReportHeatmapDirection.positive,
                        level,
                        scale: ReportHeatmapScale.frequency,
                      ),
                  ]
                : [
                    for (var level = 5; level >= 1; level--)
                      ReportTheme.heatmapColor(
                          context, ReportHeatmapDirection.positive, level),
                    ReportTheme.heatmapColor(
                        context, ReportHeatmapDirection.zero, 0),
                    for (var level = 1; level <= 5; level++)
                      ReportTheme.heatmapColor(
                          context, ReportHeatmapDirection.negative, level),
                  ],
          ),
        ),
      ],
    );
  }
}

class _HeatmapDay extends StatelessWidget {
  const _HeatmapDay({required this.day, required this.scale, this.onTap});

  final ReportHeatmapDay day;
  final ReportHeatmapScale scale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = ReportTheme.heatmapColor(
      context,
      day.direction,
      day.level,
      scale: scale,
    );
    final radius = context.metrics.cellBorderRadius;
    return Semantics(
      label: day.tooltip,
      button: onTap != null,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: day.tooltip,
        excludeFromSemantics: true,
        child: Material(
          key: ValueKey(day.date),
          color: color,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Center(
              child: Text(
                day.dayLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: ReportTheme.heatmapTextColor(context, color),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeatmapLegend extends StatelessWidget {
  const _HeatmapLegend({
    super.key,
    required this.startLabel,
    required this.endLabel,
    required this.colors,
  });

  final String startLabel;
  final String endLabel;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(startLabel,
              style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        SizedBox(width: context.spacing.sm),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final color in colors)
              Padding(
                padding:
                    EdgeInsetsDirectional.only(end: context.spacing.xs / 2),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: context.metrics.legendBorderRadius,
                  ),
                  child: SizedBox.square(dimension: context.spacing.sm),
                ),
              ),
          ],
        ),
        SizedBox(width: context.spacing.sm),
        Flexible(
          child: Text(endLabel,
              style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
