import 'dart:async';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/account_dao.dart';

/// Mock AccountDao for testing purposes
class MockAccountDao implements AccountDao {
  final StreamController<List<Account>> _accountsController =
      StreamController<List<Account>>.broadcast(sync: true);

  int addAccountCallCount = 0;
  int updateAccountCallCount = 0;
  int deleteAccountCallCount = 0;
  AccountsCompanion? lastAddedAccount;
  AccountsCompanion? lastUpdatedAccount;
  int? lastDeletedId;

  @override
  Stream<List<Account>> watchAllAccounts() {
    return _accountsController.stream;
  }

  @override
  Future<int> addAccount(AccountsCompanion entry) async {
    addAccountCallCount++;
    lastAddedAccount = entry;
    // Return a fake ID
    return 1;
  }

  @override
  Future<bool> updateAccount(AccountsCompanion entry) async {
    updateAccountCallCount++;
    lastUpdatedAccount = entry;
    // Return success
    return true;
  }

  @override
  Future<int> deleteAccount(int id) async {
    deleteAccountCallCount++;
    lastDeletedId = id;
    // Return number of deleted rows
    return 1;
  }

  // Helper methods for testing
  void emitAccounts(List<Account> accounts) {
    _accountsController.add(accounts);
  }

  void dispose() {
    _accountsController.close();
  }

  void reset() {
    addAccountCallCount = 0;
    updateAccountCallCount = 0;
    deleteAccountCallCount = 0;
    lastAddedAccount = null;
    lastUpdatedAccount = null;
    lastDeletedId = null;
  }

  // Unimplemented methods from AccountDao
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
