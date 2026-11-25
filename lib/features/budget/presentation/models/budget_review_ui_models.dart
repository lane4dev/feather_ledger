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

  /// True when a historical month still has unposted scheduled bills, which
  /// the domain excludes from every review figure.
  final bool hasLeftoverPendingBills;

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
    required this.hasLeftoverPendingBills,
    required this.overBudgetTop3,
    required this.underBudgetTop3,
    required this.monthTrend6Months,
    required this.monthReviewNote,
  });

  bool get hasAttribution =>
      overBudgetTop3.isNotEmpty || underBudgetTop3.isNotEmpty;
}
