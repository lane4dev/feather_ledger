import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/domain/commands/convert_scheduled_to_posted_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/create_recurring_series_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/deactivate_recurring_series_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/project_recurring_events_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/skip_scheduled_transaction_command.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_scheduled_transactions_query.dart';

part 'recurring_service.g.dart';

/// The write/read seam for recurring bills (spec 004, US2).
///
/// This is the only bridge between the two halves of the recurring model:
/// `recurring_series` / `scheduled_transactions_view` are CRUD-exempt tables
/// that no event touches, and posting an instance is the one action that
/// crosses into the event-sourced ledger. Everything the screens do goes
/// through here, so a unit test wires one service rather than five commands.
class RecurringService {
  final CreateRecurringSeriesCommand _createSeries;
  final DeactivateRecurringSeriesCommand _deactivateSeries;
  final SkipScheduledTransactionCommand _skipInstance;
  final ConvertScheduledToPostedCommand _postInstance;
  final ProjectRecurringEventsCommand _projectInstances;
  final WatchScheduledTransactionsQuery _watchScheduled;

  RecurringService(
    this._createSeries,
    this._deactivateSeries,
    this._skipInstance,
    this._postInstance,
    this._projectInstances,
    this._watchScheduled,
  );

  Stream<List<ScheduledTransactionEntity>> watchScheduled() =>
      _watchScheduled.execute();

  /// Creates a series and immediately materializes it, so a new series shows
  /// up as pending instances instead of only after the next launch.
  Future<Result<void>> createSeries({
    required RecurringSeriesKind type,
    required int amountMinor,
    required String accountId,
    required String categoryId,
    required String description,
    required String frequency,
    required int interval,
    required DateTime startDate,
    DateTime? endDate,
  }) {
    return guard(() async {
      await _createSeries.execute(
        id: const Uuid().v4(),
        type: type,
        amountMinor: amountMinor,
        accountId: accountId,
        categoryId: categoryId,
        description: description,
        frequency: frequency,
        interval: interval,
        startDate: startDate,
        endDate: endDate,
      );
      await materialize();
    });
  }

  Future<Result<void>> deactivateSeries(String seriesId,
      {required DateTime endDate}) {
    return guard(() => _deactivateSeries.execute(seriesId, endDate: endDate));
  }

  /// Posts a due instance into the ledger: one `TransactionRecorded`, with the
  /// status flip riding the same append transaction.
  ///
  /// [commandId] is normally left null and minted per call. It stays a
  /// parameter so a caller that already owns an idempotency key — a retry, or
  /// a test asserting on one — can supply its own.
  Future<Result<void>> postInstance(String scheduledId, {String? commandId}) {
    return guard(() => _postInstance.execute(scheduledId,
        commandId: commandId ?? const Uuid().v4()));
  }

  /// Skips a due instance. Writes no event and moves no money.
  Future<Result<void>> skipInstance(String scheduledId) {
    return guard(() => _skipInstance.execute(scheduledId));
  }

  /// Rolls the 90-day window forward for every series. Idempotent, so it is
  /// safe on every launch and after every series creation.
  Future<void> materialize() => _projectInstances.execute();
}

@riverpod
RecurringService recurringService(Ref ref) {
  return RecurringService(
    ref.watch(createRecurringSeriesCommandProvider),
    ref.watch(deactivateRecurringSeriesCommandProvider),
    ref.watch(skipScheduledTransactionCommandProvider),
    ref.watch(convertScheduledToPostedCommandProvider),
    ref.watch(projectRecurringEventsCommandProvider),
    ref.watch(watchScheduledTransactionsQueryProvider),
  );
}
