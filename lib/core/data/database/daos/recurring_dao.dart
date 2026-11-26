import 'package:drift/drift.dart';

import 'package:feather_ledger/core/domain/result/result.dart';

import '../app_database.dart';
import '../tables.dart';

part 'recurring_dao.g.dart';

/// Joined projection of a scheduled bill row together with its owning series,
/// account, and (optional) category fetched in a single SQL query.
class ScheduledBillJoinedRow {
  final ScheduledTransactionViewRow scheduled;
  final RecurringSeriesRow series;
  final AccountViewRow account;
  final CategoryViewRow? category;

  const ScheduledBillJoinedRow({
    required this.scheduled,
    required this.series,
    required this.account,
    this.category,
  });
}

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
    await insertMaterializedBatchIfActive(entry.seriesId.value, [entry]);
  }

  /// Inserts a batch of materialized occurrences for [seriesId] in a single
  /// transaction using `INSERT OR IGNORE`, after verifying the series is still
  /// active and its account is neither archived nor deleted.
  ///
  /// Returns `true` if the series and account were eligible and the batch ran.
  Future<bool> insertMaterializedBatchIfActive(
    String seriesId,
    List<ScheduledTransactionsViewCompanion> entries,
  ) async {
    if (entries.isEmpty) return true;
    return db.transaction(() async {
      final series = await getSeries(seriesId);
      if (series == null || !series.isActive) return false;
      final account = await db.accountDao.getAccountById(series.accountId);
      if (account == null || account.archived || account.deleted) return false;
      await batch((b) {
        b.insertAll(
          scheduledTransactionsView,
          entries,
          mode: InsertMode.insertOrIgnore,
        );
      });
      return true;
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

  Future<void> insertScheduledOrIgnore(
      ScheduledTransactionsViewCompanion entry) {
    return into(scheduledTransactionsView).insert(
      entry,
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> verifySeriesAccountActive(String accountId) async {
    final account = await db.accountDao.getAccountById(accountId);
    if (account == null || account.deleted) {
      throw const CommandRejected(
        LedgerErrorCode.accountNotFound,
        'Account not found',
      );
    }
    if (account.archived) {
      throw const CommandRejected(
        LedgerErrorCode.accountArchived,
        'Account is archived',
      );
    }
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

  Future<int> markManualOnlyBatch(List<String> ids) {
    if (ids.isEmpty) return Future.value(0);
    return (update(scheduledTransactionsView)..where((t) => t.id.isIn(ids)))
        .write(
            const ScheduledTransactionsViewCompanion(manualOnly: Value(true)));
  }

  /// Marks scheduled bills of [seriesId] whose effective date is strictly
  /// earlier than [cutoff] as `manualOnly = true` (leaving bills at or after
  /// [cutoff], such as same-day due occurrences when [cutoff] is
  /// `startOfDay(now)`, eligible for auto-posting).
  Future<int> markSeriesManualOnlyBefore(String seriesId, DateTime cutoff) =>
      (update(scheduledTransactionsView)
            ..where((t) =>
                t.seriesId.equals(seriesId) &
                t.status.equals('scheduled') &
                t.manualOnly.equals(false) &
                coalesce([t.dateOverride, t.scheduledDate])
                    .isSmallerThanValue(cutoff)))
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
      final normalized =
          (!entry.materializeFrom.present && entry.startDate.present)
              ? entry.copyWith(materializeFrom: entry.startDate)
              : entry;
      await into(recurringSeries).insertOnConflictUpdate(normalized);
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

  Future<int> deletePendingAndSkippedScheduledForSeries(String seriesId) {
    return (delete(scheduledTransactionsView)
          ..where((t) =>
              t.seriesId.equals(seriesId) &
              (t.status.equals('scheduled') |
                  t.status.equals('failed') |
                  t.status.equals('skipped'))))
        .go();
  }

  Future<void> restoreSkippedIfValid(String id, {required DateTime now}) async {
    await db.transaction(() async {
      final row = await getScheduled(id);
      if (row == null) {
        throw const CommandRejected(
            LedgerErrorCode.transactionNotFound, 'Scheduled bill not found');
      }
      if (row.status == 'posted') {
        throw const CommandRejected(
            LedgerErrorCode.scheduledAlreadyPosted,
            'Posted bills cannot be restored');
      }
      if (row.status != 'skipped') {
        throw const CommandRejected(
            LedgerErrorCode.scheduledNotSkipped,
            'Only skipped bills can be restored');
      }
      final series = await getSeries(row.seriesId);
      if (series == null || !series.isActive) {
        throw const CommandRejected(
            LedgerErrorCode.recurringSeriesStopped,
            'Recurring series has been stopped');
      }
      final account = await db.accountDao.getAccountById(series.accountId);
      if (account == null || account.deleted) {
        throw const CommandRejected(
            LedgerErrorCode.accountNotFound, 'Account not found');
      }
      if (account.archived) {
        throw const CommandRejected(
            LedgerErrorCode.accountArchived, 'Account is archived');
      }
      final effectiveDate = row.dateOverride ?? row.scheduledDate;
      final lockManualOnly = series.autoPost && !effectiveDate.isAfter(now);
      await (update(scheduledTransactionsView)..where((t) => t.id.equals(id)))
          .write(
        ScheduledTransactionsViewCompanion(
          status: const Value('scheduled'),
          manualOnly: lockManualOnly
              ? const Value(true)
              : Value(row.manualOnly),
        ),
      );
    });
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

  JoinedSelectStatement<HasResultSet, dynamic> _joinedScheduledQuery({
    String? currencyCode,
    bool pendingOnly = false,
    DateTime? startInclusive,
    DateTime? endExclusive,
  }) {
    final query = select(scheduledTransactionsView).join([
      innerJoin(
        recurringSeries,
        recurringSeries.id.equalsExp(scheduledTransactionsView.seriesId),
      ),
      innerJoin(
        db.accountsView,
        db.accountsView.id.equalsExp(recurringSeries.accountId),
      ),
      leftOuterJoin(
        db.categoriesView,
        db.categoriesView.id.equalsExp(recurringSeries.categoryId),
      ),
    ]);

    if (currencyCode != null) {
      query.where(db.accountsView.currencyCode.equals(currencyCode));
    }
    if (pendingOnly) {
      query.where(
        scheduledTransactionsView.status.isIn(const ['scheduled', 'failed']),
      );
    }
    if (startInclusive != null || endExclusive != null) {
      final effectiveDate = coalesce([
        scheduledTransactionsView.dateOverride,
        scheduledTransactionsView.scheduledDate,
      ]);
      if (startInclusive != null) {
        query.where(effectiveDate.isBiggerOrEqualValue(startInclusive));
      }
      if (endExclusive != null) {
        query.where(effectiveDate.isSmallerThanValue(endExclusive));
      }
    }
    return query;
  }

  ScheduledBillJoinedRow _mapJoinedRow(TypedResult row) =>
      ScheduledBillJoinedRow(
        scheduled: row.readTable(scheduledTransactionsView),
        series: row.readTable(recurringSeries),
        account: row.readTable(db.accountsView),
        category: row.readTableOrNull(db.categoriesView),
      );

  /// Single-query joined stream of scheduled bills, eliminating N+1 lookups
  /// for series, account, and category metadata.
  Stream<List<ScheduledBillJoinedRow>> watchAllScheduledJoined({
    String? currencyCode,
    bool pendingOnly = false,
    DateTime? startInclusive,
    DateTime? endExclusive,
  }) {
    final query = _joinedScheduledQuery(
      currencyCode: currencyCode,
      pendingOnly: pendingOnly,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    );
    return query.watch().map((rows) => rows.map(_mapJoinedRow).toList());
  }

  Future<ScheduledBillJoinedRow?> getScheduledJoined(String id) async {
    final query = _joinedScheduledQuery()
      ..where(scheduledTransactionsView.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _mapJoinedRow(row);
  }

  Future<ScheduledBillJoinedRow?> getScheduledJoinedByOccurrence(
    String seriesId,
    String occurrenceKey,
  ) async {
    final query = _joinedScheduledQuery()
      ..where(scheduledTransactionsView.seriesId.equals(seriesId) &
          scheduledTransactionsView.occurrenceKey.equals(occurrenceKey));
    final row = await query.getSingleOrNull();
    return row == null ? null : _mapJoinedRow(row);
  }
}
