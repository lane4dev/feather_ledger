import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' show Value;
import 'package:rrule/rrule.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';

part 'project_recurring_events_command.g.dart';

/// Materializes the instances of every active recurring series (spec 004 /
/// recurring-simplification).
///
/// - `planned` series materialize their single `'single'` occurrence at
///   `startDate`.
/// - `repeating` series materialize:
///   1. All unmaterialized historical occurrences from `startDate` up to `now`
///      (without lookback/count caps) — returning the count of newly inserted
///      overdue rows that will NOT auto-post (`!series.autoPost`), so the
///      session banner reflects only bills needing manual review.
///   2. Up to [maxKeep] (3) upcoming occurrences within [horizon] (90 days),
///      with a floor of [minKeep] (1) upcoming occurrence for sparser rules
///      such as yearly series.
///
/// Runs on every app launch and after every series creation/mutation, so it
/// must stay bounded and idempotent.
class ProjectRecurringEventsCommand {
  final RecurringRepository _recurringRepository;
  final DomainClock _clock;

  /// Turns a UTC occurrence instant into the wall time it is stored and shown
  /// under. Production uses the device's current zone (spec 006, US34: the
  /// current local time is authoritative); tests inject a fixed
  /// `package:timezone` location so DST and zone changes are deterministic.
  final DateTime Function(DateTime utc) _localize;

  ProjectRecurringEventsCommand(
    this._recurringRepository, {
    DateTime Function(DateTime utc)? localize,
    DomainClock? clock,
  })  : _localize = localize ?? _defaultLocalize,
        _clock = clock ?? const SystemClock();

  static DateTime _defaultLocalize(DateTime utc) => utc.toLocal();

  static const Duration horizon = Duration(days: 90);

  /// Never leave an active repeating series with fewer upcoming bills than
  /// this (when the rule still has future occurrences).
  static const int minKeep = 1;

  /// Never materialize more than this many upcoming bills per series within
  /// [horizon].
  static const int maxKeep = 3;

  Future<int> execute() async {
    final seriesList =
        await _recurringRepository.getMaterializableRecurringSeries();
    final now = _clock.now();
    var newlyMaterializedOverdueCount = 0;

    for (final series in seriesList) {
      newlyMaterializedOverdueCount += await _materializeSeries(series, now);
    }
    return newlyMaterializedOverdueCount;
  }

  Future<int> _materializeSeries(
      RecurringSeriesRow series, DateTime now) async {
    final startUtc = series.startDate.toUtc();
    final nowUtc = now.toUtc();
    final windowEndUtc = now.add(horizon).toUtc();

    // One read for the whole series rather than a probe per candidate date.
    // Keyed by occurrenceKey so re-running across timezones stays idempotent.
    final existing = {
      for (final row
          in await _recurringRepository.scheduledForSeries(series.id))
        row.occurrenceKey: decodeScheduledStatus(row.status),
    };

    if (series.mode == RecurringSeriesMode.planned) {
      if (!existing.containsKey(kPlannedOccurrenceKey)) {
        await _recurringRepository.insertMaterializedIfActive(
          ScheduledTransactionsViewCompanion(
            id: Value(const Uuid().v4()),
            seriesId: Value(series.id),
            occurrenceKey: const Value(kPlannedOccurrenceKey),
            scheduledDate: Value(series.startDate),
            status: Value(ScheduledTransactionStatus.scheduled.toStorage()),
            manualOnly: const Value(false),
          ),
        );
        return (!series.autoPost && !series.startDate.isAfter(now)) ? 1 : 0;
      }
      return 0;
    }

    final rule = ruleForSeries(series);
    var newlyMaterializedOverdue = 0;

    // Phase 0 — unbounded historical backfill from startDate up to now.
    final hadOverdue = !startUtc.isAfter(nowUtc);
    if (hadOverdue) {
      newlyMaterializedOverdue = await _fillOverdue(
        series: series,
        rule: rule,
        startUtc: startUtc,
        nowUtc: nowUtc,
        existing: existing,
      );
    }

    var kept = 0;

    // Phase 1 — fill the 90-day rolling window up to maxKeep (3).
    // Guard against `startUtc > windowEndUtc` because rrule asserts
    // `before >= start`.
    if (!startUtc.isAfter(windowEndUtc)) {
      kept = await _fill(
        series: series,
        rule: rule,
        startUtc: startUtc,
        afterUtc: hadOverdue ? nowUtc : null,
        beforeUtc: windowEndUtc,
        includeBefore: true,
        existing: existing,
        budget: maxKeep,
      );
      if (kept >= minKeep) return newlyMaterializedOverdue;
    }

    // Phase 2 — floor (minKeep = 1) for sparse rules (e.g. yearly) or series
    // starting past the 90-day horizon. Stops immediately on the 1st future
    // occurrence or when until/count is exhausted.
    final startsBeyondWindow = startUtc.isAfter(windowEndUtc);
    await _fill(
      series: series,
      rule: rule,
      startUtc: startUtc,
      afterUtc: startsBeyondWindow ? null : windowEndUtc,
      beforeUtc: DateTime.utc(9999, 12, 31),
      includeBefore: true,
      existing: existing,
      budget: minKeep - kept,
    );
    return newlyMaterializedOverdue;
  }

  /// Walks the rule's candidate dates and makes sure instances exist for
  /// them, returning how many count toward [budget].
  ///
  /// An instance the user already posted or skipped is neither counted nor
  /// resurrected: skipped occurrences consume `countLimit` without tail
  /// replenishment.
  Future<int> _fill({
    required RecurringSeriesRow series,
    required RecurrenceRule rule,
    required DateTime startUtc,
    required DateTime beforeUtc,
    required bool includeBefore,
    required Map<String, ScheduledTransactionStatus> existing,
    required int budget,
    DateTime? afterUtc,
  }) async {
    if (budget <= 0) return 0;

    // `before` bounds the generator itself: getInstances only stops at
    // before, until, count or year 9999.
    final candidates = rule.getInstances(
      start: startUtc,
      after: afterUtc,
      before: beforeUtc,
      includeBefore: includeBefore,
    );

    var kept = 0;
    for (final date in candidates) {
      if (kept >= budget) break;

      final localDate = _localize(date);
      final key = scheduledOccurrenceKey(date.toUtc());
      final status = existing[key];

      if (status == null) {
        await _recurringRepository.insertMaterializedIfActive(
          ScheduledTransactionsViewCompanion(
            id: Value(const Uuid().v4()),
            seriesId: Value(series.id),
            occurrenceKey: Value(key),
            scheduledDate: Value(localDate),
            status: Value(ScheduledTransactionStatus.scheduled.toStorage()),
            manualOnly: const Value(false),
          ),
        );
        existing[key] = ScheduledTransactionStatus.scheduled;
        kept++;
      } else if (status == ScheduledTransactionStatus.scheduled) {
        kept++;
      }
    }
    return kept;
  }

  Future<int> _fillOverdue({
    required RecurringSeriesRow series,
    required RecurrenceRule rule,
    required DateTime startUtc,
    required DateTime nowUtc,
    required Map<String, ScheduledTransactionStatus> existing,
  }) async {
    final allOverdue = rule.getInstances(
      start: startUtc,
      before: nowUtc,
      includeBefore: true,
    );

    var inserted = 0;
    for (final date in allOverdue) {
      final localDate = _localize(date);
      final key = scheduledOccurrenceKey(date.toUtc());
      if (existing.containsKey(key)) continue;

      await _recurringRepository.insertMaterializedIfActive(
        ScheduledTransactionsViewCompanion(
          id: Value(const Uuid().v4()),
          seriesId: Value(series.id),
          occurrenceKey: Value(key),
          scheduledDate: Value(localDate),
          status: Value(ScheduledTransactionStatus.scheduled.toStorage()),
          manualOnly: const Value(false),
        ),
      );
      existing[key] = ScheduledTransactionStatus.scheduled;
      inserted++;
    }
    return series.autoPost ? 0 : inserted;
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
