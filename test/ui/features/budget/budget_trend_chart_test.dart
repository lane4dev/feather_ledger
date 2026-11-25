import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';
import 'package:feather_ledger/features/budget/presentation/models/budget_ui_models.dart';
import 'package:feather_ledger/features/budget/presentation/widgets/budget_trend_chart.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  BudgetTrendPointUiModel point(
    int year,
    int month, {
    int? budgetMinor,
    required int actualMinor,
    bool hasReviewNote = false,
  }) {
    final ym = YearMonth(year, month);
    return BudgetTrendPointUiModel(
      ym: ym,
      shortLabel: '$month',
      budgetMinor: budgetMinor,
      actualMinor: actualMinor,
      budgetChartValue: (budgetMinor ?? 0) / 100.0,
      actualChartValue: actualMinor / 100.0,
      hasReviewNote: hasReviewNote,
    );
  }

  Future<void> pumpChart(WidgetTester tester, Widget chart) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(width: 400, child: chart),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  List<BarChartRodData> rods(WidgetTester tester) {
    final chart = tester.widget<BarChart>(find.byType(BarChart));
    return [
      for (final group in chart.data.barGroups) group.barRods.single,
    ];
  }

  Color primaryOf(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(BudgetTrendChart))).colorScheme.primary;

  Color expenseOf(WidgetTester tester) => Theme.of(
        tester.element(find.byType(BudgetTrendChart)),
      ).extension<AppSemanticColors>()!.expense;

  group('valid-month rule', () {
    test('counts a month only when it has a positive budget or actual spend', () {
      final months = [
        point(2026, 1, budgetMinor: null, actualMinor: 0, hasReviewNote: true),
        point(2026, 2, budgetMinor: 0, actualMinor: 0),
        point(2026, 3, budgetMinor: null, actualMinor: 1200),
        point(2026, 4, budgetMinor: 5000, actualMinor: 0),
      ];

      expect(BudgetTrendChart.validMonthCount(months), 2);
      expect(BudgetTrendChart.shouldShow(months), isTrue);
    });

    test('a lone note marker or padded empty month does not count', () {
      final months = [
        point(2026, 1, budgetMinor: null, actualMinor: 0, hasReviewNote: true),
        point(2026, 2, budgetMinor: null, actualMinor: 0),
      ];

      expect(BudgetTrendChart.validMonthCount(months), 0);
      expect(BudgetTrendChart.shouldShow(months), isFalse);
    });

  });

  testWidgets('renders nothing at all with zero or one valid month',
      (tester) async {
    for (final points in [
      <BudgetTrendPointUiModel>[],
      [point(2026, 5, budgetMinor: 20000, actualMinor: 0)],
      [point(2026, 5, budgetMinor: null, actualMinor: 0, hasReviewNote: true)],
    ]) {
      await pumpChart(tester, BudgetTrendChart(points: points));
      expect(find.byType(BarChart), findsNothing);
      expect(find.text('6-Month Budget vs Actual'), findsNothing);
      expect(find.text('All actual spend'), findsNothing);
      expect(find.text('Total budget'), findsNothing);
    }
  });

  testWidgets('renders title, legend and one bar per point from two valid '
      'months', (tester) async {
    await pumpChart(
      tester,
      BudgetTrendChart(
        points: [
          point(2026, 4, budgetMinor: 20000, actualMinor: 10000),
          point(2026, 5, budgetMinor: 20000, actualMinor: 24000),
        ],
        budgetLineChartValue: 200,
      ),
    );

    expect(find.text('6-Month Budget vs Actual'), findsOneWidget);
    expect(find.text('All actual spend'), findsOneWidget);
    expect(find.text('Total budget'), findsOneWidget);
    expect(find.text('3-month average'), findsNothing);
    expect(find.byType(BarChart), findsOneWidget);
    expect(rods(tester), hasLength(2));
    expect(rods(tester).every((rod) => rod.width == 10), isTrue);

    final lines = tester
        .widget<BarChart>(find.byType(BarChart))
        .data
        .extraLinesData
        .horizontalLines;
    expect(lines, hasLength(1));
    expect(lines.single.y, 200);
    expect(lines.single.dashArray, isNotNull);
  });

  testWidgets('whole-month bars stay primary even above the budget line',
      (tester) async {
    await pumpChart(
      tester,
      BudgetTrendChart(
        points: [
          point(2026, 4, budgetMinor: 20000, actualMinor: 10000),
          // ¥240 spent against a ¥200 budget, ¥40 of it unbudgeted.
          point(2026, 5, budgetMinor: 20000, actualMinor: 24000),
        ],
        budgetLineChartValue: 200,
      ),
    );

    expect(rods(tester).last.toY, 240);
    expect(rods(tester).last.color, primaryOf(tester));
    expect(rods(tester).last.color, isNot(expenseOf(tester)));
  });

  testWidgets('category mode colours only months that strictly exceed their '
      'own budget', (tester) async {
    await pumpChart(
      tester,
      BudgetTrendChart(
        mode: BudgetTrendChartMode.category,
        points: [
          point(2026, 4, budgetMinor: 20000, actualMinor: 20100),
          point(2026, 5, budgetMinor: 20000, actualMinor: 4000),
          // No budget that month: spend is not an overrun.
          point(2026, 6, budgetMinor: null, actualMinor: 5000),
        ],
      ),
    );

    final barRods = rods(tester);
    expect(barRods[0].color, expenseOf(tester));
    expect(barRods[1].color, primaryOf(tester));
    expect(barRods[2].color, primaryOf(tester));
  });

  testWidgets('category mode does not colour a month exactly on budget',
      (tester) async {
    await pumpChart(
      tester,
      BudgetTrendChart(
        mode: BudgetTrendChartMode.category,
        points: [
          point(2026, 4, budgetMinor: 20000, actualMinor: 20000),
          point(2026, 5, budgetMinor: 20000, actualMinor: 10000),
        ],
      ),
    );

    expect(rods(tester).first.color, primaryOf(tester));
  });

  testWidgets('draws note markers only for points flagged with a note',
      (tester) async {
    await pumpChart(
      tester,
      BudgetTrendChart(
        points: [
          point(2026, 4, budgetMinor: 20000, actualMinor: 10000,
              hasReviewNote: true),
          point(2026, 5, budgetMinor: 20000, actualMinor: 24000),
        ],
      ),
    );

    expect(
      find.byKey(const ValueKey('budget-trend-note-marker-2026-04')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('budget-trend-note-marker-2026-05')),
      findsNothing,
    );
  });

  testWidgets('shows the three-month average reference line and legend',
      (tester) async {
    await pumpChart(
      tester,
      BudgetTrendChart(
        points: [
          point(2026, 4, budgetMinor: 20000, actualMinor: 10000),
          point(2026, 5, budgetMinor: 20000, actualMinor: 24000),
        ],
        threeMonthAvgChartValue: 150,
      ),
    );

    expect(find.text('3-month average'), findsOneWidget);
    final lines = tester
        .widget<BarChart>(find.byType(BarChart))
        .data
        .extraLinesData
        .horizontalLines;
    expect(lines.map((line) => line.y), contains(150));
  });

  testWidgets('falls back to the selected month budget when no line value is '
      'given, and stays hidden when that month is unbudgeted', (tester) async {
    await pumpChart(
      tester,
      BudgetTrendChart(
        points: [
          point(2026, 4, budgetMinor: 20000, actualMinor: 10000),
          point(2026, 5, budgetMinor: 20000, actualMinor: 24000),
        ],
      ),
    );
    expect(
      tester
          .widget<BarChart>(find.byType(BarChart))
          .data
          .extraLinesData
          .horizontalLines
          .single
          .y,
      200,
    );

    await pumpChart(
      tester,
      BudgetTrendChart(
        points: [
          point(2026, 4, budgetMinor: 20000, actualMinor: 10000),
          point(2026, 5, budgetMinor: null, actualMinor: 24000),
        ],
      ),
    );
    expect(
      tester
          .widget<BarChart>(find.byType(BarChart))
          .data
          .extraLinesData
          .horizontalLines,
      isEmpty,
    );
    expect(find.text('Total budget'), findsNothing);
  });

  testWidgets('keeps the legacy constructor call shape compiling and renders '
      'in dark mode', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: BudgetTrendChart(
              points: [
                point(2026, 4, budgetMinor: 20000, actualMinor: 10000),
                point(2026, 5, budgetMinor: 20000, actualMinor: 24000),
              ],
              threeMonthAvgChartValue: 15000 / 100,
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(BarChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
