import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/features/ledger/domain/entities/automatic_posting_batch.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/settings/domain/models/restore_confirmation_batch.dart';

abstract class RecurringRepository {
  /// Watches all scheduled transactions along with their series details.
  /// Returns a stream of a list of [ScheduledTransactionEntity].
  Stream<List<ScheduledTransactionEntity>> watchAllScheduled();

  /// Retrieves a scheduled transaction by its [id].
  /// Returns a [ScheduledTransactionViewRow] or null if not found.
  Future<ScheduledTransactionViewRow?> getScheduled(String id);

  /// Retrieves a recurring series by its [id].
  /// Returns a [RecurringSeriesRow] or null if not found.
  Future<RecurringSeriesRow?> getSeries(String id);

  /// Every instance of one series, whatever its status. Materialization reads
  /// this once per series rather than probing per candidate date.
  Future<List<ScheduledTransactionViewRow>> scheduledForSeries(String seriesId);

  /// Inserts or updates a scheduled transaction.
  /// Takes a [ScheduledTransactionsViewCompanion] entry.
  Future<void> insertOrUpdateScheduled(
      ScheduledTransactionsViewCompanion entry);

  /// Changes a scheduled bill to skipped only if it is still scheduled.
  Future<int> skipIfScheduled(String id);

  /// Latches a scheduled bill as permanently manual (spec 006, US31): its
  /// auto-post switch was off, or its currency was not current, when it fell
  /// due, so re-enabling must never retro-post it. Writes only the latch
  /// column; the bill stays `scheduled` and renders as a normal pending row.
  Future<void> markAutoPostIneligible(String id);

  /// Latches every still-eligible pending bill of [seriesId] due at or before
  /// [cutoff] as permanently manual (spec 006, US32). Used when a series is
  /// created already past its first due date, or when an edit moves it into
  /// the past: those bills must never auto-post.
  Future<void> markSeriesIneligibleBefore(String seriesId, DateTime cutoff);

  /// Retrieves all recurring series.
  /// Returns a list of [RecurringSeriesRow].
  Future<List<RecurringSeriesRow>> getAllRecurringSeries();

  /// Series eligible to generate bills; archived accounts pause generation.
  Future<List<RecurringSeriesRow>> getMaterializableRecurringSeries();

  /// Insert a generated instance only while its account remains active.
  Future<void> insertMaterializedIfActive(
      ScheduledTransactionsViewCompanion entry);

  /// Inserts or updates a series (spec 004, US2). `recurring_series` is
  /// CRUD-exempt — this writes the table directly and emits no event.
  Future<void> saveSeries(RecurringSeriesCompanion entry);

  /// Deletes the pending instances of one series, at or after [from] when
  /// given and all of them when not.
  ///
  /// Bills already recorded are real movements, and bills already skipped are
  /// tombstones materialization respects; neither is "pending", and deleting
  /// either would be a lie about what happened.
  Future<void> deletePending(String seriesId, {DateTime? from});

  /// Deletes every instance row of one series — posted, skipped and pending
  /// alike — without touching the series itself.
  ///
  /// A whole-series edit shifts every occurrence, so *every* stale id must go
  /// and be rebuilt at its new date. The series template survives this.
  Future<void> deleteAllScheduledForSeries(String seriesId);

  /// Deletes a series and every instance row belonging to it.
  ///
  /// Recorded *transactions* are not instance rows and are not touched — they
  /// survive as ordinary ledger entries.
  Future<void> deleteSeriesWithInstances(String seriesId);

  /// Creates a new automatic-posting batch with a fixed [cutoff] and returns
  /// its id (spec 006, US46).
  Future<String> createAutomaticPostingBatch(DateTime cutoff);

  /// The most recently created batch, if any (spec 006, US51/52).
  Future<AutomaticPostingBatch?> latestAutomaticPostingBatch();

  /// Sets the current result of one member (upsert). Retrying a failed bill
  /// calls this again and replaces the old result in place (US53).
  Future<void> setAutomaticPostingMemberResult(
      String batchId, String scheduledId, AutomaticPostingMemberResult result);

  /// All members of one batch.
  Future<List<AutomaticPostingBatchMember>> automaticPostingMembers(
      String batchId);

  /// Every member across batches that still needs work: an interrupted
  /// pending claim or a failed post awaiting retry (US51/53).
  Future<List<AutomaticPostingBatchMember>>
      unsettledAutomaticPostingMembers();

  /// Whether a scheduled bill has already been claimed by any batch. A bill
  /// is claimed at most once, so a later startup never duplicates it (US52).
  Future<bool> isAutomaticPostingMember(String scheduledId);

  /// Records that a restore was applied whose backup snapshot was exported at
  /// [backupExportedAt]. Returns the barrier id. Idempotent: the id is
  /// derived from the exported-at instant (spec 006, US58). [createdAt] is the
  /// moment the snapshot was applied (the window's end); it defaults to now.
  Future<String> createRestoreConfirmationBatch(
      DateTime backupExportedAt,
      {DateTime? createdAt});

  /// The most recent barrier still awaiting a user decision, if any
  /// (spec 006, US58).
  Future<RestoreConfirmationBatch?> latestPendingRestoreConfirmationBatch();

  /// Every barrier still awaiting a user decision, oldest first (spec 006,
  /// US63: old and new batches confirm independently).
  Future<List<RestoreConfirmationBatch>> pendingRestoreConfirmationBatches();

  /// One barrier by id, whatever its status.
  Future<RestoreConfirmationBatch?> restoreConfirmationBatch(String id);

  /// Moves a barrier to [status] (confirmed/rejected). Idempotent upsert.
  Future<void> updateRestoreConfirmationStatus(
      String id, RestoreConfirmationStatus status);

  /// The still-scheduled, still-eligible bills inside a pending barrier's
  /// window — the bills a confirmation acts on (spec 006, US63).
  Future<List<ScheduledTransactionEntity>> restoreConfirmationCandidates(
      String batchId);

  /// Whether [scheduledId] is currently a candidate of any pending barrier
  /// (spec 006, US66): a date-only edit of such a bill must keep its
  /// eligibility instead of latching it manual.
  Future<bool> isPendingRestoreCandidate(String scheduledId);

  /// Records that the bill at [oldId] now lives at [newId] (or was deleted
  /// when `newId` is null). Idempotent upsert (spec 006, US45).
  Future<void> recordScheduledRedirect(String oldId, {String? newId});

  /// Resolves a stale notification's bill id to its current id (following the
  /// redirect chain), or to "deleted" (`newId == null`), or to null when the
  /// id never existed. Returns null for a redirect cycle.
  Future<ScheduledBillRedirect?> resolveScheduledRedirect(String oldId);
}
