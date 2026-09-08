import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'account_dao.g.dart';

/// Read/write seam for the event-sourced `accounts_view` projection
/// (spec 003, US3/T029). Writes come from the ledger projector only;
/// pickers exclude archived accounts while history and balances retain
/// them.
@DriftAccessor(tables: [AccountsView])
class AccountDao extends DatabaseAccessor<AppDatabase> with _$AccountDaoMixin {
  AccountDao(super.db);

  /// All rows, including archived (balance totals and history include them).
  Future<List<AccountViewRow>> getAllAccounts() => select(accountsView).get();

  Stream<List<AccountViewRow>> watchAllAccounts() =>
      select(accountsView).watch();

  Future<AccountViewRow?> getAccountById(String id) {
    return (select(accountsView)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Projector write seam — the only writer of this projection.
  Future<void> upsert(AccountsViewCompanion entry) {
    return into(accountsView).insertOnConflictUpdate(entry);
  }

  /// Projector write seam for existing rows (partial companions — the row
  /// must already exist).
  Future<int> updateRow(AccountsViewCompanion entry) {
    return (update(accountsView)..where((t) => t.id.equals(entry.id.value)))
        .write(entry);
  }

  /// Rebuild seam (US8/T057).
  Future<int> clearAll() => delete(accountsView).go();
}
