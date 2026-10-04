import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';

import '../../data/repositories/budget_repository_impl.dart';
import '../value_objects/budget_value_objects.dart';

part 'clear_category_budget_command.g.dart';

class ClearCategoryBudgetCommand {
  final BudgetRepository _repository;
  final DomainClock _clock;

  ClearCategoryBudgetCommand(
    this._repository, {
    DomainClock? clock,
  }) : _clock = clock ?? const SystemClock();

  Future<void> execute({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
    required BudgetEditScope scope,
  }) async {
    final category = await _repository.getCategoryById(categoryId);
    if (category == null) {
      throw CommandRejected(
        LedgerErrorCode.categoryNotFound,
        'Category $categoryId does not exist.',
      );
    }
    if (category.systemCode != null) {
      throw CommandRejected(
        LedgerErrorCode.systemCategoryProtected,
        'System category $categoryId cannot be modified.',
      );
    }
    if (category.archived) {
      throw CommandRejected(
        LedgerErrorCode.categoryArchived,
        'Archived category $categoryId budgets are read-only.',
      );
    }
    if (category.type != CategoryType.expense) {
      throw const CommandRejected(
        LedgerErrorCode.categoryTypeMismatch,
        'Only expense categories support budgets.',
      );
    }

    await _repository.upsertBudgetRule(
      currencyCode: currencyCode,
      categoryId: categoryId,
      month: month,
      amountMinor: null,
      scope: scope,
      now: _clock.now(),
    );
  }
}

@riverpod
ClearCategoryBudgetCommand clearCategoryBudgetCommand(Ref ref) {
  return ClearCategoryBudgetCommand(ref.watch(budgetRepositoryProvider));
}
