import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';

import '../../domain/entities/reports_entities.dart';

import 'report_breakdown_view.dart';

class ReportBreakdownTabs extends StatelessWidget {
  final AsyncValue<List<ReportCategoryTotal>> incomeAsync;
  final AsyncValue<List<ReportCategoryTotal>> expenseAsync;

  const ReportBreakdownTabs({
    super.key,
    required this.incomeAsync,
    required this.expenseAsync,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: l10n.expense),
              Tab(text: l10n.income),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
            indicatorSize: TabBarIndicatorSize.tab,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 350,
            child: TabBarView(
              children: [
                ReportBreakdownView(
                  dataAsync: expenseAsync,
                  emptyMessage: l10n.noData,
                ),
                ReportBreakdownView(
                  dataAsync: incomeAsync,
                  emptyMessage: l10n.noData,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
