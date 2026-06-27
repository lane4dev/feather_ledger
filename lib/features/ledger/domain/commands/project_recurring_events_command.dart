import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart'; // Added import for Value and ScheduledTransactionsViewCompanion
import 'package:rrule/rrule.dart';

import 'package:feather_ledger/core/data/database/app_database.dart'; // Needed for ScheduledTransactionsCompanion
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';

part 'project_recurring_events_command.g.dart';

class ProjectRecurringEventsCommand {
  final RecurringRepository _recurringRepository;

  ProjectRecurringEventsCommand(this._recurringRepository);

  Future<void> execute({int months = 12}) async {
    final seriesList = await _recurringRepository.getAllRecurringSeries();
    final now = DateTime.now();
    final limit = DateTime(now.year, now.month + months, now.day);

    for (var series in seriesList) {
      final frequency = _mapFrequency(series.frequency);

      final rrule = RecurrenceRule(
        frequency: frequency,
        interval: series.interval,
        until: series.endDate?.toUtc(),
        count: series.countLimit,
      );

      // `before` bounds the generator itself. Filtering a `.where` on top of
      // it instead would look equivalent but is not: getInstances is a lazy
      // generator that only stops at `before`, `until`, `count` or year 9999
      // — so a monthly series starting this year would run ~95,600 steps to
      // yield the ~20 inside the horizon. That was ~37 seconds per series on
      // this command, and this command now runs on every app launch.
      final startUtc = series.startDate.toUtc();
      final limitUtc = limit.toUtc();
      // getInstances asserts `before >= start`, so a series starting beyond
      // the horizon is answered directly instead of by querying.
      final instances = startUtc.isBefore(limitUtc)
          ? rrule.getInstances(start: startUtc, before: limitUtc)
          : const Iterable<DateTime>.empty();

      for (var date in instances) {
        final id = '${series.id}_${date.millisecondsSinceEpoch}';

        final existing = await _recurringRepository.getScheduled(id);
        if (existing == null) {
          await _recurringRepository.insertOrUpdateScheduled(
            ScheduledTransactionsViewCompanion(
              id: Value(id),
              seriesId: Value(series.id),
              date: Value(date.toLocal()),
              amountMinor: Value(series.amountMinor),
              status: Value(ScheduledTransactionStatus.scheduled.toStorage()),
              transactionId: const Value(null),
            ),
          );
        }
      }
    }
  }

  Frequency _mapFrequency(String freq) {
    switch (freq.toUpperCase()) {
      case 'DAILY':
        return Frequency.daily;
      case 'WEEKLY':
        return Frequency.weekly;
      case 'MONTHLY':
        return Frequency.monthly;
      case 'YEARLY':
        return Frequency.yearly;
      default:
        return Frequency.monthly;
    }
  }
}

@riverpod
ProjectRecurringEventsCommand projectRecurringEventsCommand(Ref ref) {
  return ProjectRecurringEventsCommand(ref.watch(recurringRepositoryProvider));
}
