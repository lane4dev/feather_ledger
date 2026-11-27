import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/recurrence/recurrence_expander.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart'
    show ledgerClockProvider;

part 'project_recurring_events_command.g.dart';

/// Structured summary returned by [ProjectRecurringEventsCommand.execute].
class MaterializationSummary {
  /// Newly materialized overdue bills from manual (`!autoPost`) series that
  /// need user review.
  final int newlyMaterializedOverdueCount;

  /// True when at least one active repeating series had older unmaterialized
  /// historical occurrences skipped due to the 12-month / 100-row backfill
  /// safety caps.
  final bool hasTruncatedHistory;

  const MaterializationSummary({
    this.newlyMaterializedOverdueCount = 0,
    this.hasTruncatedHistory = false,
  });

  static const MaterializationSummary empty = MaterializationSummary();

  bool get shouldNotifyUser =>
      newlyMaterializedOverdueCount > 0 || hasTruncatedHistory;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterializationSummary &&
          other.newlyMaterializedOverdueCount ==
              newlyMaterializedOverdueCount &&
          other.hasTruncatedHistory == hasTruncatedHistory;

  @override
  int get hashCode =>
      Object.hash(newlyMaterializedOverdueCount, hasTruncatedHistory);

  @override
  String toString() =>
      'MaterializationSummary(newlyMaterializedOverdueCount: '
      '$newlyMaterializedOverdueCount, '
      'hasTruncatedHistory: $hasTruncatedHistory)';
}

/// Materializes physical occurrences of every active recurring series whose
/// account is live (`!archived && !deleted`).
///
/// Uses [RecurrenceExpander] (local civil-date stepping) so physical
/// materialization and budget virtual projection share one calendar engine:
/// - `planned` series materialize their single `'single'` occurrence at
///   `startDate`.
/// - `repeating` series materialize:
///   1. Phase 0: unmaterialized historical overdue occurrences in
///      `[max(materializeFrom, startOfMonth(nowYm - 11)), now]`, capped at the
///      [maxBackfillPerSeries] (100) most recent occurrences per series.
///      Returns newly inserted overdue rows for non-auto-post series and
///      whether any older unmaterialized occurrences were truncated.
///   2. Phase 1: every missing occurrence in `(now, endOfMonth(nowYm + 1)]`
///      (current month + next full calendar month), with no `maxKeep = 3`
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
  /// physically materialize (`nowYm + 1` = 2 full calendar months total).
  static const int defaultMonthsAhead = 1;

  /// Never leave an active repeating series with fewer upcoming bills than
  /// this (when the rule still has future occurrences).
  static const int minKeep = 1;

  /// Per-series safety valve for upcoming rows materialized within the
  /// near-term horizon (2 full calendar months has at most 62 days).
  static const int maxUpcomingSafetyValve = 120;

  /// Maximum calendar months (inclusive of `now`'s month) that Phase 0
  /// historical backfill may look back (`startOfMonth(nowYm - 11)`).
  static const int maxBackfillMonths = 12;

  /// Maximum historical overdue rows retained per series in Phase 0, keeping
  /// the occurrences closest to `now`.
  static const int maxBackfillPerSeries = 100;

  Future<MaterializationSummary> execute() async {
    final seriesList =
        await _recurringRepository.getMaterializableRecurringSeries();
    final now = _clock.now();
    var newlyMaterializedOverdueCount = 0;
    var hasTruncatedHistory = false;

    for (final series in seriesList) {
      final result = await _materializeSeries(series, now);
      newlyMaterializedOverdueCount += result.newlyMaterializedOverdueCount;
      hasTruncatedHistory = hasTruncatedHistory || result.hasTruncatedHistory;
    }
    return MaterializationSummary(
      newlyMaterializedOverdueCount: newlyMaterializedOverdueCount,
      hasTruncatedHistory: hasTruncatedHistory,
    );
  }

  Future<MaterializationSummary> _materializeSeries(
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
        return MaterializationSummary.empty;
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
      if (!committed) return MaterializationSummary.empty;
      final overdueCount =
          (!series.autoPost && !series.startDate.isAfter(now)) ? 1 : 0;
      return MaterializationSummary(
        newlyMaterializedOverdueCount: overdueCount,
      );
    }

    final spec = series.toRecurrenceRuleSpec();

    final toInsert = <ScheduledTransactionsViewCompanion>[];
    var insertedOverdue = 0;

    // Phase 0 — historical overdue occurrences in
    // [max(materializeFrom, startOfMonth(nowYm - 11)), now], keeping at most
    // the 100 most recent occurrences per series so dormant relaunches stay
    // bounded and idempotent.
    final backfillFloor = RecurrenceExpander.backfillFloorForMonth(
      now,
      maxMonths: maxBackfillMonths,
    );
    final localMaterializeFrom = spec.effectiveMaterializeFrom.isUtc
        ? spec.effectiveMaterializeFrom.toLocal()
        : spec.effectiveMaterializeFrom;
    final effectiveLowerBound = localMaterializeFrom.isAfter(backfillFloor)
        ? localMaterializeFrom
        : backfillFloor;

    final overdueInWindow = _expander.expandInRange(
      spec,
      rangeStart: effectiveLowerBound,
      includeRangeStart: true,
      rangeEnd: now,
      includeRangeEnd: true,
      respectMaterializeFrom: true,
    );

    final List<RecurrenceOccurrence> overdueCandidates;
    var droppedByCountCap = false;
    if (overdueInWindow.length > maxBackfillPerSeries) {
      final dropCount = overdueInWindow.length - maxBackfillPerSeries;
      for (var i = 0; i < dropCount; i++) {
        if (!existing.containsKey(overdueInWindow[i].occurrenceKey)) {
          droppedByCountCap = true;
          break;
        }
      }
      overdueCandidates = overdueInWindow.sublist(dropCount);
    } else {
      overdueCandidates = overdueInWindow;
    }

    for (final occ in overdueCandidates) {
      if (existing.containsKey(occ.occurrenceKey)) continue;
      toInsert.add(_companionFor(series.id, occ));
      existing[occ.occurrenceKey] = ScheduledTransactionStatus.scheduled;
      insertedOverdue++;
    }

    var truncatedHistory = false;
    if (insertedOverdue > 0) {
      if (droppedByCountCap) {
        truncatedHistory = true;
      } else if (localMaterializeFrom.isBefore(backfillFloor)) {
        // Inspect at most `existing.length + 1` occurrences before the 12-month
        // floor: by the pigeonhole principle, if more exist than are already in
        // `existing`, at least one historical occurrence was never materialized.
        final olderCandidates = _expander.expandInRange(
          spec,
          rangeStart: localMaterializeFrom,
          includeRangeStart: true,
          rangeEnd: backfillFloor,
          includeRangeEnd: false,
          maxCount: existing.length + 1,
          respectMaterializeFrom: true,
        );
        for (final occ in olderCandidates) {
          if (!existing.containsKey(occ.occurrenceKey)) {
            truncatedHistory = true;
            break;
          }
        }
      }
    }

    // Phase 1 — all upcoming occurrences in (now, endOfMonth(nowYm + 1)],
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

    if (toInsert.isEmpty) return MaterializationSummary.empty;

    final committed =
        await _recurringRepository.insertMaterializedBatchIfActive(
      series.id,
      toInsert,
    );
    if (!committed) return MaterializationSummary.empty;
    return MaterializationSummary(
      newlyMaterializedOverdueCount: series.autoPost ? 0 : insertedOverdue,
      hasTruncatedHistory: truncatedHistory,
    );
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
  return ProjectRecurringEventsCommand(
    ref.watch(recurringRepositoryProvider),
    clock: ref.watch(ledgerClockProvider),
  );
}
