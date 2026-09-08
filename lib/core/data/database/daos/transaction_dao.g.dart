// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_dao.dart';

// ignore_for_file: type=lint
mixin _$TransactionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $TransactionsViewTable get transactionsView =>
      attachedDatabase.transactionsView;
  $TransactionPostingsViewTable get transactionPostingsView =>
      attachedDatabase.transactionPostingsView;
  $CategoriesViewTable get categoriesView => attachedDatabase.categoriesView;
  $AccountsViewTable get accountsView => attachedDatabase.accountsView;
  TransactionsDaoManager get managers => TransactionsDaoManager(this);
}

class TransactionsDaoManager {
  final _$TransactionsDaoMixin _db;
  TransactionsDaoManager(this._db);
  $$TransactionsViewTableTableManager get transactionsView =>
      $$TransactionsViewTableTableManager(
          _db.attachedDatabase, _db.transactionsView);
  $$TransactionPostingsViewTableTableManager get transactionPostingsView =>
      $$TransactionPostingsViewTableTableManager(
          _db.attachedDatabase, _db.transactionPostingsView);
  $$CategoriesViewTableTableManager get categoriesView =>
      $$CategoriesViewTableTableManager(
          _db.attachedDatabase, _db.categoriesView);
  $$AccountsViewTableTableManager get accountsView =>
      $$AccountsViewTableTableManager(_db.attachedDatabase, _db.accountsView);
}
