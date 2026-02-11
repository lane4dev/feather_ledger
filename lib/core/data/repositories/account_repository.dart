import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      return rows.map((row) {
        return AccountEntity(
          id: row.id,
          name: row.name,
          type: row.type,
          postedBalance: row.postedBalance,
          availableBalance: row.availableBalance,
          lastUpdatedEventId: row.lastUpdatedEventId,
        );
      }).toList();
    });
  }

  @override
  Future<AccountEntity?> getAccount(String id) async {
    final row = await _accountDao.getAccountById(id);
    if (row == null) return null;
    return AccountEntity(
      id: row.id,
      name: row.name,
      type: row.type,
      postedBalance: row.postedBalance,
      availableBalance: row.availableBalance,
      lastUpdatedEventId: row.lastUpdatedEventId,
    );
  }

  @override
  Future<void> addAccount(AccountEntity account) async {
    await _accountDao.insertOrReplace(AccountsViewCompanion(
      id: Value(account.id),
      name: Value(account.name),
      type: Value(account.type),
      postedBalance: Value(account.postedBalance),
      availableBalance: Value(account.availableBalance),
      lastUpdatedEventId: const Value(0),
    ));
  }

  @override
  Future<void> updateAccount(AccountEntity account) async {
    await _accountDao.insertOrReplace(AccountsViewCompanion(
      id: Value(account.id),
      name: Value(account.name),
      type: Value(account.type),
      postedBalance: Value(account.postedBalance),
      availableBalance: Value(account.availableBalance),
      lastUpdatedEventId: Value(account.lastUpdatedEventId!),
    ));
  }

  @override
  Future<void> deleteAccountProjection(String id) {
    return _accountDao.deleteAccount(id);
  }
}

@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return AccountRepositoryImpl(db.accountDao);
}
