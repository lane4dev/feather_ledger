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
  MonthlyAccountBalanceSnapshots
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
  int get schemaVersion => 6;

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
          if (from < 6) {
            await m.addColumn(recurringSeries, recurringSeries.reminderMinutes);
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
