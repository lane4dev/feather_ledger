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

      final instances = rrule
          .getInstances(
            start: series.startDate.toUtc(),
          )
          .where((d) => d.isBefore(limit.toUtc()));

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
              status: Value(ScheduledTransactionStatus.scheduled
                  .toString()
                  .split('.')
                  .last),
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
