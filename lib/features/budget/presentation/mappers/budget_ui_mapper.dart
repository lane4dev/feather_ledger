import 'package:intl/intl.dart';

import 'package:feather_ledger/shared/presentation/money_format.dart';

import '../../domain/entities/budget_entities.dart';
import '../../domain/value_objects/budget_value_objects.dart';
import '../models/budget_ui_models.dart';

/// Translates budget domain summaries into display-ready UI models.
///
/// All `formatMinor` / `formatMinorWithSymbol` / percentage conversions stay
/// here so widgets receive preformatted strings and chart ratios.
class BudgetUiMapper {
  const BudgetUiMapper();

  BudgetScreenUiModel mapScreen(
    MonthBudgetSummary summary, {
    required String currencySymbol,
    required String locale,
  }) {
    final monthFormat = DateFormat.MMM(locale);
    final dayFormat = DateFormat.yMd(locale).add_Hm();

    final totalBudget = summary.totalBudgetMinor;
    final actualRatio = totalBudget > 0
        ? (summary.budgetedActualMinor / totalBudget).clamp(0.0, 1.0)
        : 0.0;
    final totalWithPendingRatio = totalBudget > 0
        ? ((summary.budgetedActualMinor + summary.budgetedPendingMinor) /
                totalBudget)
            .clamp(0.0, 1.0)
        : 0.0;
    final pendingRatio =
        (totalWithPendingRatio - actualRatio).clamp(0.0, 1.0 - actualRatio);

    final complianceDisplay = summary.budgetedCategoryCount > 0
        ? '${summary.inBudgetCount}/${summary.budgetedCategoryCount}'
        : '—';

    final committedBaselineMinor = summary.allSummaries
        .fold<int>(0, (sum, c) => sum + c.committedBaselineMinor);
    final committedActualMinor = summary.allSummaries
        .fold<int>(0, (sum, c) => sum + c.committedActualMinor);
    final discretionaryActualMinor = summary.allSummaries
        .fold<int>(0, (sum, c) => sum + c.discretionaryActualMinor);

    final overview = BudgetOverviewUiModel(
      targetYm: summary.month,
      mode: summary.mode,
      currencyCode: summary.currencyCode,
      currencySymbol: currencySymbol,
      hasAnyAccount: summary.hasAnyActiveAccount,
      hasAnyBudget: summary.hasAnyBudget,
      totalBudgetDisplay:
          formatMinorWithSymbol(summary.totalBudgetMinor, currencySymbol),
      budgetedActualDisplay:
          formatMinorWithSymbol(summary.budgetedActualMinor, currencySymbol),
      budgetedPendingDisplay:
          formatMinorWithSymbol(summary.budgetedPendingMinor, currencySymbol),
      hasBudgetedPending: summary.budgetedPendingMinor > 0,
      projectedRemainingDisplay: formatMinorWithSymbol(
        summary.projectedRemainingMinor.abs(),
        currencySymbol,
      ),
      isProjectedOverBudget: summary.projectedRemainingMinor < 0,
      actualRatio: actualRatio,
      pendingRatio: pendingRatio,
      complianceDisplay: complianceDisplay,
      allExpenseActualDisplay:
          formatMinorWithSymbol(summary.allExpenseActualMinor, currencySymbol),
      unbudgetedActualDisplay:
          formatMinorWithSymbol(summary.unbudgetedActualMinor, currencySymbol),
      hasUnbudgetedSpend: summary.unbudgetedActualMinor > 0,
      committedBaselineDisplay: formatMinorWithSymbol(
        committedBaselineMinor,
        currencySymbol,
      ),
      committedActualDisplay: formatMinorWithSymbol(
        committedActualMinor,
        currencySymbol,
      ),
      discretionaryActualDisplay: formatMinorWithSymbol(
        discretionaryActualMinor,
        currencySymbol,
      ),
      hasLeftoverPendingInReview: summary.hasLeftoverPendingInReview,
      hasHighFrequencyMaterializationHint: summary.hasHighFrequencyPending ||
          summary.isFarFutureMaterializedOnly,
    );

    BudgetCategoryRowUiModel mapCategory(CategoryBudgetSummary c) {
      final budget = c.budgetMinor;
      final catActualRatio = budget != null && budget > 0
          ? (c.actualMinor / budget).clamp(0.0, 1.0)
          : 0.0;
      final catWithPendingRatio = budget != null && budget > 0
          ? ((c.actualMinor + c.pendingMinor) / budget).clamp(0.0, 1.0)
          : 0.0;
      final catPendingRatio = (catWithPendingRatio - catActualRatio)
          .clamp(0.0, 1.0 - catActualRatio);

      final variance = c.variance;
      final varianceDisplay = variance == null
          ? null
          : formatMinorWithSymbol(variance.absMinor, currencySymbol);

      int? anomalyPercent;
      if (c.isAnomaly &&
          c.threeMonthAvgMinor != null &&
          c.threeMonthAvgMinor! > 0) {
        anomalyPercent =
            (((c.actualMinor - c.threeMonthAvgMinor!) / c.threeMonthAvgMinor!) *
                    100)
                .round();
      }

      return BudgetCategoryRowUiModel(
        categoryId: c.categoryId,
        name: c.categoryName,
        iconKey: c.iconKey,
        colorInt: c.colorInt,
        archived: c.isArchived,
        isBudgetEditable: !c.isArchived,
        budgetMinor: c.budgetMinor,
        budgetDisplay: c.budgetMinor == null
            ? null
            : formatMinorWithSymbol(c.budgetMinor!, currencySymbol),
        actualDisplay: formatMinorWithSymbol(c.actualMinor, currencySymbol),
        pendingDisplay: c.pendingMinor > 0
            ? formatMinorWithSymbol(c.pendingMinor, currencySymbol)
            : null,
        varianceDisplay: varianceDisplay,
        isOverBudget: variance?.isOver ?? false,
        committedActualDisplay:
            formatMinorWithSymbol(c.committedActualMinor, currencySymbol),
        discretionaryActualDisplay:
            formatMinorWithSymbol(c.discretionaryActualMinor, currencySymbol),
        committedBaselineDisplay:
            formatMinorWithSymbol(c.committedBaselineMinor, currencySymbol),
        lastMonthActualDisplay: c.lastMonthActualMinor == null
            ? null
            : formatMinorWithSymbol(c.lastMonthActualMinor!, currencySymbol),
        threeMonthAvgDisplay: c.threeMonthAvgMinor == null
            ? null
            : formatMinorWithSymbol(c.threeMonthAvgMinor!, currencySymbol),
        lastMonthActualMinor: c.lastMonthActualMinor,
        threeMonthAvgMinor: c.threeMonthAvgMinor,
        committedBaselineMinor: c.committedBaselineMinor,
        actualProgress: catActualRatio,
        pendingProgress: catPendingRatio,
        riskLevel: c.riskLevel,
        isAnomaly: c.isAnomaly,
        anomalyPercent: anomalyPercent,
        reviewNote: c.reviewNote,
        trend6Months:
            c.sixMonthTrend.map((p) => _mapTrendPoint(p, monthFormat)).toList(),
        topContributions: c.topTransactions
            .map((tx) => _mapContribution(tx, currencySymbol, dayFormat))
            .toList(),
        allContributions: c.contributions
            .map((tx) => _mapContribution(tx, currencySymbol, dayFormat))
            .toList(),
      );
    }

    return BudgetScreenUiModel(
      overview: overview,
      budgetedRows: summary.budgetedCategories.map(mapCategory).toList(),
      unbudgetedActiveRows:
          summary.unbudgetedActiveCategories.map(mapCategory).toList(),
      remainingActiveRows:
          summary.remainingActiveCategories.map(mapCategory).toList(),
      overBudgetTop3: summary.overBudgetTop3
          .map((item) => BudgetAttributionItemUiModel(
                categoryId: item.categoryId,
                name: item.categoryName,
                iconKey: item.iconKey,
                colorInt: item.colorInt,
                deltaDisplay: formatMinorWithSymbol(
                  item.varianceMinor.abs(),
                  currencySymbol,
                ),
                isOver: true,
              ))
          .toList(),
      underBudgetTop3: summary.underBudgetTop3
          .map((item) => BudgetAttributionItemUiModel(
                categoryId: item.categoryId,
                name: item.categoryName,
                iconKey: item.iconKey,
                colorInt: item.colorInt,
                deltaDisplay: formatMinorWithSymbol(
                  item.varianceMinor.abs(),
                  currencySymbol,
                ),
                isOver: false,
              ))
          .toList(),
      unbudgetedAlertsTop3: summary.unbudgetedAlertsTop3
          .map((a) => BudgetUnbudgetedAlertUiModel(
                categoryId: a.categoryId,
                name: a.categoryName,
                iconKey: a.iconKey,
                colorInt: a.colorInt,
                actualDisplay:
                    formatMinorWithSymbol(a.actualMinor, currencySymbol),
                shareDisplay: '${(a.shareOfTotalActual * 100).round()}%',
              ))
          .toList(),
      monthTrend6Months: summary.monthTrend6Months
          .map((p) => _mapTrendPoint(p, monthFormat))
          .toList(),
      monthReviewNote: summary.monthReviewNote,
    );
  }

  BudgetTrendPointUiModel _mapTrendPoint(
    BudgetTrendPoint p,
    DateFormat monthFormat,
  ) {
    return BudgetTrendPointUiModel(
      ym: p.month,
      shortLabel: monthFormat.format(p.month.toDateTime()),
      budgetMinor: p.budgetMinor,
      actualMinor: p.actualMinor,
      budgetChartValue: (p.budgetMinor ?? 0) / 100.0,
      actualChartValue: p.actualMinor / 100.0,
      hasReviewNote: p.hasReviewNote,
    );
  }

  BudgetContributionTxUiModel _mapContribution(
    BudgetContributionTx tx,
    String currencySymbol,
    DateFormat dayFormat,
  ) {
    return BudgetContributionTxUiModel(
      id: tx.transactionId,
      isPending: tx.isPending,
      title: tx.description,
      dateDisplay: dayFormat.format(tx.occurredAt),
      amountDisplay: formatMinorWithSymbol(tx.amountMinor, currencySymbol),
      isCommitted: tx.isCommitted,
      accountName: tx.accountName,
    );
  }
}
