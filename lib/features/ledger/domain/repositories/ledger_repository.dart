import 'package:feather_ledger/features/ledger/domain/value_objects/monthly_summary.dart';

import '../entities/ledger_entities.dart';

abstract class LedgerRepository {
  /// Watches the monthly summary for the given month.
  /// [month] should be any date within the desired month.
  /// Returns a stream of [MonthlySummary].
  Stream<MonthlySummary> watchMonthlySummary(DateTime month);

  /// Watches transactions for the given month.
  /// [month] should be any date within the desired month.
  /// Returns a stream of lists of [TransactionEntity].
  Stream<List<TransactionEntity>> watchTransactions(DateTime month);

  /// Retrieves a transaction by its ID.
  /// [transactionId] is the ID of the transaction.
  /// Returns a [TransactionEntity] or null if not found.
  Future<TransactionEntity?> getTransaction(String transactionId);

  /// Inserts or updates a transaction.
  /// [transaction] is the [TransactionEntity] to insert or update.
  /// Returns a [Future] that completes when the operation is done.
  Future<void> insertOrUpdateTransaction(TransactionEntity transaction);

  /// Deletes a transaction by its ID.
  /// [transactionId] is the ID of the transaction to delete.
  Future<void> deleteTransaction(String transactionId);

  /// Watches all scheduled transactions.
  /// Returns a stream of lists of [ScheduledTransactionEntity].
  Stream<List<ScheduledTransactionEntity>> watchScheduledTransactions();

  /// Retrieves a scheduled transaction by its ID.
  /// [scheduledId] is the ID of the scheduled transaction.
  /// Returns a [ScheduledTransactionEntity] or null if not found.
  Future<ScheduledTransactionEntity?> getScheduledTransaction(
      String scheduledId);

  /// Retrieves a recurring transaction series by its ID.
  /// [seriesId] is the ID of the recurring transaction series.
  /// Returns a [RecurringTransactionSeriesEntity] or null if not found.
  Future<RecurringTransactionSeriesEntity?> getRecurringTransactionSeries(
      String seriesId);

  /// Retrieves all recurring transaction series.
  /// Returns a list of [RecurringTransactionSeriesEntity].
  Future<List<RecurringTransactionSeriesEntity>> getAllRecurringSeries();

  /// Inserts or updates a scheduled transaction.
  /// [scheduled] is the [ScheduledTransactionEntity] to insert or update.
  /// Returns a [Future] that completes when the operation is done.
  Future<void> insertOrUpdateScheduledTransaction(
      ScheduledTransactionEntity scheduled);
}
