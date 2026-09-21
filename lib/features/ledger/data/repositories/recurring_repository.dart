import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/account_dao.dart';
import 'package:feather_ledger/core/data/database/daos/categories_dao.dart';
import 'package:feather_ledger/core/data/database/daos/recurring_dao.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/domain/entities/automatic_posting_batch.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/settings/domain/models/restore_confirmation_batch.dart';

export 'package:feather_ledger/features/ledger/domain/repositories/recurring_repository.dart';

part 'recurring_repository.g.dart';

class RecurringRepositoryImpl implements RecurringRepository {
  final RecurringDao _recurringDao;
  final CategoriesDao _categoriesDao;
  final AccountDao _accountsDao;

  RecurringRepositoryImpl(
      this._recurringDao, this._categoriesDao, this._accountsDao);

  @override
  Future<ScheduledTransactionViewRow?> getScheduled(String id) {
    return _recurringDao.getScheduled(id);
  }

  @override
  Future<RecurringSeriesRow?> getSeries(String id) {
    return _recurringDao.getSeries(id);
  }

  @override
  Future<List<ScheduledTransactionViewRow>> scheduledForSeries(
      String seriesId) {
    return _recurringDao.scheduledForSeries(seriesId);
  }

  @override
  Future<void> insertOrUpdateScheduled(
      ScheduledTransactionsViewCompanion entry) {
    return _recurringDao.insertOrUpdateScheduled(entry);
  }

  @override
  Stream<List<ScheduledTransactionEntity>> watchAllScheduled() {
    return _recurringDao.watchAllScheduled().asyncMap(_toEntities);
  }

  @override
  Future<void> deletePending(String seriesId, {DateTime? from}) {
    return _recurringDao.deleteScheduledForSeries(
      seriesId,
      from: from,
      status: ScheduledTransactionStatus.scheduled.toStorage(),
    );
  }

  @override
  Future<void> deleteAllScheduledForSeries(String seriesId) {
    return _recurringDao.deleteScheduledForSeries(seriesId);
  }

  @override
  Future<void> deleteSeriesWithInstances(String seriesId) async {
    // Instances first: they reference the series, so the parent has to
    // outlive them while they go.
    await _recurringDao.deleteScheduledForSeries(seriesId);
    await _recurringDao.deleteSeries(seriesId);
  }

  /// Groups the instances by series before resolving, because a series'
  /// description, category and account are the same for every one of its
  /// instances. Resolving per row would repeat the same three lookups N
  /// times for N upcoming bills of one series.
  Future<List<ScheduledTransactionEntity>> _toEntities(
      List<ScheduledTransactionViewRow> rows) async {
    final grouped = <String, List<ScheduledTransactionViewRow>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row.seriesId, () => []).add(row);
    }

    final entities = <ScheduledTransactionEntity>[];
    for (final entry in grouped.entries) {
      final seriesRow = await _recurringDao.getSeries(entry.key);
      // An instance whose series is gone is dropped rather than rendered
      // half-described — there is nothing to show for it.
      if (seriesRow == null) continue;

      final series = _toSeriesEntity(seriesRow);
      // Archived categories and accounts still resolve: a pending bill
      // outlives the account it was set up against, and hiding it would
      // hide money the user expects to move.
      final category =
          await _categoriesDao.getCategoryById(seriesRow.categoryId);
      final account = await _accountsDao.getAccountById(seriesRow.accountId);

      for (final row in entry.value) {
        entities.add(
          ScheduledTransactionEntity(
            id: row.id,
            seriesId: row.seriesId,
            date: row.date,
            amountMinor: row.amountMinor,
            status: decodeScheduledStatus(row.status),
            transactionId: row.transactionId,
            recurringTransactionSeries: series,
            kind: seriesRow.type.toTransactionKind,
            category: category == null ? null : _toCategoryEntity(category),
            account: account == null ? null : _toAccountEntity(account),
            autoPostEligible: row.autoPostEligible,
          ),
        );
      }
    }
    return entities;
  }

  CategoryEntity _toCategoryEntity(CategoryViewRow row) => CategoryEntity(
        id: row.id,
        name: row.name,
        iconKey: row.iconKey,
        colorInt: row.colorInt,
        type: row.type,
      );

  AccountEntity _toAccountEntity(AccountViewRow row) => AccountEntity(
        id: row.id,
        name: row.name,
        type: row.type,
        currencyCode: row.currencyCode,
        balanceMinor: row.balanceMinor,
        archived: row.archived,
        includeInTotals: row.includeInTotals,
        lastUpdatedEventId: row.lastUpdatedEventId,
      );

  @override
  Future<int> skipIfScheduled(String id) => _recurringDao.skipIfScheduled(id);

  @override
  Future<void> markAutoPostIneligible(String id) =>
      _recurringDao.markAutoPostIneligible(id);

  @override
  Future<void> markSeriesIneligibleBefore(String seriesId, DateTime cutoff) =>
      _recurringDao.markSeriesIneligibleBefore(seriesId, cutoff);

  @override
  Future<List<RecurringSeriesRow>> getAllRecurringSeries() {
    return _recurringDao.getAllSeries();
  }

  @override
  Future<List<RecurringSeriesRow>> getMaterializableRecurringSeries() =>
      _recurringDao.getMaterializableSeries();

  @override
  Future<void> insertMaterializedIfActive(
          ScheduledTransactionsViewCompanion entry) =>
      _recurringDao.insertMaterializedIfActive(entry);

  @override
  Future<void> saveSeries(RecurringSeriesCompanion entry) {
    return _recurringDao.saveSeries(entry);
  }

  @override
  Future<String> createAutomaticPostingBatch(DateTime cutoff) async {
    final id = const Uuid().v4();
    await _recurringDao.createAutomaticPostingBatch(
      AutomaticPostingBatchesCompanion.insert(
        id: id,
        cutoff: cutoff,
      ),
    );
    return id;
  }

  @override
  Future<AutomaticPostingBatch?> latestAutomaticPostingBatch() async {
    final row = await _recurringDao.latestAutomaticPostingBatch();
    if (row == null) return null;
    return AutomaticPostingBatch(
      id: row.id,
      createdAt: row.createdAt,
      cutoff: row.cutoff,
    );
  }

  @override
  Future<void> setAutomaticPostingMemberResult(String batchId,
          String scheduledId, AutomaticPostingMemberResult result) =>
      _recurringDao.setAutomaticPostingMemberResult(
          batchId, scheduledId, result.name);

  @override
  Future<List<AutomaticPostingBatchMember>> automaticPostingMembers(
      String batchId) async {
    final rows = await _recurringDao.automaticPostingMembers(batchId);
    return rows
        .map((r) => AutomaticPostingBatchMember(
              batchId: r.batchId,
              scheduledId: r.scheduledId,
              result: decodeAutomaticPostingMemberResult(r.result),
            ))
        .toList();
  }

  @override
  Future<List<AutomaticPostingBatchMember>>
      unsettledAutomaticPostingMembers() async {
    final rows = await _recurringDao.unsettledAutomaticPostingMembers();
    return rows
        .map((r) => AutomaticPostingBatchMember(
              batchId: r.batchId,
              scheduledId: r.scheduledId,
              result: decodeAutomaticPostingMemberResult(r.result),
            ))
        .toList();
  }

  @override
  Future<bool> isAutomaticPostingMember(String scheduledId) =>
      _recurringDao.isAutomaticPostingMember(scheduledId);

  @override
  Future<String> createRestoreConfirmationBatch(DateTime backupExportedAt,
      {DateTime? createdAt}) async {
    final id = 'restore-${backupExportedAt.millisecondsSinceEpoch}';
    await _recurringDao.createRestoreConfirmationBatch(
      RestoreConfirmationBatchesCompanion.insert(
        id: id,
        backupExportedAt: backupExportedAt,
        createdAt: createdAt == null ? const Value.absent() : Value(createdAt),
      ),
    );
    return id;
  }

  @override
  Future<RestoreConfirmationBatch?>
      latestPendingRestoreConfirmationBatch() async {
    final row = await _recurringDao.latestPendingRestoreConfirmationBatch();
    if (row == null) return null;
    return _toRestoreConfirmationBatch(row);
  }

  @override
  Future<List<RestoreConfirmationBatch>>
      pendingRestoreConfirmationBatches() async {
    final rows = await _recurringDao.pendingRestoreConfirmationBatches();
    return rows.map(_toRestoreConfirmationBatch).toList();
  }

  @override
  Future<RestoreConfirmationBatch?> restoreConfirmationBatch(String id) async {
    final row = await _recurringDao.restoreConfirmationBatch(id);
    if (row == null) return null;
    return _toRestoreConfirmationBatch(row);
  }

  @override
  Future<void> updateRestoreConfirmationStatus(
      String id, RestoreConfirmationStatus status) async {
    await _recurringDao.updateRestoreConfirmationStatus(id, status.name);
  }

  @override
  Future<List<ScheduledTransactionEntity>> restoreConfirmationCandidates(
      String batchId) async {
    final batch = await restoreConfirmationBatch(batchId);
    if (batch == null || batch.status != RestoreConfirmationStatus.pending) {
      return const [];
    }
    final all = await watchAllScheduled().first;
    return all
        .where((i) =>
            i.status == ScheduledTransactionStatus.scheduled &&
            i.autoPostEligible &&
            batch.contains(i.date))
        .toList();
  }

  @override
  Future<bool> isPendingRestoreCandidate(String scheduledId) async {
    for (final batch in await pendingRestoreConfirmationBatches()) {
      final candidates = await restoreConfirmationCandidates(batch.id);
      if (candidates.any((c) => c.id == scheduledId)) return true;
    }
    return false;
  }

  @override
  Future<void> recordScheduledRedirect(String oldId, {String? newId}) =>
      _recurringDao.recordScheduledRedirect(oldId, newId: newId);

  @override
  Future<ScheduledBillRedirect?> resolveScheduledRedirect(String oldId) async {
    // Follow the chain up to a bounded hop count. A stale notification should
    // reach the current id through any number of edits, but a cycle (which
    // should never be written) must not hang the handler.
    var current = oldId;
    String? resolved;
    for (var hop = 0; hop < 16; hop++) {
      final row = await _recurringDao.findScheduledRedirect(current);
      if (row == null) {
        return resolved == null
            ? null
            : ScheduledBillRedirect(oldId: oldId, newId: resolved);
      }
      if (row.newId == null) {
        return ScheduledBillRedirect(oldId: oldId);
      }
      resolved = row.newId;
      current = row.newId!;
    }
    return null;
  }

  RestoreConfirmationBatch _toRestoreConfirmationBatch(
          RestoreConfirmationBatchRow row) =>
      RestoreConfirmationBatch(
        id: row.id,
        createdAt: row.createdAt,
        backupExportedAt: row.backupExportedAt,
        status: RestoreConfirmationStatus.values.firstWhere(
          (s) => s.name == row.status,
          orElse: () => RestoreConfirmationStatus.pending,
        ),
      );

  RecurringTransactionSeriesEntity _toSeriesEntity(RecurringSeriesRow row) =>
      RecurringTransactionSeriesEntity(
        id: row.id,
        description: row.description,
        startDate: row.startDate,
        endDate: row.endDate,
        amountMinor: row.amountMinor,
        categoryId: row.categoryId,
        accountId: row.accountId,
        type: row.type,
        frequency: row.frequency,
        rrule: row.rrule,
        interval: row.interval,
        limit: row.countLimit,
        autoPost: row.autoPost,
        reminderMinutes: row.reminderMinutes,
        mode: row.mode,
      );
}

@riverpod
RecurringRepository recurringRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return RecurringRepositoryImpl(
    RecurringDao(db),
    CategoriesDao(db),
    AccountDao(db),
  );
}
