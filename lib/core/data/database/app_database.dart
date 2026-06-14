import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/enums.dart';
import '../../domain/event_sourcing/event_envelope.dart';

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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Placeholder for future migrations
          // if (from < 2) {
          //   await m.createTable(ledgerEvents);
          // }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

// Provider for the database instance
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  return AppDatabase();
}
