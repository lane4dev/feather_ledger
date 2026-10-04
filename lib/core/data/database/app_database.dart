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
import 'daos/budget_dao.dart';

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
  BudgetRules,
  BudgetReviewNotes,
], daos: [
  EventsDao,
  TransactionsDao,
  AccountDao,
  CategoriesDao,
  RecurringDao,
  MonthlySnapshotDao,
  ReportsDao,
  BudgetDao
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Internal constructor for testing purposes only.
  // Used by test fakes to inject in-memory database.
  AppDatabase.internal(super.executor);

  @override
  // v16 adds CRUD-exempt budget tables (`budget_rules`, `budget_review_notes`)
  // and `categories_view.archived_at` for archive-month carry-forward cutoffs.
  int get schemaVersion => 16;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(accountsView, accountsView.includeInTotals);
          }
          if (from < 4) {
            await m.addColumn(
                transactionsView, transactionsView.attachmentsJson);
          }
          if (from < 7) {
            await m.addColumn(accountsView, accountsView.deleted);
          }
          if (from < 14) {
            await m.addColumn(
                transactionsView, transactionsView.sourceScheduledBillId);
          }
          if (from < 15) {
            await m.database.customStatement(
                'DROP TABLE IF EXISTS automatic_posting_batch_members');
            await m.database.customStatement(
                'DROP TABLE IF EXISTS automatic_posting_batches');
            await m.database.customStatement(
                'DROP TABLE IF EXISTS restore_confirmation_batches');
            await m.database.customStatement(
                'DROP TABLE IF EXISTS scheduled_bill_redirects');
            await m.database.customStatement(
                'DROP TABLE IF EXISTS scheduled_transactions_view');
            await m.database.customStatement(
                'DROP TABLE IF EXISTS recurring_series');
            await m.createTable(recurringSeries);
            await m.createTable(scheduledTransactionsView);
          }
          if (from < 16) {
            await m.addColumn(categoriesView, categoriesView.archivedAt);
            await m.createTable(budgetRules);
            await m.createTable(budgetReviewNotes);
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
