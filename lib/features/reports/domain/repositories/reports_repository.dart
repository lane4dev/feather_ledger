import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/money/money.dart';

import '../entities/reports_entities.dart';

abstract class ReportsRepository {
  /// Daily income/expense transaction counts for the month and its preceding
  /// two months. Reversed rows and accounts outside ledger totals are excluded;
  /// one transaction counts once regardless of its number of postings.
  /// [currencyCode] scopes to one ledger currency.
  Stream<Map<DateTime, int>> watchHeatmapFrequencyData(DateTime month,
      {String currencyCode = Money.defaultCurrencyCode});

  /// Daily signed posting impacts in minor units over the same window and
  /// with the same exclusions as [watchHeatmapFrequencyData].
  Stream<Map<DateTime, int>> watchHeatmapAmountData(DateTime month,
      {String currencyCode = Money.defaultCurrencyCode});

  /// Watches the category breakdown for the given month and transaction
  /// type, grouped by the transactions' write-time category snapshots.
  Stream<List<ReportCategoryTotal>> watchCategoryBreakdown(
      DateTime month, CategoryType type,
      {String currencyCode = Money.defaultCurrencyCode});

  /// Watches the monthly income/expense/balance totals read from the
  /// snapshot projection.
  Stream<ReportMonthlyTotals> watchMonthlyTotals(DateTime month,
      {String currencyCode = Money.defaultCurrencyCode});
}
