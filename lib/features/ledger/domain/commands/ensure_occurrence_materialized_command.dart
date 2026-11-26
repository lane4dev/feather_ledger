import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/recurrence/recurrence_expander.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

part 'ensure_occurrence_materialized_command.g.dart';

/// Idempotently materializes a single logical occurrence `(seriesId, occurrenceKey)`
/// on write (e.g. when a user opens a far-future virtual pending bill from a
/// budget planning view).
///
/// Inside one database transaction:
/// 1. Verifies the series exists and is active (`isActive == true`).
/// 2. Verifies its account exists and is neither archived nor deleted.
/// 3. Verifies `(seriesId, occurrenceKey)` is a valid occurrence of the series
///    under [RecurrenceExpander] satisfying `>= series.materializeFrom` (or
///    `'single'` for `planned` series).
/// 4. Returns the existing resolved [ScheduledTransactionEntity] if already
///    materialized, otherwise inserts a standard `scheduled` UUID row with
///    `manualOnly = false` via `INSERT OR IGNORE` and returns it.
class EnsureOccurrenceMaterializedCommand {
  static final RegExp _civilDateKeyPattern =
      RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  final RecurringRepository _recurringRepository;
  final RecurrenceExpander _expander;

  EnsureOccurrenceMaterializedCommand(
    this._recurringRepository, {
    LocalDateTimeBuilder? buildDateTime,
  }) : _expander = buildDateTime == null
            ? const RecurrenceExpander()
            : RecurrenceExpander(buildDateTime: buildDateTime);

  Future<ScheduledTransactionEntity> execute({
    required String seriesId,
    required String occurrenceKey,
  }) {
    return _recurringRepository.transaction(() async {
      final series = await _recurringRepository.getSeries(seriesId);
      if (series == null || !series.isActive) {
        throw const CommandRejected(
          LedgerErrorCode.recurringSeriesStopped,
          'Recurring series has been stopped',
        );
      }

      await _recurringRepository.verifySeriesAccountActive(series.accountId);

      final matched = _matchScheduledOccurrence(series, occurrenceKey);
      if (matched == null) {
        throw const CommandRejected(
          LedgerErrorCode.transactionNotFound,
          'Scheduled occurrence does not match recurring series schedule',
        );
      }

      final existing = await _recurringRepository
          .getScheduledEntityByOccurrence(seriesId, occurrenceKey);
      if (existing != null) {
        return existing;
      }

      await _recurringRepository.insertScheduledOrIgnore(
        ScheduledTransactionsViewCompanion(
          id: Value(const Uuid().v4()),
          seriesId: Value(series.id),
          occurrenceKey: Value(matched.occurrenceKey),
          scheduledDate: Value(matched.scheduledDate),
          status: Value(ScheduledTransactionStatus.scheduled.toStorage()),
          manualOnly: const Value(false),
        ),
      );

      final resolved = await _recurringRepository
          .getScheduledEntityByOccurrence(seriesId, occurrenceKey);
      if (resolved == null) {
        throw const CommandRejected(
          LedgerErrorCode.transactionNotFound,
          'Failed to materialize scheduled occurrence',
        );
      }
      return resolved;
    });
  }

  RecurrenceOccurrence? _matchScheduledOccurrence(
    RecurringSeriesRow series,
    String occurrenceKey,
  ) {
    final spec = series.toRecurrenceRuleSpec();

    if (series.mode == RecurringSeriesMode.planned) {
      if (occurrenceKey != kPlannedOccurrenceKey) return null;
      final localStart = series.startDate.isUtc
          ? series.startDate.toLocal()
          : series.startDate;
      final matches = _expander.expandInRange(
        spec,
        rangeStart: DateTime(localStart.year, localStart.month, localStart.day),
        rangeEnd: DateTime(
          localStart.year,
          localStart.month,
          localStart.day,
          23,
          59,
          59,
        ),
        includeRangeStart: true,
        includeRangeEnd: true,
        respectMaterializeFrom: true,
      );
      return matches.firstOrNull;
    }

    final parsed = _parseCivilDateKey(occurrenceKey);
    if (parsed == null) return null;
    final (year, month, day) = parsed;
    final matches = _expander.expandInRange(
      spec,
      rangeStart: DateTime(year, month, day, 0, 0, 0),
      rangeEnd: DateTime(year, month, day, 23, 59, 59),
      includeRangeStart: true,
      includeRangeEnd: true,
      respectMaterializeFrom: true,
    );
    for (final occ in matches) {
      if (occ.occurrenceKey == occurrenceKey) return occ;
    }
    return null;
  }

  static (int, int, int)? _parseCivilDateKey(String key) {
    final match = _civilDateKeyPattern.firstMatch(key);
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final probe = DateTime(year, month, day);
    if (probe.year != year || probe.month != month || probe.day != day) {
      return null;
    }
    return (year, month, day);
  }
}

@riverpod
EnsureOccurrenceMaterializedCommand ensureOccurrenceMaterializedCommand(
  Ref ref,
) {
  return EnsureOccurrenceMaterializedCommand(
    ref.watch(recurringRepositoryProvider),
  );
}
