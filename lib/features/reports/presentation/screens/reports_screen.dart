import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_month_picker.dart';

import '../providers/reports_providers.dart';
import '../widgets/report_breakdown_tabs.dart';
import '../widgets/report_heatmap_view.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final heatmapAsync = ref.watch(heatmapDataProvider);
    final incomeAsync = ref.watch(incomeChartDataProvider);
    final expenseAsync = ref.watch(expenseChartDataProvider);

    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    final spacing = context.spacing;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reports),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              FeatherMonthPicker.show(
                context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                onMonthSelected: (picked) {
                  ref.read(selectedDateProvider.notifier).setMonth(picked);
                },
              );
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
              child: Text(
                DateFormat.yMMMM(locale).format(selectedDate),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            SizedBox(height: spacing.md),

            // 1. Breakdown Section
            ReportBreakdownTabs(
              incomeAsync: incomeAsync,
              expenseAsync: expenseAsync,
            ),
            SizedBox(height: spacing.lg),
            const FeatherDivider(),
            SizedBox(height: spacing.lg),

            // 2. Heatmap Section
            ReportHeatmapView(
              selectedDate: selectedDate,
              heatmapAsync: heatmapAsync,
            ),
            SizedBox(height: spacing.xl),
          ],
        ),
      ),
    );
  }
}
