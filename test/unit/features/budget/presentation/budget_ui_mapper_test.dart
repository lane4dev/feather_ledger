import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:feather_ledger/features/budget/domain/entities/budget_entities.dart';
import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';
import 'package:feather_ledger/features/budget/presentation/mappers/budget_ui_mapper.dart';

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
}
