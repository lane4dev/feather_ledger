import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/budget_entities.dart';
import '../../domain/services/budget_service.dart';
import '../../domain/value_objects/budget_value_objects.dart';

part 'transaction_budget_hint_provider.g.dart';

@riverpod
Stream<CategoryBudgetHint> transactionBudgetHint(
  Ref ref, {
  required String currencyCode,
  required YearMonth month,
  required String categoryId,
}) {
  return ref.watch(budgetServiceProvider).watchTransactionBudgetHint(
        currencyCode: currencyCode,
        month: month,
        categoryId: categoryId,
      );
}
