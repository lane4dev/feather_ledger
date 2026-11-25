import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/budget/domain/entities/budget_entities.dart';
import 'package:feather_ledger/features/budget/domain/services/budget_service.dart';
import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';
import 'package:feather_ledger/features/budget/presentation/screens/budget_screen.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';

/// The clock the budget screen tests run on: May 2026 is the current (track) month, so
/// April is closed and June is still a plan.
final budgetTestToday = DateTime(2026, 5, 10);

const budgetTestApril = YearMonth(2026, 4);
const budgetTestMay = YearMonth(2026, 5);
const budgetTestJune = YearMonth(2026, 6);

/// The hero is the way into L2 for a tracked or closed month; the tap target
/// is an ink overlay on the card.
const budgetOverviewTapKey = ValueKey('budget-overview-tap');
const budgetPlanHintKey = ValueKey('budget-plan-hint');

BudgetMode _modeOf(YearMonth month, [DateTime? now]) {
  final nowYm = YearMonth.fromDate(now ?? budgetTestToday);
  if (month > nowYm) return BudgetMode.plan;
  if (month < nowYm) return BudgetMode.review;
  return BudgetMode.track;
}

class FakeBudgetService implements BudgetService {
  final Map<YearMonth, MonthBudgetSummary> overrides;

  FakeBudgetService({this.overrides = const {}});

  /// Months the PageView pages past get the default fixture for their mode.
  MonthBudgetSummary _summaryFor(YearMonth month) =>
      overrides[month] ?? monthBudgetSummary(month);

  @override
  Stream<MonthBudgetSummary> watchMonthBudget({
    required String currencyCode,
    required YearMonth month,
  }) =>
      Stream.value(_summaryFor(month));

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

CategoryBudgetSummary budgetCategory({
  required String id,
  required String name,
  required YearMonth month,
  int? budgetMinor,
  int actualMinor = 0,
  int pendingMinor = 0,
  int committedMinor = 0,
  int? prevBudgetMinor,
  bool isArchived = false,
  bool isAnomaly = false,
  double? anomalyDeltaRatio,
  BudgetRiskLevel riskLevel = BudgetRiskLevel.inBudget,
}) {
  // The plan hint's carry-forward claim reads this category's own trend: a
  // point for the target month's predecessor holding the same limit means the
  // rule carried over unchanged.
  final prevBudget = prevBudgetMinor ?? budgetMinor;
  return CategoryBudgetSummary(
    categoryId: id,
    categoryName: name,
    iconKey: 'utensils',
    colorInt: 0xFFE65100,
    isArchived: isArchived,
    archiveYm: isArchived ? month.addMonths(-1) : null,
    budgetMinor: budgetMinor,
    hasFutureRulesAfter: false,
    committedActualMinor: committedMinor,
    discretionaryActualMinor: actualMinor - committedMinor,
    actualMinor: actualMinor,
    pendingMinor: pendingMinor,
    projectedRemainingMinor: budgetMinor != null
        ? budgetMinor - actualMinor - pendingMinor
        : null,
    lastMonthActualMinor: 50000,
    threeMonthAvgMinor: 60000,
    committedBaselineMinor: committedMinor,
    isAnomaly: isAnomaly,
    anomalyDeltaRatio: anomalyDeltaRatio,
    riskLevel: riskLevel,
    sixMonthTrend: [
      for (var back = 5; back >= 0; back--)
        BudgetTrendPoint(
          month: month.addMonths(-back),
          budgetMinor: back == 1 ? prevBudget : budgetMinor,
          actualMinor: actualMinor,
          pendingMinor: 0,
          hasReviewNote: false,
        ),
    ],
    topTransactions: const [],
    reviewNote: null,
  );
}

/// Four normally-named budgeted categories, one unbudgeted spend and one
/// untouched category, with totals derived from the rows so the fixtures can
/// never disagree with the numbers the page shows.
MonthBudgetSummary monthBudgetSummary(
  YearMonth month, {
  bool hasAnyActiveAccount = true,
  List<CategoryBudgetSummary>? budgeted,
  List<CategoryBudgetSummary>? unbudgeted,
  List<CategoryBudgetSummary>? remaining,
  List<BudgetAttributionItem> overBudget = const [],
  List<BudgetAttributionItem> underBudget = const [],
  String? note,
  bool hasHighFrequencyPending = false,
  DateTime? now,
}) {
  final resolvedMode = _modeOf(month, now);
  final closed = resolvedMode == BudgetMode.review;
  final budgetedRows = budgeted ??
      [
        budgetCategory(
          id: 'dining',
          name: 'Dining',
          month: month,
          budgetMinor: 100000,
          actualMinor: 40000,
          pendingMinor: closed ? 0 : 10000,
        ),
        budgetCategory(
          id: 'groceries',
          name: 'Groceries',
          month: month,
          budgetMinor: 50000,
          actualMinor: 20000,
        ),
        budgetCategory(
          id: 'transport',
          name: 'Transport',
          month: month,
          budgetMinor: 30000,
          actualMinor: 30000,
        ),
        budgetCategory(
          id: 'housing',
          name: 'Housing',
          month: month,
          budgetMinor: 200000,
          actualMinor: 200000,
        ),
      ];
  final unbudgetedRows = unbudgeted ??
      [
        budgetCategory(id: 'travel', name: 'Travel', month: month, actualMinor: 25000),
      ];
  final remainingRows = remaining ??
      [budgetCategory(id: 'utils', name: 'Utilities', month: month)];

  int total(Iterable<int> values) => values.fold(0, (a, b) => a + b);
  int actualOf(List<CategoryBudgetSummary> rows) =>
      total(rows.map((c) => c.actualMinor));
  int pendingOf(List<CategoryBudgetSummary> rows) =>
      total(rows.map((c) => c.pendingMinor));

  final totalBudget =
      total(budgetedRows.map((c) => c.budgetMinor).whereType<int>());
  final budgetedActual = actualOf(budgetedRows);
  final budgetedPending = pendingOf(budgetedRows);
  final unbudgetedActual = actualOf(unbudgetedRows);
  final unbudgetedPending = pendingOf(unbudgetedRows);
  final budgetedCount =
      budgetedRows.where((c) => c.budgetMinor != null).length;
  final inBudget = budgetedRows
      .where((c) =>
          c.budgetMinor != null &&
          c.actualMinor + c.pendingMinor <= c.budgetMinor!)
      .length;
  final allActual = budgetedActual + unbudgetedActual;

  return MonthBudgetSummary(
    currencyCode: 'USD',
    month: month,
    mode: resolvedMode,
    hasAnyActiveAccount: hasAnyActiveAccount,
    totalBudgetMinor: totalBudget,
    budgetedActualMinor: budgetedActual,
    budgetedPendingMinor: budgetedPending,
    projectedRemainingMinor: totalBudget - budgetedActual - budgetedPending,
    budgetedRemainingActualMinor: totalBudget - budgetedActual,
    allExpenseActualMinor: allActual,
    allExpensePendingMinor: budgetedPending + unbudgetedPending,
    unbudgetedActualMinor: unbudgetedActual,
    unbudgetedPendingMinor: unbudgetedPending,
    inBudgetCount: inBudget,
    budgetedCategoryCount: budgetedCount,
    complianceRate: budgetedCount == 0 ? 0 : inBudget / budgetedCount,
    hasAnyBudget: budgetedCount > 0,
    hasUnbudgetedActivity: unbudgetedActual + unbudgetedPending > 0,
    hasLeftoverPendingInReview: closed && budgetedPending > 0,
    hasHighFrequencyPending: hasHighFrequencyPending,
    isFarFutureMaterializedOnly: false,
    budgetedCategories: budgetedRows,
    unbudgetedActiveCategories: unbudgetedRows,
    remainingActiveCategories: remainingRows,
    overBudgetTop3: overBudget,
    underBudgetTop3: underBudget,
    unbudgetedAlertsTop3: [
      if (unbudgetedActual + unbudgetedPending > 0)
        UnbudgetedSpendAlert(
          categoryId: 'travel',
          categoryName: 'Travel',
          iconKey: 'utensils',
          colorInt: 0xFFE65100,
          actualMinor: unbudgetedActual,
          pendingMinor: unbudgetedPending,
          shareOfTotalActual:
              allActual == 0 ? 0 : unbudgetedActual / allActual,
        ),
    ],
    monthTrend6Months: [
      for (var back = 5; back >= 0; back--)
        BudgetTrendPoint(
          month: month.addMonths(-back),
          budgetMinor: totalBudget,
          actualMinor: allActual,
          pendingMinor: 0,
          hasReviewNote: false,
        ),
    ],
    monthReviewNote: note,
  );
}

BudgetAttributionItem budgetAttribution({
  required String id,
  required String name,
  required int varianceMinor,
}) =>
    BudgetAttributionItem(
      categoryId: id,
      categoryName: name,
      iconKey: 'utensils',
      colorInt: 0xFFE65100,
      budgetMinor: 100000,
      actualMinor: 100000 + varianceMinor,
      varianceMinor: varianceMinor,
      shareOfTotalActual: 0.5,
    );

Future<void> pumpBudgetScreen(
  WidgetTester tester, {
  required FakeBudgetService service,
  Size size = const Size(400, 700),
  ThemeData? theme,
  double textScale = 1,
  DateTime? now,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        budgetClockProvider.overrideWithValue(FixedClock(now ?? budgetTestToday)),
        budgetServiceProvider.overrideWithValue(service),
        ledgerCurrencyProvider.overrideWithValue('USD'),
        displayCurrencySymbolProvider.overrideWithValue('\$'),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        locale: locale,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
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
        supportedLocales: const [
          Locale('en'),
          Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
          Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        ],
        home: const BudgetScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
