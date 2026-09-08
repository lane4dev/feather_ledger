import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/data/repositories/account_repository.dart';

part 'get_account_by_id_query.g.dart';

class GetAccountByIdQuery {
  final AccountRepository _accountRepository;

  GetAccountByIdQuery(this._accountRepository);

  Future<AccountEntity?> execute(String accountId) {
    return _accountRepository.getAccount(accountId);
  }
}

@riverpod
GetAccountByIdQuery getAccountByIdQuery(Ref ref) {
  return GetAccountByIdQuery(ref.watch(accountRepositoryProvider));
}
