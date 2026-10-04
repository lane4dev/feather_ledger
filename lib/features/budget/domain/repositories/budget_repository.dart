import 'package:feather_ledger/core/data/database/daos/budget_dao.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';

import '../entities/budget_entities.dart';
import '../value_objects/budget_value_objects.dart';

abstract class BudgetRepository {
  Stream<BudgetMonthRawSummary> watchMonthBudgetSummary(
    String currencyCode,
    YearMonth month,
  );

  Stream<BudgetMonthPendingRaw> watchMonthPendingExpenses(
    String currencyCode,
    YearMonth month,
  );

  Stream<CategoryBudgetHint> watchCategoryBudgetHint({
    required String currencyCode,
    required YearMonth month,
    required String categoryId,
  });

  Future<CategoryEntity?> getCategoryById(String categoryId);

  Future<bool> hasFutureRulesAfter({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
  });

  Future<void> upsertBudgetRule({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
    required int? amountMinor,
    required BudgetEditScope scope,
    required DateTime now,
  });

  Future<void> upsertReviewNote({
    required String currencyCode,
    required YearMonth month,
    required String? categoryId,
    required String note,
    required DateTime now,
  });
}
