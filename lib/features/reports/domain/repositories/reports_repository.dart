import 'package:feather_ledger/core/domain/entities/enums.dart';

import '../entities/reports_entities.dart';

abstract class ReportsRepository {
  Stream<Map<DateTime, int>> watchHeatmapData(DateTime month);
  Stream<Map<DateTime, int>> watchHeatmapAmountData(DateTime month);
  Stream<List<ReportCategoryTotal>> watchCategoryBreakdown(
      DateTime month, TransactionType type); // Removed prefix
}
