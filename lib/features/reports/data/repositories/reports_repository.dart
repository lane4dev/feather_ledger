import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/reports_dao.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/money/money.dart';

import '../../domain/entities/reports_entities.dart';
import '../../domain/repositories/reports_repository.dart';

export '../../domain/repositories/reports_repository.dart';

part 'reports_repository.g.dart';

/// Report reads go through the snapshot and projection DAOs only (spec 003,
/// US9/T064): no live category joins, no double totals, no independent
/// balance arithmetic.
class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsDao _dao;

  ReportsRepositoryImpl(this._dao);

  @override
  Stream<Map<DateTime, int>> watchHeatmapFrequencyData(DateTime month,
      {String currencyCode = Money.defaultCurrencyCode}) {
    return _dao.watchDailyTransactionCounts(month,
        currencyCode: currencyCode);
  }

  @override
  Stream<Map<DateTime, int>> watchHeatmapAmountData(DateTime month,
      {String currencyCode = Money.defaultCurrencyCode}) {
    return _dao.watchDailyTransactionAmounts(month,
        currencyCode: currencyCode);
  }

  @override
  Stream<List<ReportCategoryTotal>> watchCategoryBreakdown(
      DateTime month, CategoryType type,
      {String currencyCode = Money.defaultCurrencyCode}) {
    return _dao
        .watchCategoryBreakdown(month, type, currencyCode: currencyCode)
        .map((rows) {
      return rows.map((row) {
        return ReportCategoryTotal(
          // Write-time snapshot: history keeps rendering archived (or
          // renamed) categories exactly as recorded.
          category: CategoryEntity(
            id: row.categoryId,
            name: row.name,
            iconKey: row.iconKey,
            colorInt: int.parse(row.colorHex, radix: 16),
            type: type,
          ),
          totalMinor: row.totalMinor,
        );
      }).toList();
    });
  }

  @override
  Stream<ReportMonthlyTotals> watchMonthlyTotals(DateTime month,
      {String currencyCode = Money.defaultCurrencyCode}) {
    return _dao
        .watchMonthlyTotals(month, currencyCode: currencyCode)
        .map((row) => ReportMonthlyTotals(
              incomeMinor: row.incomeMinor,
              expenseMinor: row.expenseMinor,
              balanceMinor: row.balanceMinor,
            ));
  }
}

@riverpod
ReportsRepository reportsRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return ReportsRepositoryImpl(db.reportsDao);
}
