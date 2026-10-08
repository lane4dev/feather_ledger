import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/design_system/app_floating_toolbar.dart';
import 'package:feather_ledger/app/design_system/app_badge.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/budget/domain/entities/budget_entities.dart';
import 'package:feather_ledger/features/budget/domain/services/budget_service.dart';
import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';
import 'package:feather_ledger/features/budget/presentation/screens/budget_screen.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';

class _FakeBudgetService implements BudgetService {
  final Map<YearMonth, MonthBudgetSummary> summaries;

  _FakeBudgetService(this.summaries);

  @override
  Stream<MonthBudgetSummary> watchMonthBudget({
    required String currencyCode,
    required YearMonth month,
  }) =>
      Stream.value(summaries[month]!);

  @override
  Stream<CategoryBudgetHint> watchTransactionBudgetHint({
    required String currencyCode,
    required YearMonth month,
    required String categoryId,
  }) =>
      const Stream.empty();

  @override
  Future<bool> hasFutureRulesAfter({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
  }) async =>
      false;

  @override
  Future<Result<void>> setCategoryBudget({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
    required int amountMinor,
    required BudgetEditScope scope,
  }) async =>
      unitResult;

  @override
  Future<Result<void>> clearCategoryBudget({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
    required BudgetEditScope scope,
  }) async =>
      unitResult;

  @override
  Future<Result<void>> saveReviewNote({
    required String currencyCode,
    required YearMonth month,
    String? categoryId,
    required String note,
  }) async =>
      unitResult;
}

CategoryBudgetSummary _cat({
  required String id,
  required String name,
  int? budgetMinor,
  int actualMinor = 0,
  int pendingMinor = 0,
  bool isArchived = false,
  BudgetRiskLevel riskLevel = BudgetRiskLevel.inBudget,
}) {
  return CategoryBudgetSummary(
    categoryId: id,
    categoryName: name,
    iconKey: 'utensils',
    colorInt: 0xFFE65100,
    isArchived: isArchived,
    archiveYm: isArchived ? const YearMonth(2026, 4) : null,
    budgetMinor: budgetMinor,
    hasFutureRulesAfter: false,
    committedActualMinor: 0,
    discretionaryActualMinor: actualMinor,
    actualMinor: actualMinor,
    pendingMinor: pendingMinor,
    projectedRemainingMinor:
        budgetMinor != null ? budgetMinor - actualMinor - pendingMinor : null,
    lastMonthActualMinor: 50000,
    threeMonthAvgMinor: 60000,
    committedBaselineMinor: pendingMinor,
    isAnomaly: false,
    anomalyDeltaRatio: null,
    riskLevel: riskLevel,
    sixMonthTrend: const [
      BudgetTrendPoint(
        month: YearMonth(2026, 5),
        budgetMinor: 100000,
        actualMinor: 40000,
        pendingMinor: 0,
        hasReviewNote: false,
      ),
    ],
    topTransactions: const [],
    reviewNote: null,
  );
}

MonthBudgetSummary _summary({
  required YearMonth month,
  required BudgetMode mode,
  int unbudgetedMinor = 25000,
}) {
  final dining = _cat(
    id: 'dining',
    name: 'Dining',
    budgetMinor: 100000,
    actualMinor: 40000,
    pendingMinor: mode == BudgetMode.review ? 0 : 10000,
  );
  final travel = _cat(
    id: 'travel',
    name: 'Travel',
    budgetMinor: null,
    actualMinor: unbudgetedMinor,
    isArchived: mode == BudgetMode.review,
  );
  final utils = _cat(
    id: 'utils',
    name: 'Utilities',
    budgetMinor: null,
    actualMinor: 0,
  );

  return MonthBudgetSummary(
    currencyCode: 'USD',
    month: month,
    mode: mode,
    hasAnyActiveAccount: true,
    totalBudgetMinor: 100000,
    budgetedActualMinor: 40000,
    budgetedPendingMinor: mode == BudgetMode.review ? 0 : 10000,
    projectedRemainingMinor: mode == BudgetMode.review ? 60000 : 50000,
    budgetedRemainingActualMinor: 60000,
    allExpenseActualMinor: 40000 + unbudgetedMinor,
    allExpensePendingMinor: mode == BudgetMode.review ? 0 : 10000,
    unbudgetedActualMinor: unbudgetedMinor,
    unbudgetedPendingMinor: 0,
    inBudgetCount: 1,
    budgetedCategoryCount: 1,
    complianceRate: 1.0,
    hasAnyBudget: true,
    hasUnbudgetedActivity: true,
    hasLeftoverPendingInReview: mode == BudgetMode.review,
    hasHighFrequencyPending: false,
    isFarFutureMaterializedOnly: mode == BudgetMode.plan,
    budgetedCategories: [dining],
    unbudgetedActiveCategories: [travel],
    remainingActiveCategories: [utils],
    overBudgetTop3: const [],
    underBudgetTop3: mode == BudgetMode.review
        ? const [
            BudgetAttributionItem(
              categoryId: 'dining',
              categoryName: 'Dining',
              iconKey: 'utensils',
              colorInt: 0xFFE65100,
              budgetMinor: 100000,
              actualMinor: 40000,
              varianceMinor: 60000,
              shareOfTotalActual: 0.62,
            ),
          ]
        : const [],
    unbudgetedAlertsTop3: const [
      UnbudgetedSpendAlert(
        categoryId: 'travel',
        categoryName: 'Travel',
        iconKey: 'utensils',
        colorInt: 0xFFE65100,
        actualMinor: 25000,
        pendingMinor: 0,
        shareOfTotalActual: 0.38,
      ),
    ],
    monthTrend6Months: const [
      BudgetTrendPoint(
        month: YearMonth(2026, 5),
        budgetMinor: 100000,
        actualMinor: 65000,
        pendingMinor: 0,
        hasReviewNote: false,
      ),
    ],
    monthReviewNote: null,
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  Future<void> pumpBudgetScreen(
    WidgetTester tester, {
    required _FakeBudgetService service,
    required DateTime now,
    Size size = const Size(1200, 2400),
    bool accessibleNavigation = false,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          budgetClockProvider.overrideWithValue(FixedClock(now)),
          budgetServiceProvider.overrideWithValue(service),
          ledgerCurrencyProvider.overrideWithValue('USD'),
          displayCurrencySymbolProvider.overrideWithValue('\$'),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              accessibleNavigation: accessibleNavigation,
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: const BudgetScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool isSelected(WidgetTester tester, String label) {
    final selection = find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((widget) =>
          widget is Semantics &&
          widget.properties.inMutuallyExclusiveGroup == true),
    );
    return tester.widget<Semantics>(selection.first).properties.selected!;
  }

  testWidgets(
      'switches Track -> Review preview -> Review/Plan, shows unbudgeted '
      'side-note, and expands remaining categories', (tester) async {
    const apr = YearMonth(2026, 4);
    const may = YearMonth(2026, 5);
    const jun = YearMonth(2026, 6);

    final service = _FakeBudgetService({
      apr: _summary(month: apr, mode: BudgetMode.review),
      may: _summary(month: may, mode: BudgetMode.track),
      jun: _summary(month: jun, mode: BudgetMode.plan),
    });

    await pumpBudgetScreen(tester,
        service: service, now: DateTime(2026, 5, 10));

    // Track mode hero + budgeted-only compliance + unbudgeted side-note
    expect(find.text('Track'), findsOneWidget);
    expect(find.textContaining('1/1'), findsOneWidget);
    expect(find.textContaining('All expenses'), findsOneWidget);
    expect(find.byIcon(LucideIcons.info), findsOneWidget);
    expect(tester.getTopLeft(find.textContaining('All expenses')).dy,
        greaterThan(tester.getTopLeft(find.text('Total budget').first).dy));
    expect(tester.getCenter(find.textContaining('1/1')).dx,
        greaterThan(tester.getCenter(find.text('Track')).dx));
    final badge = find.ancestor(
        of: find.textContaining('1/1'), matching: find.byType(AppBadge));
    final headerRow =
        find.ancestor(of: badge, matching: find.byType(Row)).first;
    expect(tester.getRect(badge).right, tester.getRect(headerRow).right);

    // Remaining categories collapsed initially
    expect(find.text('Utilities'), findsNothing);
    await tester.tap(find.textContaining('Other categories'));
    await tester.pumpAndSettle();
    expect(find.text('Utilities'), findsOneWidget);

    // Toggle Review preview inside Track month
    expect(find.text('Month Review & Attribution'), findsNothing);
    expect(isSelected(tester, 'Budget tracking'), isTrue);
    expect(isSelected(tester, 'Review preview'), isFalse);
    await tester.tap(find.text('Budget tracking'));
    await tester.pumpAndSettle();
    expect(find.text('Month Review & Attribution'), findsNothing);
    await tester.tap(find.text('Review preview'));
    await tester.pumpAndSettle();
    expect(find.text('Month Review & Attribution'), findsOneWidget);
    expect(isSelected(tester, 'Budget tracking'), isFalse);
    expect(isSelected(tester, 'Review preview'), isTrue);

    // Navigate backward to April -> Review mode + archived badge + leftover pending hint
    await tester.fling(find.byType(PageView), const Offset(900, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Archived'), findsOneWidget);
    expect(find.textContaining('unposted scheduled bills'), findsOneWidget);

    // Navigate forward twice to June -> Plan mode
    await tester.fling(find.byType(PageView), const Offset(-900, 0), 1500);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.chevronRight));
    await tester.pumpAndSettle();
    expect(find.text('Plan'), findsOneWidget);
    expect(find.textContaining('materialized pending bills'), findsNothing);
    expect(find.byType(AppFloatingToolbar), findsNothing);
  });

  testWidgets('omits the expense note when there is no unbudgeted spend',
      (tester) async {
    const may = YearMonth(2026, 5);
    await pumpBudgetScreen(tester,
        service: _FakeBudgetService({
          may: _summary(month: may, mode: BudgetMode.track, unbudgetedMinor: 0),
        }),
        now: DateTime(2026, 5, 10));
    expect(find.textContaining('All expenses'), findsNothing);
    expect(find.byIcon(LucideIcons.info), findsNothing);
  });

  testWidgets('toolbar hides on downward scroll and returns on upward scroll',
      (tester) async {
    const may = YearMonth(2026, 5);
    await pumpBudgetScreen(tester,
        service: _FakeBudgetService(
            {may: _summary(month: may, mode: BudgetMode.track)}),
        now: DateTime(2026, 5, 10),
        size: const Size(400, 700));

    expect(find.text('Review preview').hitTestable(), findsOneWidget);
    await tester.dragFrom(const Offset(100, 300), const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(find.text('Review preview').hitTestable(), findsNothing);

    await tester.dragFrom(const Offset(100, 300), const Offset(0, 180));
    await tester.pumpAndSettle();
    expect(find.text('Review preview').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Review preview'));
    await tester.pumpAndSettle();
    expect(find.text('Budget tracking').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Budget tracking'));
    await tester.pumpAndSettle();
    expect(find.text('Review preview').hitTestable(), findsOneWidget);
  });

  testWidgets('toolbar remains accessible while scrolling', (tester) async {
    const may = YearMonth(2026, 5);
    await pumpBudgetScreen(tester,
        service: _FakeBudgetService(
            {may: _summary(month: may, mode: BudgetMode.track)}),
        now: DateTime(2026, 5, 10),
        size: const Size(400, 700),
        accessibleNavigation: true,
        textScale: 1.4);
    await tester.dragFrom(const Offset(100, 300), const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(find.text('Review preview').hitTestable(), findsOneWidget);
  });
}
