import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';

import '../../domain/entities/ledger_entities.dart';
import '../../domain/recurrence/distant_past_guard.dart';
import '../../domain/services/recurring_service.dart';
import '../mappers/transaction_ui_mapper.dart';
import '../models/transaction_tile_ui_model.dart';

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

  /// Idempotently materializes a virtual occurrence `(seriesId, occurrenceKey)`
  /// into a physical pending bill row before opening bill actions or edits.
  Future<Result<ScheduledTransactionEntity>> ensureMaterialized({
    required String seriesId,
    required String occurrenceKey,
  }) =>
      ref.read(recurringServiceProvider).ensureMaterialized(
            seriesId: seriesId,
            occurrenceKey: occurrenceKey,
          );

  /// Materializes a virtual occurrence and maps it to a UI tile ready for
  /// `PendingBillSheet`, keeping domain-to-UI mapping out of widgets.
  Future<Result<TransactionTileUiModel>> materializeVirtualPendingTile({
    required String seriesId,
    required String occurrenceKey,
  }) async {
    final result = await ensureMaterialized(
      seriesId: seriesId,
      occurrenceKey: occurrenceKey,
    );
    return switch (result) {
      Failure(:final code, :final message) => Failure(code, message),
      Success(:final value) => _mapPendingTile(value),
    };
  }

  static Result<TransactionTileUiModel> _mapPendingTile(
    ScheduledTransactionEntity entity,
  ) {
    final category = entity.category;
    final account = entity.account;
    if (category == null || account == null) {
      return const Failure(
        LedgerErrorCode.transactionNotFound,
        'Scheduled bill metadata could not be resolved',
      );
    }
    return Success(
      const TransactionUiMapper().toPendingTile(
        entity,
        category: category,
        account: account,
      ),
    );
  }

  int takeLastAutoPostedCount() =>
      ref.read(recurringServiceProvider).takeLastAutoPostedCount();

  /// Whether editing a recurring bill with [scope] changes its repeating base
  /// schedule to a start date strictly earlier than 2 calendar months before
  /// [now], requiring the distant-past confirmation dialog.
  static bool needsDistantPastConfirmation({
    required RecurringScope scope,
    required RecurringTransactionSeriesEntity? series,
    required DateTime currentDate,
    required DateTime nextDate,
    required String nextFrequency,
    required int nextInterval,
    required List<int> initialWeekdays,
    required List<int> nextWeekdays,
    required DateTime now,
  }) {
    if (scope != RecurringScope.updateRule ||
        series == null ||
        series.mode != RecurringSeriesMode.repeating) {
      return false;
    }
    final baseScheduleChanged = DistantPastStartGuard.hasBaseScheduleChanged(
      currentDate: currentDate,
      nextDate: nextDate,
      currentFrequency: series.frequency,
      nextFrequency: nextFrequency,
      currentInterval: series.interval,
      nextInterval: nextInterval,
      currentWeekdays: initialWeekdays,
      nextWeekdays: nextWeekdays,
    );
    return baseScheduleChanged &&
        DistantPastStartGuard.isDistantPast(nextDate, now: now);
  }

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
    DateTime? materializeFrom,
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
            materializeFrom: materializeFrom,
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
