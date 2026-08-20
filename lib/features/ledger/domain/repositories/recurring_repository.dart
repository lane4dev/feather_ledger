import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

abstract class RecurringRepository {
  /// Watches all scheduled transactions along with their series details.
  /// Returns a stream of a list of [ScheduledTransactionEntity].
  Stream<List<ScheduledTransactionEntity>> watchAllScheduled();

  /// Retrieves a scheduled transaction by its [id].
  /// Returns a [ScheduledTransactionViewRow] or null if not found.
  Future<ScheduledTransactionViewRow?> getScheduled(String id);

  /// Retrieves a recurring series by its [id].
  /// Returns a [RecurringSeriesRow] or null if not found.
  Future<RecurringSeriesRow?> getSeries(String id);

  /// Every instance of one series, whatever its status. Materialization reads
  /// this once per series rather than probing per candidate date.
  Future<List<ScheduledTransactionViewRow>> scheduledForSeries(String seriesId);

  /// Inserts or updates a scheduled transaction.
  /// Takes a [ScheduledTransactionsViewCompanion] entry.
  Future<void> insertOrUpdateScheduled(
      ScheduledTransactionsViewCompanion entry);

  /// Changes a scheduled bill to skipped only if it is still scheduled.
  Future<int> skipIfScheduled(String id);

  /// Retrieves all recurring series.
  /// Returns a list of [RecurringSeriesRow].
  Future<List<RecurringSeriesRow>> getAllRecurringSeries();

  /// Series eligible to generate bills; archived accounts pause generation.
  Future<List<RecurringSeriesRow>> getMaterializableRecurringSeries();

  /// Insert a generated instance only while its account remains active.
  Future<void> insertMaterializedIfActive(
      ScheduledTransactionsViewCompanion entry);

  /// Inserts or updates a series (spec 004, US2). `recurring_series` is
  /// CRUD-exempt — this writes the table directly and emits no event.
  Future<void> saveSeries(RecurringSeriesCompanion entry);

  /// Deletes the pending instances of one series, at or after [from] when
  /// given and all of them when not.
  ///
  /// Bills already recorded are real movements, and bills already skipped are
  /// tombstones materialization respects; neither is "pending", and deleting
  /// either would be a lie about what happened.
  Future<void> deletePending(String seriesId, {DateTime? from});

  /// Deletes a series and every instance row belonging to it.
  ///
  /// Recorded *transactions* are not instance rows and are not touched — they
  /// survive as ordinary ledger entries.
  Future<void> deleteSeriesWithInstances(String seriesId);
}
