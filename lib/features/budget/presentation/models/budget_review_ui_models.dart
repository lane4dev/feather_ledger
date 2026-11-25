import 'package:flutter/foundation.dart';

import '../../domain/value_objects/budget_value_objects.dart';
import 'budget_ui_models.dart';

/// Display-ready data for the L2 monthly review page.
///
/// Scope is the whole month: the three headline figures are folded over every
/// category, including unbudgeted ones. [BudgetReviewUiMapper] owns all
/// formatting and chart ratios; the page only lays the values out.
@immutable
class BudgetReviewUiModel {
  final YearMonth month;
  final String monthLabel;

  final String committedActualDisplay;
  final String discretionaryActualDisplay;
  final String committedBaselineDisplay;

  /// Whole-month minor-unit figures behind the two composition labels. The
  /// composition bar proportions them; the card never does the arithmetic.
  final int committedActualMinor;
  final int discretionaryActualMinor;

  /// False only for a historical month whose committed baseline equals its
  /// committed actual with no pending bills left: the bottom line would then
  /// repeat the figure directly above it.
  final bool showBaselineRow;

  final List<BudgetAttributionItemUiModel> overBudgetTop3;
  final List<BudgetAttributionItemUiModel> underBudgetTop3;

  /// Six months of budget and actual, each carrying its own budget for the
  /// chart's ghost columns.
  final List<BudgetTrendPointUiModel> monthTrend6Months;

  final String? monthReviewNote;

  const BudgetReviewUiModel({
    required this.month,
    required this.monthLabel,
    required this.committedActualDisplay,
    required this.discretionaryActualDisplay,
    required this.committedBaselineDisplay,
    required this.committedActualMinor,
    required this.discretionaryActualMinor,
    required this.showBaselineRow,
    required this.overBudgetTop3,
    required this.underBudgetTop3,
    required this.monthTrend6Months,
    required this.monthReviewNote,
  });

  bool get hasAttribution =>
      overBudgetTop3.isNotEmpty || underBudgetTop3.isNotEmpty;
}
