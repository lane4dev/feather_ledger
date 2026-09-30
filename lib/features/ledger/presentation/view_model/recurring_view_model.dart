import 'package:riverpod_annotation/riverpod_annotation.dart';

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

  /// Records a pending bill as a real transaction.
  Future<Result<void>> postInstance(String scheduledId) =>
      ref.read(recurringServiceProvider).postInstance(scheduledId);

  /// Deletes a pending bill at one of the three scopes. Moves no money and
  /// writes no event.
  Future<Result<void>> deleteBill(
    String scheduledId, {
    required RecurringScope scope,
  }) =>
      ref.read(recurringServiceProvider).deleteBill(scheduledId, scope: scope);

  /// Restores a skipped bill occurrence back to pending (`scheduled`).
  Future<Result<void>> restoreSkippedBill(String scheduledId) =>
      ref.read(recurringServiceProvider).restoreSkippedBill(scheduledId);

  int takeLastAutoPostedCount() =>
      ref.read(recurringServiceProvider).takeLastAutoPostedCount();

  /// Edits a pending bill at one of the two scopes. Moves no money and
  /// writes no event.
  Future<Result<void>> updateBill(
    String scheduledId, {
    required RecurringScope scope,
    required int amountMinor,
    required DateTime date,
    required String categoryId,
    required String accountId,
    required String description,
    String? frequency,
    int? interval,
    DateTime? endDate,
    int? countLimit,
    List<int>? weekdays,
    bool? autoPost,
    int? reminderMinutes,
    bool clearEndDate = false,
    bool clearCountLimit = false,
    bool clearReminder = false,
  }) =>
      ref.read(recurringServiceProvider).updateBill(
            scheduledId,
            scope: scope,
            amountMinor: amountMinor,
            date: date,
            categoryId: categoryId,
            accountId: accountId,
            description: description,
            frequency: frequency,
            interval: interval,
            endDate: endDate,
            countLimit: countLimit,
            weekdays: weekdays,
            autoPost: autoPost,
            reminderMinutes: reminderMinutes,
            clearEndDate: clearEndDate,
            clearCountLimit: clearCountLimit,
            clearReminder: clearReminder,
          );
}
