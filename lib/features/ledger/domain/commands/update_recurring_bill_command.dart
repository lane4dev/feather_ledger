import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/services/posting_context.dart';

part 'update_recurring_bill_command.g.dart';

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

  Future<void> execute({
    required String scheduledId,
    required RecurringScope scope,
    required int amountMinor,
    required DateTime date,
    required String categoryId,
    required String accountId,
    required String description,
    String? frequency,
    int? interval,
    DateTime? endDate,
    int? countLimit,
    List<int>? weekdays,
    bool? autoPost,
    int? reminderMinutes,
  }) async {
    if (amountMinor <= 0) {
      throw const CommandRejected(
        LedgerErrorCode.invalidAmount,
        'Amount must be positive',
      );
    }

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

    final hasRuleChange = categoryId != series.categoryId ||
        accountId != series.accountId ||
        (autoPost != null && autoPost != series.autoPost) ||
        (frequency != null && frequency != series.frequency) ||
        (interval != null && interval != series.interval) ||
        (endDate != null && endDate != series.endDate) ||
        (countLimit != null && countLimit != series.countLimit);
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
      await _recurringRepository.insertOrUpdateScheduled(
        ScheduledTransactionsViewCompanion(
          id: Value(scheduled.id),
          seriesId: Value(scheduled.seriesId),
          occurrenceKey: Value(scheduled.occurrenceKey),
          scheduledDate: Value(scheduled.scheduledDate),
          amountOverrideMinor: Value(
              amountMinor == series.amountMinor ? null : amountMinor),
          dateOverride: Value(
              date.isAtSameMomentAs(scheduled.scheduledDate) ? null : date),
          memoOverride: Value(
              description == series.description ? null : description),
          status: Value(ScheduledTransactionStatus.scheduled.toStorage()),
          manualOnly: Value(scheduled.manualOnly),
          transactionId: Value(scheduled.transactionId),
        ),
      );
      return;
    }

    final effectiveAutoPost = autoPost ?? series.autoPost;
    final nextFrequency = frequency ?? series.frequency;
    final nextInterval = interval ?? series.interval ?? 1;
    final nextRrule = _buildRrule(
      frequency: nextFrequency,
      interval: nextInterval,
      weekdays: weekdays ?? const [],
    );

    final currentDate = scheduled.dateOverride ?? scheduled.scheduledDate;
    final nextEndDate = series.mode == RecurringSeriesMode.planned
        ? date
        : (endDate ?? series.endDate);
    final nextCountLimit = countLimit ?? series.countLimit;
    final scheduleChanged = !date.isAtSameMomentAs(currentDate) ||
        nextFrequency != series.frequency ||
        nextInterval != series.interval ||
        nextEndDate != series.endDate ||
        nextCountLimit != series.countLimit;

    final nextStartDate = series.mode == RecurringSeriesMode.planned
        ? date
        : (scheduleChanged ? date : series.startDate);

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
        reminderMinutes: Value(reminderMinutes),
        mode: Value(series.mode),
        isActive: Value(series.isActive),
      ),
    );

    if (series.mode == RecurringSeriesMode.planned) {
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
          manualOnly: Value(scheduled.manualOnly),
          transactionId: Value(scheduled.transactionId),
        ),
      );
      return;
    }

    if (scheduleChanged) {
      await _recurringRepository.deletePendingForSeries(series.id);
      if (effectiveAutoPost && !date.isAfter(_clock.now())) {
        await _recurringRepository.insertOrUpdateScheduled(
          ScheduledTransactionsViewCompanion(
            id: Value(const Uuid().v4()),
            seriesId: Value(series.id),
            occurrenceKey: Value(scheduledOccurrenceKey(date.toUtc())),
            scheduledDate: Value(date),
            status: Value(ScheduledTransactionStatus.scheduled.toStorage()),
            manualOnly: const Value(true),
          ),
        );
      }
    } else if (!series.autoPost && effectiveAutoPost) {
      await _recurringRepository.markSeriesManualOnlyBefore(
          series.id, _clock.now());
    }
  }

  String _buildRrule({
    required String frequency,
    required int interval,
    required List<int> weekdays,
  }) {
    final buffer = StringBuffer('FREQ=${frequency.toUpperCase()}');
    if (interval > 1) buffer.write(';INTERVAL=$interval');
    if (weekdays.isNotEmpty) {
      const codes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
      final byDay = weekdays.map((d) => codes[(d - 1).clamp(0, 6)]).join(',');
      buffer.write(';BYDAY=$byDay');
    }
    return buffer.toString();
  }
}

@riverpod
UpdateRecurringBillCommand updateRecurringBillCommand(Ref ref) {
  return UpdateRecurringBillCommand(
    ref.watch(recurringRepositoryProvider),
    ref.watch(postingContextResolverProvider),
  );
}
