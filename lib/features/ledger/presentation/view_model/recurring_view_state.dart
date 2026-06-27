import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ledger_entities.dart';

class RecurringViewState {
  /// Instances awaiting a decision, and the rules behind them. Both are
  /// streams from the CRUD-exempt tables — nothing here is event-sourced.
  final AsyncValue<List<ScheduledTransactionEntity>> scheduled;
  final AsyncValue<List<RecurringTransactionSeriesEntity>> series;

  const RecurringViewState({
    required this.scheduled,
    required this.series,
  });

  const RecurringViewState.initial()
      : scheduled = const AsyncLoading(),
        series = const AsyncLoading();

  RecurringViewState copyWith({
    AsyncValue<List<ScheduledTransactionEntity>>? scheduled,
    AsyncValue<List<RecurringTransactionSeriesEntity>>? series,
  }) {
    return RecurringViewState(
      scheduled: scheduled ?? this.scheduled,
      series: series ?? this.series,
    );
  }
}

/// The instances that are due and still undecided, oldest first.
///
/// Overdue counts as due: an instance whose date has passed is exactly the
/// one the user needs to see. `posted` and `skipped` are decisions already
/// made, and a future instance is not yet actionable.
///
/// Compared **by day on both sides**. An instance keeps the series' time of
/// day, so comparing its full timestamp against midnight-truncated "today"
/// would drop this morning's bill until tomorrow.
///
/// A free function taking [today] so it can be tested without a clock.
List<ScheduledTransactionEntity> dueScheduledInstances(
  List<ScheduledTransactionEntity> instances, {
  required DateTime today,
}) {
  final cutoff = DateTime(today.year, today.month, today.day);
  bool isDue(ScheduledTransactionEntity instance) {
    if (instance.status != ScheduledTransactionStatus.scheduled) return false;
    final date = instance.date;
    final day = DateTime(date.year, date.month, date.day);
    return !day.isAfter(cutoff);
  }

  final due = instances.where(isDue).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  return due;
}
