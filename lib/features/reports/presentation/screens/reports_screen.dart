import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/features/ledger/presentation/providers/ledger_providers.dart';
import '../providers/reports_providers.dart';
import '../../domain/reports_entities.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final heatmapAsync = ref.watch(heatmapDataProvider);
    final incomeAsync = ref.watch(incomeChartDataProvider);
    final expenseAsync = ref.watch(expenseChartDataProvider);
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reports),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                ref.read(selectedDateProvider.notifier).setMonth(picked);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Header
            Center(
                child: Text(DateFormat.yMMMM().format(selectedDate),
                    style: Theme.of(context).textTheme.titleLarge)),
            SizedBox(height: spacing.md),

            // 1. Heatmap
            Text(l10n.activityHeatmap,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: spacing.sm),
            heatmapAsync.when(
              data: (data) {
                return HeatMap(
                  startDate: DateTime(selectedDate.year, selectedDate.month, 1),
                  endDate:
                      DateTime(selectedDate.year, selectedDate.month + 1, 0),
                  datasets: data,
                  colorMode: ColorMode.opacity,
                  showText: true,
                  scrollable: true,
                  colorsets: {
                    1: Theme.of(context).colorScheme.primary,
                  },
                  onClick: (value) {
                    // Maybe filter ledger to this day?
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text(l10n.errorPrefix(e.toString())),
            ),
            SizedBox(height: spacing.lg),

            // 2. Charts
            Text(l10n.incomeBreakdown,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 200,
              child: incomeAsync.when(
                data: (data) => _buildDonutChart(context, data, l10n),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) =>
                    Center(child: Text(l10n.errorPrefix(e.toString()))),
              ),
            ),
            SizedBox(height: spacing.lg),

            Text(l10n.expenseBreakdown,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 200,
              child: expenseAsync.when(
                data: (data) => _buildDonutChart(context, data, l10n),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) =>
                    Center(child: Text(l10n.errorPrefix(e.toString()))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutChart(BuildContext context, List<ReportCategoryTotal> data,
      AppLocalizations l10n) {
    if (data.isEmpty) return Center(child: Text(l10n.noData));

    return PieChart(
      PieChartData(
        sections: data.map((item) {
          return PieChartSectionData(
            color: Color(item.category.colorInt),
            value: item.total,
            title: '\$${item.total.toStringAsFixed(0)}',
            radius: 50,
            titleStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }
}
