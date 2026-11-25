import 'package:feather_ledger/core/data/database/daos/budget_dao.dart';

import '../entities/budget_entities.dart';
import '../value_objects/budget_value_objects.dart';

/// Pure domain calculation kernel assembling [MonthBudgetSummary] from raw
/// database snapshots without side effects or clock reads.
abstract final class BudgetCalculator {
  static MonthBudgetSummary compute({
    required String currencyCode,
    required BudgetMonthRawSummary raw,
    required BudgetMonthPendingRaw pending,
    required YearMonth targetYm,
    required DateTime now,
  }) {
    final nowYm = YearMonth.fromDate(now);
    final mode = targetYm > nowYm
        ? BudgetMode.plan
        : targetYm < nowYm
            ? BudgetMode.review
            : BudgetMode.track;

    final horizonYm = YearMonth.fromDate(now.add(const Duration(days: 90)));
    final isFarFuture = targetYm > horizonYm;

    final sixMonths = List<YearMonth>.generate(
      6,
      (i) => targetYm.addMonths(i - 5),
      growable: false,
    );

    // Index rules by categoryId (already sorted ascending by effectiveYm from DAO).
    final rulesByCategory = <String, List<({int ym, int? amount})>>{};
    for (final rule in raw.rules) {
      rulesByCategory
          .putIfAbsent(rule.categoryId, () => [])
          .add((ym: rule.effectiveYm, amount: rule.amountMinor));
    }

    // Index review notes by (ym, categoryKey). Keep the write time so the L2
    // card can show when the month note was last updated.
    final noteByYmCat = <(int, String), ({String note, DateTime updatedAt})>{};
    for (final note in raw.reviewNotes) {
      noteByYmCat[(note.ym, note.categoryKey)] = (
        note: note.note,
        updatedAt: note.updatedAt,
      );
    }

    // Index expense rows by (categoryId, ym) and total by ym.
    final txByCatYm = <(String, int), List<BudgetExpensePostingRaw>>{};
    final actualByCatYm = <(String, int), int>{};
    final allActualByYm = <int, int>{};

    for (final tx in raw.windowExpenses) {
      final txYm = YearMonth.fromDate(tx.occurredAt.toLocal()).ym;
      txByCatYm.putIfAbsent((tx.categoryId, txYm), () => []).add(tx);
      actualByCatYm[(tx.categoryId, txYm)] =
          (actualByCatYm[(tx.categoryId, txYm)] ?? 0) + tx.amountMinor;
      allActualByYm[txYm] = (allActualByYm[txYm] ?? 0) + tx.amountMinor;
    }

    // Index pending bills by categoryId (for targetYm).
    final pendingByCat = <String, List<BudgetPendingBillRaw>>{};
    final pendingSumByCat = <String, int>{};
    var rawTotalPending = 0;

    for (final bill in pending.bills) {
      rawTotalPending += bill.amountMinor;
      pendingByCat.putIfAbsent(bill.categoryId, () => []).add(bill);
      pendingSumByCat[bill.categoryId] =
          (pendingSumByCat[bill.categoryId] ?? 0) + bill.amountMinor;
    }

    final allExpenseActualMinor = allActualByYm[targetYm.ym] ?? 0;
    final hasLeftoverPendingInReview =
        mode == BudgetMode.review && rawTotalPending > 0;
    final earliestYm = raw.earliestExpenseYm == null
        ? null
        : YearMonth.fromYm(raw.earliestExpenseYm!);

    final prevYm = targetYm.previous;
    final threeMoStart = targetYm.addMonths(-3);

    int? resolveEffectiveBudget(
      String categoryId,
      YearMonth month, {
      required bool isArchived,
      required YearMonth? archiveYm,
    }) {
      if (isArchived && (archiveYm == null || month > archiveYm)) {
        return null;
      }
      final catRules = rulesByCategory[categoryId];
      if (catRules == null || catRules.isEmpty) return null;
      int? effective;
      for (final r in catRules) {
        if (r.ym <= month.ym) {
          effective = r.amount;
        } else {
          break;
        }
      }
      return effective;
    }

    final budgeted = <CategoryBudgetSummary>[];
    final unbudgetedActive = <CategoryBudgetSummary>[];
    final remainingActive = <CategoryBudgetSummary>[];

    var totalBudgetMinor = 0;
    var budgetedActualMinor = 0;
    var budgetedPendingMinor = 0;
    var allExpensePendingMinor = 0;
    var inBudgetCount = 0;

    final monthTrendBudgetTotals = <int, int?>{
      for (final m in sixMonths) m.ym: null,
    };

    for (final cat in raw.expenseCategories) {
      final archiveYm = cat.archivedAt == null
          ? null
          : YearMonth.fromDate(cat.archivedAt!.toLocal());

      final effectiveBudget = resolveEffectiveBudget(
        cat.id,
        targetYm,
        isArchived: cat.archived,
        archiveYm: archiveYm,
      );

      final catRules = rulesByCategory[cat.id];
      final hasFutureRulesAfter =
          catRules != null && catRules.any((r) => r.ym > targetYm.ym);

      final targetTxs = txByCatYm[(cat.id, targetYm.ym)] ?? const [];
      var committedActualMinor = 0;
      var discretionaryActualMinor = 0;
      for (final tx in targetTxs) {
        if (tx.sourceScheduledBillId != null) {
          committedActualMinor += tx.amountMinor;
        } else {
          discretionaryActualMinor += tx.amountMinor;
        }
      }
      final actualMinor = committedActualMinor + discretionaryActualMinor;
      final rawCatPending = pendingSumByCat[cat.id] ?? 0;
      final pendingMinor = mode == BudgetMode.review ? 0 : rawCatPending;
      allExpensePendingMinor += pendingMinor;

      final lastMonthActualMinor = (earliestYm != null && prevYm >= earliestYm)
          ? (actualByCatYm[(cat.id, prevYm.ym)] ?? 0)
          : null;

      int? threeMonthAvgMinor;
      if (earliestYm != null && targetYm > earliestYm) {
        final avgStart = earliestYm > threeMoStart ? earliestYm : threeMoStart;
        final monthCount = avgStart.monthsUntil(prevYm) + 1;
        var sum3m = 0;
        for (var i = 0; i < monthCount; i++) {
          final m = avgStart.addMonths(i);
          sum3m += actualByCatYm[(cat.id, m.ym)] ?? 0;
        }
        threeMonthAvgMinor = (sum3m / monthCount).round();
      }

      double? anomalyDeltaRatio;
      var isAnomaly = false;
      if (threeMonthAvgMinor != null && threeMonthAvgMinor > 0) {
        final ratio = (actualMinor - threeMonthAvgMinor) / threeMonthAvgMinor;
        anomalyDeltaRatio = ratio;
        final share = allExpenseActualMinor > 0
            ? actualMinor / allExpenseActualMinor
            : 0.0;
        final overBudget =
            effectiveBudget != null && actualMinor > effectiveBudget;
        if (ratio >= 0.25 && (share >= 0.05 || overBudget)) {
          isAnomaly = true;
        }
      }

      final BudgetRiskLevel riskLevel;
      int? projectedRemainingMinor;
      if (effectiveBudget == null) {
        riskLevel = BudgetRiskLevel.none;
      } else {
        totalBudgetMinor += effectiveBudget;
        budgetedActualMinor += actualMinor;
        budgetedPendingMinor += pendingMinor;
        projectedRemainingMinor = effectiveBudget - actualMinor - pendingMinor;

        if (actualMinor > effectiveBudget) {
          riskLevel = BudgetRiskLevel.overBudget;
        } else {
          inBudgetCount += 1;
          if (actualMinor + pendingMinor > effectiveBudget) {
            riskLevel = BudgetRiskLevel.atRisk;
          } else {
            riskLevel = BudgetRiskLevel.inBudget;
          }
        }
      }

      final trend = <BudgetTrendPoint>[];
      for (final m in sixMonths) {
        final mBudget = resolveEffectiveBudget(
          cat.id,
          m,
          isArchived: cat.archived,
          archiveYm: archiveYm,
        );
        if (mBudget != null) {
          monthTrendBudgetTotals[m.ym] =
              (monthTrendBudgetTotals[m.ym] ?? 0) + mBudget;
        }
        trend.add(
          BudgetTrendPoint(
            month: m,
            budgetMinor: mBudget,
            actualMinor: actualByCatYm[(cat.id, m.ym)] ?? 0,
            pendingMinor: m == targetYm ? pendingMinor : 0,
            hasReviewNote:
                (noteByYmCat[(m.ym, cat.id)]?.note ?? '').trim().isNotEmpty,
          ),
        );
      }

      // Top 3 contributing transactions (posted + active pending bills in plan/track).
      final contributions = <BudgetContributionTx>[
        for (final tx in targetTxs)
          BudgetContributionTx(
            transactionId: tx.transactionId,
            sourceScheduledBillId: tx.sourceScheduledBillId,
            scheduledBillId: null,
            description: tx.description,
            occurredAt: tx.occurredAt,
            amountMinor: tx.amountMinor,
            isPending: false,
            accountName: tx.accountName,
          ),
        if (mode != BudgetMode.review)
          for (final bill in pendingByCat[cat.id] ?? const [])
            BudgetContributionTx(
              transactionId: bill.scheduledBillId,
              sourceScheduledBillId: bill.scheduledBillId,
              scheduledBillId: bill.scheduledBillId,
              description: bill.description,
              occurredAt: bill.effectiveDate,
              amountMinor: bill.amountMinor,
              isPending: true,
              accountName: bill.accountName,
            ),
      ]..sort((a, b) {
          final cmp = b.amountMinor.compareTo(a.amountMinor);
          if (cmp != 0) return cmp;
          return b.occurredAt.compareTo(a.occurredAt);
        });

      final summary = CategoryBudgetSummary(
        categoryId: cat.id,
        categoryName: cat.name,
        iconKey: cat.iconKey,
        colorInt: cat.colorInt,
        isArchived: cat.archived,
        archiveYm: archiveYm,
        budgetMinor: effectiveBudget,
        hasFutureRulesAfter: hasFutureRulesAfter,
        committedActualMinor: committedActualMinor,
        discretionaryActualMinor: discretionaryActualMinor,
        actualMinor: actualMinor,
        pendingMinor: pendingMinor,
        projectedRemainingMinor: projectedRemainingMinor,
        lastMonthActualMinor: lastMonthActualMinor,
        threeMonthAvgMinor: threeMonthAvgMinor,
        committedBaselineMinor: committedActualMinor + pendingMinor,
        isAnomaly: isAnomaly,
        anomalyDeltaRatio: anomalyDeltaRatio,
        riskLevel: riskLevel,
        sixMonthTrend: trend,
        topTransactions: contributions.take(3).toList(growable: false),
        allTransactions: List.unmodifiable(contributions),
        reviewNote: noteByYmCat[(targetYm.ym, cat.id)]?.note,
      );

      if (effectiveBudget != null) {
        budgeted.add(summary);
      } else if (actualMinor > 0 || pendingMinor > 0) {
        unbudgetedActive.add(summary);
      } else if (!cat.archived) {
        remainingActive.add(summary);
      }
    }

    // Sort budgeted rows according to mode.
    budgeted.sort((a, b) {
      if (mode == BudgetMode.review) {
        final overA = a.actualMinor - a.budgetMinor!;
        final overB = b.actualMinor - b.budgetMinor!;
        final overCmp = overB.compareTo(overA);
        if (overCmp != 0) return overCmp;
        final actCmp = b.actualMinor.compareTo(a.actualMinor);
        if (actCmp != 0) return actCmp;
        return a.categoryName.compareTo(b.categoryName);
      }
      int priority(BudgetRiskLevel r) => switch (r) {
            BudgetRiskLevel.overBudget => 0,
            BudgetRiskLevel.atRisk => 1,
            BudgetRiskLevel.inBudget => 2,
            BudgetRiskLevel.none => 3,
          };
      final pCmp = priority(a.riskLevel).compareTo(priority(b.riskLevel));
      if (pCmp != 0) return pCmp;
      final utilA =
          (a.actualMinor + a.pendingMinor) / a.budgetMinor!.toDouble();
      final utilB =
          (b.actualMinor + b.pendingMinor) / b.budgetMinor!.toDouble();
      final uCmp = utilB.compareTo(utilA);
      if (uCmp != 0) return uCmp;
      return a.categoryName.compareTo(b.categoryName);
    });

    unbudgetedActive.sort((a, b) {
      final sumCmp = (b.actualMinor + b.pendingMinor)
          .compareTo(a.actualMinor + a.pendingMinor);
      if (sumCmp != 0) return sumCmp;
      return a.categoryName.compareTo(b.categoryName);
    });

    remainingActive.sort((a, b) => a.categoryName.compareTo(b.categoryName));

    // Review attribution top 3s.
    final overItems = budgeted
        .where((c) => c.actualMinor > c.budgetMinor!)
        .map((c) => BudgetAttributionItem(
              categoryId: c.categoryId,
              categoryName: c.categoryName,
              iconKey: c.iconKey,
              colorInt: c.colorInt,
              budgetMinor: c.budgetMinor!,
              actualMinor: c.actualMinor,
              varianceMinor: c.budgetMinor! - c.actualMinor,
              shareOfTotalActual: allExpenseActualMinor > 0
                  ? c.actualMinor / allExpenseActualMinor
                  : 0.0,
            ))
        .toList()
      ..sort((a, b) => a.varianceMinor.compareTo(b.varianceMinor));

    final underItems = budgeted
        .where((c) => c.actualMinor <= c.budgetMinor!)
        .map((c) => BudgetAttributionItem(
              categoryId: c.categoryId,
              categoryName: c.categoryName,
              iconKey: c.iconKey,
              colorInt: c.colorInt,
              budgetMinor: c.budgetMinor!,
              actualMinor: c.actualMinor,
              varianceMinor: c.budgetMinor! - c.actualMinor,
              shareOfTotalActual: allExpenseActualMinor > 0
                  ? c.actualMinor / allExpenseActualMinor
                  : 0.0,
            ))
        .toList()
      ..sort((a, b) => b.varianceMinor.compareTo(a.varianceMinor));

    final unbudgetedAlerts = allExpenseActualMinor > 0
        ? (unbudgetedActive
            .where((c) =>
                !c.isArchived &&
                (c.actualMinor / allExpenseActualMinor) >= 0.05)
            .map((c) => UnbudgetedSpendAlert(
                  categoryId: c.categoryId,
                  categoryName: c.categoryName,
                  iconKey: c.iconKey,
                  colorInt: c.colorInt,
                  actualMinor: c.actualMinor,
                  pendingMinor: c.pendingMinor,
                  shareOfTotalActual: c.actualMinor / allExpenseActualMinor,
                ))
            .toList()
          ..sort((a, b) => b.actualMinor.compareTo(a.actualMinor)))
        : <UnbudgetedSpendAlert>[];

    final monthTrend = sixMonths
        .map((m) => BudgetTrendPoint(
              month: m,
              budgetMinor: monthTrendBudgetTotals[m.ym],
              actualMinor: allActualByYm[m.ym] ?? 0,
              pendingMinor: m == targetYm ? allExpensePendingMinor : 0,
              hasReviewNote:
                  (noteByYmCat[(m.ym, '')]?.note ?? '').trim().isNotEmpty,
            ))
        .toList(growable: false);

    final budgetedCount = budgeted.length;
    final complianceRate =
        budgetedCount == 0 ? null : inBudgetCount / budgetedCount;

    return MonthBudgetSummary(
      currencyCode: currencyCode,
      month: targetYm,
      mode: mode,
      hasAnyActiveAccount: raw.hasAnyActiveAccount,
      totalBudgetMinor: totalBudgetMinor,
      budgetedActualMinor: budgetedActualMinor,
      budgetedPendingMinor: budgetedPendingMinor,
      projectedRemainingMinor:
          totalBudgetMinor - budgetedActualMinor - budgetedPendingMinor,
      budgetedRemainingActualMinor: totalBudgetMinor - budgetedActualMinor,
      allExpenseActualMinor: allExpenseActualMinor,
      allExpensePendingMinor: allExpensePendingMinor,
      unbudgetedActualMinor: allExpenseActualMinor - budgetedActualMinor,
      unbudgetedPendingMinor: allExpensePendingMinor - budgetedPendingMinor,
      inBudgetCount: inBudgetCount,
      budgetedCategoryCount: budgetedCount,
      complianceRate: complianceRate,
      hasAnyBudget: budgetedCount > 0,
      hasUnbudgetedActivity: unbudgetedActive.isNotEmpty,
      hasLeftoverPendingInReview: hasLeftoverPendingInReview,
      hasHighFrequencyPending:
          mode != BudgetMode.review && pending.hasHighFrequencyActiveSeries,
      isFarFutureMaterializedOnly: isFarFuture && mode == BudgetMode.plan,
      budgetedCategories: List.unmodifiable(budgeted),
      unbudgetedActiveCategories: List.unmodifiable(unbudgetedActive),
      remainingActiveCategories: List.unmodifiable(remainingActive),
      overBudgetTop3: overItems.take(3).toList(growable: false),
      underBudgetTop3: underItems.take(3).toList(growable: false),
      unbudgetedAlertsTop3: unbudgetedAlerts.take(3).toList(growable: false),
      monthTrend6Months: monthTrend,
      monthReviewNote: noteByYmCat[(targetYm.ym, '')]?.note,
      monthReviewNoteUpdatedAt: noteByYmCat[(targetYm.ym, '')]?.updatedAt,
    );
  }
}
