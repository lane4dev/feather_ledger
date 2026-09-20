import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/features/ledger/domain/entities/automatic_posting_batch.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/settings/domain/models/restore_confirmation_batch.dart';

part 'watch_scheduled_transactions_query.g.dart';

class WatchScheduledTransactionsQuery {
  final RecurringRepository _recurringRepository;

  WatchScheduledTransactionsQuery(this._recurringRepository);

  /// [currencyCode] scopes the pending-bill list to one ledger currency
  /// (spec 006); null returns every currency — used by the catch-up path,
  /// which posts due instances regardless of the screen's currency.
  Stream<List<ScheduledTransactionEntity>> execute({String? currencyCode}) {
    return _recurringRepository
        .watchAllScheduled()
        .map((items) => items
            .where((s) =>
                currencyCode == null ||
                s.account?.currencyCode == currencyCode)
            .toList());
  }

  /// Latches a bill as permanently manual (spec 006, US31): it stays
  /// `scheduled` and renders as a normal pending row, but [catchUpAutoPosted]
  /// never posts it — not even after its switch or currency returns.
  Future<void> markAutoPostIneligible(String id) =>
      _recurringRepository.markAutoPostIneligible(id);

  /// Latches every still-eligible pending bill of [seriesId] due at or before
  /// [cutoff] (spec 006, US32): a series created already past its first due
  /// date must never auto-post those bills.
  Future<void> markSeriesIneligibleBefore(String seriesId, DateTime cutoff) =>
      _recurringRepository.markSeriesIneligibleBefore(seriesId, cutoff);

  // ---- Automatic-posting batches (spec 006, US46–55) ----

  Future<String> createAutomaticPostingBatch(DateTime cutoff) =>
      _recurringRepository.createAutomaticPostingBatch(cutoff);

  Future<AutomaticPostingBatch?> latestAutomaticPostingBatch() =>
      _recurringRepository.latestAutomaticPostingBatch();

  Future<void> setAutomaticPostingMemberResult(
          String batchId,
          String scheduledId,
          AutomaticPostingMemberResult result) =>
      _recurringRepository.setAutomaticPostingMemberResult(
          batchId, scheduledId, result);

  Future<List<AutomaticPostingBatchMember>> automaticPostingMembers(
          String batchId) =>
      _recurringRepository.automaticPostingMembers(batchId);

  Future<List<AutomaticPostingBatchMember>>
      unsettledAutomaticPostingMembers() =>
          _recurringRepository.unsettledAutomaticPostingMembers();

  Future<bool> isAutomaticPostingMember(String scheduledId) =>
      _recurringRepository.isAutomaticPostingMember(scheduledId);

  Future<String> createRestoreConfirmationBatch(
          DateTime backupExportedAt,
          {DateTime? createdAt}) =>
      _recurringRepository.createRestoreConfirmationBatch(backupExportedAt,
          createdAt: createdAt);

  Future<RestoreConfirmationBatch?> latestPendingRestoreConfirmationBatch() =>
      _recurringRepository.latestPendingRestoreConfirmationBatch();

  Future<List<RestoreConfirmationBatch>>
      pendingRestoreConfirmationBatches() =>
          _recurringRepository.pendingRestoreConfirmationBatches();

  Future<RestoreConfirmationBatch?> restoreConfirmationBatch(String id) =>
      _recurringRepository.restoreConfirmationBatch(id);

  Future<void> updateRestoreConfirmationStatus(
          String id, RestoreConfirmationStatus status) =>
      _recurringRepository.updateRestoreConfirmationStatus(id, status);

  Future<List<ScheduledTransactionEntity>> restoreConfirmationCandidates(
          String batchId) =>
      _recurringRepository.restoreConfirmationCandidates(batchId);

  Future<bool> isPendingRestoreCandidate(String scheduledId) =>
      _recurringRepository.isPendingRestoreCandidate(scheduledId);

  Future<void> recordScheduledRedirect(String oldId, {String? newId}) =>
      _recurringRepository.recordScheduledRedirect(oldId, newId: newId);

  Future<ScheduledBillRedirect?> resolveScheduledRedirect(String oldId) =>
      _recurringRepository.resolveScheduledRedirect(oldId);
}

@riverpod
WatchScheduledTransactionsQuery watchScheduledTransactionsQuery(Ref ref) {
  return WatchScheduledTransactionsQuery(
      ref.watch(recurringRepositoryProvider));
}
