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

  /// Whether the month is after the mapper's today. A future month may carry a
  /// budget rule but no spending, so it must not open a chart on its own.
  final bool isFuture;

  const BudgetTrendPointUiModel({
    required this.ym,
    required this.shortLabel,
    required this.budgetMinor,
    required this.actualMinor,
    required this.budgetChartValue,
    required this.actualChartValue,
    required this.hasReviewNote,
    this.isFuture = false,
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

/// What a category row's right-hand amount measures.
///
/// The words in front of the amount are a localizable resource, so the mapper
/// names the meaning and the widget resolves it — the same split as
/// [BudgetOverviewMainLabel]. The amounts themselves arrive preformatted.
enum BudgetCategoryAmountLabel {
  /// Nothing to name: the amount stands on its own (a category with no
  /// limit, whose spend is the answer).
  none,

  /// Track: spent plus billed still sits inside the limit.
  remaining,

  /// Track: spent plus billed is over the limit.
  projectedOver,

  /// Track: money already spent is over the limit.
  over,

  /// Review: a closed month ended under its limit.
  reviewRemaining,

  /// Review: a closed month ended over its limit.
  reviewOver,

  /// Plan: the limit the category has been given.
  planBudget,
}

/// What a category row's second line on the left says.
enum BudgetCategorySubtitle {
  /// Nothing to add beyond the name.
  none,

  /// Track: the bills included in the spend, as an amount.
  pendingIncluded,

  /// No limit: money billed here but not yet posted, as an amount.
  pending,

  /// Share of the limit already used, as a percent.
  usage,

  /// Plan: the fixed baseline, with the three-month average beside it when
  /// the category has one.
  baseline,
}

/// The header of the unbudgeted group.
///
/// Set on every row of that group: the section is handed rows, not the screen
/// model, and a header derived from anything but those rows could disagree
/// with the rows underneath it.
@immutable
class BudgetUnbudgetedGroupUiModel {
  /// True when the group's only activity is billed-but-unposted money, which
  /// makes [amountDisplay] pending rather than spent.
  final bool isPendingOnly;

  /// The group's total: spent when there is any, otherwise pending.
  final String amountDisplay;

  const BudgetUnbudgetedGroupUiModel({
    required this.isPendingOnly,
    required this.amountDisplay,
  });
}

@immutable
class BudgetCategoryRowUiModel {
  final String categoryId;
  final String name;

  /// The category name with the month, e.g. `Dining · May 2026`. Composite text
  /// belongs here rather than in a widget so the same phrase cannot drift
  /// between the detail screen and its contributions page.
  final String titleDisplay;
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

  /// [threeMonthAvgMinor] in chart units (major units, as fl_chart draws them),
  /// or null when there is no average to plot.
  final double? threeMonthAvgChartValue;

  /// [budgetMinor] in chart units, or null when the category has no budget in
  /// this month.
  final double? budgetChartValue;
  final double actualProgress;
  final double pendingProgress;
  final BudgetRiskLevel riskLevel;
  final bool isAnomaly;
  final int? anomalyPercent;
  final String? reviewNote;
  final List<BudgetTrendPointUiModel> trend6Months;
  final List<BudgetContributionTxUiModel> topContributions;
  final List<BudgetContributionTxUiModel> allContributions;

  /// Which month phase the row is drawn for. Track and review rows open the
  /// category's detail; plan rows open the budget editor.
  final BudgetMode mode;

  /// What [mainAmountDisplay] measures.
  final BudgetCategoryAmountLabel amountLabel;

  /// The right-hand amount — what is left, what is over, or the row's own
  /// spend when [amountLabel] is [BudgetCategoryAmountLabel.none].
  final String? mainAmountDisplay;

  /// Whether [mainAmountDisplay] is a shortfall, which paints it in the
  /// expense colour.
  final bool isMainAmountNegative;

  /// The spent-against-limit line under [mainAmountDisplay], e.g.
  /// `¥40.00 / ¥200.00`. Null when there is no limit to compare against.
  final String? secondaryAmountDisplay;

  /// What the row's second line on the left says.
  final BudgetCategorySubtitle subtitleKind;

  /// Amount for [subtitleKind] — the pending bills, or the fixed baseline.
  final String? subtitleAmountDisplay;

  /// The three-month average set after a [BudgetCategorySubtitle.baseline],
  /// when the category has one worth comparing against.
  final String? subtitleReferenceDisplay;

  /// Percent for [BudgetCategorySubtitle.usage], e.g. `20%`.
  final String? subtitlePercentDisplay;

  /// The row's share of the month's spending, when it clears the 5% gate.
  final String? sharePercentDisplay;

  /// How much of the limit the plan bar's fixed baseline covers (0..1). Zero
  /// means the row draws no bar.
  final double baselineProgress;

  /// The header of the unbudgeted group this row belongs to; null for rows
  /// outside it.
  final BudgetUnbudgetedGroupUiModel? unbudgetedGroup;

  const BudgetCategoryRowUiModel({
    required this.categoryId,
    required this.name,
    required this.titleDisplay,
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
    this.threeMonthAvgChartValue,
    this.budgetChartValue,
    required this.actualProgress,
    required this.pendingProgress,
    required this.riskLevel,
    required this.isAnomaly,
    required this.anomalyPercent,
    required this.reviewNote,
    required this.trend6Months,
    required this.topContributions,
    this.allContributions = const [],
    this.mode = BudgetMode.track,
    this.amountLabel = BudgetCategoryAmountLabel.none,
    this.mainAmountDisplay,
    this.isMainAmountNegative = false,
    this.secondaryAmountDisplay,
    this.subtitleKind = BudgetCategorySubtitle.none,
    this.subtitleAmountDisplay,
    this.subtitleReferenceDisplay,
    this.subtitlePercentDisplay,
    this.sharePercentDisplay,
    this.baselineProgress = 0,
    this.unbudgetedGroup,
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

  /// Whether any category carries a fixed baseline at all — the same total
  /// [committedBaselineDisplay] shows. Plan hints ask this rather than "is
  /// every bill in a budgeted category", so a bill in an unbudgeted category is
  /// still visible.
  final bool hasCommittedBaseline;
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
    required this.hasCommittedBaseline,
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

  /// The month written out in the active locale, e.g. `May 2026`.
  final String monthDisplay;
  final List<BudgetCategoryRowUiModel> budgetedRows;
  final List<BudgetCategoryRowUiModel> unbudgetedActiveRows;
  final List<BudgetCategoryRowUiModel> remainingActiveRows;
  final List<BudgetAttributionItemUiModel> overBudgetTop3;
  final List<BudgetAttributionItemUiModel> underBudgetTop3;
  final List<BudgetTrendPointUiModel> monthTrend6Months;
  final String? monthReviewNote;

  const BudgetScreenUiModel({
    required this.overview,
    required this.monthDisplay,
    required this.budgetedRows,
    required this.unbudgetedActiveRows,
    required this.remainingActiveRows,
    required this.overBudgetTop3,
    required this.underBudgetTop3,
    required this.monthTrend6Months,
    required this.monthReviewNote,
  });

  List<BudgetCategoryRowUiModel> get allEditableCategories => [
        ...budgetedRows.where((r) => r.isBudgetEditable),
        ...unbudgetedActiveRows.where((r) => r.isBudgetEditable),
        ...remainingActiveRows.where((r) => r.isBudgetEditable),
      ];
}

/// What the category detail page (L3) needs from its month, resolved once.
///
/// The page is one category out of the month's rows, so it reads the same
/// [BudgetScreenUiModel] the home does and keeps the row it is about.
@immutable
class BudgetCategoryDetailUiModel {
  final BudgetCategoryRowUiModel row;

  /// The month written out in the active locale, for the clear-budget dialog.
  final String monthDisplay;

  /// A month that has already ended: no bill can still arrive in it, so the
  /// page drops every pending figure.
  final bool isHistoricalMonth;

  /// The month's pending money is only materialised bills, which the
  /// composition card says out loud.
  final bool showMaterializationHint;

  const BudgetCategoryDetailUiModel({
    required this.row,
    required this.monthDisplay,
    required this.isHistoricalMonth,
    required this.showMaterializationHint,
  });
}
