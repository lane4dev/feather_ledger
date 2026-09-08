// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_snapshot_dao.dart';

// ignore_for_file: type=lint
mixin _$MonthlySnapshotDaoMixin on DatabaseAccessor<AppDatabase> {
  $MonthlyAccountBalanceSnapshotsTable get monthlyAccountBalanceSnapshots =>
      attachedDatabase.monthlyAccountBalanceSnapshots;
  MonthlySnapshotDaoManager get managers => MonthlySnapshotDaoManager(this);
}

class MonthlySnapshotDaoManager {
  final _$MonthlySnapshotDaoMixin _db;
  MonthlySnapshotDaoManager(this._db);
  $$MonthlyAccountBalanceSnapshotsTableTableManager
      get monthlyAccountBalanceSnapshots =>
          $$MonthlyAccountBalanceSnapshotsTableTableManager(
              _db.attachedDatabase, _db.monthlyAccountBalanceSnapshots);
}
