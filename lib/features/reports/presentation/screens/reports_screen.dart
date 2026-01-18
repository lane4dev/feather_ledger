import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Header
            Center(
                child: Text(DateFormat.yMMMM().format(selectedDate),
                    style: Theme.of(context).textTheme.titleLarge)),
            const SizedBox(height: 16),

            // 1. Heatmap
            const Text('Activity Heatmap',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
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
              error: (e, s) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),

            // 2. Charts
            const Text('Income Breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 200,
              child: incomeAsync.when(
                data: (data) => _buildDonutChart(data),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Expense Breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 200,
              child: expenseAsync.when(
                data: (data) => _buildDonutChart(data),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutChart(List<ReportCategoryTotal> data) {
    if (data.isEmpty) return const Center(child: Text('No data'));

    return PieChart(
      PieChartData(
        sections: data.map((item) {
          return PieChartSectionData(
            color: Color(item.category.colorInt),
            value: item.total,
            title: '\$${item.total.toStringAsFixed(0)}',
            radius: 50,
            titleStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }
}
