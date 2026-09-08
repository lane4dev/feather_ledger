// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_dao.dart';

// ignore_for_file: type=lint
mixin _$AccountDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountsViewTable get accountsView => attachedDatabase.accountsView;
  AccountDaoManager get managers => AccountDaoManager(this);
}

class AccountDaoManager {
  final _$AccountDaoMixin _db;
  AccountDaoManager(this._db);
  $$AccountsViewTableTableManager get accountsView =>
      $$AccountsViewTableTableManager(_db.attachedDatabase, _db.accountsView);
}
