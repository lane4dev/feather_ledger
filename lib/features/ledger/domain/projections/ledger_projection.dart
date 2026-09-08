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
const int ledgerProjectionVersion = 1;

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
