import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/database/app_database.dart';
import 'package:feather_ledger/core/database/daos/transaction_dao.dart';
import 'package:feather_ledger/core/database/tables.dart' as db_tables;
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/reports/domain/reports_entities.dart';

part 'reports_repository.g.dart';

abstract class ReportsRepository {
  Stream<Map<DateTime, int>> watchHeatmapData(DateTime month);
  Stream<List<ReportCategoryTotal>> watchCategoryBreakdown(
      DateTime month, db_tables.TransactionType type);
}

class ReportsRepositoryImpl implements ReportsRepository {
  final TransactionDao _dao;

  ReportsRepositoryImpl(this._dao);

  @override
  Stream<Map<DateTime, int>> watchHeatmapData(DateTime month) {
    return _dao.watchDailyTransactionCounts(month);
  }

  @override
  Stream<List<ReportCategoryTotal>> watchCategoryBreakdown(
      DateTime month, db_tables.TransactionType type) {
    return _dao.watchCategoryTotals(month, type).map((rows) {
      return rows.map((row) {
        return ReportCategoryTotal(
          category: CategoryEntity(
            id: row.category.id,
            name: row.category.name,
            iconKey: row.category.iconKey,
            colorInt: row.category.colorInt,
            type: row.category.type,
            isDefault: row.category.isDefault,
          ),
          total: row.total,
        );
      }).toList();
    });
  }
}

@riverpod
ReportsRepository reportsRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return ReportsRepositoryImpl(db.transactionDao);
}
