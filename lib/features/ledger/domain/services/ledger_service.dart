import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';

import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/value_objects/account_balance.dart';
import 'package:feather_ledger/features/ledger/domain/value_objects/monthly_summary.dart';
import 'package:feather_ledger/features/ledger/domain/commands/post_transaction_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/reverse_transaction_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/correct_transaction_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/convert_scheduled_to_posted_command.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_transactions_query.dart';
import 'package:feather_ledger/features/ledger/domain/queries/get_account_balance_query.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_monthly_summary_query.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_scheduled_transactions_query.dart'; // New import

part 'ledger_service.g.dart';

class LedgerService {
  final PostTransactionCommand _postTransactionCommand;
  final ReverseTransactionCommand _reverseTransactionCommand;
  final CorrectTransactionCommand _correctTransactionCommand;
  final ConvertScheduledToPostedCommand _convertScheduledToPostedCommand;
  final WatchTransactionsQuery _watchTransactionsQuery;
  final WatchMonthlySummaryQuery _watchMonthlySummaryQuery;
  final GetAccountBalanceQuery _getAccountBalanceQuery;
  final WatchScheduledTransactionsQuery _watchScheduledTransactionsQuery;

  LedgerService(
    this._postTransactionCommand,
    this._reverseTransactionCommand,
    this._correctTransactionCommand,
    this._convertScheduledToPostedCommand,
    this._watchTransactionsQuery,
    this._watchMonthlySummaryQuery,
    this._getAccountBalanceQuery,
    this._watchScheduledTransactionsQuery,
  );

  Stream<List<TransactionEntity>> watchTransactions(DateTime month) {
    return _watchTransactionsQuery.execute(month);
  }

  Stream<MonthlySummary> watchMonthlySummary(DateTime month) {
    return _watchMonthlySummaryQuery.execute(month);
  }

  Stream<List<ScheduledTransactionEntity>> watchScheduledTransactions() {
    return _watchScheduledTransactionsQuery.execute();
  }

  Future<AccountBalance> accountBalance(String accountId) {
    return _getAccountBalanceQuery.execute(accountId);
  }

  Future<void> addTransaction({
    required double amount,
    required TransactionType type,
    required DateTime date,
    required String categoryId,
    required String accountId,
    String? note,
  }) {
    return _postTransactionCommand.execute(
      amount: amount,
      type: type,
      date: date,
      categoryId: categoryId,
      accountId: accountId,
      note: note,
    );
  }

  Future<void> updateTransaction({
    required String id,
    required double amount,
    required TransactionType type,
    required DateTime date,
    required String categoryId,
    required String accountId,
    String? note,
  }) async {
    return _correctTransactionCommand.execute(
      originalTransactionId: id,
      amount: amount,
      type: type,
      date: date,
      categoryId: categoryId,
      accountId: accountId,
      note: note,
    );
  }

  Future<void> deleteTransaction(String id) async {
    return _reverseTransactionCommand.execute(id, 'User deleted');
  }

  Future<void> convertScheduledToPosted(String scheduledId) async {
    await _convertScheduledToPostedCommand.execute(scheduledId);
  }
}

@riverpod
LedgerService ledgerService(Ref ref) {
  return LedgerService(
    ref.watch(postTransactionCommandProvider),
    ref.watch(reverseTransactionCommandProvider),
    ref.watch(correctTransactionCommandProvider),
    ref.watch(convertScheduledToPostedCommandProvider),
    ref.watch(watchTransactionsQueryProvider),
    ref.watch(watchMonthlySummaryQueryProvider),
    ref.watch(getAccountBalanceQueryProvider),
    ref.watch(watchScheduledTransactionsQueryProvider), // New dependency
  );
}
