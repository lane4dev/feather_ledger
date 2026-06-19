import 'dart:async';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/account_dao.dart';

/// Mock AccountDao for testing purposes
class MockAccountDao implements AccountDao {
  final StreamController<List<AccountViewRow>> _accountsController =
      StreamController<List<AccountViewRow>>.broadcast(sync: true);

  int upsertCallCount = 0;
  int clearAllCallCount = 0;

  AccountsViewCompanion? lastUpsertedAccount;

  List<AccountViewRow> _currentAccounts = const [];

  @override
  Stream<List<AccountViewRow>> watchAllAccounts() => _accountsController.stream;

  @override
  Future<List<AccountViewRow>> getAllAccounts() async => _currentAccounts;

  @override
  Future<AccountViewRow?> getAccountById(String id) async {
    for (final row in _currentAccounts) {
      if (row.id == id) return row;
    }
    return null;
  }

  @override
  Future<void> upsert(AccountsViewCompanion entry) async {
    upsertCallCount++;
    lastUpsertedAccount = entry;
    await Future.delayed(Duration.zero);
  }

  @override
  Future<int> clearAll() async {
    clearAllCallCount++;
    return 0;
  }

  // Helper methods for testing
  void emitAccounts(List<AccountViewRow> accounts) {
    _currentAccounts = accounts;
    _accountsController.add(accounts);
  }

  void dispose() {
    _accountsController.close();
  }

  void reset() {
    upsertCallCount = 0;
    clearAllCallCount = 0;
    lastUpsertedAccount = null;
  }

  // DatabaseAccessor mixin members are irrelevant for this mock.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
