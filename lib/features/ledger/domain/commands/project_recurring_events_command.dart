import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/recurrence/recurrence_expander.dart';

part 'project_recurring_events_command.g.dart';

/// Materializes physical occurrences of every active recurring series whose
/// account is live (`!archived && !deleted`).
///
/// Uses [RecurrenceExpander] (local civil-date stepping) so physical
/// materialization and budget virtual projection share one calendar engine:
/// - `planned` series materialize their single `'single'` occurrence at
///   `startDate`.
/// - `repeating` series materialize:
///   1. Phase 0: unmaterialized historical overdue occurrences in
///      `[materializeFrom, now]`, returning the count of newly inserted overdue
///      rows whose series does NOT auto-post (`!series.autoPost`).
///   2. Phase 1: every missing occurrence in `(now, endOfMonth(nowYm + 2)]`
///      (current month + next 2 full calendar months), with no `maxKeep = 3`
///      cap and a safety valve of [maxUpcomingSafetyValve] (120) upcoming rows.
///   3. Phase 2: sparse floor of [minKeep] (1) upcoming occurrence beyond the
///      horizon for rules such as yearly or far-future series that have zero
///      upcoming `scheduled` instances within `(now, horizonEnd]`.
///
/// Inserts for each series are batched into a single database transaction via
/// `INSERT OR IGNORE`, keeping repeated runs bounded and idempotent.
class ProjectRecurringEventsCommand {
  final RecurringRepository _recurringRepository;
  final DomainClock _clock;
  final RecurrenceExpander _expander;
  final int _monthsAhead;

  ProjectRecurringEventsCommand(
    this._recurringRepository, {
    DomainClock? clock,
    LocalDateTimeBuilder? buildDateTime,
    int monthsAhead = defaultMonthsAhead,
  })  : _clock = clock ?? const SystemClock(),
        _expander = buildDateTime == null
            ? const RecurrenceExpander()
            : RecurrenceExpander(buildDateTime: buildDateTime),
        _monthsAhead = monthsAhead;

  /// Number of additional full calendar months beyond the current month to
  /// physically materialize (`nowYm + 2` = 3 full calendar months total).
  static const int defaultMonthsAhead = 2;

  /// Never leave an active repeating series with fewer upcoming bills than
  /// this (when the rule still has future occurrences).
  static const int minKeep = 1;

  /// Per-series safety valve for upcoming rows materialized within the
  /// near-term horizon (3 full calendar months has at most 92 days).
  static const int maxUpcomingSafetyValve = 120;

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
    RecurringSeriesRow series,
    DateTime now,
  ) async {
    // One read for the whole series rather than a probe per candidate date.
    // Keyed by local civil occurrenceKey so re-runs stay idempotent.
    final existing = {
      for (final row
          in await _recurringRepository.scheduledForSeries(series.id))
        row.occurrenceKey: decodeScheduledStatus(row.status),
    };

    if (series.mode == RecurringSeriesMode.planned) {
      if (existing.containsKey(kPlannedOccurrenceKey)) {
        return 0;
      }
      final committed =
          await _recurringRepository.insertMaterializedBatchIfActive(
        series.id,
        [
          ScheduledTransactionsViewCompanion(
            id: Value(const Uuid().v4()),
            seriesId: Value(series.id),
            occurrenceKey: const Value(kPlannedOccurrenceKey),
            scheduledDate: Value(series.startDate),
            status: Value(ScheduledTransactionStatus.scheduled.toStorage()),
            manualOnly: const Value(false),
          ),
        ],
      );
      if (!committed) return 0;
      return (!series.autoPost && !series.startDate.isAfter(now)) ? 1 : 0;
    }

    final spec = RecurrenceRuleSpec.fromStored(
      mode: series.mode,
      frequency: series.frequency,
      interval: series.interval,
      startDate: series.startDate,
      endDate: series.endDate,
      countLimit: series.countLimit,
      completedCountOffset: series.completedCountOffset,
      rrule: series.rrule,
      materializeFrom: series.materializeFrom,
    );

    final toInsert = <ScheduledTransactionsViewCompanion>[];
    var insertedOverdue = 0;

    // Phase 0 — historical overdue occurrences in [materializeFrom, now].
    final overdueCandidates = _expander.expandInRange(
      spec,
      rangeEnd: now,
      includeRangeEnd: true,
      respectMaterializeFrom: true,
    );
    for (final occ in overdueCandidates) {
      if (existing.containsKey(occ.occurrenceKey)) continue;
      toInsert.add(_companionFor(series.id, occ));
      existing[occ.occurrenceKey] = ScheduledTransactionStatus.scheduled;
      insertedOverdue++;
    }

    // Phase 1 — all upcoming occurrences in (now, endOfMonth(nowYm + 2)],
    // bounded only by the per-series safety valve (120).
    final horizonEnd =
        RecurrenceExpander.horizonEndForMonth(now, monthsAhead: _monthsAhead);
    final upcomingCandidates = _expander.expandInRange(
      spec,
      rangeStart: now,
      includeRangeStart: false,
      rangeEnd: horizonEnd,
      includeRangeEnd: true,
      respectMaterializeFrom: true,
    );

    var upcomingScheduledCount = 0;
    for (final occ in upcomingCandidates) {
      if (upcomingScheduledCount >= maxUpcomingSafetyValve) break;
      final status = existing[occ.occurrenceKey];
      if (status == null) {
        toInsert.add(_companionFor(series.id, occ));
        existing[occ.occurrenceKey] = ScheduledTransactionStatus.scheduled;
        upcomingScheduledCount++;
      } else if (status == ScheduledTransactionStatus.scheduled) {
        upcomingScheduledCount++;
      }
    }

    // Phase 2 — sparse floor (minKeep = 1) when no upcoming scheduled bill
    // exists inside (now, horizonEnd] (e.g. yearly rules or far-future start).
    if (upcomingScheduledCount < minKeep) {
      final skipKeys = <String>{
        for (final entry in existing.entries)
          if (entry.value != ScheduledTransactionStatus.scheduled) entry.key,
      };
      final next = _expander.firstOccurrenceAfter(
        spec,
        horizonEnd,
        respectMaterializeFrom: true,
        skipKeys: skipKeys,
      );
      if (next != null && !existing.containsKey(next.occurrenceKey)) {
        toInsert.add(_companionFor(series.id, next));
        existing[next.occurrenceKey] = ScheduledTransactionStatus.scheduled;
      }
    }

    if (toInsert.isEmpty) return 0;

    final committed =
        await _recurringRepository.insertMaterializedBatchIfActive(
      series.id,
      toInsert,
    );
    if (!committed) return 0;
    return series.autoPost ? 0 : insertedOverdue;
  }

  static ScheduledTransactionsViewCompanion _companionFor(
    String seriesId,
    RecurrenceOccurrence occ,
  ) =>
      ScheduledTransactionsViewCompanion(
        id: Value(const Uuid().v4()),
        seriesId: Value(seriesId),
        occurrenceKey: Value(occ.occurrenceKey),
        scheduledDate: Value(occ.scheduledDate),
        status: Value(ScheduledTransactionStatus.scheduled.toStorage()),
        manualOnly: const Value(false),
      );
}

@riverpod
ProjectRecurringEventsCommand projectRecurringEventsCommand(Ref ref) {
  return ProjectRecurringEventsCommand(ref.watch(recurringRepositoryProvider));
}
