import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';

part 'deactivate_recurring_series_command.g.dart';

/// Stops a recurring series producing new instances (spec 004, US2 / FR-012).
///
/// Deactivation sets `endDate`, which is what `ProjectRecurringEventsCommand`
/// filters on, so no future instance is ever materialized again. Existing
/// instances are kept on purpose: past ones are history, and pending future
/// ones stay visible so the user can post or skip each deliberately rather
/// than having them vanish.
class DeactivateRecurringSeriesCommand {
  final RecurringRepository _recurringRepository;

  DeactivateRecurringSeriesCommand(this._recurringRepository);

  Future<void> execute(String seriesId, {required DateTime endDate}) async {
    final series = await _recurringRepository.getSeries(seriesId);
    if (series == null) {
      // Same code the existing "series not found" path uses
      // (ConvertScheduledToPostedCommand); a dedicated code would mean four
      // more ARB entries for no user-visible difference.
      throw CommandRejected(
          LedgerErrorCode.transactionNotFound, 'Series $seriesId not found');
    }

    await _recurringRepository.saveSeries(
      RecurringSeriesCompanion(
        id: Value(series.id),
        rrule: Value(series.rrule),
        startDate: Value(series.startDate),
        endDate: Value(endDate),
        frequency: Value(series.frequency),
        interval: Value(series.interval),
        countLimit: Value(series.countLimit),
        amountMinor: Value(series.amountMinor),
        description: Value(series.description),
        categoryId: Value(series.categoryId),
        accountId: Value(series.accountId),
        type: Value(series.type),
      ),
    );
  }
}

@riverpod
DeactivateRecurringSeriesCommand deactivateRecurringSeriesCommand(Ref ref) {
  return DeactivateRecurringSeriesCommand(
      ref.watch(recurringRepositoryProvider));
}
