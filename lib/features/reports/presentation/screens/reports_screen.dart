import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/shared/presentation/money_format.dart';
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
    final totalsAsync = ref.watch(monthlyTotalsProvider);

    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    final currencyKey = ref.watch(currencyControllerProvider).value ??
        AppCurrencies.supportedCurrencyCodes.first;
    final currencySymbol = AppCurrencies.getSymbol(currencyKey);

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
                    amountMinor: totals.incomeMinor,
                    currencySymbol: currencySymbol,
                    color: context.colors.income,
                  ),
                  _TotalsColumn(
                    label: l10n.expense,
                    amountMinor: totals.expenseMinor,
                    currencySymbol: currencySymbol,
                    color: context.colors.expense,
                  ),
                  _TotalsColumn(
                    label: l10n.totalBalance,
                    amountMinor: totals.balanceMinor,
                    currencySymbol: currencySymbol,
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
  final int amountMinor;
  final String currencySymbol;
  final Color color;

  const _TotalsColumn({
    required this.label,
    required this.amountMinor,
    required this.currencySymbol,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$currencySymbol${formatMinor(amountMinor.abs())}',
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
