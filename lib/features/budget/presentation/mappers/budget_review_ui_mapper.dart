import 'package:intl/intl.dart';

import 'package:feather_ledger/shared/presentation/money_format.dart';

import '../../domain/entities/budget_entities.dart';
import '../../domain/value_objects/budget_value_objects.dart';
import '../models/budget_review_ui_models.dart';
import '../models/budget_ui_models.dart';

/// Translates the domain month summary into the L2 review page model.
///
/// The whole-month figures fold every category summary so unbudgeted spend is
/// included. Attribution lists keep the domain ordering (over: largest overrun
/// first, under: largest surplus first) and only add formatted deltas.
class BudgetReviewUiMapper {
  const BudgetReviewUiMapper();

  BudgetReviewUiModel map(
    MonthBudgetSummary summary, {
    required String currencySymbol,
    required String locale,
    DateTime? today,
  }) {
    final todayMonth = today == null ? null : YearMonth.fromDate(today);
    final monthFormat = DateFormat.yMMMM(locale);
    final shortMonthFormat = DateFormat.MMM(locale);

    var committedActualMinor = 0;
    var discretionaryActualMinor = 0;
    var committedBaselineMinor = 0;
    for (final category in summary.allSummaries) {
      committedActualMinor += category.committedActualMinor;
      discretionaryActualMinor += category.discretionaryActualMinor;
      committedBaselineMinor += category.committedBaselineMinor;
    }

    return BudgetReviewUiModel(
      month: summary.month,
      monthLabel: monthFormat.format(summary.month.toDateTime()),
      committedActualDisplay:
          formatMinorWithSymbol(committedActualMinor, currencySymbol),
      discretionaryActualDisplay:
          formatMinorWithSymbol(discretionaryActualMinor, currencySymbol),
      committedBaselineDisplay:
          formatMinorWithSymbol(committedBaselineMinor, currencySymbol),
      hasLeftoverPendingBills: summary.hasLeftoverPendingInReview,
      overBudgetTop3: summary.overBudgetTop3
          .map((item) => _mapAttribution(item, currencySymbol, isOver: true))
          .toList(growable: false),
      underBudgetTop3: summary.underBudgetTop3
          .map((item) => _mapAttribution(item, currencySymbol, isOver: false))
          .toList(growable: false),
      monthTrend6Months: summary.monthTrend6Months
          .map((point) => _mapTrendPoint(point, shortMonthFormat, todayMonth))
          .toList(growable: false),
      monthReviewNote: _normalizedNote(summary.monthReviewNote),
    );
  }

  BudgetAttributionItemUiModel _mapAttribution(
    BudgetAttributionItem item,
    String currencySymbol, {
    required bool isOver,
  }) {
    return BudgetAttributionItemUiModel(
      categoryId: item.categoryId,
      name: item.categoryName,
      iconKey: item.iconKey,
      colorInt: item.colorInt,
      deltaDisplay: formatMinorWithSymbol(
        item.varianceMinor.abs(),
        currencySymbol,
      ),
      isOver: isOver,
    );
  }

  BudgetTrendPointUiModel _mapTrendPoint(
    BudgetTrendPoint point,
    DateFormat monthFormat,
    YearMonth? todayMonth,
  ) {
    return BudgetTrendPointUiModel(
      ym: point.month,
      shortLabel: monthFormat.format(point.month.toDateTime()),
      budgetMinor: point.budgetMinor,
      actualMinor: point.actualMinor,
      budgetChartValue: (point.budgetMinor ?? 0) / 100.0,
      actualChartValue: point.actualMinor / 100.0,
      hasReviewNote: point.hasReviewNote,
      isFuture: todayMonth != null && point.month > todayMonth,
    );
  }

  String? _normalizedNote(String? note) {
    final trimmed = note?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
