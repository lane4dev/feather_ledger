import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/account_dao.dart';
import 'package:feather_ledger/core/domain/entities/enums.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/repositories/account_repository.dart';

export 'package:feather_ledger/core/domain/repositories/account_repository.dart';

part 'account_repository.g.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountDao _dao;

  AccountRepositoryImpl(this._dao);

  @override
  Stream<List<AccountEntity>> watchAccounts() {
    return _dao.watchAllAccounts().map((rows) {
      return rows.map((row) {
        return AccountEntity(
          id: row.id,
          name: row.name,
          type: row.type,
          initialBalance: row.initialBalance,
        );
      }).toList();
    });
  }

  @override
  Future<void> addAccount({
    required String name,
    required AccountType type,
    required double initialBalance,
  }) {
    return _dao.addAccount(AccountsCompanion(
      name: Value(name),
      type: Value(type),
      initialBalance: Value(initialBalance),
    ));
  }

  @override
  Future<void> updateAccount({
    required int id,
    required String name,
    required AccountType type,
    required double initialBalance,
  }) {
    return _dao.updateAccount(AccountsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      initialBalance: Value(initialBalance),
    ));
  }

  @override
  Future<void> deleteAccount(int id) {
    return _dao.deleteAccount(id);
  }
}

@riverpod
AccountRepository accountRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return AccountRepositoryImpl(db.accountDao);
}
