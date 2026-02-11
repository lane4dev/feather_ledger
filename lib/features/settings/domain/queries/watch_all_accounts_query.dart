import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/data/repositories/account_repository.dart';

part 'watch_all_accounts_query.g.dart';

class WatchAllAccountsQuery {
  final AccountRepository _accountRepository;

  WatchAllAccountsQuery(this._accountRepository);

  Stream<List<AccountEntity>> execute() {
    return _accountRepository.watchAccounts();
  }
}

@riverpod
WatchAllAccountsQuery watchAllAccountsQuery(Ref ref) {
  return WatchAllAccountsQuery(ref.watch(accountRepositoryProvider));
}
