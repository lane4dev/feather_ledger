import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/features/ledger/data/event_sourcing/drift_event_store.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_projector.dart';
import 'package:feather_ledger/features/ledger/domain/projections/ledger_projection.dart';

part 'ledger_rebuild_service.g.dart';

/// Projection rebuild (spec 003, US8/T057): one database transaction that
/// clears **only** the event-sourced projections (accounts, transactions,
/// postings, categories, monthly snapshots), replays the event store in GSN
/// order through the projector, and stamps the projection version. The
/// CRUD-exempt tables (`recurring_series`, `scheduled_transactions_view`)
/// and SharedPreferences are never touched.
///
/// Replay and incremental application share the projector's [apply] code
/// path, which is what the US8 golden equivalence test exploits.
///
/// ponytail: the snapshot projector recomputes per account per event during
/// replay (O(events²) scans). Rebuilds only run on a projection-version
/// bump or the developer entry — acceptable; batch the snapshot refresh if
/// startup rebuilds ever become frequent.
class LedgerRebuildService {
  final AppDatabase _db;
  final EventStore _eventStore;
  final LedgerProjector _projector;

  LedgerRebuildService(this._db, this._eventStore, this._projector);

  /// Clears the event-sourced projections and rebuilds them from the event
  /// store. Unknown event types hard-fail inside the transaction — a
  /// rebuild that guesses makes the ledger silently drift.
  Future<void> rebuild() async {
    await _db.transaction(() async {
      await _projector.clear();
      final events = (await _eventStore.readAll()).events;
      for (final event in events) {
        await _projector.apply(event);
      }
      await _projector.stampProjectionVersion();
    });
  }

  /// True when any event-sourced view carries a projection version older
  /// than the current projector code — the startup trigger for a rebuild.
  Future<bool> isStale() async {
    final accounts = await _db.accountDao.getAllAccounts();
    final categories = await _db.categoriesDao.getAllCategories();
    final transactions =
        await _db.select(_db.transactionsView).get();
    final snapshots = await _db.select(_db.monthlyAccountBalanceSnapshots).get();

    return [
      ...accounts.map((r) => r.projectionVersion),
      ...categories.map((r) => r.projectionVersion),
      ...transactions.map((r) => r.projectionVersion),
      ...snapshots.map((r) => r.projectionVersion),
    ].any((v) => v != ledgerProjectionVersion);
  }
}

@Riverpod(keepAlive: true)
LedgerRebuildService ledgerRebuildService(Ref ref) {
  return LedgerRebuildService(
    ref.watch(appDatabaseProvider),
    ref.watch(driftEventStoreProvider),
    ref.watch(ledgerProjectorProvider),
  );
}
