import 'package:flutter/material.dart';

import 'package:feather_ledger/app/theme/app_theme.dart';

import '../models/report_heatmap_ui_model.dart';

class ReportTheme {
  static Color heatmapColor(
    BuildContext context,
    ReportHeatmapDirection direction,
    int level, {
    ReportHeatmapScale scale = ReportHeatmapScale.netFlow,
  }) {
    final neutral = Theme.of(context).colorScheme.surfaceContainerHighest;
    if (direction == ReportHeatmapDirection.zero) return neutral;
    final color = scale == ReportHeatmapScale.frequency
        ? Theme.of(context).colorScheme.primary
        : direction == ReportHeatmapDirection.positive
            ? context.colors.income
            : context.colors.expense;
    return Color.lerp(neutral, color, level / 5)!;
  }

  static Color heatmapTextColor(BuildContext context, Color background) {
    final theme = Theme.of(context);
    return ThemeData.estimateBrightnessForColor(background) == theme.brightness
        ? theme.colorScheme.onSurface
        : theme.colorScheme.surface;
  }

  static double heatmapCellSize(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );
    var extent = 0.0;
    // Measure all date labels so proportional digits and enlarged system
    // fonts fit, with only a small inset around the numbers.
    for (var day = 1; day <= 31; day++) {
      painter.text = TextSpan(text: day.toString(), style: style);
      painter.layout();
      if (painter.width > extent) extent = painter.width;
      if (painter.height > extent) extent = painter.height;
    }
    painter.dispose();
    return extent.ceilToDouble() + context.spacing.xs * 2;
  }
}
