// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_dao.dart';

// ignore_for_file: type=lint
mixin _$RecurringDaoMixin on DatabaseAccessor<AppDatabase> {
  $RecurringSeriesTable get recurringSeries => attachedDatabase.recurringSeries;
  $ScheduledTransactionsViewTable get scheduledTransactionsView =>
      attachedDatabase.scheduledTransactionsView;
  RecurringDaoManager get managers => RecurringDaoManager(this);
}

class RecurringDaoManager {
  final _$RecurringDaoMixin _db;
  RecurringDaoManager(this._db);
  $$RecurringSeriesTableTableManager get recurringSeries =>
      $$RecurringSeriesTableTableManager(
          _db.attachedDatabase, _db.recurringSeries);
  $$ScheduledTransactionsViewTableTableManager get scheduledTransactionsView =>
      $$ScheduledTransactionsViewTableTableManager(
          _db.attachedDatabase, _db.scheduledTransactionsView);
}
