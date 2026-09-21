import 'package:drift/drift.dart';

import 'package:feather_ledger/core/domain/result/result.dart';

import '../app_database.dart';
import '../tables.dart';

part 'recurring_dao.g.dart';

@DriftAccessor(tables: [
  RecurringSeries,
  ScheduledTransactionsView,
])
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
      ..where(recurringSeries.isActive.equals(true) &
          db.accountsView.archived.equals(false) &
          db.accountsView.deleted.equals(false));
    return (await query.get())
        .map((row) => row.readTable(recurringSeries))
        .toList();
  }

  Future<void> insertMaterializedIfActive(
      ScheduledTransactionsViewCompanion entry) async {
    await db.transaction(() async {
      final series = await getSeries(entry.seriesId.value);
      if (series == null || !series.isActive) return;
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

  Future<int> skipIfScheduled(String id) => (update(scheduledTransactionsView)
        ..where((t) =>
            t.id.equals(id) &
            (t.status.equals('scheduled') | t.status.equals('failed'))))
      .write(
          const ScheduledTransactionsViewCompanion(status: Value('skipped')));

  Future<int> markManualOnly(String id) =>
      (update(scheduledTransactionsView)..where((t) => t.id.equals(id))).write(
          const ScheduledTransactionsViewCompanion(manualOnly: Value(true)));

  Future<int> markSeriesManualOnlyBefore(String seriesId, DateTime cutoff) =>
      (update(scheduledTransactionsView)
            ..where((t) =>
                t.seriesId.equals(seriesId) &
                t.status.equals('scheduled') &
                t.manualOnly.equals(false) &
                coalesce([t.dateOverride, t.scheduledDate])
                    .isSmallerOrEqualValue(cutoff)))
          .write(const ScheduledTransactionsViewCompanion(
              manualOnly: Value(true)));

  Future<int> markAllScheduledManualOnlyBefore(DateTime cutoff) =>
      (update(scheduledTransactionsView)
            ..where((t) =>
                t.status.equals('scheduled') &
                t.manualOnly.equals(false) &
                coalesce([t.dateOverride, t.scheduledDate])
                    .isSmallerOrEqualValue(cutoff)))
          .write(const ScheduledTransactionsViewCompanion(
              manualOnly: Value(true)));

  Future<int> resetFailedToScheduledForSeries(String seriesId) =>
      (update(scheduledTransactionsView)
            ..where((t) =>
                t.seriesId.equals(seriesId) & t.status.equals('failed')))
          .write(const ScheduledTransactionsViewCompanion(
              status: Value('scheduled')));

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

  Future<int> deleteScheduledForSeries(
    String seriesId, {
    DateTime? from,
    String? status,
  }) {
    final query = delete(scheduledTransactionsView)
      ..where((t) => t.seriesId.equals(seriesId));
    if (from != null) {
      query.where((t) =>
          coalesce([t.dateOverride, t.scheduledDate])
              .isBiggerOrEqualValue(from));
    }
    if (status != null) query.where((t) => t.status.equals(status));
    return query.go();
  }

  Future<int> deletePendingScheduledForSeries(String seriesId) {
    return (delete(scheduledTransactionsView)
          ..where((t) =>
              t.seriesId.equals(seriesId) &
              (t.status.equals('scheduled') | t.status.equals('failed'))))
        .go();
  }

  Future<int> deleteScheduledById(String id) {
    return (delete(scheduledTransactionsView)..where((t) => t.id.equals(id)))
        .go();
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
