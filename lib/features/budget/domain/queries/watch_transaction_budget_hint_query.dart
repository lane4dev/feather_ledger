import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/budget_repository_impl.dart';
import '../entities/budget_entities.dart';
import '../value_objects/budget_value_objects.dart';

part 'watch_transaction_budget_hint_query.g.dart';

class WatchTransactionBudgetHintQuery {
  final BudgetRepository _repository;

  WatchTransactionBudgetHintQuery(this._repository);

  Stream<CategoryBudgetHint> execute({
    required String currencyCode,
    required YearMonth month,
    required String categoryId,
  }) {
    return _repository.watchCategoryBudgetHint(
      currencyCode: currencyCode,
      month: month,
      categoryId: categoryId,
    );
  }
}

@riverpod
WatchTransactionBudgetHintQuery watchTransactionBudgetHintQuery(Ref ref) {
  return WatchTransactionBudgetHintQuery(ref.watch(budgetRepositoryProvider));
}
