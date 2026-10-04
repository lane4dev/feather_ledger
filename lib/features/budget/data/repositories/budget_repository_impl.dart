import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/budget_dao.dart';
import 'package:feather_ledger/core/data/database/daos/categories_dao.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';

import '../../domain/entities/budget_entities.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/value_objects/budget_value_objects.dart';

export '../../domain/repositories/budget_repository.dart';

part 'budget_repository_impl.g.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetDao _budgetDao;
  final CategoriesDao _categoriesDao;

  BudgetRepositoryImpl(this._budgetDao, this._categoriesDao);

  @override
  Stream<BudgetMonthRawSummary> watchMonthBudgetSummary(
    String currencyCode,
    YearMonth month,
  ) {
    return _budgetDao.watchMonthBudgetSummary(currencyCode, month.ym);
  }

  @override
  Stream<BudgetMonthPendingRaw> watchMonthPendingExpenses(
    String currencyCode,
    YearMonth month,
  ) {
    return _budgetDao.watchMonthPendingExpenses(currencyCode, month.ym);
  }

  @override
  Stream<CategoryBudgetHint> watchCategoryBudgetHint({
    required String currencyCode,
    required YearMonth month,
    required String categoryId,
  }) {
    return _budgetDao
        .watchCategoryBudgetHint(currencyCode, month.ym, categoryId)
        .map(
          (raw) => CategoryBudgetHint(
            currencyCode: raw.currencyCode,
            month: YearMonth.fromYm(raw.targetYm),
            categoryId: raw.categoryId,
            isCategoryArchived: raw.isCategoryArchived,
            effectiveBudgetMinor: raw.effectiveBudgetMinor,
            actualMinor: raw.actualMinor,
            pendingMinor: raw.pendingMinor,
          ),
        );
  }

  @override
  Future<CategoryEntity?> getCategoryById(String categoryId) async {
    final row = await _categoriesDao.getCategoryById(categoryId);
    if (row == null) return null;
    return CategoryEntity(
      id: row.id,
      name: row.name,
      iconKey: row.iconKey,
      colorInt: row.colorInt,
      type: row.type,
      archived: row.archived,
      systemCode: row.systemCode,
    );
  }

  @override
  Future<bool> hasFutureRulesAfter({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
  }) {
    return _budgetDao.hasFutureRulesAfter(currencyCode, categoryId, month.ym);
  }

  @override
  Future<void> upsertBudgetRule({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
    required int? amountMinor,
    required BudgetEditScope scope,
    required DateTime now,
  }) {
    return _budgetDao.upsertBudgetRule(
      currencyCode: currencyCode,
      categoryId: categoryId,
      targetYm: month.ym,
      amountMinor: amountMinor,
      thisMonthOnly: scope == BudgetEditScope.thisMonthOnly,
      now: now,
    );
  }

  @override
  Future<void> upsertReviewNote({
    required String currencyCode,
    required YearMonth month,
    required String? categoryId,
    required String note,
    required DateTime now,
  }) {
    return _budgetDao.upsertReviewNote(
      currencyCode: currencyCode,
      ym: month.ym,
      categoryKey: categoryId ?? '',
      note: note,
      now: now,
    );
  }
}

@riverpod
BudgetRepository budgetRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return BudgetRepositoryImpl(db.budgetDao, db.categoriesDao);
}
