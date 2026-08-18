import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' show Value;
import 'package:rrule/rrule.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';

part 'project_recurring_events_command.g.dart';

/// Materializes the upcoming instances of every recurring series
/// (spec 004, US2).
///
/// Finite rules produce all occurrences. Never-ending rules use a rolling
/// 90-day window clamped to [3, 12] pending instances. Fill the window; if the window holds fewer than three, keep
/// going until it does; never materialize more than twelve. That yields the
/// numbers a person expects without a per-frequency rule:
///
/// | frequency | result | why |
/// |---|---|---|
/// | monthly | 3 | the window holds exactly three |
/// | weekly | 12 | the window holds ~13, capped |
/// | yearly | 3 | the window holds none, so the floor reaches forward |
/// | daily | 12 | the window holds 90, capped |
///
/// Runs on every app launch and after every series creation, so it must stay
/// cheap and must be idempotent — see [_fill] for both.
class ProjectRecurringEventsCommand {
  final RecurringRepository _recurringRepository;

  ProjectRecurringEventsCommand(this._recurringRepository);

  static const Duration horizon = Duration(days: 90);

  /// Never leave a series with fewer upcoming bills than this.
  static const int minKeep = 3;

  /// Never materialize more than this per series.
  static const int maxKeep = 12;

  /// How far past the window the floor is allowed to reach. Three years
  /// covers three yearly occurrences, the sparsest rule the app offers.
  static const int _floorLookaheadYears = 3;

  Future<void> execute() async {
    final seriesList = await _recurringRepository.getAllRecurringSeries();
    final windowEnd = DateTime.now().add(horizon);

    for (final series in seriesList) {
      await _materializeSeries(series, windowEnd);
    }
  }

  Future<void> _materializeSeries(
      RecurringSeriesRow series, DateTime windowEnd) async {
    final startUtc = series.startDate.toUtc();
    final windowEndUtc = windowEnd.toUtc();

    final rule = ruleForSeries(series);

    // One read for the whole series rather than a probe per candidate date.
    // Keyed by the derived instance id, which is exactly what identity means
    // here — comparing dates would have to re-derive the same normalization.
    final existing = {
      for (final row
          in await _recurringRepository.scheduledForSeries(series.id))
        row.id: decodeScheduledStatus(row.status),
    };

    if (series.endDate != null || series.countLimit != null) {
      final before = series.endDate == null
          ? DateTime.utc(9999, 12, 31)
          : series.endDate!.toUtc().add(const Duration(days: 1));
      if (before.isAfter(startUtc)) {
        await _fill(
            series: series,
            rule: rule,
            startUtc: startUtc,
            beforeUtc: before,
            existing: existing,
            budget: 0x7fffffff,
            capped: false);
      }
      return;
    }

    var kept = 0;

    // Phase 1 — fill the rolling window. Skipped when the series starts
    // beyond it, because the generator asserts `before >= start`, and a
    // yearly series legitimately does start up to a year out.
    if (startUtc.isBefore(windowEndUtc)) {
      kept = await _fill(
        series: series,
        rule: rule,
        startUtc: startUtc,
        beforeUtc: windowEndUtc,
        existing: existing,
        budget: maxKeep,
      );
      if (kept >= minKeep) return;
    }

    // Phase 2 — the floor. Either the window held fewer than three (a yearly
    // rule holds none in 90 days) or the series starts past it. Reach forward
    // until the floor is met, bounded from whichever end is later so the walk
    // stays finite for every frequency. `after` is set only when phase 1 ran,
    // so nothing is counted twice.
    final startsBeyondWindow = !startUtc.isBefore(windowEndUtc);
    final floorFrom = startsBeyondWindow ? null : windowEndUtc;
    final floorAnchor = startsBeyondWindow ? startUtc : windowEndUtc;

    await _fill(
      series: series,
      rule: rule,
      startUtc: startUtc,
      afterUtc: floorFrom,
      beforeUtc: DateTime(
        floorAnchor.year + _floorLookaheadYears,
        floorAnchor.month,
        floorAnchor.day,
      ).toUtc(),
      existing: existing,
      budget: minKeep - kept,
    );
  }

  /// Walks the rule's candidate dates and makes sure instances exist for
  /// them, returning how many count toward the budget.
  ///
  /// Idempotency is the derived id: `'${series.id}_${date…}'` is stable for a
  /// given (series, date), so a second run finds every instance it made and
  /// only *counts* them. **Do not change the id or the date normalization** —
  /// either would make every run create a duplicate set of bills.
  ///
  /// An instance the user already posted or skipped is neither counted nor
  /// resurrected: that decision is theirs, and re-creating it would undo it.
  Future<int> _fill({
    required RecurringSeriesRow series,
    required RecurrenceRule rule,
    required DateTime startUtc,
    required DateTime beforeUtc,
    required Map<String, ScheduledTransactionStatus> existing,
    required int budget,
    DateTime? afterUtc,
    bool capped = true,
  }) async {
    // `before` bounds the generator itself, and it is load-bearing:
    // getInstances only stops at before, until, count or year 9999, so
    // filtering its output with a `.where` instead walks ~95,600 monthly
    // steps to find the few inside the window. That was ~37 seconds per
    // series on a command that runs at startup.
    final candidates = rule.getInstances(
      start: startUtc,
      after: afterUtc,
      before: beforeUtc,
    );

    var kept = 0;
    for (final date in candidates) {
      if (kept >= budget) break;

      final id = scheduledInstanceId(series.id, date);
      final status = existing[id];

      if (status == null) {
        if (capped &&
            existing.values
                    .where((s) => s == ScheduledTransactionStatus.scheduled)
                    .length >=
                maxKeep) {
          break;
        }
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
        existing[id] = ScheduledTransactionStatus.scheduled;
        kept++;
      } else if (status == ScheduledTransactionStatus.scheduled) {
        kept++;
      }
    }
    return kept;
  }

  static RecurrenceRule ruleForSeries(RecurringSeriesRow series) =>
      RecurrenceRule(
        frequency: _mapFrequency(series.frequency),
        interval: series.interval,
        until: series.countLimit == null ? series.endDate?.toUtc() : null,
        count: series.countLimit,
        byWeekDays: _weekdays(series.rrule, series.startDate),
      );

  static List<ByWeekDayEntry> _weekdays(String text, DateTime start) {
    final match = RegExp(r'(?:^|;)BYDAY=([^;]+)').firstMatch(text);
    if (match == null) return const [];
    const days = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    final shift = start.toUtc().weekday - start.toLocal().weekday;
    return match
        .group(1)!
        .split(',')
        .map((d) => days.indexOf(d) + 1)
        .where((d) => d > 0)
        .map((d) => ByWeekDayEntry((d - 1 + shift) % 7 + 1))
        .toList();
  }

  static Frequency _mapFrequency(String freq) {
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
