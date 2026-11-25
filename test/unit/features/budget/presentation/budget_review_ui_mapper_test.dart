import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:feather_ledger/features/budget/domain/entities/budget_entities.dart';
import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';
import 'package:feather_ledger/features/budget/presentation/mappers/budget_review_ui_mapper.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  const may = YearMonth(2026, 5);

  CategoryBudgetSummary category({
    required String id,
    required String name,
    int? budgetMinor,
    required int committedActualMinor,
    required int discretionaryActualMinor,
    required int pendingMinor,
  }) {
    return CategoryBudgetSummary(
      categoryId: id,
      categoryName: name,
      iconKey: 'utensils',
      colorInt: 0xFFE65100,
      isArchived: false,
      archiveYm: null,
      budgetMinor: budgetMinor,
      hasFutureRulesAfter: false,
      committedActualMinor: committedActualMinor,
      discretionaryActualMinor: discretionaryActualMinor,
      actualMinor: committedActualMinor + discretionaryActualMinor,
      pendingMinor: pendingMinor,
      projectedRemainingMinor: 0,
      lastMonthActualMinor: 0,
      threeMonthAvgMinor: 0,
      committedBaselineMinor: committedActualMinor + pendingMinor,
      isAnomaly: false,
      anomalyDeltaRatio: null,
      riskLevel: BudgetRiskLevel.inBudget,
      sixMonthTrend: const [],
      topTransactions: const [],
      allTransactions: const [],
      reviewNote: null,
    );
  }

  MonthBudgetSummary summary({
    List<CategoryBudgetSummary>? budgeted,
    List<CategoryBudgetSummary> unbudgeted = const [],
    List<BudgetAttributionItem> over = const [],
    List<BudgetAttributionItem> under = const [],
    List<BudgetTrendPoint> trend = const [],
    int totalBudgetMinor = 0,
    bool hasLeftoverPendingInReview = false,
    String? monthReviewNote,
  }) {
    final categories = [...?budgeted, ...unbudgeted];
    return MonthBudgetSummary(
      currencyCode: 'USD',
      month: may,
      mode: BudgetMode.review,
      hasAnyActiveAccount: true,
      totalBudgetMinor: totalBudgetMinor,
      budgetedActualMinor: 0,
      budgetedPendingMinor: 0,
      projectedRemainingMinor: 0,
      budgetedRemainingActualMinor: 0,
      allExpenseActualMinor: 0,
      allExpensePendingMinor: 0,
      unbudgetedActualMinor: 0,
      unbudgetedPendingMinor: 0,
      inBudgetCount: 0,
      budgetedCategoryCount: categories.length,
      complianceRate: 1,
      hasAnyBudget: totalBudgetMinor > 0,
      hasUnbudgetedActivity: unbudgeted.isNotEmpty,
      hasLeftoverPendingInReview: hasLeftoverPendingInReview,
      hasHighFrequencyPending: false,
      isFarFutureMaterializedOnly: false,
      budgetedCategories: budgeted ?? const [],
      unbudgetedActiveCategories: unbudgeted,
      remainingActiveCategories: const [],
      overBudgetTop3: over,
      underBudgetTop3: under,
      unbudgetedAlertsTop3: const [],
      monthTrend6Months: trend,
      monthReviewNote: monthReviewNote,
    );
  }

  const mapper = BudgetReviewUiMapper();

  test(
      'folds committed, discretionary and baseline across every category, '
      'including unbudgeted ones', () {
    final model = mapper.map(
      summary(
        budgeted: [
          category(
            id: 'dining',
            name: 'Dining',
            budgetMinor: 20000,
            committedActualMinor: 40000,
            discretionaryActualMinor: 60000,
            pendingMinor: 0,
          ),
        ],
        unbudgeted: [
          category(
            id: 'medical',
            name: 'Medical',
            committedActualMinor: 0,
            discretionaryActualMinor: 200000,
            pendingMinor: 0,
          ),
        ],
      ),
      currencySymbol: '\$',
      locale: 'en',
    );

    expect(model.month, may);
    expect(model.monthLabel, 'May 2026');
    expect(model.committedActualDisplay, '\$400.00');
    expect(model.discretionaryActualDisplay, '\$2600.00');
    // Review mode zeroes pending, so baseline equals committed actual here.
    expect(model.committedBaselineDisplay, '\$400.00');
  });

  test('keeps domain attribution order and formats deltas without signs', () {
    final model = mapper.map(
      summary(
        over: const [
          BudgetAttributionItem(
            categoryId: 'dining',
            categoryName: 'Dining',
            iconKey: 'utensils',
            colorInt: 0xFFE65100,
            budgetMinor: 20000,
            actualMinor: 32000,
            varianceMinor: -12000,
            shareOfTotalActual: 0.5,
          ),
        ],
        under: const [
          BudgetAttributionItem(
            categoryId: 'transport',
            categoryName: 'Transport',
            iconKey: 'bus',
            colorInt: 0xFF1565C0,
            budgetMinor: 30000,
            actualMinor: 10000,
            varianceMinor: 20000,
            shareOfTotalActual: 0.2,
          ),
        ],
      ),
      currencySymbol: '\$',
      locale: 'en',
    );

    expect(model.overBudgetTop3.single.categoryId, 'dining');
    expect(model.overBudgetTop3.single.deltaDisplay, '\$120.00');
    expect(model.overBudgetTop3.single.isOver, isTrue);
    expect(model.underBudgetTop3.single.categoryId, 'transport');
    expect(model.underBudgetTop3.single.deltaDisplay, '\$200.00');
    expect(model.underBudgetTop3.single.isOver, isFalse);
    expect(model.hasAttribution, isTrue);
  });

  test(
      'maps trend points and exposes the selected month budget line only when '
      'the month is budgeted', () {
    final model = mapper.map(
      summary(
        totalBudgetMinor: 20000,
        trend: const [
          BudgetTrendPoint(
            month: YearMonth(2026, 4),
            budgetMinor: null,
            actualMinor: 24000,
            pendingMinor: 0,
            hasReviewNote: true,
          ),
          BudgetTrendPoint(
            month: may,
            budgetMinor: 20000,
            actualMinor: 24000,
            pendingMinor: 0,
            hasReviewNote: false,
          ),
        ],
      ),
      currencySymbol: '\$',
      locale: 'en',
    );

    expect(model.monthTrend6Months, hasLength(2));
    expect(model.monthTrend6Months.first.shortLabel, 'Apr');
    expect(model.monthTrend6Months.first.budgetMinor, isNull);
    expect(model.monthTrend6Months.first.budgetChartValue, 0);
    expect(model.monthTrend6Months.first.actualChartValue, 240);
    expect(model.monthTrend6Months.first.hasReviewNote, isTrue);
    expect(model.monthTrend6Months.last.shortLabel, 'May');
    // Each month carries its own budget into the chart's ghost column.
    expect(model.monthTrend6Months.last.budgetChartValue, 200);
    expect(model.monthTrend6Months.every((point) => !point.isFuture), isTrue);
  });

  test('months after today are flagged as future', () {
    final model = mapper.map(
      summary(
        trend: const [
          BudgetTrendPoint(
            month: YearMonth(2026, 5),
            budgetMinor: 0,
            actualMinor: 1200,
            pendingMinor: 0,
            hasReviewNote: false,
          ),
          BudgetTrendPoint(
            month: YearMonth(2026, 6),
            budgetMinor: 50000,
            actualMinor: 0,
            pendingMinor: 0,
            hasReviewNote: false,
          ),
        ],
      ),
      currencySymbol: '\$',
      locale: 'en',
      today: DateTime(2026, 5, 10),
    );

    expect(model.monthTrend6Months.map((point) => point.isFuture), [
      false,
      true,
    ]);
  });

  test('no budget means no chart budget columns', () {
    final model = mapper.map(
      summary(totalBudgetMinor: 0),
      currencySymbol: '\$',
      locale: 'en',
    );

    expect(model.monthTrend6Months, isEmpty);
  });

  test('normalizes blank notes to null and carries leftover-pending flag', () {
    expect(
      mapper
          .map(
            summary(monthReviewNote: '  Car repair  '),
            currencySymbol: '\$',
            locale: 'en',
          )
          .monthReviewNote,
      'Car repair',
    );
    expect(
      mapper
          .map(
            summary(monthReviewNote: '   '),
            currencySymbol: '\$',
            locale: 'en',
          )
          .monthReviewNote,
      isNull,
    );
    expect(
      mapper
          .map(
            summary(hasLeftoverPendingInReview: true),
            currencySymbol: '\$',
            locale: 'en',
          )
          .showBaselineRow,
      isTrue,
    );
  });
}
