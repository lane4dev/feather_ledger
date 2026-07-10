import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/data/repositories/account_repository.dart';
import 'package:feather_ledger/shared/presentation/models/account_ui_model.dart';

part 'account_providers.g.dart';

@riverpod
Stream<List<AccountEntity>> accountList(Ref ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchAccounts();
}

/// The same accounts, with their balances written out.
///
/// The row a screen builds should not be the thing that knows what an amount
/// is; this is the seam where the entity becomes something printable, and
/// both the ledger's picker and the management screen read it.
@riverpod
AsyncValue<List<AccountUiModel>> accountUiList(Ref ref) {
  return ref
      .watch(accountListProvider)
      .whenData((accounts) => accounts.map(AccountUiModel.of).toList());
}
