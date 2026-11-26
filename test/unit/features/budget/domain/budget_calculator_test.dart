import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/budget_dao.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/budget/domain/services/budget_calculator.dart';
import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';

void main() {
  CategoryViewRow makeCategory({
    required String id,
    String? name,
    bool archived = false,
    DateTime? archivedAt,
  }) {
    return CategoryViewRow(
      id: id,
      name: name ?? id,
      iconKey: 'utensils',
      colorInt: 0xFFE65100,
      type: CategoryType.expense,
      systemCode: null,
      archived: archived,
      archivedAt: archivedAt,
      lastUpdatedEventId: 1,
      projectionVersion: 8,
    );
  }

  BudgetRuleRow makeRule({
    required String categoryId,
    required int effectiveYm,
    required int? amountMinor,
  }) {
    return BudgetRuleRow(
      currencyCode: 'CNY',
      categoryId: categoryId,
      effectiveYm: effectiveYm,
      amountMinor: amountMinor,
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  BudgetExpensePostingRaw makeTx({
    required String id,
    required String categoryId,
    required DateTime occurredAt,
    required int amountMinor,
    String? sourceScheduledBillId,
  }) {
    return BudgetExpensePostingRaw(
      transactionId: id,
      categoryId: categoryId,
      description: 'Tx $id',
      occurredAt: occurredAt,
      ym: occurredAt.year * 100 + occurredAt.month,
      amountMinor: amountMinor,
      sourceScheduledBillId: sourceScheduledBillId,
      categorySnapshotName: null,
      categorySnapshotIcon: null,
      categorySnapshotColorInt: null,
    );
  }

  BudgetPendingBillRaw makePending({
    required String id,
    required String categoryId,
    required DateTime effectiveDate,
    required int amountMinor,
  }) {
    return BudgetPendingBillRaw(
      scheduledBillId: id,
      seriesId: 'series-$id',
      categoryId: categoryId,
      description: 'Bill $id',
      effectiveDate: effectiveDate,
      amountMinor: amountMinor,
      status: 'scheduled',
      accountId: 'acc-1',
      frequency: 'MONTHLY',
    );
  }

  group('BudgetCalculator', () {
    test('retains all contributions in the same order as the top three', () {
      final raw = BudgetMonthRawSummary(
        currencyCode: 'CNY',
        targetYm: 202605,
        rules: const [],
        expenseCategories: [makeCategory(id: 'dining')],
        windowExpenses: [
          makeTx(
              id: 'a',
              categoryId: 'dining',
              occurredAt: DateTime(2026, 5, 1),
              amountMinor: 300),
          makeTx(
              id: 'b',
              categoryId: 'dining',
              occurredAt: DateTime(2026, 5, 2),
              amountMinor: 100),
          makeTx(
              id: 'c',
              categoryId: 'dining',
              occurredAt: DateTime(2026, 5, 3),
              amountMinor: 200),
        ],
        reviewNotes: const [],
        earliestExpenseYm: 202605,
        hasAnyActiveAccount: true,
      );
      final pending = BudgetMonthPendingRaw(
        bills: [
          makePending(
              id: 'p',
              categoryId: 'dining',
              effectiveDate: DateTime(2026, 5, 4),
              amountMinor: 400)
        ],
      );
      final tracked = BudgetCalculator.compute(
              currencyCode: 'CNY',
              raw: raw,
              pending: pending,
              targetYm: const YearMonth(2026, 5),
              now: DateTime(2026, 5, 10))
          .findCategory('dining')!;
      expect(tracked.contributions.map((tx) => tx.transactionId),
          ['p', 'a', 'c', 'b']);
      expect(tracked.topTransactions.map((tx) => tx.transactionId),
          ['p', 'a', 'c']);
      final reviewed = BudgetCalculator.compute(
              currencyCode: 'CNY',
              raw: raw,
              pending: pending,
              targetYm: const YearMonth(2026, 5),
              now: DateTime(2026, 6, 1))
          .findCategory('dining')!;
      expect(reviewed.contributions.map((tx) => tx.transactionId),
          ['a', 'c', 'b']);
    });

    test('selects plan / track / review mode relative to clock date', () {
      const raw = BudgetMonthRawSummary(
        currencyCode: 'CNY',
        targetYm: 202605,
        rules: [],
        expenseCategories: [],
        windowExpenses: [],
        reviewNotes: [],
        earliestExpenseYm: null,
        hasAnyActiveAccount: true,
      );
      const pending = BudgetMonthPendingRaw(
        bills: [],
      );
      final now = DateTime(2026, 5, 10);

      expect(
        BudgetCalculator.compute(
          currencyCode: 'CNY',
          raw: raw,
          pending: pending,
          targetYm: const YearMonth(2026, 6),
          now: now,
        ).mode,
        BudgetMode.plan,
      );
      expect(
        BudgetCalculator.compute(
          currencyCode: 'CNY',
          raw: raw,
          pending: pending,
          targetYm: const YearMonth(2026, 5),
          now: now,
        ).mode,
        BudgetMode.track,
      );
      expect(
        BudgetCalculator.compute(
          currencyCode: 'CNY',
          raw: raw,
          pending: pending,
          targetYm: const YearMonth(2026, 4),
          now: now,
        ).mode,
        BudgetMode.review,
      );
    });

    test(
        'aligns budgeted-only totals with compliance rate while separating '
        'unbudgeted spend, committed/discretionary, and pending bills', () {
      final dining = makeCategory(id: 'dining', name: 'Dining');
      final rent = makeCategory(id: 'rent', name: 'Rent');
      final travel = makeCategory(id: 'travel', name: 'Travel');
      final utils = makeCategory(id: 'utils', name: 'Utilities');

      final raw = BudgetMonthRawSummary(
        currencyCode: 'CNY',
        targetYm: 202605,
        rules: [
          makeRule(
              categoryId: 'dining', effectiveYm: 202604, amountMinor: 200000),
          makeRule(
              categoryId: 'rent', effectiveYm: 202604, amountMinor: 300000),
        ],
        expenseCategories: [dining, rent, travel, utils],
        windowExpenses: [
          makeTx(
            id: 't1',
            categoryId: 'dining',
            occurredAt: DateTime(2026, 5, 3),
            amountMinor: 50000,
          ),
          makeTx(
            id: 't2',
            categoryId: 'rent',
            occurredAt: DateTime(2026, 5, 1),
            amountMinor: 200000,
            sourceScheduledBillId: 'b-posted',
          ),
          makeTx(
            id: 't3',
            categoryId: 'travel',
            occurredAt: DateTime(2026, 5, 8),
            amountMinor: 400000,
          ),
        ],
        reviewNotes: const [],
        earliestExpenseYm: 202605,
        hasAnyActiveAccount: true,
      );
      final pending = BudgetMonthPendingRaw(
        bills: [
          makePending(
            id: 'b-rent',
            categoryId: 'rent',
            effectiveDate: DateTime(2026, 5, 25),
            amountMinor: 150000, // 2000 + 1500 = 3500 > 3000 -> At Risk
          ),
          makePending(
            id: 'b-travel',
            categoryId: 'travel',
            effectiveDate: DateTime(2026, 5, 26),
            amountMinor: 20000,
          ),
        ],
      );

      final summary = BudgetCalculator.compute(
        currencyCode: 'CNY',
        raw: raw,
        pending: pending,
        targetYm: const YearMonth(2026, 5),
        now: DateTime(2026, 5, 10),
      );

      // Both budgeted categories have Actual <= Budget -> 2/2 = 100%
      expect(summary.inBudgetCount, 2);
      expect(summary.budgetedCategoryCount, 2);
      expect(summary.complianceRate, 1.0);

      // Budgeted-only aggregates stay positive (no 100% vs overspent conflict)
      expect(summary.totalBudgetMinor, 500000);
      expect(summary.budgetedActualMinor, 250000);
      expect(summary.budgetedPendingMinor, 150000);
      expect(summary.projectedRemainingMinor, 100000);

      // Full-ledger totals still capture unbudgeted spend
      expect(summary.allExpenseActualMinor, 650000);
      expect(summary.allExpensePendingMinor, 170000);
      expect(summary.unbudgetedActualMinor, 400000);
      expect(summary.unbudgetedPendingMinor, 20000);

      // Grouping
      expect(summary.budgetedCategories.map((c) => c.categoryId),
          ['rent', 'dining']); // atRisk sorted ahead of inBudget
      expect(summary.budgetedCategories[0].riskLevel, BudgetRiskLevel.atRisk);
      expect(summary.budgetedCategories[0].committedActualMinor, 200000);
      expect(summary.budgetedCategories[0].committedBaselineMinor, 350000);
      expect(summary.unbudgetedActiveCategories.map((c) => c.categoryId),
          ['travel']);
      expect(summary.remainingActiveCategories.map((c) => c.categoryId),
          ['utils']);
      expect(summary.unbudgetedAlertsTop3.single.categoryId, 'travel');
    });

    test(
        'cold-start 3-month average divides by actual months since earliestTxYm '
        'and flags anomaly when >= +25% and >= 5% share', () {
      final dining = makeCategory(id: 'dining', name: 'Dining');
      final raw = BudgetMonthRawSummary(
        currencyCode: 'CNY',
        targetYm: 202605,
        rules: [
          makeRule(
              categoryId: 'dining', effectiveYm: 202603, amountMinor: 200000),
        ],
        expenseCategories: [dining],
        windowExpenses: [
          // Earliest month is 2026-03 (only 2 prior months before 2026-05!)
          makeTx(
            id: 't-mar',
            categoryId: 'dining',
            occurredAt: DateTime(2026, 3, 10),
            amountMinor: 60000,
          ),
          makeTx(
            id: 't-apr',
            categoryId: 'dining',
            occurredAt: DateTime(2026, 4, 10),
            amountMinor: 100000,
          ),
          // 2026-05: actual 150000 vs avg (60000+100000)/2 = 80000 -> +87.5%
          makeTx(
            id: 't-may',
            categoryId: 'dining',
            occurredAt: DateTime(2026, 5, 10),
            amountMinor: 150000,
          ),
        ],
        reviewNotes: const [],
        earliestExpenseYm: 202603,
        hasAnyActiveAccount: true,
      );

      final maySummary = BudgetCalculator.compute(
        currencyCode: 'CNY',
        raw: raw,
        pending: const BudgetMonthPendingRaw(
          bills: [],
        ),
        targetYm: const YearMonth(2026, 5),
        now: DateTime(2026, 5, 15),
      );
      final cat = maySummary.budgetedCategories.single;
      expect(cat.threeMonthAvgMinor, 80000);
      expect(cat.lastMonthActualMinor, 100000);
      expect(cat.isAnomaly, isTrue);

      // In the earliest month itself (2026-03), both 3-mo avg and last month are null
      final marSummary = BudgetCalculator.compute(
        currencyCode: 'CNY',
        raw: raw,
        pending: const BudgetMonthPendingRaw(
          bills: [],
        ),
        targetYm: const YearMonth(2026, 3),
        now: DateTime(2026, 5, 15),
      );
      expect(marSummary.budgetedCategories.single.threeMonthAvgMinor, isNull);
      expect(marSummary.budgetedCategories.single.lastMonthActualMinor, isNull);
    });

    test(
        'archived category keeps budget in archiveYm, stops carry-forward next '
        'month, and leaves break on 6-month trend', () {
      // Archived on 2026-04-15 local
      final dining = makeCategory(
        id: 'dining',
        name: 'Dining',
        archived: true,
        archivedAt: DateTime(2026, 4, 15, 20, 0),
      );
      final raw = BudgetMonthRawSummary(
        currencyCode: 'CNY',
        targetYm: 202605,
        rules: [
          makeRule(
              categoryId: 'dining', effectiveYm: 202602, amountMinor: 120000),
        ],
        expenseCategories: [dining],
        windowExpenses: const [],
        reviewNotes: const [],
        earliestExpenseYm: null,
        hasAnyActiveAccount: true,
      );

      // Archive month (2026-04) still sees budget
      final apr = BudgetCalculator.compute(
        currencyCode: 'CNY',
        raw: raw,
        pending: const BudgetMonthPendingRaw(
          bills: [],
        ),
        targetYm: const YearMonth(2026, 4),
        now: DateTime(2026, 5, 1),
      );
      expect(apr.budgetedCategories.single.budgetMinor, 120000);

      // Month after archive (2026-05) cuts off carry-forward and hides from remainingActive
      final may = BudgetCalculator.compute(
        currencyCode: 'CNY',
        raw: raw,
        pending: const BudgetMonthPendingRaw(
          bills: [],
        ),
        targetYm: const YearMonth(2026, 5),
        now: DateTime(2026, 5, 1),
      );
      expect(may.budgetedCategories, isEmpty);
      expect(may.remainingActiveCategories, isEmpty);
      expect(may.complianceRate, isNull);

      // Month-level 6-month trend for 2026-05: Feb/Mar/Apr=120000, Dec/Jan/May=null
      expect(
        may.monthTrend6Months.map((p) => p.budgetMinor).toList(),
        [null, null, 120000, 120000, 120000, null],
      );
    });

    test('review mode ignores leftover pending bills but flags hint', () {
      final dining = makeCategory(id: 'dining', name: 'Dining');
      final raw = BudgetMonthRawSummary(
        currencyCode: 'CNY',
        targetYm: 202604,
        rules: [
          makeRule(
              categoryId: 'dining', effectiveYm: 202604, amountMinor: 100000),
        ],
        expenseCategories: [dining],
        windowExpenses: [
          makeTx(
            id: 't1',
            categoryId: 'dining',
            occurredAt: DateTime(2026, 4, 10),
            amountMinor: 80000,
          ),
        ],
        reviewNotes: const [],
        earliestExpenseYm: 202604,
        hasAnyActiveAccount: true,
      );
      final pending = BudgetMonthPendingRaw(
        bills: [
          makePending(
            id: 'b-old',
            categoryId: 'dining',
            effectiveDate: DateTime(2026, 4, 28),
            amountMinor: 50000,
          ),
        ],
      );

      final summary = BudgetCalculator.compute(
        currencyCode: 'CNY',
        raw: raw,
        pending: pending,
        targetYm: const YearMonth(2026, 4),
        now: DateTime(2026, 5, 10),
      );

      expect(summary.mode, BudgetMode.review);
      expect(summary.hasLeftoverPendingInReview, isTrue);
      expect(summary.budgetedPendingMinor, 0);
      expect(summary.projectedRemainingMinor, 20000);
      expect(summary.budgetedCategories.single.riskLevel,
          BudgetRiskLevel.inBudget);
      expect(summary.underBudgetTop3.single.varianceMinor, 20000);
    });
  });
}
