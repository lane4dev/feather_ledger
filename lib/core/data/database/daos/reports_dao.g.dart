// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_dao.dart';

// ignore_for_file: type=lint
mixin _$ReportsDaoMixin on DatabaseAccessor<AppDatabase> {
  $TransactionsViewTable get transactionsView =>
      attachedDatabase.transactionsView;
  $TransactionPostingsViewTable get transactionPostingsView =>
      attachedDatabase.transactionPostingsView;
  $MonthlyAccountBalanceSnapshotsTable get monthlyAccountBalanceSnapshots =>
      attachedDatabase.monthlyAccountBalanceSnapshots;
  ReportsDaoManager get managers => ReportsDaoManager(this);
}

class ReportsDaoManager {
  final _$ReportsDaoMixin _db;
  ReportsDaoManager(this._db);
  $$TransactionsViewTableTableManager get transactionsView =>
      $$TransactionsViewTableTableManager(
          _db.attachedDatabase, _db.transactionsView);
  $$TransactionPostingsViewTableTableManager get transactionPostingsView =>
      $$TransactionPostingsViewTableTableManager(
          _db.attachedDatabase, _db.transactionPostingsView);
  $$MonthlyAccountBalanceSnapshotsTableTableManager
      get monthlyAccountBalanceSnapshots =>
          $$MonthlyAccountBalanceSnapshotsTableTableManager(
              _db.attachedDatabase, _db.monthlyAccountBalanceSnapshots);
}
