import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/result/result.dart';

import '../../data/repositories/budget_repository_impl.dart';
import '../commands/clear_category_budget_command.dart';
import '../commands/save_review_note_command.dart';
import '../commands/set_category_budget_command.dart';
import '../entities/budget_entities.dart';
import '../queries/watch_month_budget_query.dart';
import '../queries/watch_transaction_budget_hint_query.dart';
import '../value_objects/budget_value_objects.dart';

part 'budget_service.g.dart';

class BudgetService {
  final SetCategoryBudgetCommand _setBudget;
  final ClearCategoryBudgetCommand _clearBudget;
  final SaveReviewNoteCommand _saveReviewNote;
  final WatchMonthBudgetQuery _watchMonthBudget;
  final WatchTransactionBudgetHintQuery _watchHint;
  final BudgetRepository _repository;

  BudgetService(
    this._setBudget,
    this._clearBudget,
    this._saveReviewNote,
    this._watchMonthBudget,
    this._watchHint,
    this._repository,
  );

  Stream<MonthBudgetSummary> watchMonthBudget({
    required String currencyCode,
    required YearMonth month,
  }) {
    return _watchMonthBudget.execute(currencyCode: currencyCode, month: month);
  }

  Stream<CategoryBudgetHint> watchTransactionBudgetHint({
    required String currencyCode,
    required YearMonth month,
    required String categoryId,
  }) {
    return _watchHint.execute(
      currencyCode: currencyCode,
      month: month,
      categoryId: categoryId,
    );
  }

  Future<bool> hasFutureRulesAfter({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
  }) {
    return _repository.hasFutureRulesAfter(
      currencyCode: currencyCode,
      categoryId: categoryId,
      month: month,
    );
  }

  Future<Result<void>> setCategoryBudget({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
    required int amountMinor,
    required BudgetEditScope scope,
  }) {
    return guard(() => _setBudget.execute(
          currencyCode: currencyCode,
          categoryId: categoryId,
          month: month,
          amountMinor: amountMinor,
          scope: scope,
        ));
  }

  Future<Result<void>> clearCategoryBudget({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
    required BudgetEditScope scope,
  }) {
    return guard(() => _clearBudget.execute(
          currencyCode: currencyCode,
          categoryId: categoryId,
          month: month,
          scope: scope,
        ));
  }

  Future<Result<void>> saveReviewNote({
    required String currencyCode,
    required YearMonth month,
    String? categoryId,
    required String note,
  }) {
    return guard(() => _saveReviewNote.execute(
          currencyCode: currencyCode,
          month: month,
          categoryId: categoryId,
          note: note,
        ));
  }
}

@riverpod
BudgetService budgetService(Ref ref) {
  return BudgetService(
    ref.watch(setCategoryBudgetCommandProvider),
    ref.watch(clearCategoryBudgetCommandProvider),
    ref.watch(saveReviewNoteCommandProvider),
    ref.watch(watchMonthBudgetQueryProvider),
    ref.watch(watchTransactionBudgetHintQueryProvider),
    ref.watch(budgetRepositoryProvider),
  );
}
