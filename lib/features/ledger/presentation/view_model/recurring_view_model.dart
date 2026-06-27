import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';

import '../../domain/entities/ledger_entities.dart';
import '../../domain/services/recurring_service.dart';

import 'recurring_view_state.dart';

part 'recurring_view_model.g.dart';

/// Recurring bills (spec 004, US2).
///
/// Shapes follow [LedgerViewModel]: keep-alive, one subscription per stream,
/// disposed together, and every write routed through the service so the
/// screen never touches a command.
@Riverpod(keepAlive: true)
class RecurringViewModel extends _$RecurringViewModel {
  StreamSubscription<List<ScheduledTransactionEntity>>? _scheduledSub;
  StreamSubscription<List<RecurringTransactionSeriesEntity>>? _seriesSub;

  @override
  RecurringViewState build() {
    ref.onDispose(() {
      _scheduledSub?.cancel();
      _seriesSub?.cancel();
    });

    _subscribeScheduled();
    _subscribeSeries();
    return const RecurringViewState.initial();
  }

  /// Instances due today or earlier that are still awaiting a decision.
  List<ScheduledTransactionEntity> dueNow() {
    final scheduled = state.scheduled.value ?? const [];
    return dueScheduledInstances(scheduled, today: DateTime.now());
  }

  Future<Result<void>> createSeries({
    required RecurringSeriesKind type,
    required int amountMinor,
    required String accountId,
    required String categoryId,
    required String description,
    required String frequency,
    required int interval,
    required DateTime startDate,
    DateTime? endDate,
  }) {
    return ref.read(recurringServiceProvider).createSeries(
          type: type,
          amountMinor: amountMinor,
          accountId: accountId,
          categoryId: categoryId,
          description: description,
          frequency: frequency,
          interval: interval,
          startDate: startDate,
          endDate: endDate,
        );
  }

  /// Deactivates a series as of [endDate]. Existing instances are kept.
  Future<Result<void>> deactivateSeries(
    String seriesId, {
    required DateTime endDate,
  }) {
    return ref
        .read(recurringServiceProvider)
        .deactivateSeries(seriesId, endDate: endDate);
  }

  /// Records a due instance as a real transaction.
  Future<Result<void>> postInstance(String scheduledId) =>
      ref.read(recurringServiceProvider).postInstance(scheduledId);

  /// Marks a due instance as skipped. Moves no money.
  Future<Result<void>> skipInstance(String scheduledId) =>
      ref.read(recurringServiceProvider).skipInstance(scheduledId);

  void _subscribeScheduled() {
    _scheduledSub ??=
        ref.read(recurringServiceProvider).watchScheduled().listen(
      (items) => state = state.copyWith(scheduled: AsyncData(items)),
      onError: (Object error, StackTrace st) =>
          state = state.copyWith(scheduled: AsyncError(error, st)),
    );
  }

  void _subscribeSeries() {
    _seriesSub ??= ref.read(recurringServiceProvider).watchSeries().listen(
          (items) => state = state.copyWith(series: AsyncData(items)),
          onError: (Object error, StackTrace st) =>
              state = state.copyWith(series: AsyncError(error, st)),
        );
  }
}
