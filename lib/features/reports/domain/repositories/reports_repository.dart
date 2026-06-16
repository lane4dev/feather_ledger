import 'package:feather_ledger/core/domain/enums.dart';

import '../entities/reports_entities.dart';

abstract class ReportsRepository {
  /// Watches heatmap data for the given month.
  /// [month] should be any date within the desired month.
  /// Returns a stream of maps where the key is the date and the value is the
  /// signed posting impact in minor units (transfers and reversed rows
  /// excluded).
  Stream<Map<DateTime, int>> watchHeatmapData(DateTime month);

  /// Watches heatmap amount data for the given month — same projection
  /// source as [watchHeatmapData].
  Stream<Map<DateTime, int>> watchHeatmapAmountData(DateTime month);

  /// Watches the category breakdown for the given month and transaction
  /// type, grouped by the transactions' write-time category snapshots.
  Stream<List<ReportCategoryTotal>> watchCategoryBreakdown(
      DateTime month, CategoryType type);

  /// Watches the monthly income/expense/balance totals read from the
  /// snapshot projection.
  Stream<ReportMonthlyTotals> watchMonthlyTotals(DateTime month,
      {String currencyCode = 'USD'});
}
