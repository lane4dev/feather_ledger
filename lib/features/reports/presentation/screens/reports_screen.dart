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
    final totalsAsync = ref.watch(monthlySummaryProvider);

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

            // Monthly totals from the snapshot projection (spec 003, US9
            // 同源) — same numbers the ledger header shows.
            totalsAsync.when(
              data: (totals) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _TotalsColumn(
                    label: l10n.income,
                    displayAmount: totals.displayIncome,
                    color: context.colors.income,
                  ),
                  _TotalsColumn(
                    label: l10n.expense,
                    displayAmount: totals.displayExpense,
                    color: context.colors.expense,
                  ),
                  _TotalsColumn(
                    label: l10n.totalBalance,
                    displayAmount: totals.displayBalance,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox(),
            ),
            SizedBox(height: spacing.lg),
            const FeatherDivider(),
            SizedBox(height: spacing.lg),

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

class _TotalsColumn extends StatelessWidget {
  final String label;

  /// Written out, symbol and all — the screen is not the side that knows what
  /// an amount is.
  final String displayAmount;
  final Color color;

  const _TotalsColumn({
    required this.label,
    required this.displayAmount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          displayAmount,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: Theme.of(context).hintColor),
        ),
      ],
    );
  }
}
