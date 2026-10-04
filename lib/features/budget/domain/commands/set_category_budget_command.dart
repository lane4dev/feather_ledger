import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';

import '../../data/repositories/budget_repository_impl.dart';
import '../value_objects/budget_value_objects.dart';

part 'set_category_budget_command.g.dart';

class SetCategoryBudgetCommand {
  final BudgetRepository _repository;
  final DomainClock _clock;

  SetCategoryBudgetCommand(
    this._repository, {
    DomainClock? clock,
  }) : _clock = clock ?? const SystemClock();

  Future<void> execute({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
    required int amountMinor,
    required BudgetEditScope scope,
  }) async {
    if (amountMinor <= 0) {
      throw const CommandRejected(
        LedgerErrorCode.invalidAmount,
        'Category budget amount must be greater than zero.',
      );
    }

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
        'System category $categoryId cannot have a budget.',
      );
    }
    if (category.archived) {
      throw CommandRejected(
        LedgerErrorCode.categoryArchived,
        'Archived category $categoryId cannot set or restore a budget.',
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
      amountMinor: amountMinor,
      scope: scope,
      now: _clock.now(),
    );
  }
}

@riverpod
SetCategoryBudgetCommand setCategoryBudgetCommand(Ref ref) {
  return SetCategoryBudgetCommand(ref.watch(budgetRepositoryProvider));
}
