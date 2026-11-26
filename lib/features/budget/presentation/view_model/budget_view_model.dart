import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/repositories/account_repository.dart';
import 'package:feather_ledger/core/data/repositories/category_repository.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/repositories/ledger_repository.dart';
import 'package:feather_ledger/features/ledger/presentation/mappers/transaction_ui_mapper.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';

import '../../domain/entities/budget_entities.dart';
import '../../domain/services/budget_service.dart';
import '../../domain/value_objects/budget_value_objects.dart';
import '../mappers/budget_ui_mapper.dart';
import '../models/budget_ui_models.dart';

part 'budget_view_model.g.dart';

@immutable
class BudgetUiState {
  final YearMonth selectedMonth;

  const BudgetUiState({required this.selectedMonth});

  BudgetUiState copyWith({YearMonth? selectedMonth}) {
    return BudgetUiState(selectedMonth: selectedMonth ?? this.selectedMonth);
  }
}

@Riverpod(keepAlive: true)
class BudgetViewModel extends _$BudgetViewModel {
  @override
  BudgetUiState build() {
    final now = ref.read(budgetClockProvider).now();
    return BudgetUiState(selectedMonth: YearMonth.fromDate(now));
  }

  void setMonth(DateTime date) {
    final next = YearMonth.fromDate(date);
    if (next == state.selectedMonth) return;
    state = state.copyWith(selectedMonth: next);
  }

  Future<Result<bool>> checkFutureRules({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
  }) =>
      checkFutureBudgetRules(ref.read(budgetServiceProvider),
          currencyCode: currencyCode, categoryId: categoryId, month: month);

  Future<Result<void>> setCategoryBudget({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
    required int amountMinor,
    required BudgetEditScope scope,
  }) {
    return ref.read(budgetServiceProvider).setCategoryBudget(
          currencyCode: currencyCode,
          categoryId: categoryId,
          month: month,
          amountMinor: amountMinor,
          scope: scope,
        );
  }

  Future<Result<void>> clearCategoryBudget({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
    required BudgetEditScope scope,
  }) {
    return ref.read(budgetServiceProvider).clearCategoryBudget(
          currencyCode: currencyCode,
          categoryId: categoryId,
          month: month,
          scope: scope,
        );
  }

  Future<Result<void>> saveReviewNote({
    required String currencyCode,
    required YearMonth month,
    String? categoryId,
    required String note,
  }) {
    return ref.read(budgetServiceProvider).saveReviewNote(
          currencyCode: currencyCode,
          month: month,
          categoryId: categoryId,
          note: note,
        );
  }

  Future<TransactionTileUiModel?> loadTransactionForEdit(
      String transactionId) async {
    final entity =
        await ref.read(ledgerRepositoryProvider).getTransaction(transactionId);
    if (entity == null) return null;
    return const TransactionUiMapper().toTile(entity);
  }

  Future<TransactionTileUiModel?> loadPendingBillForEdit(
      String scheduledBillId) async {
    final repo = ref.read(ledgerRepositoryProvider);
    final scheduled = await repo.getScheduledTransaction(scheduledBillId);
    if (scheduled == null) return null;
    final categoryId = scheduled.category?.id ??
        scheduled.recurringTransactionSeries?.categoryId;
    final accountId = scheduled.account?.id ??
        scheduled.recurringTransactionSeries?.accountId;
    if (categoryId == null || accountId == null) return null;
    final category = scheduled.category ??
        await ref.read(categoryRepositoryProvider).getCategory(categoryId);
    final account = scheduled.account ??
        await ref.read(accountRepositoryProvider).getAccount(accountId);
    if (category == null || account == null) return null;
    return const TransactionUiMapper().toPendingTile(
      scheduled,
      category: category,
      account: account,
    );
  }
}

@riverpod
Stream<MonthBudgetSummary> budgetMonthSummary(Ref ref, YearMonth month) {
  final currencyCode = ref.watch(ledgerCurrencyProvider);
  return ref.watch(budgetServiceProvider).watchMonthBudget(
        currencyCode: currencyCode,
        month: month,
      );
}

/// The home page's view model for one month: the mapper's output, derived from
/// the month stream, the display currency and the locale.
///
/// A provider rather than a call in `build`, so the page never re-maps on a
/// rebuild that changed none of those three, and so every consumer of the same
/// month shares one model.
@riverpod
AsyncValue<BudgetScreenUiModel> budgetScreenUiModel(
  Ref ref,
  ({YearMonth month, String locale}) request,
) {
  final currencySymbol = ref.watch(displayCurrencySymbolProvider);
  final today = ref.watch(budgetClockProvider).now();
  return ref.watch(budgetMonthSummaryProvider(request.month)).whenData(
        (summary) => const BudgetUiMapper().mapScreen(
          summary,
          currencySymbol: currencySymbol,
          locale: request.locale,
          today: today,
        ),
      );
}

/// The category detail page's view model: one row out of the month's model,
/// or null once that category has no row in this month.
@riverpod
AsyncValue<BudgetCategoryDetailUiModel?> budgetCategoryDetail(
  Ref ref,
  ({YearMonth month, String categoryId, String locale}) request,
) {
  final today = ref.watch(budgetClockProvider).now();
  return ref
      .watch(budgetScreenUiModelProvider(
        (month: request.month, locale: request.locale),
      ))
      .whenData((screen) {
    final row = [
      ...screen.budgetedRows,
      ...screen.unbudgetedActiveRows,
      ...screen.remainingActiveRows,
    ].where((row) => row.categoryId == request.categoryId).firstOrNull;
    if (row == null) return null;
    return BudgetCategoryDetailUiModel(
      row: row,
      monthDisplay: screen.monthDisplay,
      isHistoricalMonth: request.month < YearMonth.fromDate(today),
    );
  });
}
