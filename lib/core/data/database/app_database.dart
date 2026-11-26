import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/enums.dart';
import '../../domain/event_sourcing/event_envelope.dart';
import '../../domain/recurrence/recurrence_expander.dart';

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
  // v17 adds `materialize_from` and `completed_count_offset` to CRUD-exempt
  // `recurring_series` and migrates `scheduled_transactions_view.occurrence_key`
  // for repeating series to local civil YYYY-MM-DD (without touching
  // event-sourced projections or bumping `ledgerProjectionVersion`).
  int get schemaVersion => 17;

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
          if (from >= 15 && from < 17) {
            final existingCols = (await m.database
                    .customSelect('PRAGMA table_info(recurring_series)')
                    .get())
                .map((r) => r.read<String>('name'))
                .toSet();
            if (!existingCols.contains('materialize_from')) {
              await m.addColumn(
                  recurringSeries, recurringSeries.materializeFrom);
            }
            if (!existingCols.contains('completed_count_offset')) {
              await m.addColumn(
                  recurringSeries, recurringSeries.completedCountOffset);
            }
            await m.database.customStatement(
              'UPDATE recurring_series SET materialize_from = start_date',
            );
            await _migrateRepeatingOccurrenceKeysToLocalCivil();
          }
        },
      );

  static int _occurrenceStatusPriority(String status) => switch (status) {
        'posted' => 4,
        'failed' => 3,
        'scheduled' => 2,
        'skipped' => 1,
        _ => 0,
      };

  Future<void> _migrateRepeatingOccurrenceKeysToLocalCivil() async {
    final query = select(scheduledTransactionsView).join([
      innerJoin(
        recurringSeries,
        recurringSeries.id.equalsExp(scheduledTransactionsView.seriesId),
      ),
    ])
      ..where(
        recurringSeries.mode.equalsValue(RecurringSeriesMode.repeating) &
            scheduledTransactionsView.occurrenceKey
                .equals(kPlannedOccurrenceKey)
                .not(),
      );

    final joined = await query.get();
    if (joined.isEmpty) return;

    final grouped = <({String seriesId, String key}),
        List<ScheduledTransactionViewRow>>{};
    for (final row in joined) {
      final scheduled = row.readTable(scheduledTransactionsView);
      final targetKey =
          scheduledOccurrenceKey(scheduled.scheduledDate.toLocal());
      grouped
          .putIfAbsent(
            (seriesId: scheduled.seriesId, key: targetKey),
            () => [],
          )
          .add(scheduled);
    }

    final loserIds = <String>[];
    final updates = <({String id, String targetKey})>[];

    for (final entry in grouped.entries) {
      final candidates = entry.value;
      candidates.sort((a, b) {
        final prioDiff = _occurrenceStatusPriority(b.status)
            .compareTo(_occurrenceStatusPriority(a.status));
        if (prioDiff != 0) return prioDiff;
        return a.id.compareTo(b.id);
      });
      final winner = candidates.first;
      for (var i = 1; i < candidates.length; i++) {
        loserIds.add(candidates[i].id);
      }
      if (winner.occurrenceKey != entry.key.key) {
        updates.add((id: winner.id, targetKey: entry.key.key));
      }
    }

    if (loserIds.isNotEmpty) {
      await (delete(scheduledTransactionsView)
            ..where((t) => t.id.isIn(loserIds)))
          .go();
    }

    // Two-phase key rewrite prevents transient UNIQUE(series_id, occurrence_key)
    // collisions when consecutive days shift forward together.
    for (final item in updates) {
      await (update(scheduledTransactionsView)
            ..where((t) => t.id.equals(item.id)))
          .write(
        ScheduledTransactionsViewCompanion(
          occurrenceKey: Value('__mig_v17__${item.id}'),
        ),
      );
    }
    for (final item in updates) {
      await (update(scheduledTransactionsView)
            ..where((t) => t.id.equals(item.id)))
          .write(
        ScheduledTransactionsViewCompanion(
          occurrenceKey: Value(item.targetKey),
        ),
      );
    }
  }
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

/// Shared mapping from a stored [RecurringSeriesRow] to a pure
/// [RecurrenceRuleSpec], keeping physical materialization, virtual overlay,
/// on-write materialization, and collision checks on one canonical conversion.
extension RecurringSeriesRowRecurrenceSpec on RecurringSeriesRow {
  RecurrenceRuleSpec toRecurrenceRuleSpec() => RecurrenceRuleSpec.fromStored(
        mode: mode,
        frequency: frequency,
        interval: interval,
        startDate: startDate,
        endDate: endDate,
        countLimit: countLimit,
        completedCountOffset: completedCountOffset,
        rrule: rrule,
        materializeFrom: materializeFrom,
      );
}
