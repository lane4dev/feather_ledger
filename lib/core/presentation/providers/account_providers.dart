import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/data/repositories/account_repository.dart';

part 'account_providers.g.dart';

@riverpod
Stream<List<AccountEntity>> accountList(Ref ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchAccounts();
}
