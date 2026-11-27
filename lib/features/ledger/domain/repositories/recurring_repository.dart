import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

abstract class RecurringRepository {
  Future<T> transaction<T>(Future<T> Function() action);

  Stream<List<ScheduledTransactionEntity>> watchAllScheduled({
    String? currencyCode,
  });

  Stream<List<ScheduledTransactionEntity>> watchPendingScheduled({
    String? currencyCode,
  });

  Stream<List<ScheduledTransactionEntity>> watchScheduledInRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
    String? currencyCode,
    bool pendingOnly = false,
  });

  /// A calendar month of pending bills for the ledger list. When
  /// [includeVirtual] is true, active series are expanded read-time and any
  /// occurrence without a physical `(seriesId, occurrenceKey)` row is
  /// returned with `isVirtual = true`.
  Stream<List<ScheduledTransactionEntity>> watchMonthlyPendingBills({
    required String currencyCode,
    required int year,
    required int month,
    required bool includeVirtual,
  });

  Future<ScheduledTransactionEntity?> getScheduledEntity(String id);

  Future<ScheduledTransactionEntity?> getScheduledEntityByOccurrence(
    String seriesId,
    String occurrenceKey,
  );

  Future<ScheduledTransactionViewRow?> getScheduled(String id);

  Future<RecurringSeriesRow?> getSeries(String id);

  Future<void> verifySeriesAccountActive(String accountId);

  Future<List<ScheduledTransactionViewRow>> scheduledForSeries(String seriesId);

  Future<void> insertOrUpdateScheduled(
      ScheduledTransactionsViewCompanion entry);

  Future<void> insertScheduledOrIgnore(
      ScheduledTransactionsViewCompanion entry);

  Future<int> skipIfScheduled(String id);

  Future<void> markManualOnly(String id);

  Future<int> markManualOnlyBatch(List<String> ids);

  Future<void> markSeriesManualOnlyBefore(String seriesId, DateTime cutoff);

  Future<int> markAllScheduledManualOnlyBefore(DateTime cutoff);

  Future<int> resetFailedToScheduledForSeries(String seriesId);

  Future<List<RecurringSeriesRow>> getAllRecurringSeries();

  Future<List<RecurringSeriesRow>> getMaterializableRecurringSeries();

  Future<void> insertMaterializedIfActive(
      ScheduledTransactionsViewCompanion entry);

  Future<bool> insertMaterializedBatchIfActive(
    String seriesId,
    List<ScheduledTransactionsViewCompanion> entries,
  );

  Future<void> saveSeries(RecurringSeriesCompanion entry);

  Future<void> deletePending(String seriesId, {DateTime? from});

  Future<void> deletePendingForSeries(String seriesId);

  Future<void> deletePendingAndSkippedForSeries(String seriesId);

  Future<void> restoreSkippedBill(String id, {required DateTime now});

  Future<void> deleteScheduledById(String id);

  Future<void> deleteAllScheduledForSeries(String seriesId);

  Future<void> deleteSeriesWithInstances(String seriesId);
}
