import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/ledger/domain/services/posting_context.dart';

part 'create_recurring_series_command.g.dart';

/// Creates a recurring series (spec 004, US2 / FR-006/FR-007).
///
/// `recurring_series` is the CRUD-exempt table: this writes it directly and
/// emits no event, exactly like [InsertOrUpdateScheduledTransactionCommand].
/// The kind is [RecurringSeriesKind], so a transfer — which needs a second
/// account a series does not have — is unrepresentable rather than rejected
/// (ADR-0002).
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
    DateTime? endDate,
  }) async {
    if (amountMinor <= 0) {
      throw const CommandRejected(
          LedgerErrorCode.invalidAmount, 'Series amount must be positive');
    }
    if (interval < 1) {
      throw const CommandRejected(
          LedgerErrorCode.invalidAmount, 'Series interval must be at least 1');
    }
    if (endDate != null && !endDate.isAfter(startDate)) {
      throw const CommandRejected(LedgerErrorCode.invalidAmount,
          'Series end date must be after its start date');
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
        rrule: _rruleText(
          frequency: normalizedFrequency,
          interval: interval,
          endDate: endDate,
        ),
        startDate: startDate,
        endDate: Value(endDate),
        frequency: normalizedFrequency,
        interval: Value(interval),
        amountMinor: amountMinor,
        description: description,
        categoryId: categoryId,
        accountId: accountId,
        type: type,
      ),
    );
  }

  /// Canonical RRULE text for the `rrule` column.
  ///
  /// Nothing reads that column yet — materialization builds its rule from the
  /// discrete columns — so this exists for a future import/export consumer.
  // ponytail: rrule and the discrete columns encode the same schedule;
  // converge on rrule if a second consumer ever appears.
  static String _rruleText({
    required String frequency,
    required int interval,
    DateTime? endDate,
  }) {
    final buffer = StringBuffer('FREQ=$frequency');
    if (interval != 1) buffer.write(';INTERVAL=$interval');
    if (endDate != null) {
      final utc = endDate.toUtc();
      buffer.write(';UNTIL=${utc.year.toString().padLeft(4, '0')}'
          '${utc.month.toString().padLeft(2, '0')}'
          '${utc.day.toString().padLeft(2, '0')}T000000Z');
    }
    return buffer.toString();
  }
}

@riverpod
CreateRecurringSeriesCommand createRecurringSeriesCommand(Ref ref) {
  return CreateRecurringSeriesCommand(
    ref.watch(recurringRepositoryProvider),
    ref.watch(postingContextResolverProvider),
  );
}
