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
    final dayFormat = DateFormat.Md(locale).add_Hm();
    final monthDisplay =
        DateFormat.yMMMM(locale).format(summary.month.toDateTime());
    final todayMonth = today == null ? null : YearMonth.fromDate(today);

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
        : _placeholder;

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

    // A share of nothing has no answer; `—` says so instead of `0%`.
    final sharePercent = totalBudget > 0
        ? '${(budgetedBaselineMinor / totalBudget * 100).round()}%'
        : _placeholder;
    // Usage is deliberately uncapped: a month that spent 150% of its budget
    // should be readable as such, the bar being full is the geometric half.
    final usagePercent = totalBudget > 0
        ? '${(summary.budgetedActualMinor / totalBudget * 100).round()}%'
        : _placeholder;

    final budgetedBaselineDisplay =
        formatMinorWithSymbol(budgetedBaselineMinor, currencySymbol);
    final remainingBudgetDisplay =
        formatMinorWithSymbol(summary.totalBudgetMinor, currencySymbol);
    final budgetValueDisplay =
        summary.hasAnyBudget ? remainingBudgetDisplay : _placeholder;

    // Each mode is one row of this table: the hero's amount with its label, and
    // the three footer columns. One switch keeps a mode's hero from drifting
    // away from the footer that explains it. The main amount is the one number
    // each mode exists to show: what is left after what is spent and billed
    // (track), what the closed month ended with (review), and what the budget
    // has not been pinned down by (plan).
    final readings = switch (summary.mode) {
      BudgetMode.track => (
          mainMinor: summary.projectedRemainingMinor,
          label: summary.projectedRemainingMinor < 0
              ? BudgetOverviewMainLabel.projectedOver
              : BudgetOverviewMainLabel.projectedRemaining,
          footer: [
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
        ),
      BudgetMode.review => (
          mainMinor: summary.budgetedRemainingActualMinor,
          label: summary.budgetedRemainingActualMinor < 0
              ? BudgetOverviewMainLabel.monthlyOverspend
              : BudgetOverviewMainLabel.monthlySurplus,
          footer: [
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
        ),
      BudgetMode.plan => (
          mainMinor: summary.totalBudgetMinor - budgetedBaselineMinor,
          label: BudgetOverviewMainLabel.availableToSpend,
          footer: [
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
        ),
    };

    final mainMinor = readings.mainMinor;
    final mainLabel = readings.label;

    final baselineRatio = totalBudget > 0
        ? (budgetedBaselineMinor / totalBudget).clamp(0.0, 1.0)
        : 0.0;

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
      hasCommittedBaseline: committedBaselineMinor > 0,
      committedActualDisplay: formatMinorWithSymbol(
        committedActualMinor,
        currencySymbol,
      ),
      discretionaryActualDisplay: formatMinorWithSymbol(
        discretionaryActualMinor,
        currencySymbol,
      ),
      hasLeftoverPendingInReview: summary.hasLeftoverPendingInReview,
      mainLabel: mainLabel,
      mainAmount: BalanceDisplayParts.parse(
        summary.hasAnyBudget
            ? formatMinorWithSymbol(mainMinor, currencySymbol)
            : _placeholder,
      ),
      isMainAmountNegative: summary.hasAnyBudget && mainMinor < 0,
      footerMetrics: readings.footer,
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
      final catActualRatio =
          hasLimit ? (c.actualMinor / limit).clamp(0.0, 1.0) : 0.0;
      final catWithPendingRatio = hasLimit
          ? ((c.actualMinor + c.pendingMinor) / limit).clamp(0.0, 1.0)
          : 0.0;
      // A closed month has nothing left to arrive, so review rows never carry
      // a pending segment even if the summary still holds one.
      final catPendingRatio = mode == BudgetMode.review
          ? 0.0
          : (catWithPendingRatio - catActualRatio)
              .clamp(0.0, 1.0 - catActualRatio);

      final contributions = c.contributions;
      var pendingContributionsMinor = 0;
      var postedContributionsMinor = 0;
      for (final tx in contributions) {
        final amount = tx.amountMinor.abs();
        if (tx.isPending) {
          pendingContributionsMinor += amount;
        } else {
          postedContributionsMinor += amount;
        }
      }

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
      var mainAmountTone = BudgetCategoryAmountTone.neutral;
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
        mainAmountDisplay =
            formatMinorWithSymbol(c.actualMinor, currencySymbol);
      } else {
        final readings = _rowSemantics(c, mode);
        amountLabel = readings.label;
        mainAmountDisplay =
            formatMinorWithSymbol(readings.amountMinor, currencySymbol);
        isMainAmountNegative = readings.negative;
        mainAmountTone = readings.tone;
        subtitleKind = readings.subtitle;
        baselineProgress = readings.baselineProgress;
        final subtitleAmountMinor = readings.subtitleAmountMinor;
        if (subtitleAmountMinor != null) {
          subtitleAmountDisplay =
              formatMinorWithSymbol(subtitleAmountMinor, currencySymbol);
        }
        final subtitlePercent = readings.subtitlePercent;
        if (subtitlePercent != null) {
          subtitlePercentDisplay = '$subtitlePercent%';
        }
        final referenceMinor = readings.referenceMinor;
        if (referenceMinor != null) {
          subtitleReferenceDisplay =
              formatMinorWithSymbol(referenceMinor, currencySymbol);
        }
      }

      return BudgetCategoryRowUiModel(
        categoryId: c.categoryId,
        name: c.categoryName,
        titleDisplay: '${c.categoryName} · $monthDisplay',
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
        committedShare: c.actualMinor > 0
            ? (c.committedActualMinor / c.actualMinor).clamp(0.0, 1.0)
            : 0.0,
        hasActualSpend: c.actualMinor > 0,
        threeMonthAvgChartValue: _chartValue(c.threeMonthAvgMinor),
        budgetChartValue: hasLimit ? limit / 100.0 : null,
        actualProgress: catActualRatio,
        pendingProgress: catPendingRatio,
        riskLevel: c.riskLevel,
        isAnomaly: c.isAnomaly,
        anomalyPercent: anomalyPercent,
        reviewNote: c.reviewNote,
        trend6Months: c.sixMonthTrend
            .map((p) =>
                _mapTrendPoint(p, monthFormat, todayMonth, currencySymbol))
            .toList(),
        topContributions: c.topTransactions
            .map((tx) => _mapContribution(tx, currencySymbol, dayFormat))
            .toList(),
        allContributions: contributions
            .map((tx) => _mapContribution(tx, currencySymbol, dayFormat))
            .toList(),
        contributionsTotalDisplay: formatMinorWithSymbol(
          pendingContributionsMinor + postedContributionsMinor,
          currencySymbol,
        ),
        pendingContributionsTotalDisplay:
            formatMinorWithSymbol(pendingContributionsMinor, currencySymbol),
        postedContributionsTotalDisplay:
            formatMinorWithSymbol(postedContributionsMinor, currencySymbol),
        mode: mode,
        amountLabel: amountLabel,
        mainAmountDisplay: mainAmountDisplay,
        isMainAmountNegative: isMainAmountNegative,
        mainAmountTone: mainAmountTone,
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
      monthDisplay: monthDisplay,
      budgetedRows: summary.budgetedCategories
          .map((c) => mapCategory(c, _CategoryGroup.budgeted))
          .toList(),
      unbudgetedActiveRows: unbudgetedActive
          .map((c) => mapCategory(c, _CategoryGroup.unbudgetedActive))
          .toList(),
      remainingActiveRows:
          _sortRemainingBySpend(summary.remainingActiveCategories)
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
      monthTrend6Months: summary.monthTrend6Months
          .map(
              (p) => _mapTrendPoint(p, monthFormat, todayMonth, currencySymbol))
          .toList(),
      monthReviewNote: summary.monthReviewNote,
    );
  }

  BudgetTrendPointUiModel _mapTrendPoint(
    BudgetTrendPoint p,
    DateFormat monthFormat,
    YearMonth? todayMonth,
    String currencySymbol,
  ) {
    final budgetMinor = p.budgetMinor;
    return BudgetTrendPointUiModel(
      ym: p.month,
      shortLabel: monthFormat.format(p.month.toDateTime()),
      budgetMinor: budgetMinor,
      actualMinor: p.actualMinor,
      budgetChartValue: (budgetMinor ?? 0) / 100.0,
      actualChartValue: p.actualMinor / 100.0,
      budgetDisplay: budgetMinor == null
          ? null
          : formatMinorWithSymbol(budgetMinor, currencySymbol),
      actualDisplay: formatMinorWithSymbol(p.actualMinor, currencySymbol),
      hasReviewNote: p.hasReviewNote,
      isFuture: todayMonth != null && p.month > todayMonth,
    );
  }

  /// Major units for a chart axis, or null when there is nothing to plot.
  /// The only division by 100 outside the domain is this bridge.
  double? _chartValue(int? minor) =>
      minor != null && minor > 0 ? minor / 100.0 : null;

  /// The one place a month phase's row semantics live: what the right-hand
  /// amount measures, how it is signed, and what the second line says. Keeping
  /// one arm per mode means a mode's amount and its own subtitle cannot drift.
  _RowSemantics _rowSemantics(CategoryBudgetSummary c, BudgetMode mode) {
    final limit = c.budgetMinor!;
    switch (mode) {
      case BudgetMode.plan:
        // A zero baseline is not a fact worth a line: fall back to the
        // three-month average when there is one, and say nothing otherwise.
        final baseline = c.committedBaselineMinor;
        final average = c.threeMonthAvgMinor;
        return _RowSemantics(
          label: BudgetCategoryAmountLabel.planBudget,
          amountMinor: limit,
          tone: BudgetCategoryAmountTone.neutral,
          subtitle: baseline > 0
              ? BudgetCategorySubtitle.baseline
              : average != null && average > 0
                  ? BudgetCategorySubtitle.average
                  : BudgetCategorySubtitle.none,
          subtitleAmountMinor: baseline > 0
              ? baseline
              : average != null && average > 0
                  ? average
                  : null,
          referenceMinor:
              baseline > 0 && average != null && average > 0 ? average : null,
          baselineProgress: (c.committedBaselineMinor / limit).clamp(0.0, 1.0),
        );
      case BudgetMode.review:
        // A closed month has no bills left to arrive: pending is not its story.
        final usagePercent = (c.actualMinor * 100 / limit).round();
        if (c.actualMinor > limit) {
          return _RowSemantics(
            label: BudgetCategoryAmountLabel.reviewOver,
            amountMinor: c.actualMinor - limit,
            negative: true,
            tone: BudgetCategoryAmountTone.negative,
            subtitle: BudgetCategorySubtitle.usage,
            subtitlePercent: usagePercent,
          );
        }
        return _RowSemantics(
          label: BudgetCategoryAmountLabel.reviewRemaining,
          amountMinor: limit - c.actualMinor,
          tone: BudgetCategoryAmountTone.positive,
          subtitle: BudgetCategorySubtitle.usage,
          subtitlePercent: usagePercent,
        );
      case BudgetMode.track:
        final committed = c.actualMinor + c.pendingMinor;
        final over = c.actualMinor > limit;
        final projectedOver = !over && committed > limit;
        return _RowSemantics(
          label: over
              ? BudgetCategoryAmountLabel.over
              : projectedOver
                  ? BudgetCategoryAmountLabel.projectedOver
                  : c.pendingMinor > 0
                      ? BudgetCategoryAmountLabel.projectedRemaining
                      : BudgetCategoryAmountLabel.remaining,
          amountMinor: over
              ? c.actualMinor - limit
              : projectedOver
                  ? committed - limit
                  : limit - committed,
          negative: over || projectedOver,
          tone: over
              ? BudgetCategoryAmountTone.negative
              : projectedOver
                  ? BudgetCategoryAmountTone.warning
                  : BudgetCategoryAmountTone.positive,
          subtitle: c.pendingMinor > 0
              ? BudgetCategorySubtitle.pendingIncluded
              : BudgetCategorySubtitle.usage,
          subtitleAmountMinor: c.pendingMinor > 0 ? c.pendingMinor : null,
          subtitlePercent:
              c.pendingMinor > 0 ? null : (c.actualMinor * 100 / limit).round(),
        );
    }
  }

  BudgetContributionTxUiModel _mapContribution(
    BudgetContributionTx tx,
    String currencySymbol,
    DateFormat dayFormat,
  ) {
    return BudgetContributionTxUiModel(
      id: tx.transactionId,
      isPending: tx.isPending,
      seriesId: tx.seriesId,
      occurrenceKey: tx.occurrenceKey,
      isVirtual: tx.isVirtual,
      title: tx.description,
      dateDisplay: dayFormat.format(tx.occurredAt),
      amountDisplay:
          formatMinorWithSymbol(-tx.amountMinor.abs(), currencySymbol),
      amountMinor: tx.amountMinor.abs(),
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

/// How a category row reads in one month phase.
class _RowSemantics {
  const _RowSemantics({
    required this.label,
    required this.amountMinor,
    this.negative = false,
    this.tone = BudgetCategoryAmountTone.neutral,
    required this.subtitle,
    this.subtitleAmountMinor,
    this.subtitlePercent,
    this.referenceMinor,
    this.baselineProgress = 0,
  });

  final BudgetCategoryAmountLabel label;
  final int amountMinor;
  final bool negative;
  final BudgetCategoryAmountTone tone;
  final BudgetCategorySubtitle subtitle;
  final int? subtitleAmountMinor;
  final int? subtitlePercent;
  final int? referenceMinor;
  final double baselineProgress;
}

/// Stands in for a figure that has no answer, e.g. a share of a month with no
/// budget. One spelling so the placeholders cannot drift apart.
const _placeholder = '—';

/// The "+" drawer lists untouched categories by what the month already spent
/// there: a category that has spending is the one most likely to need a limit.
/// Ties — and categories with nothing spent — keep the summary's order.
List<CategoryBudgetSummary> _sortRemainingBySpend(
  List<CategoryBudgetSummary> categories,
) {
  final indexed = categories.indexed.toList(growable: false)
    ..sort((a, b) {
      final bySpend = b.$2.actualMinor.compareTo(a.$2.actualMinor);
      return bySpend != 0 ? bySpend : a.$1.compareTo(b.$1);
    });
  return [for (final (_, category) in indexed) category];
}
