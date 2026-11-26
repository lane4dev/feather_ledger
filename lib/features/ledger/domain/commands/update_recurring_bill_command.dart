import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/recurrence/recurrence_expander.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/ledger/domain/commands/create_recurring_series_command.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/recurrence/distant_past_guard.dart';
import 'package:feather_ledger/features/ledger/domain/services/posting_context.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart'
    show ledgerClockProvider;

part 'update_recurring_bill_command.g.dart';

/// Post-update actions requested by [UpdateRecurringBillCommand.execute].
class UpdateRecurringBillResult {
  /// Non-null when `updateRule` leaves `autoPost` enabled so the caller can
  /// trigger an immediate catch-up pass for this series in the active currency.
  final String? autoPostSeriesId;

  /// Non-null when `updateRule` on a repeating series changed the base
  /// schedule (or `materializeFrom`), so newly materialized occurrences strictly
  /// before `startOfDay(now)` must be latched `manualOnly = true`.
  final String? guardPastSeriesId;

  const UpdateRecurringBillResult({
    this.autoPostSeriesId,
    this.guardPastSeriesId,
  });

  static const UpdateRecurringBillResult none = UpdateRecurringBillResult();
}

/// Edits a pending bill under one of the two v15 scopes:
/// - `thisOnly`: stores sparse override columns (`amountOverrideMinor`,
///   `dateOverride`, `memoOverride`) directly on the UUID instance row.
/// - `updateRule`: updates the series template (and clears/re-materializes
///   pending future instances when schedule/date changed).
class UpdateRecurringBillCommand {
  final RecurringRepository _recurringRepository;
  final PostingContextResolver _postingContext;
  final DomainClock _clock;

  UpdateRecurringBillCommand(
    this._recurringRepository,
    this._postingContext, {
    DomainClock? clock,
  }) : _clock = clock ?? const SystemClock();

  /// Returns an [UpdateRecurringBillResult] describing whether newly
  /// materialized past occurrences must be latched `manualOnly` and whether
  /// `autoPost` catch-up should run for this series.
  Future<UpdateRecurringBillResult> execute({
    required String scheduledId,
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
  }) async {
    if (amountMinor <= 0) {
      throw const CommandRejected(
        LedgerErrorCode.invalidAmount,
        'Amount must be positive',
      );
    }
    if (reminderMinutes != null && reminderMinutes <= 0) {
      throw const CommandRejected(
        LedgerErrorCode.invalidAmount,
        'Reminder must be positive',
      );
    }

    return _recurringRepository.transaction(() async {
      final scheduled = await _recurringRepository.getScheduled(scheduledId);
      if (scheduled == null) {
        throw const CommandRejected(
          LedgerErrorCode.transactionNotFound,
          'Scheduled bill not found',
        );
      }
      if (scheduled.status == ScheduledTransactionStatus.posted.toStorage()) {
        throw const CommandRejected(
          LedgerErrorCode.scheduledAlreadyPosted,
          'Posted bills cannot be edited',
        );
      }
      if (scheduled.status == ScheduledTransactionStatus.skipped.toStorage()) {
        throw const CommandRejected(
          LedgerErrorCode.transactionNotFound,
          'Skipped bill cannot be edited',
        );
      }

      final series = await _recurringRepository.getSeries(scheduled.seriesId);
      if (series == null) {
        throw const CommandRejected(
          LedgerErrorCode.transactionNotFound,
          'Recurring series not found',
        );
      }

      final existingWeekdays =
          CreateRecurringSeriesCommand.weekdaysFromRrule(series.rrule);
      final normalizedFrequency = frequency?.toUpperCase();
      final hasRuleChange = categoryId != series.categoryId ||
          accountId != series.accountId ||
          (autoPost != null && autoPost != series.autoPost) ||
          (normalizedFrequency != null &&
              normalizedFrequency != series.frequency) ||
          (interval != null && interval != series.interval) ||
          (clearEndDate && series.endDate != null) ||
          (!clearEndDate &&
              endDate != null &&
              !_sameMoment(endDate, series.endDate)) ||
          (clearCountLimit && series.countLimit != null) ||
          (!clearCountLimit &&
              countLimit != null &&
              countLimit != series.countLimit) ||
          (weekdays != null &&
              !DistantPastStartGuard.sameWeekdays(weekdays, existingWeekdays)) ||
          (clearReminder && series.reminderMinutes != null) ||
          (!clearReminder &&
              reminderMinutes != null &&
              reminderMinutes != series.reminderMinutes);
      if (scope == RecurringScope.thisOnly && hasRuleChange) {
        throw const CommandRejected(
          LedgerErrorCode.invalidTransactionShape,
          'Rule-only fields cannot be edited in thisOnly scope',
        );
      }

      await _postingContext.resolveForKind(
        accountId: accountId,
        categoryId: categoryId,
        kind: series.type.toTransactionKind,
      );

      if (scope == RecurringScope.thisOnly) {
        final nextDateOverride =
            date.isAtSameMomentAs(scheduled.scheduledDate) ? null : date;
        final dateChanged =
            !_sameMoment(nextDateOverride, scheduled.dateOverride);
        if (dateChanged) {
          final targetDayKey = scheduledOccurrenceKey(date);
          final rows =
              await _recurringRepository.scheduledForSeries(series.id);
          final physicalCollides = rows.any((row) {
            if (row.id == scheduled.id) return false;
            if (row.status ==
                ScheduledTransactionStatus.skipped.toStorage()) {
              return false;
            }
            final rowEffectiveDate = row.dateOverride ?? row.scheduledDate;
            return scheduledOccurrenceKey(rowEffectiveDate) == targetDayKey;
          });
          var collides = physicalCollides;
          if (!collides &&
              series.mode == RecurringSeriesMode.repeating &&
              series.isActive) {
            final localTarget = date.isUtc ? date.toLocal() : date;
            final targetDayStart = DateTime(
              localTarget.year,
              localTarget.month,
              localTarget.day,
            );
            final targetDayEnd = DateTime(
              localTarget.year,
              localTarget.month,
              localTarget.day,
              23,
              59,
              59,
              999,
            );
            final logicalOccurrences = const RecurrenceExpander().expandInRange(
              series.toRecurrenceRuleSpec(),
              rangeStart: targetDayStart,
              rangeEnd: targetDayEnd,
              includeRangeStart: true,
              includeRangeEnd: true,
              respectMaterializeFrom: true,
            );
            final physicalByKey = {
              for (final row in rows) row.occurrenceKey: row,
            };
            for (final occ in logicalOccurrences) {
              if (occ.occurrenceKey != targetDayKey) continue;
              if (occ.occurrenceKey == scheduled.occurrenceKey) continue;
              final physical = physicalByKey[occ.occurrenceKey];
              if (physical == null) {
                collides = true;
                break;
              }
              final isSkipped = physical.status ==
                  ScheduledTransactionStatus.skipped.toStorage();
              final movedAway = physical.dateOverride != null &&
                  scheduledOccurrenceKey(physical.dateOverride!) !=
                      targetDayKey;
              if (!isSkipped && !movedAway) {
                collides = true;
                break;
              }
            }
          }
          if (collides) {
            throw const CommandRejected(
              LedgerErrorCode.scheduledDateTaken,
              'Another occurrence of this series already falls on this date',
            );
          }
        }
        final clearToAuto = series.autoPost && date.isAfter(_clock.now());
        await _recurringRepository.insertOrUpdateScheduled(
          ScheduledTransactionsViewCompanion(
            id: Value(scheduled.id),
            seriesId: Value(scheduled.seriesId),
            occurrenceKey: Value(scheduled.occurrenceKey),
            scheduledDate: Value(scheduled.scheduledDate),
            amountOverrideMinor: Value(
                amountMinor == series.amountMinor ? null : amountMinor),
            dateOverride: Value(nextDateOverride),
            memoOverride: Value(
                description == series.description ? null : description),
            status: Value(ScheduledTransactionStatus.scheduled.toStorage()),
            manualOnly: Value(clearToAuto ? false : scheduled.manualOnly),
            transactionId: Value(scheduled.transactionId),
          ),
        );
        return UpdateRecurringBillResult.none;
      }

      final effectiveAutoPost = autoPost ?? series.autoPost;
      final nextFrequency = normalizedFrequency ?? series.frequency;
      final nextInterval = interval ?? series.interval ?? 1;
      final nextWeekdays = nextFrequency == 'WEEKLY'
          ? (weekdays ?? existingWeekdays)
          : const <int>[];
      final nextEndDate = series.mode == RecurringSeriesMode.planned
          ? date
          : (clearEndDate ? null : (endDate ?? series.endDate));
      final nextCountLimit = series.mode == RecurringSeriesMode.planned
          ? null
          : (clearCountLimit ? null : (countLimit ?? series.countLimit));
      final nextReminderMinutes =
          clearReminder ? null : (reminderMinutes ?? series.reminderMinutes);

      if (nextInterval < 1 ||
          (nextCountLimit != null && nextCountLimit < 1) ||
          (nextCountLimit != null && nextEndDate != null) ||
          nextWeekdays.any((d) => d < 1 || d > 7)) {
        throw const CommandRejected(
          LedgerErrorCode.invalidAmount,
          'Invalid recurrence rule',
        );
      }

      final currentDate = scheduled.dateOverride ?? scheduled.scheduledDate;
      final baseScheduleChanged = DistantPastStartGuard.hasBaseScheduleChanged(
        currentDate: currentDate,
        nextDate: date,
        currentFrequency: series.frequency,
        nextFrequency: nextFrequency,
        currentInterval: series.interval,
        nextInterval: nextInterval,
        currentWeekdays: existingWeekdays,
        nextWeekdays: nextWeekdays,
      );
      final endConditionChanged = !_sameMoment(nextEndDate, series.endDate) ||
          nextCountLimit != series.countLimit;

      final nextStartDate = series.mode == RecurringSeriesMode.planned
          ? date
          : (baseScheduleChanged ? date : series.startDate);

      if (nextEndDate != null && nextEndDate.isBefore(nextStartDate)) {
        throw const CommandRejected(
          LedgerErrorCode.invalidAmount,
          'Series end date must not be before its start date',
        );
      }

      var nextCompletedCountOffset = series.completedCountOffset;
      if (series.mode == RecurringSeriesMode.repeating &&
          (baseScheduleChanged || nextCountLimit != null)) {
        final rows = await _recurringRepository.scheduledForSeries(series.id);
        final postedCount = rows
            .where((row) =>
                row.status == ScheduledTransactionStatus.posted.toStorage())
            .length;
        if (baseScheduleChanged) {
          nextCompletedCountOffset = postedCount;
        }
        if (nextCountLimit != null) {
          final skippedCount = baseScheduleChanged
              ? 0
              : rows
                  .where((row) =>
                      row.status ==
                      ScheduledTransactionStatus.skipped.toStorage())
                  .length;
          final k = postedCount + skippedCount;
          if (nextCountLimit < k + 1) {
            throw CommandRejected(
              LedgerErrorCode.countLimitTooSmall,
              'countLimit ($nextCountLimit) must be at least ${k + 1} '
              '($k recorded/skipped + 1 remaining)',
            );
          }
        }
      }

      final nextRrule = CreateRecurringSeriesCommand.rruleText(
        frequency: nextFrequency,
        interval: nextInterval,
        endDate: nextEndDate,
        countLimit: nextCountLimit,
        weekdays: nextWeekdays,
      );

      final nextMaterializeFrom = series.mode == RecurringSeriesMode.planned
          ? nextStartDate
          : (materializeFrom ??
              (baseScheduleChanged ? nextStartDate : series.materializeFrom));
      final materializeFromChanged =
          !_sameMoment(nextMaterializeFrom, series.materializeFrom);

      await _recurringRepository.saveSeries(
        RecurringSeriesCompanion(
          id: Value(series.id),
          rrule: Value(nextRrule),
          startDate: Value(nextStartDate),
          endDate: Value(nextEndDate),
          frequency: Value(nextFrequency),
          interval: Value(nextInterval),
          countLimit: Value(nextCountLimit),
          amountMinor: Value(amountMinor),
          description: Value(description),
          categoryId: Value(categoryId),
          accountId: Value(accountId),
          type: Value(series.type),
          autoPost: Value(effectiveAutoPost),
          reminderMinutes: Value(nextReminderMinutes),
          mode: Value(series.mode),
          isActive: Value(series.isActive),
          materializeFrom: Value(nextMaterializeFrom),
          completedCountOffset: Value(nextCompletedCountOffset),
        ),
      );

      if (series.mode == RecurringSeriesMode.planned) {
        final clearToAuto = effectiveAutoPost &&
            (!series.autoPost || date.isAfter(_clock.now()));
        await _recurringRepository.insertOrUpdateScheduled(
          ScheduledTransactionsViewCompanion(
            id: Value(scheduled.id),
            seriesId: Value(series.id),
            occurrenceKey: const Value(kPlannedOccurrenceKey),
            scheduledDate: Value(date),
            amountOverrideMinor: const Value(null),
            dateOverride: const Value(null),
            memoOverride: const Value(null),
            status: Value(ScheduledTransactionStatus.scheduled.toStorage()),
            manualOnly: Value(clearToAuto ? false : scheduled.manualOnly),
            transactionId: Value(scheduled.transactionId),
          ),
        );
        return UpdateRecurringBillResult(
          autoPostSeriesId: effectiveAutoPost ? series.id : null,
        );
      }

      if (baseScheduleChanged) {
        await _recurringRepository.deletePendingAndSkippedForSeries(series.id);
      } else if (endConditionChanged || materializeFromChanged) {
        await _recurringRepository.deletePendingForSeries(series.id);
      } else {
        await _recurringRepository.resetFailedToScheduledForSeries(series.id);
      }
      return UpdateRecurringBillResult(
        autoPostSeriesId: effectiveAutoPost ? series.id : null,
        guardPastSeriesId: (baseScheduleChanged || materializeFromChanged)
            ? series.id
            : null,
      );
    });
  }

  static bool _sameMoment(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.isAtSameMomentAs(b);
  }
}

@riverpod
UpdateRecurringBillCommand updateRecurringBillCommand(Ref ref) {
  return UpdateRecurringBillCommand(
    ref.watch(recurringRepositoryProvider),
    ref.watch(postingContextResolverProvider),
    clock: ref.watch(ledgerClockProvider),
  );
}
