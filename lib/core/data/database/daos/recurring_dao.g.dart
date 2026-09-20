// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_dao.dart';

// ignore_for_file: type=lint
mixin _$RecurringDaoMixin on DatabaseAccessor<AppDatabase> {
  $RecurringSeriesTable get recurringSeries => attachedDatabase.recurringSeries;
  $ScheduledTransactionsViewTable get scheduledTransactionsView =>
      attachedDatabase.scheduledTransactionsView;
  $AutomaticPostingBatchesTable get automaticPostingBatches =>
      attachedDatabase.automaticPostingBatches;
  $AutomaticPostingBatchMembersTable get automaticPostingBatchMembers =>
      attachedDatabase.automaticPostingBatchMembers;
  $RestoreConfirmationBatchesTable get restoreConfirmationBatches =>
      attachedDatabase.restoreConfirmationBatches;
  $ScheduledBillRedirectsTable get scheduledBillRedirects =>
      attachedDatabase.scheduledBillRedirects;
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
  $$AutomaticPostingBatchesTableTableManager get automaticPostingBatches =>
      $$AutomaticPostingBatchesTableTableManager(
          _db.attachedDatabase, _db.automaticPostingBatches);
  $$AutomaticPostingBatchMembersTableTableManager
      get automaticPostingBatchMembers =>
          $$AutomaticPostingBatchMembersTableTableManager(
              _db.attachedDatabase, _db.automaticPostingBatchMembers);
  $$RestoreConfirmationBatchesTableTableManager
      get restoreConfirmationBatches =>
          $$RestoreConfirmationBatchesTableTableManager(
              _db.attachedDatabase, _db.restoreConfirmationBatches);
  $$ScheduledBillRedirectsTableTableManager get scheduledBillRedirects =>
      $$ScheduledBillRedirectsTableTableManager(
          _db.attachedDatabase, _db.scheduledBillRedirects);
}
