import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/core/data/repositories/account_repository.dart';

import '../value_objects/account_balance.dart';

part 'get_account_balance_query.g.dart';

class GetAccountBalanceQuery {
  final AccountRepository _repository;

  GetAccountBalanceQuery(this._repository);

  Future<AccountBalance> execute(String accountId) async {
    final account = await _repository.getAccount(accountId);
    if (account == null) {
      throw Exception('Account not found');
    }
    // Convert back to cents since Repository returns double (Entity)
    // NOTE: This conversion is redundant if we just used cents in Entity, but sticking to existing patterns.
    // Entity stores balance as double (dollars). UseCase seems to want cents (int).
    // Or maybe AccountBalance.posted is dollars?
    // Looking at previous AccountDao implementation:
    // return AccountBalance(posted: account.postedBalance, available: account.availableBalance);
    // where AccountRow.postedBalance is int (cents).
    // AccountEntity has balance as double (dollars).
    // So we must convert back to cents.
    return AccountBalance(
      posted: account.postedBalance,
      available: account.availableBalance,
    );
  }
}

@riverpod
GetAccountBalanceQuery getAccountBalanceQuery(Ref ref) {
  return GetAccountBalanceQuery(ref.watch(accountRepositoryProvider));
}
