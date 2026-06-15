import 'package:riverpod_annotation/riverpod_annotation.dart';

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
    return AccountBalance(balance: account.balanceMinor);
  }
}

@riverpod
GetAccountBalanceQuery getAccountBalanceQuery(Ref ref) {
  return GetAccountBalanceQuery(ref.watch(accountRepositoryProvider));
}
