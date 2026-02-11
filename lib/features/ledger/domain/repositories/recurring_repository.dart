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

  /// Inserts or updates a scheduled transaction.
  /// Takes a [ScheduledTransactionsViewCompanion] entry.
  Future<void> insertOrUpdateScheduled(
      ScheduledTransactionsViewCompanion entry);

  /// Retrieves all recurring series.
  /// Returns a list of [RecurringSeriesRow].
  Future<List<RecurringSeriesRow>> getAllRecurringSeries();
}
