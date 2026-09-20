import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/enums.dart';
import '../../domain/event_sourcing/event_envelope.dart';

import 'database_file.dart';
import 'tables.dart';

import 'daos/transaction_dao.dart';
import 'daos/account_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/events_dao.dart';
import 'daos/recurring_dao.dart';
import 'daos/monthly_snapshot_dao.dart';
import 'daos/reports_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  LedgerEvents,
  AccountsView,
  TransactionsView,
  TransactionPostingsView,
  CategoriesView,
  RecurringSeries,
  ScheduledTransactionsView,
  MonthlyAccountBalanceSnapshots,
  AutomaticPostingBatches,
  AutomaticPostingBatchMembers,
  RestoreConfirmationBatches,
  ScheduledBillRedirects
], daos: [
  EventsDao,
  TransactionsDao,
  AccountDao,
  CategoriesDao,
  RecurringDao,
  MonthlySnapshotDao,
  ReportsDao
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Internal constructor for testing purposes only.
  // Used by test fakes to inject in-memory database.
  AppDatabase.internal(super.executor);

  @override
  // v10 adds `scheduled_transactions_view.auto_post_eligible` (ticket 31).
  // Default true backfills existing rows (they were eligible under the old
  // model); the column is a per-instance manual latch, not a projection.
  // v11 adds the automatic-posting batch tables (ticket 38/39). They are
  // CRUD-exempt progress records, not event-sourced projections.
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // v2: accounts gained `include_in_totals`.
          //
          // **addColumn, never deleteTable/createTable.** The event-sourced
          // views are rebuilt from `ledger_events`, so recreating one looks
          // harmless — but `LedgerRebuildService.isStale()` is `.any(...)`
          // over four views' projection versions, and an empty list is
          // `false`. Drop enough of them at once and nothing is ever stale
          // again: the home page stays empty over a full event store, with no
          // error and no way back. addColumn keeps the rows, and the rebuild
          // below re-derives the column from the events anyway.
          //
          // `ledgerProjectionVersion` goes to 3 in the same change, so every
          // derived row is re-written by the current projector regardless of
          // what this migration left behind.
          if (from < 2) {
            await m.addColumn(accountsView, accountsView.includeInTotals);
          }
          // v3 adds TransactionKind values only. Drift persists the enum as
          // its existing integer ordinal and the new values are appended, so
          // no table change is needed; projection version 4 triggers replay.
          // v4 projects transaction attachment metadata alongside the ledger
          // row. The attachment bytes live outside SQLite, while the event
          // remains the source for this re-buildable reference list.
          if (from < 4) {
            await m.addColumn(
                transactionsView, transactionsView.attachmentsJson);
          }
          // v5: recurring_series gained `auto_post` (订阅 auto-post).
          // CRUD-exempt table, never rebuilt — the column default backfills
          // every existing row, so no upcaster and no projection bump.
          if (from < 5) {
            await m.addColumn(recurringSeries, recurringSeries.autoPost);
          }
          if (from < 7) {
            await m.addColumn(accountsView, accountsView.deleted);
          }
          if (from < 6) {
            await m.addColumn(recurringSeries, recurringSeries.reminderMinutes);
          }
          // v9: recurring_series gained `mode` (计划/订阅/重复). CRUD-exempt,
          // never rebuilt — the column default backfills 0 (计划) and the
          // UPDATE below re-derives the true mode from the existing shape
          // (auto_post ⇒ 订阅, start==end ⇒ 计划, else 重复).
          if (from < 9) {
            await m.addColumn(recurringSeries, recurringSeries.mode);
            await m.database.customStatement(
              'UPDATE recurring_series SET mode = CASE '
              'WHEN auto_post = 1 THEN ${RecurringSeriesMode.subscription.index} '
              'WHEN start_date = end_date THEN ${RecurringSeriesMode.planned.index} '
              'ELSE ${RecurringSeriesMode.repeating.index} END',
            );
          }
          // v10: scheduled_transactions_view gained `auto_post_eligible`.
          // CRUD-exempt table, never rebuilt — the boolean default (true)
          // backfills every existing row, so no projection bump.
          if (from < 10) {
            await m.addColumn(
                scheduledTransactionsView, scheduledTransactionsView.autoPostEligible);
          }
          // v11: automatic-posting batch tables (ticket 38/39). New
          // CRUD-exempt tables, never rebuilt — createTable is additive and
          // safe here (it never drops a derived view).
          if (from < 11) {
            await m.createTable(automaticPostingBatches);
            await m.createTable(automaticPostingBatchMembers);
          }
          // v12: restore-confirmation barrier table (ticket 41). New
          // CRUD-exempt table, never rebuilt — createTable is additive and
          // safe here.
          if (from < 12) {
            await m.createTable(restoreConfirmationBatches);
          }
          // v13: scheduled-bill redirect table (ticket 46). New CRUD-exempt
          // table, never rebuilt — createTable is additive and safe here.
          if (from < 13) {
            await m.createTable(scheduledBillRedirects);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, kDatabaseFileName));
    return NativeDatabase.createInBackground(file);
  });
}

// Provider for the database instance
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  return AppDatabase();
}
