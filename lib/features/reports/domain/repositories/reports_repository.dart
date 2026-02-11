import 'package:feather_ledger/core/domain/enums.dart';

import '../entities/reports_entities.dart';

abstract class ReportsRepository {
  /// Watches heatmap data for the given month.
  /// [month] should be any date within the desired month.
  /// Returns a stream of maps where the key is the date and the value is the count.
  Stream<Map<DateTime, int>> watchHeatmapData(DateTime month);

  /// Watches heatmap amount data for the given month.
  /// [month] should be any date within the desired month.
  /// Returns a stream of maps where the key is the date and the value is the total amount.
  Stream<Map<DateTime, int>> watchHeatmapAmountData(DateTime month);

  /// Watches category breakdown for the given month and transaction type.
  /// [month] should be any date within the desired month.
  /// [type] specifies whether to fetch income or expense categories.
  Stream<List<ReportCategoryTotal>> watchCategoryBreakdown(
      DateTime month, TransactionType type); // Removed prefix
}
