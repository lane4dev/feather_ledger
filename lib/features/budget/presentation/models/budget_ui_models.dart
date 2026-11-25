import 'package:flutter/foundation.dart';

import 'package:feather_ledger/shared/presentation/models/balance_display_parts.dart';

import '../../domain/value_objects/budget_value_objects.dart';

@immutable
class BudgetTrendPointUiModel {
  final YearMonth ym;
  final String shortLabel;
  final int? budgetMinor;
  final int actualMinor;
  final double budgetChartValue;
  final double actualChartValue;
  final bool hasReviewNote;

  const BudgetTrendPointUiModel({
    required this.ym,
    required this.shortLabel,
    required this.budgetMinor,
    required this.actualMinor,
    required this.budgetChartValue,
    required this.actualChartValue,
    required this.hasReviewNote,
  });
}

@immutable
class BudgetContributionTxUiModel {
  final String id;
  final bool isPending;
  final String title;
  final String dateDisplay;
  final String amountDisplay;
  final bool isCommitted;
  final String accountName;

  const BudgetContributionTxUiModel({
    required this.id,
    required this.isPending,
    required this.title,
    required this.dateDisplay,
    required this.amountDisplay,
    required this.isCommitted,
    this.accountName = '',
  });
}

@immutable
class BudgetCategoryRowUiModel {
  final String categoryId;
  final String name;
  final String iconKey;
  final int colorInt;
  final bool archived;
  final bool isBudgetEditable;
  final int? budgetMinor;
  final String? budgetDisplay;
  final String actualDisplay;
  final String? pendingDisplay;
  final String? varianceDisplay;
  final bool isOverBudget;
  final String committedActualDisplay;
  final String discretionaryActualDisplay;
  final String committedBaselineDisplay;
  final String? lastMonthActualDisplay;
  final String? threeMonthAvgDisplay;
  final int? lastMonthActualMinor;
  final int? threeMonthAvgMinor;
  final int committedBaselineMinor;
  final double actualProgress;
  final double pendingProgress;
  final BudgetRiskLevel riskLevel;
  final bool isAnomaly;
  final int? anomalyPercent;
  final String? reviewNote;
  final List<BudgetTrendPointUiModel> trend6Months;
  final List<BudgetContributionTxUiModel> topContributions;
  final List<BudgetContributionTxUiModel> allContributions;

  const BudgetCategoryRowUiModel({
    required this.categoryId,
    required this.name,
    required this.iconKey,
    required this.colorInt,
    required this.archived,
    required this.isBudgetEditable,
    required this.budgetMinor,
    required this.budgetDisplay,
    required this.actualDisplay,
    required this.pendingDisplay,
    required this.varianceDisplay,
    required this.isOverBudget,
    required this.committedActualDisplay,
    required this.discretionaryActualDisplay,
    required this.committedBaselineDisplay,
    required this.lastMonthActualDisplay,
    required this.threeMonthAvgDisplay,
    required this.lastMonthActualMinor,
    required this.threeMonthAvgMinor,
    required this.committedBaselineMinor,
    required this.actualProgress,
    required this.pendingProgress,
    required this.riskLevel,
    required this.isAnomaly,
    required this.anomalyPercent,
    required this.reviewNote,
    required this.trend6Months,
    required this.topContributions,
    this.allContributions = const [],
  });
}

@immutable
class BudgetAttributionItemUiModel {
  final String categoryId;
  final String name;
  final String iconKey;
  final int colorInt;
  final String deltaDisplay;
  final bool isOver;

  const BudgetAttributionItemUiModel({
    required this.categoryId,
    required this.name,
    required this.iconKey,
    required this.colorInt,
    required this.deltaDisplay,
    required this.isOver,
  });
}

@immutable
class BudgetUnbudgetedAlertUiModel {
  final String categoryId;
  final String name;
  final String iconKey;
  final int colorInt;
  final String actualDisplay;
  final String shareDisplay;

  const BudgetUnbudgetedAlertUiModel({
    required this.categoryId,
    required this.name,
    required this.iconKey,
    required this.colorInt,
    required this.actualDisplay,
    required this.shareDisplay,
  });
}

@immutable
class BudgetOverviewUiModel {
  final YearMonth targetYm;
  final BudgetMode mode;
  final String currencyCode;
  final String currencySymbol;
  final bool hasAnyAccount;
  final bool hasAnyBudget;
  final String totalBudgetDisplay;
  final String budgetedActualDisplay;
  final String budgetedPendingDisplay;
  final bool hasBudgetedPending;
  final String projectedRemainingDisplay;
  final bool isProjectedOverBudget;
  final double actualRatio;
  final double pendingRatio;
  final String complianceDisplay;
  final String allExpenseActualDisplay;
  final String unbudgetedActualDisplay;
  final bool hasUnbudgetedSpend;
  final String committedBaselineDisplay;
  final String committedActualDisplay;
  final String discretionaryActualDisplay;
  final bool hasLeftoverPendingInReview;
  final bool hasHighFrequencyMaterializationHint;

  /// What the main amount measures this mode — the hero's label.
  final BudgetOverviewMainLabel mainLabel;

  /// The main amount, already written and taken apart for three-tier setting.
  /// Non-numeric (`—`) when the month has no budget at all.
  final BalanceDisplayParts mainAmount;

  /// True when [mainAmount] is a shortfall (projected over, overspent in a
  /// closed month, or a baseline above the budget). The card paints the amount
  /// in the expense colour only then; everything else stays in ink.
  final bool isMainAmountNegative;

  /// The footer's three columns, in reading order.
  final List<BudgetOverviewMetricUiModel> footerMetrics;

  /// The share of the total budget the budgeted categories' fixed baseline
  /// occupies — plan mode's bar. Clamped to 1 so an over-committed month still
  /// draws a full bar and states the gap as an amount instead.
  final double fixedBaselineRatio;

  /// Whether the month has any budgeted baseline to draw in plan mode.
  final bool hasFixedBaseline;

  /// Where today sits in the month (0..1), or null when the month is not the
  /// one containing today. Track mode's tick on the bar.
  final double? todayTickRatio;

  const BudgetOverviewUiModel({
    required this.targetYm,
    required this.mode,
    required this.currencyCode,
    required this.currencySymbol,
    required this.hasAnyAccount,
    required this.hasAnyBudget,
    required this.totalBudgetDisplay,
    required this.budgetedActualDisplay,
    required this.budgetedPendingDisplay,
    required this.hasBudgetedPending,
    required this.projectedRemainingDisplay,
    required this.isProjectedOverBudget,
    required this.actualRatio,
    required this.pendingRatio,
    required this.complianceDisplay,
    required this.allExpenseActualDisplay,
    required this.unbudgetedActualDisplay,
    required this.hasUnbudgetedSpend,
    required this.committedBaselineDisplay,
    required this.committedActualDisplay,
    required this.discretionaryActualDisplay,
    required this.hasLeftoverPendingInReview,
    required this.hasHighFrequencyMaterializationHint,
    required this.mainLabel,
    required this.mainAmount,
    required this.isMainAmountNegative,
    required this.footerMetrics,
    required this.fixedBaselineRatio,
    required this.hasFixedBaseline,
    required this.todayTickRatio,
  });
}

/// Which quantity the overview card's main amount is.
///
/// The label is a localizable resource, not a number, so the mapper names the
/// meaning and the widget resolves it — the same split as
/// [BudgetOverviewMetric].
enum BudgetOverviewMainLabel {
  projectedRemaining,
  projectedOver,
  monthlySurplus,
  monthlyOverspend,
  availableToSpend,
}

/// A footer column of the overview card.
enum BudgetOverviewMetric {
  spent,
  pending,
  totalBudget,
  budgetUsage,
  committedBaseline,
  baselineShare,
}

/// How much weight a footer column carries.
///
/// Only [pending] is distinct: it is the one figure that is money not yet
/// spent, so it wears the same lavender as the bar's pending segment.
enum BudgetOverviewMetricTone { neutral, pending }

@immutable
class BudgetOverviewMetricUiModel {
  final BudgetOverviewMetric metric;
  final String value;
  final BudgetOverviewMetricTone tone;

  const BudgetOverviewMetricUiModel({
    required this.metric,
    required this.value,
    this.tone = BudgetOverviewMetricTone.neutral,
  });
}

@immutable
class BudgetScreenUiModel {
  final BudgetOverviewUiModel overview;
  final List<BudgetCategoryRowUiModel> budgetedRows;
  final List<BudgetCategoryRowUiModel> unbudgetedActiveRows;
  final List<BudgetCategoryRowUiModel> remainingActiveRows;
  final List<BudgetAttributionItemUiModel> overBudgetTop3;
  final List<BudgetAttributionItemUiModel> underBudgetTop3;
  final List<BudgetUnbudgetedAlertUiModel> unbudgetedAlertsTop3;
  final List<BudgetTrendPointUiModel> monthTrend6Months;
  final String? monthReviewNote;

  const BudgetScreenUiModel({
    required this.overview,
    required this.budgetedRows,
    required this.unbudgetedActiveRows,
    required this.remainingActiveRows,
    required this.overBudgetTop3,
    required this.underBudgetTop3,
    required this.unbudgetedAlertsTop3,
    required this.monthTrend6Months,
    required this.monthReviewNote,
  });

  List<BudgetCategoryRowUiModel> get allEditableCategories => [
        ...budgetedRows.where((r) => r.isBudgetEditable),
        ...unbudgetedActiveRows.where((r) => r.isBudgetEditable),
        ...remainingActiveRows.where((r) => r.isBudgetEditable),
      ];
}
