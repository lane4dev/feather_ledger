import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';

import '../../domain/entities/ledger_entities.dart';
import '../../domain/services/recurring_service.dart';

part 'recurring_view_model.g.dart';

/// The write actions for recurring bills (spec 004, US2).
///
/// There is no state here: the bills themselves reach the screen through
/// `ledgerMonthlyTransactionsProvider`, which merges them into the month
/// list, and the series list is gone. What is left is the three things a
/// person can *do* to a pending bill.
@riverpod
class RecurringViewModel extends _$RecurringViewModel {
  @override
  void build() {}

  /// Starts a series — what the transaction form calls when the user sets a
  /// repeat rule. Materializes the first instances as part of the same call.
  Future<Result<void>> createSeries({
    required RecurringSeriesKind type,
    required int amountMinor,
    required String accountId,
    required String categoryId,
    required String description,
    required String frequency,
    required DateTime startDate,
  }) =>
      ref.read(recurringServiceProvider).createSeries(
            type: type,
            amountMinor: amountMinor,
            accountId: accountId,
            categoryId: categoryId,
            description: description,
            frequency: frequency,
            interval: 1,
            startDate: startDate,
          );

  /// Records a pending bill as a real transaction.
  Future<Result<void>> postInstance(String scheduledId) =>
      ref.read(recurringServiceProvider).postInstance(scheduledId);

  /// Deletes a pending bill at one of the three scopes. Moves no money and
  /// writes no event.
  Future<Result<void>> deleteBill(
    String scheduledId, {
    required RecurringScope scope,
  }) =>
      ref
          .read(recurringServiceProvider)
          .deleteBill(scheduledId, scope: scope);

  /// Edits a pending bill at one of the three scopes. Moves no money and
  /// writes no event.
  Future<Result<void>> updateBill(
    String scheduledId, {
    required RecurringScope scope,
    required int amountMinor,
    required DateTime date,
    required String categoryId,
    required String accountId,
    required String description,
  }) =>
      ref.read(recurringServiceProvider).updateBill(
            scheduledId,
            scope: scope,
            amountMinor: amountMinor,
            date: date,
            categoryId: categoryId,
            accountId: accountId,
            description: description,
          );
}
