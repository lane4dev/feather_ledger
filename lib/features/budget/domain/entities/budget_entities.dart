import 'package:flutter/foundation.dart';

import '../value_objects/budget_value_objects.dart';

@immutable
class BudgetRule {
  final String currencyCode;
  final String categoryId;
  final YearMonth effectiveYm;
  final int? amountMinor;
  final DateTime updatedAt;

  const BudgetRule({
    required this.currencyCode,
    required this.categoryId,
    required this.effectiveYm,
    required this.amountMinor,
    required this.updatedAt,
  });
}

@immutable
class BudgetReviewNote {
  final String currencyCode;
  final YearMonth month;
  final String? categoryId;
  final String note;
  final DateTime updatedAt;

  const BudgetReviewNote({
    required this.currencyCode,
    required this.month,
    required this.categoryId,
    required this.note,
    required this.updatedAt,
  });
}

@immutable
class CategoryBudgetSummary {
  final String categoryId;
  final String categoryName;
  final String iconKey;
  final int colorInt;
  final bool isArchived;
  final YearMonth? archiveYm;

  /// Effective budget in the target month (`null` when unset or past archive).
  final int? budgetMinor;

  /// True when an explicit breakpoint exists strictly after target month.
  final bool hasFutureRulesAfter;

  final int committedActualMinor;
  final int discretionaryActualMinor;
  final int actualMinor;
  final int pendingMinor;
  final int? projectedRemainingMinor;
  final int? lastMonthActualMinor;
  final int? threeMonthAvgMinor;
  final int committedBaselineMinor;
  final bool isAnomaly;
  final double? anomalyDeltaRatio;
  final BudgetRiskLevel riskLevel;
  final List<BudgetTrendPoint> sixMonthTrend;
  final List<BudgetContributionTx> topTransactions;
  final List<BudgetContributionTx>? allTransactions;
  final String? reviewNote;

  const CategoryBudgetSummary({
    required this.categoryId,
    required this.categoryName,
    required this.iconKey,
    required this.colorInt,
    required this.isArchived,
    required this.archiveYm,
    required this.budgetMinor,
    required this.hasFutureRulesAfter,
    required this.committedActualMinor,
    required this.discretionaryActualMinor,
    required this.actualMinor,
    required this.pendingMinor,
    required this.projectedRemainingMinor,
    required this.lastMonthActualMinor,
    required this.threeMonthAvgMinor,
    required this.committedBaselineMinor,
    required this.isAnomaly,
    required this.anomalyDeltaRatio,
    required this.riskLevel,
    required this.sixMonthTrend,
    required this.topTransactions,
    this.allTransactions,
    required this.reviewNote,
  });

  bool get hasBudget => budgetMinor != null;

  List<BudgetContributionTx> get contributions =>
      allTransactions ?? topTransactions;

  BudgetVariance? get variance =>
      budgetMinor == null ? null : BudgetVariance(budgetMinor! - actualMinor);
}

@immutable
class BudgetAttributionItem {
  final String categoryId;
  final String categoryName;
  final String iconKey;
  final int colorInt;
  final int budgetMinor;
  final int actualMinor;
  final int varianceMinor;
  final double shareOfTotalActual;

  const BudgetAttributionItem({
    required this.categoryId,
    required this.categoryName,
    required this.iconKey,
    required this.colorInt,
    required this.budgetMinor,
    required this.actualMinor,
    required this.varianceMinor,
    required this.shareOfTotalActual,
  });
}

@immutable
class UnbudgetedSpendAlert {
  final String categoryId;
  final String categoryName;
  final String iconKey;
  final int colorInt;
  final int actualMinor;
  final int pendingMinor;
  final double shareOfTotalActual;

  const UnbudgetedSpendAlert({
    required this.categoryId,
    required this.categoryName,
    required this.iconKey,
    required this.colorInt,
    required this.actualMinor,
    required this.pendingMinor,
    required this.shareOfTotalActual,
  });
}

@immutable
class MonthBudgetSummary {
  final String currencyCode;
  final YearMonth month;
  final BudgetMode mode;
  final bool hasAnyActiveAccount;

  /// Sum of effective budgets across all budgeted categories.
  final int totalBudgetMinor;

  /// Sum of actuals strictly across budgeted categories (matches compliance).
  final int budgetedActualMinor;

  /// Sum of pending bills strictly across budgeted categories.
  final int budgetedPendingMinor;

  /// `totalBudgetMinor - budgetedActualMinor - budgetedPendingMinor`.
  final int projectedRemainingMinor;

  /// `totalBudgetMinor - budgetedActualMinor`.
  final int budgetedRemainingActualMinor;

  /// Total actual expense across ALL expense categories (incl. unbudgeted).
  final int allExpenseActualMinor;

  /// Total pending expense across ALL expense categories (incl. unbudgeted).
  final int allExpensePendingMinor;

  /// Unbudgeted actual spend (`allExpenseActualMinor - budgetedActualMinor`).
  final int unbudgetedActualMinor;

  /// Unbudgeted pending spend (`allExpensePendingMinor - budgetedPendingMinor`).
  final int unbudgetedPendingMinor;

  final int inBudgetCount;
  final int budgetedCategoryCount;

  /// `null` when [budgetedCategoryCount] == 0.
  final double? complianceRate;

  final bool hasAnyBudget;
  final bool hasUnbudgetedActivity;
  final bool hasLeftoverPendingInReview;
  final bool hasHighFrequencyPending;
  final bool isFarFutureMaterializedOnly;

  final List<CategoryBudgetSummary> budgetedCategories;
  final List<CategoryBudgetSummary> unbudgetedActiveCategories;
  final List<CategoryBudgetSummary> remainingActiveCategories;

  final List<BudgetAttributionItem> overBudgetTop3;
  final List<BudgetAttributionItem> underBudgetTop3;
  final List<UnbudgetedSpendAlert> unbudgetedAlertsTop3;

  final List<BudgetTrendPoint> monthTrend6Months;
  final String? monthReviewNote;

  /// When [monthReviewNote] was last written, or null when the month has no
  /// note yet. Display-only: callers must not derive budget figures from it.
  final DateTime? monthReviewNoteUpdatedAt;

  const MonthBudgetSummary({
    required this.currencyCode,
    required this.month,
    required this.mode,
    required this.hasAnyActiveAccount,
    required this.totalBudgetMinor,
    required this.budgetedActualMinor,
    required this.budgetedPendingMinor,
    required this.projectedRemainingMinor,
    required this.budgetedRemainingActualMinor,
    required this.allExpenseActualMinor,
    required this.allExpensePendingMinor,
    required this.unbudgetedActualMinor,
    required this.unbudgetedPendingMinor,
    required this.inBudgetCount,
    required this.budgetedCategoryCount,
    required this.complianceRate,
    required this.hasAnyBudget,
    required this.hasUnbudgetedActivity,
    required this.hasLeftoverPendingInReview,
    required this.hasHighFrequencyPending,
    required this.isFarFutureMaterializedOnly,
    required this.budgetedCategories,
    required this.unbudgetedActiveCategories,
    required this.remainingActiveCategories,
    required this.overBudgetTop3,
    required this.underBudgetTop3,
    required this.unbudgetedAlertsTop3,
    required this.monthTrend6Months,
    required this.monthReviewNote,
    this.monthReviewNoteUpdatedAt,
  });

  List<CategoryBudgetSummary> get allSummaries => [
        ...budgetedCategories,
        ...unbudgetedActiveCategories,
        ...remainingActiveCategories,
      ];

  CategoryBudgetSummary? findCategory(String categoryId) {
    for (final item in allSummaries) {
      if (item.categoryId == categoryId) return item;
    }
    return null;
  }
}

@immutable
class CategoryBudgetHint {
  final String currencyCode;
  final YearMonth month;
  final String categoryId;
  final bool isCategoryArchived;
  final int? effectiveBudgetMinor;
  final int actualMinor;
  final int pendingMinor;

  const CategoryBudgetHint({
    required this.currencyCode,
    required this.month,
    required this.categoryId,
    required this.isCategoryArchived,
    required this.effectiveBudgetMinor,
    required this.actualMinor,
    required this.pendingMinor,
  });
}
