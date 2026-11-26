import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/clock/clock.dart';

import '../../data/repositories/budget_repository_impl.dart';
import '../entities/budget_entities.dart';
import '../services/budget_service.dart';
import '../value_objects/budget_value_objects.dart';

part 'watch_transaction_budget_hint_query.g.dart';

class WatchTransactionBudgetHintQuery {
  final BudgetRepository _repository;
  final DomainClock _clock;

  WatchTransactionBudgetHintQuery(
    this._repository, {
    DomainClock? clock,
  }) : _clock = clock ?? const SystemClock();

  Stream<CategoryBudgetHint> execute({
    required String currencyCode,
    required YearMonth month,
    required String categoryId,
  }) {
    final includeVirtual = month >= YearMonth.fromDate(_clock.now());
    return _repository.watchCategoryBudgetHint(
      currencyCode: currencyCode,
      month: month,
      categoryId: categoryId,
      includeVirtual: includeVirtual,
    );
  }
}

@riverpod
WatchTransactionBudgetHintQuery watchTransactionBudgetHintQuery(Ref ref) {
  return WatchTransactionBudgetHintQuery(
    ref.watch(budgetRepositoryProvider),
    clock: ref.watch(budgetClockProvider),
  );
}
