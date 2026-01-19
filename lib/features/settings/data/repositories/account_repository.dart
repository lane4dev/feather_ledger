import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';

import 'package:feather_ledger/core/database/app_database.dart';
import 'package:feather_ledger/core/database/daos/account_dao.dart';
import 'package:feather_ledger/core/database/tables.dart' as db_tables;
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

part 'account_repository.g.dart';

abstract class AccountRepository {
  Stream<List<AccountEntity>> watchAccounts();
  Future<void> addAccount({
    required String name,
    required db_tables.AccountType type,
    required double initialBalance,
  });
  Future<void> updateAccount({
    required int id,
    required String name,
    required db_tables.AccountType type,
    required double initialBalance,
  });
  Future<void> deleteAccount(int id);
}

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
    required db_tables.AccountType type,
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
    required db_tables.AccountType type,
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
