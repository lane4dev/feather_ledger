import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'recurring_dao.g.dart';

@DriftAccessor(tables: [RecurringSeries, ScheduledTransactionsView])
class RecurringDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringDaoMixin {
  RecurringDao(super.db);

  Future<List<RecurringSeriesRow>> getAllSeries() =>
      select(recurringSeries).get();

  Future<List<RecurringSeriesRow>> getMaterializableSeries() async {
    final query = select(recurringSeries).join([
      innerJoin(db.accountsView,
          db.accountsView.id.equalsExp(recurringSeries.accountId)),
    ])
      ..where(db.accountsView.archived.equals(false) &
          db.accountsView.deleted.equals(false));
    return (await query.get())
        .map((row) => row.readTable(recurringSeries))
        .toList();
  }

  Future<void> insertMaterializedIfActive(
      ScheduledTransactionsViewCompanion entry) async {
    await db.transaction(() async {
      final series = await getSeries(entry.seriesId.value);
      if (series == null) return;
      final account = await db.accountDao.getAccountById(series.accountId);
      if (account == null || account.archived || account.deleted) return;
      await into(scheduledTransactionsView)
          .insert(entry, mode: InsertMode.insertOrIgnore);
    });
  }

  Future<ScheduledTransactionViewRow?> getScheduled(String id) {
    return (select(scheduledTransactionsView)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<RecurringSeriesRow?> getSeries(String id) {
    return (select(recurringSeries)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Every instance of one series, whatever its status.
  ///
  /// Materialization needs the whole set at once: it walks the rule's
  /// candidate dates and has to know, per date, whether an instance already
  /// exists and whether the user has already decided about it.
  Future<List<ScheduledTransactionViewRow>> scheduledForSeries(
      String seriesId) {
    return (select(scheduledTransactionsView)
          ..where((t) => t.seriesId.equals(seriesId)))
        .get();
  }

  Future<void> insertOrUpdateScheduled(
      ScheduledTransactionsViewCompanion entry) {
    return into(scheduledTransactionsView).insertOnConflictUpdate(entry);
  }

  /// Atomically claim a pending bill for skipping without overwriting a post.
  Future<int> skipIfScheduled(String id) => (update(scheduledTransactionsView)
        ..where((t) => t.id.equals(id) & t.status.equals('scheduled')))
      .write(
          const ScheduledTransactionsViewCompanion(status: Value('skipped')));

  Future<void> saveSeries(RecurringSeriesCompanion entry) async {
    await db.transaction(() async {
      if (entry.accountId.present) {
        final account =
            await db.accountDao.getAccountById(entry.accountId.value);
        if (account == null || account.deleted) {
          throw const CommandRejected(
              LedgerErrorCode.accountNotFound, 'Account not found');
        }
        if (account.archived) {
          throw const CommandRejected(
              LedgerErrorCode.accountArchived, 'Account is archived');
        }
      }
      await into(recurringSeries).insertOnConflictUpdate(entry);
    });
  }

  /// Deletes instance rows of one series.
  ///
  /// [from] keeps the instances at or after that date, [status] keeps one
  /// storage-encoded status. The two filters together say "the pending bills
  /// from here on"; passing neither deletes every row of the series, which is
  /// what removing the series itself needs. Which status counts as pending is
  /// the caller's policy — this table accessor does not know the enum.
  Future<int> deleteScheduledForSeries(
    String seriesId, {
    DateTime? from,
    String? status,
  }) {
    final query = delete(scheduledTransactionsView)
      ..where((t) => t.seriesId.equals(seriesId));
    if (from != null) query.where((t) => t.date.isBiggerOrEqualValue(from));
    if (status != null) query.where((t) => t.status.equals(status));
    return query.go();
  }

  Future<int> deleteSeries(String seriesId) {
    return (delete(recurringSeries)..where((t) => t.id.equals(seriesId))).go();
  }

  Stream<List<ScheduledTransactionViewRow>> watchAllScheduled() {
    final query = select(scheduledTransactionsView).join([
      innerJoin(recurringSeries,
          recurringSeries.id.equalsExp(scheduledTransactionsView.seriesId)),
      innerJoin(db.accountsView,
          db.accountsView.id.equalsExp(recurringSeries.accountId)),
    ]);
    return query.watch().map((rows) =>
        rows.map((row) => row.readTable(scheduledTransactionsView)).toList());
  }
}
