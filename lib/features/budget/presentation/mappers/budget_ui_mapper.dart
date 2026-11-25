import 'package:intl/intl.dart';

import 'package:feather_ledger/shared/presentation/models/balance_display_parts.dart';
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
    DateTime? today,
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

    // The plan card answers "how much is still free to allocate", so its
    // baseline is the *budgeted* categories' alone: what an unbudgeted
    // category has committed is not money the budget has spoken for yet.
    final budgetedBaselineMinor = summary.budgetedCategories
        .fold<int>(0, (sum, c) => sum + c.committedBaselineMinor);

    // The main amount is the one number each mode exists to show: what is left
    // after what is spent and billed (track), what the closed month ended with
    // (review), and what the budget has not been pinned down by (plan).
    final mainMinor = switch (summary.mode) {
      BudgetMode.track => summary.projectedRemainingMinor,
      BudgetMode.review => summary.budgetedRemainingActualMinor,
      BudgetMode.plan => summary.totalBudgetMinor - budgetedBaselineMinor,
    };

    final mainLabel = switch (summary.mode) {
      BudgetMode.track => mainMinor < 0
          ? BudgetOverviewMainLabel.projectedOver
          : BudgetOverviewMainLabel.projectedRemaining,
      BudgetMode.review => mainMinor < 0
          ? BudgetOverviewMainLabel.monthlyOverspend
          : BudgetOverviewMainLabel.monthlySurplus,
      BudgetMode.plan => BudgetOverviewMainLabel.availableToSpend,
    };

    final baselineRatio = totalBudget > 0
        ? (budgetedBaselineMinor / totalBudget).clamp(0.0, 1.0)
        : 0.0;

    // A share of nothing has no answer; `—` says so instead of `0%`.
    final sharePercent = totalBudget > 0
        ? '${(budgetedBaselineMinor / totalBudget * 100).round()}%'
        : '—';
    // Usage is deliberately uncapped: a month that spent 150% of its budget
    // should be readable as such, the bar being full is the geometric half.
    final usagePercent = totalBudget > 0
        ? '${(summary.budgetedActualMinor / totalBudget * 100).round()}%'
        : '—';

    final budgetedBaselineDisplay =
        formatMinorWithSymbol(budgetedBaselineMinor, currencySymbol);
    final remainingBudgetDisplay =
        formatMinorWithSymbol(summary.totalBudgetMinor, currencySymbol);
    final budgetValueDisplay =
        summary.hasAnyBudget ? remainingBudgetDisplay : '—';

    final footerMetrics = switch (summary.mode) {
      BudgetMode.track => [
          BudgetOverviewMetricUiModel(
            metric: BudgetOverviewMetric.spent,
            value: formatMinorWithSymbol(
              summary.budgetedActualMinor,
              currencySymbol,
            ),
          ),
          BudgetOverviewMetricUiModel(
            metric: BudgetOverviewMetric.pending,
            value: formatMinorWithSymbol(
              summary.budgetedPendingMinor,
              currencySymbol,
            ),
            tone: BudgetOverviewMetricTone.pending,
          ),
          BudgetOverviewMetricUiModel(
            metric: BudgetOverviewMetric.totalBudget,
            value: budgetValueDisplay,
          ),
        ],
      BudgetMode.review => [
          BudgetOverviewMetricUiModel(
            metric: BudgetOverviewMetric.spent,
            value: formatMinorWithSymbol(
              summary.budgetedActualMinor,
              currencySymbol,
            ),
          ),
          BudgetOverviewMetricUiModel(
            metric: BudgetOverviewMetric.budgetUsage,
            value: usagePercent,
          ),
          BudgetOverviewMetricUiModel(
            metric: BudgetOverviewMetric.totalBudget,
            value: budgetValueDisplay,
          ),
        ],
      BudgetMode.plan => [
          BudgetOverviewMetricUiModel(
            metric: BudgetOverviewMetric.committedBaseline,
            value: budgetedBaselineDisplay,
          ),
          BudgetOverviewMetricUiModel(
            metric: BudgetOverviewMetric.baselineShare,
            value: sharePercent,
          ),
          BudgetOverviewMetricUiModel(
            metric: BudgetOverviewMetric.totalBudget,
            value: budgetValueDisplay,
          ),
        ],
    };

    // Today's position on the bar only means something in the month that
    // contains it; other months get no tick at all.
    final todayTickRatio =
        today != null && YearMonth.fromDate(today) == summary.month
            ? (today.day / DateTime(today.year, today.month + 1, 0).day)
                .clamp(0.0, 1.0)
            : null;

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
      mainLabel: mainLabel,
      mainAmount: BalanceDisplayParts.parse(
        summary.hasAnyBudget
            ? formatMinorWithSymbol(mainMinor, currencySymbol)
            : '—',
      ),
      isMainAmountNegative: summary.hasAnyBudget && mainMinor < 0,
      footerMetrics: footerMetrics,
      fixedBaselineRatio: baselineRatio,
      hasFixedBaseline: budgetedBaselineMinor > 0,
      todayTickRatio: todayTickRatio,
    );

    // The unbudgeted group's header comes from the rows it sits above, so the
    // total can never disagree with what it heads.
    final unbudgetedActive = summary.unbudgetedActiveCategories;
    final unbudgetedActual = unbudgetedActive.fold<int>(
      0,
      (sum, c) => sum + c.actualMinor,
    );
    final unbudgetedPending = unbudgetedActive.fold<int>(
      0,
      (sum, c) => sum + c.pendingMinor,
    );
    final unbudgetedGroup = unbudgetedActive.isEmpty
        ? null
        : BudgetUnbudgetedGroupUiModel(
            isPendingOnly: unbudgetedActual == 0,
            amountDisplay: formatMinorWithSymbol(
              unbudgetedActual > 0 ? unbudgetedActual : unbudgetedPending,
              currencySymbol,
            ),
          );

    BudgetCategoryRowUiModel mapCategory(
      CategoryBudgetSummary c,
      _CategoryGroup group,
    ) {
      final budget = c.budgetMinor;
      final hasLimit = budget != null && budget > 0;
      final limit = budget ?? 0;
      final mode = summary.mode;
      final catActualRatio = hasLimit
          ? (c.actualMinor / limit).clamp(0.0, 1.0)
          : 0.0;
      final catWithPendingRatio = hasLimit
          ? ((c.actualMinor + c.pendingMinor) / limit).clamp(0.0, 1.0)
          : 0.0;
      // A closed month has nothing left to arrive, so review rows never carry
      // a pending segment even if the summary still holds one.
      final catPendingRatio = mode == BudgetMode.review
          ? 0.0
          : (catWithPendingRatio - catActualRatio)
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

      var amountLabel = BudgetCategoryAmountLabel.none;
      var isMainAmountNegative = false;
      String? mainAmountDisplay;
      var subtitleKind = BudgetCategorySubtitle.none;
      String? subtitleAmountDisplay;
      String? subtitleReferenceDisplay;
      String? subtitlePercentDisplay;
      String? sharePercentDisplay;
      var baselineProgress = 0.0;

      if (group == _CategoryGroup.unbudgetedActive) {
        // No limit to measure against: the row's own spend is the answer, and
        // a billed-but-unposted amount is named rather than coloured.
        mainAmountDisplay = formatMinorWithSymbol(
          c.actualMinor > 0 ? c.actualMinor : c.pendingMinor,
          currencySymbol,
        );
        if (c.pendingMinor > 0) {
          subtitleKind = BudgetCategorySubtitle.pending;
          subtitleAmountDisplay =
              formatMinorWithSymbol(c.pendingMinor, currencySymbol);
        }
        final monthTotal = summary.allExpenseActualMinor;
        // Compared before any rounding: 5% exactly qualifies, 4.99% does not.
        if (c.actualMinor > 0 &&
            monthTotal > 0 &&
            c.actualMinor * 100 >= monthTotal * 5) {
          sharePercentDisplay =
              '${(c.actualMinor * 100 / monthTotal).round()}%';
        }
      } else if (!hasLimit) {
        mainAmountDisplay = formatMinorWithSymbol(c.actualMinor, currencySymbol);
      } else if (mode == BudgetMode.plan) {
        amountLabel = BudgetCategoryAmountLabel.planBudget;
        mainAmountDisplay = formatMinorWithSymbol(limit, currencySymbol);
        subtitleKind = BudgetCategorySubtitle.baseline;
        subtitleAmountDisplay = formatMinorWithSymbol(
          c.committedBaselineMinor,
          currencySymbol,
        );
        final average = c.threeMonthAvgMinor;
        if (average != null && average > 0) {
          subtitleReferenceDisplay =
              formatMinorWithSymbol(average, currencySymbol);
        }
        baselineProgress =
            (c.committedBaselineMinor / limit).clamp(0.0, 1.0);
      } else if (mode == BudgetMode.review) {
        // A closed month has no bills left to arrive: pending is not its story.
        if (c.actualMinor > limit) {
          amountLabel = BudgetCategoryAmountLabel.reviewOver;
          mainAmountDisplay =
              formatMinorWithSymbol(c.actualMinor - limit, currencySymbol);
          isMainAmountNegative = true;
        } else {
          amountLabel = BudgetCategoryAmountLabel.reviewRemaining;
          mainAmountDisplay =
              formatMinorWithSymbol(limit - c.actualMinor, currencySymbol);
        }
        subtitleKind = BudgetCategorySubtitle.usage;
        subtitlePercentDisplay =
            '${(c.actualMinor * 100 / limit).round()}%';
      } else {
        final committed = c.actualMinor + c.pendingMinor;
        if (c.actualMinor > limit) {
          amountLabel = BudgetCategoryAmountLabel.over;
          mainAmountDisplay =
              formatMinorWithSymbol(c.actualMinor - limit, currencySymbol);
          isMainAmountNegative = true;
        } else if (committed > limit) {
          amountLabel = BudgetCategoryAmountLabel.projectedOver;
          mainAmountDisplay =
              formatMinorWithSymbol(committed - limit, currencySymbol);
          isMainAmountNegative = true;
        } else {
          amountLabel = BudgetCategoryAmountLabel.remaining;
          mainAmountDisplay =
              formatMinorWithSymbol(limit - committed, currencySymbol);
        }
        if (c.pendingMinor > 0) {
          subtitleKind = BudgetCategorySubtitle.pendingIncluded;
          subtitleAmountDisplay =
              formatMinorWithSymbol(c.pendingMinor, currencySymbol);
        } else {
          subtitleKind = BudgetCategorySubtitle.usage;
          subtitlePercentDisplay =
              '${(c.actualMinor * 100 / limit).round()}%';
        }
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
        mode: mode,
        amountLabel: amountLabel,
        mainAmountDisplay: mainAmountDisplay,
        isMainAmountNegative: isMainAmountNegative,
        secondaryAmountDisplay: hasLimit && mode != BudgetMode.plan
            ? '${formatMinorWithSymbol(c.actualMinor, currencySymbol)} / '
                '${formatMinorWithSymbol(limit, currencySymbol)}'
            : null,
        subtitleKind: subtitleKind,
        subtitleAmountDisplay: subtitleAmountDisplay,
        subtitleReferenceDisplay: subtitleReferenceDisplay,
        subtitlePercentDisplay: subtitlePercentDisplay,
        sharePercentDisplay: sharePercentDisplay,
        baselineProgress: baselineProgress,
        unbudgetedGroup:
            group == _CategoryGroup.unbudgetedActive ? unbudgetedGroup : null,
      );
    }

    return BudgetScreenUiModel(
      overview: overview,
      budgetedRows: summary.budgetedCategories
          .map((c) => mapCategory(c, _CategoryGroup.budgeted))
          .toList(),
      unbudgetedActiveRows: unbudgetedActive
          .map((c) => mapCategory(c, _CategoryGroup.unbudgetedActive))
          .toList(),
      remainingActiveRows: summary.remainingActiveCategories
          .map((c) => mapCategory(c, _CategoryGroup.remaining))
          .toList(),
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
      amountDisplay:
          formatMinorWithSymbol(-tx.amountMinor.abs(), currencySymbol),
      isCommitted: tx.isCommitted,
      accountName: tx.accountName,
    );
  }
}

/// Which of the screen's three category lists a row was mapped for.
///
/// The lists answer different questions — budgeted, active without a limit,
/// and untouched — so the same category summary turns into a different row
/// depending on which one it lands in.
enum _CategoryGroup { budgeted, unbudgetedActive, remaining }
