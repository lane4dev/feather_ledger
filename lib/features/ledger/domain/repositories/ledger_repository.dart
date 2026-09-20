import '../entities/ledger_entities.dart';
import '../value_objects/transaction_filter.dart';

abstract class LedgerRepository {
  /// Watches transactions for the given month.
  /// [month] should be any date within the desired month.
  /// [currencyCode] scopes to one ledger currency; null returns every
  /// currency. Returns a stream of lists of [TransactionEntity].
  Stream<List<TransactionEntity>> watchTransactions(DateTime month,
      {String? currencyCode});

  /// Watches the transactions matching [filter], newest first
  /// (spec 004, US3).
  ///
  /// Reversed transactions are excluded by the query itself, not by this
  /// layer; a transfer matching on either of its accounts comes back whole.
  /// [currencyCode] scopes to one ledger currency; null returns every
  /// currency.
  Stream<List<TransactionEntity>> watchTransactionsFiltered(
      TransactionFilter filter,
      {String? currencyCode});

  /// Retrieves a transaction by its ID.
  /// [transactionId] is the ID of the transaction.
  /// Returns a [TransactionEntity] or null if not found.
  Future<TransactionEntity?> getTransaction(String transactionId);

  /// Retrieves the latest non-reversed transaction posted from the given
  /// scheduled bill (spec 006, US47). Pre-model rows have no source bill, so
  /// callers must fall back to [getTransaction] on the bill's `transactionId`.
  Future<TransactionEntity?> getTransactionBySourceBill(
      String sourceScheduledBillId);

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
