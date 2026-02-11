import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'account_dao.g.dart';

@DriftAccessor(tables: [AccountsView])
class AccountDao extends DatabaseAccessor<AppDatabase> with _$AccountDaoMixin {
  AccountDao(super.db);

  Future<List<AccountViewRow>> getAllAccounts() => select(accountsView).get();

  Stream<List<AccountViewRow>> watchAllAccounts() =>
      select(accountsView).watch();

  Future<AccountViewRow?> getAccountById(String id) {
    return (select(accountsView)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // Projection updates (called by Repository)
  Future<void> insertOrReplace(AccountsViewCompanion entry) {
    return into(accountsView).insertOnConflictUpdate(entry);
  }

  Future<void> deleteAccount(String id) {
    return (delete(accountsView)..where((t) => t.id.equals(id))).go();
  }
}
