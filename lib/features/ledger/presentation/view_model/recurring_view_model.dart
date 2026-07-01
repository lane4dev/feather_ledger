import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';

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

  /// Marks a pending bill as skipped. Moves no money and writes no event.
  Future<Result<void>> skipInstance(String scheduledId) =>
      ref.read(recurringServiceProvider).skipInstance(scheduledId);

  /// Stops a series producing further bills. Bills already created are kept.
  Future<Result<void>> deactivateSeries(
    String seriesId, {
    required DateTime endDate,
  }) =>
      ref
          .read(recurringServiceProvider)
          .deactivateSeries(seriesId, endDate: endDate);
}
