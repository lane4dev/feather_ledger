import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'account_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountDao extends DatabaseAccessor<AppDatabase> with _$AccountDaoMixin {
  AccountDao(super.db);

  Future<List<Account>> getAllAccounts() => select(accounts).get();

  Stream<List<Account>> watchAllAccounts() => select(accounts).watch();

  Future<Account?> getAccountById(int id) {
    return (select(accounts)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> addAccount(AccountsCompanion entry) {
    return into(accounts).insert(entry);
  }

  Future<bool> updateAccount(AccountsCompanion entry) {
    return update(accounts).replace(entry);
  }

  Future<int> deleteAccount(int id) {
    return (delete(accounts)..where((t) => t.id.equals(id))).go();
  }
}
