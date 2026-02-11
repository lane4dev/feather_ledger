import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/transaction_dao.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';

import '../../domain/entities/reports_entities.dart';
import '../../domain/repositories/reports_repository.dart';

export '../../domain/repositories/reports_repository.dart';

part 'reports_repository.g.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final TransactionsDao _dao;

  ReportsRepositoryImpl(this._dao);

  @override
  Stream<Map<DateTime, int>> watchHeatmapData(DateTime month) {
    // Original implementation was counts, keeping for compatibility if available
    return _dao.watchDailyTransactionAmounts(month);
  }

  @override
  Stream<Map<DateTime, int>> watchHeatmapAmountData(DateTime month) {
    return _dao.watchDailyTransactionAmounts(month);
  }

  @override
  Stream<List<ReportCategoryTotal>> watchCategoryBreakdown(
      DateTime month, TransactionType type) {
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
          total: row.total / 100.0,
        );
      }).toList();
    });
  }
}

@riverpod
ReportsRepository reportsRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return ReportsRepositoryImpl(db.transactionsDao);
}
