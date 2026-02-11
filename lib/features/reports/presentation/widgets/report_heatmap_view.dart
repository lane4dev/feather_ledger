import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';

import '../theme/report_theme.dart';

import 'heatmap_mode_dropdown.dart';

class ReportHeatmapView extends ConsumerWidget {
  final DateTime selectedDate;
  final AsyncValue<Map<DateTime, int>> heatmapAsync;

  const ReportHeatmapView({
    super.key,
    required this.selectedDate,
    required this.heatmapAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.activityHeatmap,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const HeatmapModeDropdown(),
          ],
        ),
        SizedBox(height: spacing.sm),
        heatmapAsync.when(
          data: (data) {
            return HeatMap(
              startDate: DateTime(selectedDate.year, selectedDate.month - 2, 1),
              endDate: DateTime(selectedDate.year, selectedDate.month + 1, 0),
              datasets: data,
              colorMode: ColorMode.color,
              showText: true,
              scrollable: true,
              colorsets: ReportTheme.heatmapColors,
              onClick: (value) {
                // Future: filter ledger to this day
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text(l10n.errorPrefix(e.toString())),
        ),
      ],
    );
  }
}
