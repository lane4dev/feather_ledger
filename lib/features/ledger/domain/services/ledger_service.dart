import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';

import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/value_objects/account_balance.dart';
import 'package:feather_ledger/features/ledger/domain/commands/record_transaction_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/reverse_transaction_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/correct_transaction_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/convert_scheduled_to_posted_command.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_transactions_query.dart';
import 'package:feather_ledger/features/ledger/domain/queries/get_account_balance_query.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_monthly_snapshot_query.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_scheduled_transactions_query.dart'; // New import

part 'ledger_service.g.dart';

class LedgerService {
  final RecordTransactionCommand _recordTransactionCommand;
  final ReverseTransactionCommand _reverseTransactionCommand;
  final CorrectTransactionCommand _correctTransactionCommand;
  final ConvertScheduledToPostedCommand _convertScheduledToPostedCommand;
  final WatchTransactionsQuery _watchTransactionsQuery;
  final WatchMonthlySnapshotQuery _watchMonthlySnapshotQuery;
  final GetAccountBalanceQuery _getAccountBalanceQuery;
  final WatchScheduledTransactionsQuery _watchScheduledTransactionsQuery;

  LedgerService(
    this._recordTransactionCommand,
    this._reverseTransactionCommand,
    this._correctTransactionCommand,
    this._convertScheduledToPostedCommand,
    this._watchTransactionsQuery,
    this._watchMonthlySnapshotQuery,
    this._getAccountBalanceQuery,
    this._watchScheduledTransactionsQuery,
  );

  Stream<List<TransactionEntity>> watchTransactions(DateTime month) {
    return _watchTransactionsQuery.execute(month);
  }

  Stream<MonthlySnapshotTotals> watchMonthlySnapshot(DateTime month,
      {String currencyCode = 'USD'}) {
    return _watchMonthlySnapshotQuery.execute(month, currencyCode: currencyCode);
  }

  Stream<List<ScheduledTransactionEntity>> watchScheduledTransactions() {
    return _watchScheduledTransactionsQuery.execute();
  }

  Future<AccountBalance> accountBalance(String accountId) {
    return _getAccountBalanceQuery.execute(accountId);
  }

  // Write methods take [commandId] as the idempotency key. It becomes a live
  // contract when the event store lands (US2); the signature is fixed now so
  // callers already generate one key per user action.

  Future<Result<void>> addTransaction({
    required String commandId,
    required int amountMinor,
    required TransactionKind type,
    required DateTime date,
    required String categoryId,
    required String accountId,
    String? note,
  }) {
    return guard(() => _recordTransactionCommand.execute(
          commandId: commandId,
          amountMinor: amountMinor,
          kind: type,
          occurredAt: date,
          categoryId: categoryId,
          accountId: accountId,
          note: note,
        ));
  }

  /// Records a transfer (spec 003, US5/T041): one debit + one equal credit
  /// posting, kind=transfer — excluded from income/expense statistics by
  /// the single `kind == transfer` criterion. Credit-card repayment is
  /// this same transfer; there is no separate repayment model.
  Future<Result<void>> addTransfer({
    required String commandId,
    required int amountMinor,
    required String fromAccountId,
    required String toAccountId,
    required DateTime date,
    String? note,
  }) {
    return guard(() => _recordTransactionCommand.executeTransfer(
          commandId: commandId,
          amountMinor: amountMinor,
          fromAccountId: fromAccountId,
          toAccountId: toAccountId,
          occurredAt: date,
          note: note,
        ));
  }

  Future<Result<void>> updateTransaction({
    required String commandId,
    required String id,
    required int amountMinor,
    required TransactionKind type,
    required DateTime date,
    required String categoryId,
    required String accountId,
    String? note,
  }) {
    return guard(() => _correctTransactionCommand.execute(
          commandId: commandId,
          originalTransactionId: id,
          amountMinor: amountMinor,
          type: type,
          date: date,
          categoryId: categoryId,
          accountId: accountId,
          note: note,
        ));
  }

  Future<Result<void>> deleteTransaction(String id, {required String commandId}) {
    return guard(() =>
        _reverseTransactionCommand.execute(id, commandId: commandId));
  }

  Future<Result<void>> convertScheduledToPosted(String scheduledId,
      {required String commandId}) {
    return guard(() =>
        _convertScheduledToPostedCommand.execute(scheduledId,
            commandId: commandId));
  }
}

@riverpod
LedgerService ledgerService(Ref ref) {
  return LedgerService(
    ref.watch(recordTransactionCommandProvider),
    ref.watch(reverseTransactionCommandProvider),
    ref.watch(correctTransactionCommandProvider),
    ref.watch(convertScheduledToPostedCommandProvider),
    ref.watch(watchTransactionsQueryProvider),
    ref.watch(watchMonthlySnapshotQueryProvider),
    ref.watch(getAccountBalanceQueryProvider),
    ref.watch(watchScheduledTransactionsQueryProvider), // New dependency
  );
}
