import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

abstract class RecurringRepository {
  Stream<List<ScheduledTransactionEntity>> watchAllScheduled();

  Future<ScheduledTransactionViewRow?> getScheduled(String id);

  Future<RecurringSeriesRow?> getSeries(String id);

  Future<List<ScheduledTransactionViewRow>> scheduledForSeries(String seriesId);

  Future<void> insertOrUpdateScheduled(
      ScheduledTransactionsViewCompanion entry);

  Future<int> skipIfScheduled(String id);

  Future<void> markManualOnly(String id);

  Future<void> markSeriesManualOnlyBefore(String seriesId, DateTime cutoff);

  Future<int> markAllScheduledManualOnlyBefore(DateTime cutoff);

  Future<int> resetFailedToScheduledForSeries(String seriesId);

  Future<List<RecurringSeriesRow>> getAllRecurringSeries();

  Future<List<RecurringSeriesRow>> getMaterializableRecurringSeries();

  Future<void> insertMaterializedIfActive(
      ScheduledTransactionsViewCompanion entry);

  Future<void> saveSeries(RecurringSeriesCompanion entry);

  Future<void> deletePending(String seriesId, {DateTime? from});

  Future<void> deletePendingForSeries(String seriesId);

  Future<void> deleteScheduledById(String id);

  Future<void> deleteAllScheduledForSeries(String seriesId);

  Future<void> deleteSeriesWithInstances(String seriesId);
}
