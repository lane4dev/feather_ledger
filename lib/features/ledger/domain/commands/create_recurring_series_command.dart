import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/ledger/domain/recurrence/recurrence_expander.dart';
import 'package:feather_ledger/features/ledger/domain/services/posting_context.dart';

part 'create_recurring_series_command.g.dart';

/// Creates a recurring series (spec 004, US2 / FR-006/FR-007).
///
/// `recurring_series` is the CRUD-exempt table: this writes it directly and
/// emits no event. The kind is [RecurringSeriesKind], so a transfer — which
/// needs a second account a series does not have — is unrepresentable rather
/// than rejected (ADR-0002).
///
/// It takes named values rather than a Drift companion so the view model
/// never imports Drift, and so the account/category red lines still run
/// through [PostingContextResolver] like every other writer.
class CreateRecurringSeriesCommand {
  final RecurringRepository _recurringRepository;
  final PostingContextResolver _context;

  CreateRecurringSeriesCommand(this._recurringRepository, this._context);

  Future<void> execute({
    required String id,
    required RecurringSeriesKind type,
    required int amountMinor,
    required String accountId,
    required String categoryId,
    required String description,
    required String frequency,
    required int interval,
    required DateTime startDate,
    DateTime? materializeFrom,
    DateTime? endDate,
    int? countLimit,
    List<int> weekdays = const [],
    bool autoPost = false,
    int? reminderMinutes,
    RecurringSeriesMode mode = RecurringSeriesMode.repeating,
  }) async {
    if (reminderMinutes != null && reminderMinutes <= 0) {
      throw const CommandRejected(
          LedgerErrorCode.invalidAmount, 'Reminder must be positive');
    }
    if (amountMinor <= 0) {
      throw const CommandRejected(
          LedgerErrorCode.invalidAmount, 'Series amount must be positive');
    }
    if (interval < 1) {
      throw const CommandRejected(
          LedgerErrorCode.invalidAmount, 'Series interval must be at least 1');
    }
    if ((countLimit != null && countLimit < 1) ||
        (countLimit != null && endDate != null) ||
        weekdays.any((d) => d < 1 || d > 7) ||
        (weekdays.isNotEmpty && frequency.toUpperCase() != 'WEEKLY')) {
      throw const CommandRejected(
          LedgerErrorCode.invalidAmount, 'Invalid recurrence rule');
    }
    if (endDate != null && endDate.isBefore(startDate)) {
      // Equal is the one-shot series (计划): UNTIL is inclusive, so a rule
      // capped at its own start date yields exactly one instance.
      throw const CommandRejected(LedgerErrorCode.invalidAmount,
          'Series end date must not be before its start date');
    }

    // The same red lines a manual record runs: the account and category must
    // exist, be usable, and agree on kind. A series that could never post is
    // rejected at creation rather than at its first due date.
    await _context.resolveForKind(
      accountId: accountId,
      categoryId: categoryId,
      kind: type.toTransactionKind,
    );

    final normalizedFrequency = frequency.toUpperCase();
    await _recurringRepository.saveSeries(
      RecurringSeriesCompanion.insert(
        id: id,
        rrule: rruleText(
          frequency: normalizedFrequency,
          interval: interval,
          endDate: endDate,
          countLimit: countLimit,
          weekdays: weekdays,
        ),
        startDate: startDate,
        endDate: Value(endDate),
        countLimit: Value(countLimit),
        frequency: normalizedFrequency,
        interval: Value(interval),
        amountMinor: amountMinor,
        description: description,
        categoryId: categoryId,
        accountId: accountId,
        type: type,
        autoPost: Value(autoPost),
        mode: Value(mode),
        reminderMinutes: Value(reminderMinutes),
        materializeFrom: Value(materializeFrom ?? startDate),
        completedCountOffset: const Value(0),
      ),
    );
  }

  /// Canonical RRULE text for the `rrule` column, delegated to
  /// [RecurrenceExpander] so serialization and expansion share one source of
  /// truth.
  static String rruleText({
    required String frequency,
    required int interval,
    DateTime? endDate,
    int? countLimit,
    List<int> weekdays = const [],
  }) =>
      RecurrenceExpander.formatRrule(
        frequency: frequency,
        interval: interval,
        endDate: endDate,
        countLimit: countLimit,
        weekdays: weekdays,
      );

  static List<int> weekdaysFromRrule(String? rrule) =>
      RecurrenceExpander.parseWeekdaysFromRrule(rrule);
}

@riverpod
CreateRecurringSeriesCommand createRecurringSeriesCommand(Ref ref) {
  return CreateRecurringSeriesCommand(
    ref.watch(recurringRepositoryProvider),
    ref.watch(postingContextResolverProvider),
  );
}
