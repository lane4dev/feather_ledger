import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/reports/data/repositories/reports_repository.dart';
import 'package:feather_ledger/features/reports/domain/entities/reports_entities.dart';
import 'package:feather_ledger/features/reports/presentation/screens/reports_screen.dart';

/// Widget test (spec 003, US9/T066): the reports screen renders the
/// snapshot-sourced monthly totals and the breakdown rows — presentation
/// only, no business computation.
class _FakeReportsRepository implements ReportsRepository {
  @override
  Stream<Map<DateTime, int>> watchHeatmapData(DateTime month) =>
      Stream.value({DateTime(2024, 1, 15): -5000});

  @override
  Stream<Map<DateTime, int>> watchHeatmapAmountData(DateTime month) =>
      watchHeatmapData(month);

  @override
  Stream<List<ReportCategoryTotal>> watchCategoryBreakdown(
          DateTime month, CategoryType type) =>
      Stream.value(const [
        ReportCategoryTotal(
          category: CategoryEntity(
            id: 'cat_food',
            name: 'Food',
            iconKey: 'restaurant',
            colorInt: 0xFFFF0000,
            type: CategoryType.expense,
          ),
          totalMinor: -5000,
        ),
      ]);

  @override
  Stream<ReportMonthlyTotals> watchMonthlyTotals(DateTime month,
          {String currencyCode = 'USD'}) =>
      Stream.value(const ReportMonthlyTotals(
        incomeMinor: 10000,
        expenseMinor: -5000,
        balanceMinor: 5000,
      ));
}

void main() {
  testWidgets('renders snapshot totals and the category breakdown',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportsRepositoryProvider.overrideWithValue(_FakeReportsRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: const ReportsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Monthly totals header: income, expense (absolute) and balance from
    // the snapshot projection.
    expect(find.text('\$100.00'), findsOneWidget);
    expect(find.text('\$50.00'), findsWidgets);
    // Breakdown list: category name from the write-time snapshot.
    expect(find.text('Food'), findsOneWidget);
  });
}
