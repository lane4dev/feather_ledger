import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:feather_ledger/features/budget/domain/entities/budget_entities.dart';
import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';
import 'package:feather_ledger/features/budget/presentation/mappers/budget_ui_mapper.dart';
import 'package:feather_ledger/features/budget/presentation/models/budget_ui_models.dart';

void main() {
  group('BudgetUiMapper', () {
    setUpAll(() async {
      await initializeDateFormatting('en');
    });

    test('formats overview, category rows, compliance, and 6-mo chart points',
        () {
      final summary = MonthBudgetSummary(
        currencyCode: 'CNY',
        month: const YearMonth(2026, 5),
        mode: BudgetMode.track,
        hasAnyActiveAccount: true,
        totalBudgetMinor: 300000,
        budgetedActualMinor: 120000,
        budgetedPendingMinor: 60000,
        projectedRemainingMinor: 120000,
        budgetedRemainingActualMinor: 180000,
        allExpenseActualMinor: 170000,
        allExpensePendingMinor: 60000,
        unbudgetedActualMinor: 50000,
        unbudgetedPendingMinor: 0,
        inBudgetCount: 1,
        budgetedCategoryCount: 1,
        complianceRate: 1.0,
        hasAnyBudget: true,
        hasUnbudgetedActivity: true,
        hasLeftoverPendingInReview: false,
        hasHighFrequencyPending: true,
        isFarFutureMaterializedOnly: false,
        budgetedCategories: [
          CategoryBudgetSummary(
            categoryId: 'dining',
            categoryName: 'Dining',
            iconKey: 'utensils',
            colorInt: 0xFFE65100,
            isArchived: false,
            archiveYm: null,
            budgetMinor: 300000,
            hasFutureRulesAfter: false,
            committedActualMinor: 20000,
            discretionaryActualMinor: 100000,
            actualMinor: 120000,
            pendingMinor: 60000,
            projectedRemainingMinor: 120000,
            lastMonthActualMinor: 110000,
            threeMonthAvgMinor: 90000,
            committedBaselineMinor: 80000,
            isAnomaly: true,
            anomalyDeltaRatio: 0.333,
            riskLevel: BudgetRiskLevel.inBudget,
            sixMonthTrend: [
              const BudgetTrendPoint(
                month: YearMonth(2026, 5),
                budgetMinor: 300000,
                actualMinor: 120000,
                pendingMinor: 60000,
                hasReviewNote: true,
              ),
            ],
            topTransactions: [
              BudgetContributionTx(
                transactionId: 'tx-1',
                sourceScheduledBillId: null,
                scheduledBillId: null,
                description: 'Lunch',
                occurredAt: DateTime(2026, 5, 10),
                amountMinor: 1000,
                isPending: false,
                accountName: 'Cash',
              ),
            ],
            reviewNote: 'Eating out',
          ),
        ],
        unbudgetedActiveCategories: [],
        remainingActiveCategories: [],
        overBudgetTop3: [],
        underBudgetTop3: [],
        unbudgetedAlertsTop3: [
          const UnbudgetedSpendAlert(
            categoryId: 'travel',
            categoryName: 'Travel',
            iconKey: 'plane',
            colorInt: 0xFF1E88E5,
            actualMinor: 50000,
            pendingMinor: 0,
            shareOfTotalActual: 0.294,
          ),
        ],
        monthTrend6Months: [],
        monthReviewNote: null,
      );

      final ui = const BudgetUiMapper().mapScreen(
        summary,
        currencySymbol: '¥',
        locale: 'en',
      );

      expect(ui.overview.totalBudgetDisplay, '¥3000.00');
      expect(ui.overview.budgetedActualDisplay, '¥1200.00');
      expect(ui.overview.budgetedPendingDisplay, '¥600.00');
      expect(ui.overview.projectedRemainingDisplay, '¥1200.00');
      expect(ui.overview.complianceDisplay, '1/1');
      expect(ui.overview.actualRatio, closeTo(0.4, 0.001));
      expect(ui.overview.pendingRatio, closeTo(0.2, 0.001));
      expect(ui.overview.hasUnbudgetedSpend, isTrue);
      expect(ui.overview.hasHighFrequencyMaterializationHint, isTrue);

      final row = ui.budgetedRows.single;
      expect(row.budgetDisplay, '¥3000.00');
      expect(row.varianceDisplay, '¥1800.00');
      expect(row.isOverBudget, isFalse);
      expect(row.anomalyPercent, 33);
      expect(row.trend6Months.single.hasReviewNote, isTrue);
      expect(row.trend6Months.single.budgetChartValue, 3000.0);
      expect(row.trend6Months.single.actualChartValue, 1200.0);
      expect(row.topContributions.single.amountDisplay, '-¥10.00');
      expect(ui.unbudgetedAlertsTop3.single.shareDisplay, '29%');
    });
  });

  // The three modes read the same budget, so the tests below are written
  // against the spec's locked examples: ¥200 budget, ¥40 actually spent, ¥30
  // billed and unposted.
  group('BudgetUiMapper overview — track', () {
    test('reports what is left after spend and pending bills', () {
      final overview = _track().overview;

      expect(overview.mainLabel, BudgetOverviewMainLabel.projectedRemaining);
      expect(overview.mainAmount.symbol, '¥');
      expect(overview.mainAmount.whole, '130');
      expect(overview.mainAmount.fraction, '.00');
      expect(overview.isMainAmountNegative, isFalse);
      expect(
        overview.footerMetrics.map((m) => m.metric),
        [
          BudgetOverviewMetric.spent,
          BudgetOverviewMetric.pending,
          BudgetOverviewMetric.totalBudget,
        ],
      );
      expect(
        overview.footerMetrics.map((m) => m.value),
        ['¥40.00', '¥30.00', '¥200.00'],
      );
      expect(
        overview.footerMetrics[1].tone,
        BudgetOverviewMetricTone.pending,
      );
      expect(overview.actualRatio, closeTo(0.2, 1e-9));
      expect(overview.pendingRatio, closeTo(0.15, 1e-9));
    });

    test('spending without a budget does not move any number on the card', () {
      final without = _track(unbudgetedActualMinor: 0).overview;
      final with_ = _track(unbudgetedActualMinor: 20000).overview;

      expect(with_.mainAmount.whole, without.mainAmount.whole);
      expect(with_.actualRatio, without.actualRatio);
      expect(with_.pendingRatio, without.pendingRatio);
      expect(
        with_.footerMetrics.map((m) => m.value),
        without.footerMetrics.map((m) => m.value),
      );
    });

    test('an overrun shows its real size, not a clamped one', () {
      final overview = _track(
        budgetedActualMinor: 25000,
        budgetedPendingMinor: 0,
        projectedRemainingMinor: -5000,
      ).overview;

      expect(overview.mainLabel, BudgetOverviewMainLabel.projectedOver);
      expect(overview.mainAmount.sign, '-');
      expect(overview.mainAmount.whole, '50');
      expect(overview.isMainAmountNegative, isTrue);
      // The bar is capped, the number is not.
      expect(overview.actualRatio, 1.0);
    });
  });

  group('BudgetUiMapper overview — review', () {
    test('reports the month\'s surplus and no pending column', () {
      final overview = _review().overview;

      expect(overview.mainLabel, BudgetOverviewMainLabel.monthlySurplus);
      expect(overview.mainAmount.whole, '160');
      expect(overview.mainAmount.fraction, '.00');
      expect(
        overview.footerMetrics.map((m) => m.metric),
        [
          BudgetOverviewMetric.spent,
          BudgetOverviewMetric.budgetUsage,
          BudgetOverviewMetric.totalBudget,
        ],
      );
      expect(
        overview.footerMetrics.map((m) => m.value),
        ['¥40.00', '20%', '¥200.00'],
      );
      expect(overview.pendingRatio, 0);
    });

    test('an overspent month reports the overspend', () {
      final overview = _review(budgetedActualMinor: 25000).overview;

      expect(overview.mainLabel, BudgetOverviewMainLabel.monthlyOverspend);
      expect(overview.mainAmount.sign, '-');
      expect(overview.mainAmount.whole, '50');
      expect(overview.isMainAmountNegative, isTrue);
      // Usage is deliberately uncapped: 150% says what happened.
      expect(overview.footerMetrics[1].value, '125%');
    });
  });

  group('BudgetUiMapper overview — plan', () {
    test('counts only the baseline inside budgeted categories', () {
      final overview = _plan().overview;

      expect(overview.mainLabel, BudgetOverviewMainLabel.availableToSpend);
      expect(overview.mainAmount.whole, '140');
      expect(overview.mainAmount.fraction, '.00');
      expect(overview.isMainAmountNegative, isFalse);
      expect(overview.hasFixedBaseline, isTrue);
      expect(overview.fixedBaselineRatio, closeTo(0.3, 1e-9));
      expect(
        overview.footerMetrics.map((m) => m.metric),
        [
          BudgetOverviewMetric.committedBaseline,
          BudgetOverviewMetric.baselineShare,
          BudgetOverviewMetric.totalBudget,
        ],
      );
      // ¥60 budgeted + ¥20 unbudgeted baseline: only the first is in the plan.
      expect(
        overview.footerMetrics.map((m) => m.value),
        ['¥60.00', '30%', '¥200.00'],
      );
    });

    test('a baseline larger than the budget shows the real gap', () {
      final overview = _plan(budgetedBaselineMinor: 25000).overview;

      expect(overview.mainLabel, BudgetOverviewMainLabel.availableToSpend);
      expect(overview.mainAmount.sign, '-');
      expect(overview.mainAmount.whole, '50');
      expect(overview.isMainAmountNegative, isTrue);
      expect(overview.fixedBaselineRatio, 1.0);
    });
  });

  group('BudgetUiMapper overview — edges', () {
    test('no budget anywhere prints a dash instead of a number', () {
      final overview = _map(
        _summary(
          mode: BudgetMode.track,
          totalBudgetMinor: 0,
          hasAnyBudget: false,
          budgetedCategories: const [],
          unbudgetedActiveCategories: const [],
        ),
      ).overview;

      expect(overview.mainAmount.isNumeric, isFalse);
      expect(overview.mainAmount.whole, '—');
      expect(overview.isMainAmountNegative, isFalse);
      expect(overview.footerMetrics[2].value, '—');
      expect(overview.actualRatio, 0);
      expect(overview.pendingRatio, 0);
    });

    test('zero budget never divides by it', () {
      final overview =
          _review(totalBudgetMinor: 0, budgetedCategories: const []).overview;

      expect(overview.actualRatio, 0);
      expect(overview.footerMetrics[1].value, '—');
      // A budget of zero is still a budget: only the ratio has no answer.
      expect(overview.footerMetrics[2].value, '¥0.00');
    });

    test('the today tick only exists for the month that is running', () {
      final may = _track(today: DateTime(2026, 5, 16)).overview;
      expect(may.todayTickRatio, closeTo(16 / 31, 1e-9));

      final june = _track(today: DateTime(2026, 6, 1)).overview;
      expect(june.todayTickRatio, isNull);

      final unknown = _track().overview;
      expect(unknown.todayTickRatio, isNull);
    });
  });
}

BudgetScreenUiModel _map(MonthBudgetSummary summary, {DateTime? today}) =>
    const BudgetUiMapper().mapScreen(
      summary,
      currencySymbol: '¥',
      locale: 'en',
      today: today,
    );

/// ¥200 budget, ¥40 spent, ¥30 billed and unposted, ¥200 spent outside the
/// budget.
BudgetScreenUiModel _track({
  int totalBudgetMinor = 20000,
  int budgetedActualMinor = 4000,
  int budgetedPendingMinor = 3000,
  int projectedRemainingMinor = 13000,
  int unbudgetedActualMinor = 20000,
  DateTime? today,
}) {
  return _map(
    _summary(
      mode: BudgetMode.track,
      totalBudgetMinor: totalBudgetMinor,
      budgetedActualMinor: budgetedActualMinor,
      budgetedPendingMinor: budgetedPendingMinor,
      projectedRemainingMinor: projectedRemainingMinor,
      budgetedRemainingActualMinor: budgetedActualMinor,
      unbudgetedActualMinor: unbudgetedActualMinor,
    ),
    today: today,
  );
}

BudgetScreenUiModel _review({
  int totalBudgetMinor = 20000,
  int budgetedActualMinor = 4000,
  List<CategoryBudgetSummary>? budgetedCategories,
}) {
  return _map(
    _summary(
      mode: BudgetMode.review,
      totalBudgetMinor: totalBudgetMinor,
      budgetedActualMinor: budgetedActualMinor,
      budgetedPendingMinor: 0,
      projectedRemainingMinor: budgetedActualMinor,
      budgetedRemainingActualMinor: totalBudgetMinor - budgetedActualMinor,
      budgetedCategories: budgetedCategories ?? [_cat()],
    ),
  );
}

/// ¥200 budget, ¥60 of it committed inside budgeted categories and ¥20 more
/// committed in a category that has no budget.
BudgetScreenUiModel _plan({
  int totalBudgetMinor = 20000,
  int budgetedBaselineMinor = 6000,
  int unbudgetedBaselineMinor = 2000,
}) {
  return _map(
    _summary(
      mode: BudgetMode.plan,
      totalBudgetMinor: totalBudgetMinor,
      budgetedActualMinor: 0,
      budgetedPendingMinor: 0,
      projectedRemainingMinor: totalBudgetMinor,
      budgetedRemainingActualMinor: totalBudgetMinor,
      budgetedCategories: [
        _cat(committedBaselineMinor: budgetedBaselineMinor),
      ],
      unbudgetedActiveCategories: [
        _cat(
          categoryId: 'travel',
          committedBaselineMinor: unbudgetedBaselineMinor,
          budgetMinor: null,
        ),
      ],
    ),
  );
}

MonthBudgetSummary _summary({
  required BudgetMode mode,
  int totalBudgetMinor = 20000,
  int budgetedActualMinor = 4000,
  int budgetedPendingMinor = 3000,
  int projectedRemainingMinor = 13000,
  int budgetedRemainingActualMinor = 16000,
  int unbudgetedActualMinor = 0,
  bool hasAnyBudget = true,
  List<CategoryBudgetSummary>? budgetedCategories,
  List<CategoryBudgetSummary> unbudgetedActiveCategories = const [],
}) {
  final actual = budgetedActualMinor;
  return MonthBudgetSummary(
    currencyCode: 'CNY',
    month: const YearMonth(2026, 5),
    mode: mode,
    hasAnyActiveAccount: true,
    totalBudgetMinor: totalBudgetMinor,
    budgetedActualMinor: actual,
    budgetedPendingMinor: budgetedPendingMinor,
    projectedRemainingMinor: projectedRemainingMinor,
    budgetedRemainingActualMinor: budgetedRemainingActualMinor,
    allExpenseActualMinor: actual + unbudgetedActualMinor,
    allExpensePendingMinor: budgetedPendingMinor,
    unbudgetedActualMinor: unbudgetedActualMinor,
    unbudgetedPendingMinor: 0,
    inBudgetCount: 1,
    budgetedCategoryCount: 1,
    complianceRate: 1.0,
    hasAnyBudget: hasAnyBudget,
    hasUnbudgetedActivity: unbudgetedActualMinor > 0,
    hasLeftoverPendingInReview: mode == BudgetMode.review,
    hasHighFrequencyPending: false,
    isFarFutureMaterializedOnly: mode == BudgetMode.plan,
    budgetedCategories: budgetedCategories ?? [_cat()],
    unbudgetedActiveCategories: unbudgetedActiveCategories,
    remainingActiveCategories: const [],
    overBudgetTop3: const [],
    underBudgetTop3: const [],
    unbudgetedAlertsTop3: const [],
    monthTrend6Months: const [],
    monthReviewNote: null,
  );
}

CategoryBudgetSummary _cat({
  String categoryId = 'dining',
  int? budgetMinor = 20000,
  int actualMinor = 4000,
  int pendingMinor = 0,
  int committedBaselineMinor = 0,
}) {
  return CategoryBudgetSummary(
    categoryId: categoryId,
    categoryName: 'Dining',
    iconKey: 'utensils',
    colorInt: 0xFFE65100,
    isArchived: false,
    archiveYm: null,
    budgetMinor: budgetMinor,
    hasFutureRulesAfter: false,
    committedActualMinor: actualMinor,
    discretionaryActualMinor: 0,
    actualMinor: actualMinor,
    pendingMinor: pendingMinor,
    projectedRemainingMinor: budgetMinor == null ? null : 10000,
    lastMonthActualMinor: 0,
    threeMonthAvgMinor: 0,
    committedBaselineMinor: committedBaselineMinor,
    isAnomaly: false,
    anomalyDeltaRatio: null,
    riskLevel: BudgetRiskLevel.inBudget,
    sixMonthTrend: const [],
    topTransactions: const [],
    reviewNote: null,
  );
}
