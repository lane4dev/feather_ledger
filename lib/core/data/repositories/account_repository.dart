import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/account_dao.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/repositories/account_repository.dart';

export 'package:feather_ledger/core/domain/repositories/account_repository.dart';

part 'account_repository.g.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountDao _accountDao;

  AccountRepositoryImpl(this._accountDao);

  @override
  Stream<List<AccountEntity>> watchAccounts() {
    return _accountDao.watchAllAccounts().map((rows) {
      return rows.map(_toEntity).toList();
    });
  }

  @override
  Future<AccountEntity?> getAccount(String id) async {
    final row = await _accountDao.getAccountById(id);
    return row == null ? null : _toEntity(row);
  }

  AccountEntity _toEntity(AccountViewRow row) => AccountEntity(
        id: row.id,
        name: row.name,
        type: row.type,
        currencyCode: row.currencyCode,
        balanceMinor: row.balanceMinor,
        archived: row.archived,
        lastUpdatedEventId: row.lastUpdatedEventId,
      );
}

@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return AccountRepositoryImpl(db.accountDao);
}
