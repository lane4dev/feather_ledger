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

  group('BudgetUiMapper category rows — track', () {
    test('pending that carries a category over is named before it happens', () {
      final row = _map(
        _summary(
          mode: BudgetMode.track,
          budgetedActualMinor: 18000,
          budgetedPendingMinor: 4000,
          budgetedCategories: [
            _cat(actualMinor: 18000, pendingMinor: 4000),
          ],
        ),
      ).budgetedRows.single;

      expect(row.mode, BudgetMode.track);
      expect(row.amountLabel, BudgetCategoryAmountLabel.projectedOver);
      expect(row.mainAmountDisplay, '¥20.00');
      expect(row.isMainAmountNegative, isTrue);
      expect(row.subtitleKind, BudgetCategorySubtitle.pendingIncluded);
      expect(row.subtitleAmountDisplay, '¥40.00');
      expect(row.secondaryAmountDisplay, '¥180.00 / ¥200.00');
      expect(row.actualProgress, closeTo(0.9, 1e-9));
      // The segments never exceed the track: 90% + 20% would overflow it.
      expect(row.pendingProgress, closeTo(0.1, 1e-9));
    });

    test('money already spent over the limit reports the overrun', () {
      final row = _map(
        _summary(
          mode: BudgetMode.track,
          budgetedActualMinor: 22000,
          budgetedPendingMinor: 0,
          budgetedCategories: [_cat(actualMinor: 22000)],
        ),
      ).budgetedRows.single;

      expect(row.amountLabel, BudgetCategoryAmountLabel.over);
      expect(row.mainAmountDisplay, '¥20.00');
      expect(row.isMainAmountNegative, isTrue);
      expect(row.subtitleKind, BudgetCategorySubtitle.usage);
      expect(row.subtitlePercentDisplay, '110%');
      expect(row.actualProgress, 1);
      expect(row.pendingProgress, 0);
    });

    test('a category inside its limit reports what is left after pending', () {
      final row = _map(
        _summary(
          mode: BudgetMode.track,
          budgetedActualMinor: 4000,
          budgetedPendingMinor: 3000,
          budgetedCategories: [_cat(actualMinor: 4000, pendingMinor: 3000)],
        ),
      ).budgetedRows.single;

      expect(row.amountLabel, BudgetCategoryAmountLabel.remaining);
      expect(row.mainAmountDisplay, '¥130.00');
      expect(row.isMainAmountNegative, isFalse);
      expect(row.subtitleKind, BudgetCategorySubtitle.pendingIncluded);
      expect(row.subtitleAmountDisplay, '¥30.00');
    });

    test('a category with nothing billed reads as a share of its limit', () {
      final row = _map(
        _summary(
          mode: BudgetMode.track,
          budgetedActualMinor: 4000,
          budgetedPendingMinor: 0,
        ),
      ).budgetedRows.single;

      expect(row.subtitleKind, BudgetCategorySubtitle.usage);
      expect(row.subtitlePercentDisplay, '20%');
      expect(row.subtitleAmountDisplay, isNull);
    });
  });

  group('BudgetUiMapper category rows — review', () {
    test('a closed month reports what it did not spend', () {
      final row = _map(
        _summary(
          mode: BudgetMode.review,
          budgetedActualMinor: 4000,
          budgetedPendingMinor: 0,
        ),
      ).budgetedRows.single;

      expect(row.mode, BudgetMode.review);
      expect(row.amountLabel, BudgetCategoryAmountLabel.reviewRemaining);
      expect(row.mainAmountDisplay, '¥160.00');
      expect(row.isMainAmountNegative, isFalse);
      expect(row.subtitleKind, BudgetCategorySubtitle.usage);
      expect(row.subtitlePercentDisplay, '20%');
      expect(row.secondaryAmountDisplay, '¥40.00 / ¥200.00');
    });

    test('a closed month over its limit reports the overrun', () {
      final row = _map(
        _summary(
          mode: BudgetMode.review,
          budgetedActualMinor: 22000,
          budgetedPendingMinor: 0,
          budgetedCategories: [_cat(actualMinor: 22000)],
        ),
      ).budgetedRows.single;

      expect(row.amountLabel, BudgetCategoryAmountLabel.reviewOver);
      expect(row.mainAmountDisplay, '¥20.00');
      expect(row.isMainAmountNegative, isTrue);
      expect(row.subtitlePercentDisplay, '110%');
    });

    test('a closed month never carries a pending amount into the row', () {
      final row = _map(
        _summary(
          mode: BudgetMode.review,
          budgetedActualMinor: 4000,
          budgetedPendingMinor: 3000,
          budgetedCategories: [_cat(actualMinor: 4000, pendingMinor: 3000)],
        ),
      ).budgetedRows.single;

      expect(row.subtitleKind, BudgetCategorySubtitle.usage);
      expect(row.pendingProgress, 0);
      expect(row.subtitleAmountDisplay, isNull);
    });
  });

  group('BudgetUiMapper category rows — plan', () {
    test('a plan row leads with its limit and its fixed baseline', () {
      final row = _map(
        _summary(
          mode: BudgetMode.plan,
          budgetedActualMinor: 0,
          budgetedPendingMinor: 0,
          budgetedCategories: [
            _cat(
              actualMinor: 0,
              committedBaselineMinor: 6000,
              threeMonthAvgMinor: 9000,
            ),
          ],
        ),
      ).budgetedRows.single;

      expect(row.mode, BudgetMode.plan);
      expect(row.amountLabel, BudgetCategoryAmountLabel.planBudget);
      expect(row.mainAmountDisplay, '¥200.00');
      expect(row.secondaryAmountDisplay, isNull);
      expect(row.subtitleKind, BudgetCategorySubtitle.baseline);
      expect(row.subtitleAmountDisplay, '¥60.00');
      expect(row.subtitleReferenceDisplay, '¥90.00');
      expect(row.baselineProgress, closeTo(0.3, 1e-9));
    });

    test('an average of zero is not worth showing', () {
      final row = _map(
        _summary(
          mode: BudgetMode.plan,
          budgetedActualMinor: 0,
          budgetedPendingMinor: 0,
          budgetedCategories: [
            _cat(actualMinor: 0, committedBaselineMinor: 0),
          ],
        ),
      ).budgetedRows.single;

      expect(row.subtitleReferenceDisplay, isNull);
      expect(row.baselineProgress, 0);
    });
  });

  group('BudgetUiMapper category rows — unbudgeted group', () {
    test('a row without a limit shows its own spend and its share', () {
      final screen = _map(
        _summary(
          mode: BudgetMode.track,
          budgetedActualMinor: 0,
          budgetedPendingMinor: 0,
          budgetedCategories: const [],
          unbudgetedActualMinor: 100000,
          unbudgetedActiveCategories: [
            _cat(budgetMinor: null, actualMinor: 6000, categoryName: 'Hobby'),
            _cat(
              categoryId: 'fuel',
              categoryName: 'Fuel',
              budgetMinor: null,
              actualMinor: 4000,
            ),
          ],
        ),
      );
      final hobby = screen.unbudgetedActiveRows.first;

      expect(hobby.amountLabel, BudgetCategoryAmountLabel.none);
      expect(hobby.mainAmountDisplay, '¥60.00');
      expect(hobby.secondaryAmountDisplay, isNull);
      expect(hobby.sharePercentDisplay, '6%');
      expect(hobby.subtitleKind, BudgetCategorySubtitle.none);
      expect(hobby.unbudgetedGroup, isNotNull);
      expect(hobby.unbudgetedGroup!.isPendingOnly, isFalse);
      // The header sums the rows it heads, not the screen's own totals.
      expect(hobby.unbudgetedGroup!.amountDisplay, '¥100.00');
      // 4% of the month is not worth a sentence.
      expect(screen.unbudgetedActiveRows.last.sharePercentDisplay, isNull);
    });

    test('the share survives rounding at the five percent gate', () {
      BudgetCategoryRowUiModel atGate(int actualMinor) {
        return _map(
          _summary(
            mode: BudgetMode.track,
            budgetedActualMinor: 0,
            budgetedPendingMinor: 0,
            budgetedCategories: const [],
            unbudgetedActualMinor: 100000,
            unbudgetedActiveCategories: [
              _cat(budgetMinor: null, actualMinor: actualMinor),
            ],
          ),
        ).unbudgetedActiveRows.single;
      }

      expect(atGate(5000).sharePercentDisplay, '5%');
      expect(atGate(4999).sharePercentDisplay, isNull);
    });

    test('the share is not capped at the first three rows', () {
      final rows = _map(
        _summary(
          mode: BudgetMode.track,
          budgetedActualMinor: 0,
          budgetedPendingMinor: 0,
          budgetedCategories: const [],
          unbudgetedActualMinor: 50000,
          unbudgetedActiveCategories: [
            for (var i = 0; i < 5; i++)
              _cat(
                categoryId: 'cat$i',
                categoryName: 'Category $i',
                budgetMinor: null,
                actualMinor: 10000,
              ),
          ],
        ),
      ).unbudgetedActiveRows;

      expect(rows, hasLength(5));
      expect(
        rows.map((r) => r.sharePercentDisplay),
        everyElement('20%'),
      );
    });

    test('a pending-only group says pending in its header', () {
      final rows = _map(
        _summary(
          mode: BudgetMode.track,
          budgetedActualMinor: 0,
          budgetedPendingMinor: 6000,
          budgetedCategories: const [],
          unbudgetedActiveCategories: [
            _cat(budgetMinor: null, actualMinor: 0, pendingMinor: 6000),
          ],
        ),
      ).unbudgetedActiveRows;

      expect(rows.single.unbudgetedGroup!.isPendingOnly, isTrue);
      expect(rows.single.unbudgetedGroup!.amountDisplay, '¥60.00');
      expect(rows.single.mainAmountDisplay, '¥60.00');
      expect(rows.single.subtitleKind, BudgetCategorySubtitle.pending);
      expect(rows.single.subtitleAmountDisplay, '¥60.00');
      expect(rows.single.sharePercentDisplay, isNull);
    });

    test('a mixed group is headed by its spend and still names each pending', () {
      final rows = _map(
        _summary(
          mode: BudgetMode.track,
          budgetedActualMinor: 0,
          budgetedPendingMinor: 500,
          budgetedCategories: const [],
          unbudgetedActualMinor: 10000,
          unbudgetedActiveCategories: [
            _cat(budgetMinor: null, actualMinor: 1000, pendingMinor: 500),
          ],
        ),
      ).unbudgetedActiveRows;

      expect(rows.single.unbudgetedGroup!.isPendingOnly, isFalse);
      expect(rows.single.unbudgetedGroup!.amountDisplay, '¥10.00');
      expect(rows.single.mainAmountDisplay, '¥10.00');
      expect(rows.single.subtitleKind, BudgetCategorySubtitle.pending);
      expect(rows.single.subtitleAmountDisplay, '¥5.00');
      expect(rows.single.sharePercentDisplay, '10%');
    });

    test('no month spending means no share to state', () {
      final row = _plan(budgetedBaselineMinor: 0).unbudgetedActiveRows.single;

      expect(row.sharePercentDisplay, isNull);
    });

    test('only the unbudgeted group carries a header model', () {
      final screen = _map(
        _summary(
          mode: BudgetMode.track,
          unbudgetedActiveCategories: [
            _cat(categoryId: 'hobby', budgetMinor: null),
          ],
        ),
      );

      expect(screen.budgetedRows.single.unbudgetedGroup, isNull);
      expect(screen.unbudgetedActiveRows.single.unbudgetedGroup, isNotNull);
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
  String categoryName = 'Dining',
  int? budgetMinor = 20000,
  int actualMinor = 4000,
  int pendingMinor = 0,
  int committedBaselineMinor = 0,
  int threeMonthAvgMinor = 0,
  bool isAnomaly = false,
}) {
  return CategoryBudgetSummary(
    categoryId: categoryId,
    categoryName: categoryName,
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
    threeMonthAvgMinor: threeMonthAvgMinor,
    committedBaselineMinor: committedBaselineMinor,
    isAnomaly: isAnomaly,
    anomalyDeltaRatio: null,
    riskLevel: BudgetRiskLevel.inBudget,
    sixMonthTrend: const [],
    topTransactions: const [],
    reviewNote: null,
  );
}
