/// Sync projector port for the ledger (spec 003, Projection Model).
///
/// The projector is the **only** code that mutates event-sourced
/// projections (accounts_view, transactions_view, transaction_postings_view,
/// categories_view, monthly snapshots) and the only balance calculation
/// point. It is driven synchronously from inside the same database
/// transaction that appends events — never async, never from UI, never
/// from DAOs. Incremental application and full rebuild go through the same
/// [apply] code path, which is what the US8 golden equivalence test
/// exploits.
library;

import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';

/// Per-view projection code version. Bump when projector logic changes in
/// a way that requires a rebuild of existing data; the value is written
/// into each view's rows by the rebuild.
/// Bumped when projector code changes what a persisted view should contain.
///
/// 2: category icons moved from Material code points to Lucide ones, so both
/// `categories_view.icon_key` and the write-time snapshot in
/// `transactions_view.category_icon` have to be re-derived — through the
/// `CategoryCreated` upcaster, which is why a rebuild lands on the new
/// vocabulary rather than replaying the old one.
///
/// 3: accounts gained `include_in_totals` (Drift schema v2). The new column
/// arrives by `ALTER TABLE` with a default, so no existing row is *wrong* —
/// but a rebuild is what makes the migration self-healing: every derived row
/// gets re-written from the events by the current projector, whatever the
/// ALTER happened to leave behind. Keep the two version numbers moving
/// together for that reason — a schema bump that changes what a projection
/// column *means* and forgets this one restores a database that migrates
/// cleanly and then never rebuilds, showing wrong figures with no error.
/// 4: legacy reversal-category rows are re-projected as `openingBalance` or
/// `balanceAdjustment`, and those purposes are excluded from income/expense
/// snapshot fields and reports while still affecting balance.
/// 5: transaction attachment metadata is projected from `TransactionRecorded`
/// v2, so rows written before this field existed are replayed with an empty
/// attachment list and current rows retain their event-backed references.
/// 6: scheduled-bill redirects (ticket 46) are CRUD-exempt and not projected.
/// 7: `transactions_view.source_scheduled_bill_id` is projected from
/// `TransactionRecorded` v4 (ticket 47), so pre-model rows (no source bill)
/// stay null and posted-bill rows re-derive their event-backed link.
const int ledgerProjectionVersion = 7;

/// A projection's applied-event cursor. Rows record the GSN of the last
/// event applied to them so replay is idempotent: events at or below the
/// cursor are skipped.
abstract interface class ProjectionCursor {
  /// GSN of the last applied event, null when nothing applied yet.
  Future<int?> read(String viewName);

  /// Writes the new high-water mark. Called at the end of each applied
  /// event, inside the caller's transaction.
  Future<void> write(String viewName, int globalSequenceNumber);
}

/// Synchronous projector port. Implementations live in
/// `features/ledger/data/projections/` (T026/T034/T052).
abstract interface class LedgerProjector {
  /// Applies one event to the projections.
  ///
  /// Contract:
  /// - Called by the EventStore append transaction with the *persisted*
  ///   envelope (GSN assigned), in GSN order during rebuild.
  /// - Must be idempotent per event: an event already at/below the target
  ///   row's cursor is a no-op.
  /// - Must throw on unknown event types — a projector that guesses makes
  ///   the ledger silently drift (spec红线).
  Future<void> apply(EventEnvelope envelope);

  /// Applies a persisted batch in order — the `AppendOptions.apply` entry
  /// point for commands.
  Future<void> applyAll(List<EventEnvelope> events);

  /// Clears every event-sourced projection (accounts, transactions,
  /// postings, categories, snapshots) — *not* recurring_series,
  /// scheduled_transactions_view or any preference storage. Used by
  /// rebuild before replay (T057).
  Future<void> clear();

  /// Writes the current [ledgerProjectionVersion] into all views and
  /// resets cursors — the last step of a rebuild.
  Future<void> stampProjectionVersion();
}
