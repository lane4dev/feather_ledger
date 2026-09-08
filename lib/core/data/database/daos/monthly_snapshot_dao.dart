import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'monthly_snapshot_dao.g.dart';

/// Row access for the monthly account balance snapshots (spec 003,
/// US7/T051). Writes come only from the snapshot projector
/// (`MonthlySnapshotProjectorImpl`); queries serve the ledger header (US7)
/// and the reports feature (US9).
@DriftAccessor(tables: [MonthlyAccountBalanceSnapshots])
class MonthlySnapshotDao extends DatabaseAccessor<AppDatabase>
    with _$MonthlySnapshotDaoMixin {
  MonthlySnapshotDao(super.db);

  /// Upserts one snapshot row keyed by (accountId, currencyCode, year,
  /// month). Drift's `insertOnConflictUpdate` only resolves primary-key
  /// conflicts — this table conflicts on its unique key — so the upsert is
  /// explicit: insert, or update the existing row with the columns present
  /// in [entry] (`createdAt` keeps its insert-time value).
  Future<void> upsert(MonthlyAccountBalanceSnapshotsCompanion entry) async {
    final existing = await getForAccount(
        entry.accountId.value, entry.year.value, entry.month.value);
    if (existing == null) {
      await into(monthlyAccountBalanceSnapshots).insert(entry);
    } else {
      await (update(monthlyAccountBalanceSnapshots)
            ..where((t) => t.id.equals(existing.id)))
          .write(entry);
    }
  }

  Future<MonthlyAccountBalanceSnapshot?> getForAccount(
      String accountId, int year, int month) {
    return (select(monthlyAccountBalanceSnapshots)
          ..where((t) =>
              t.accountId.equals(accountId) &
              t.year.equals(year) &
              t.month.equals(month)))
        .getSingleOrNull();
  }

  Future<List<MonthlyAccountBalanceSnapshot>> getAllForMonth(
      int year, int month) {
    return (select(monthlyAccountBalanceSnapshots)
          ..where((t) => t.year.equals(year) & t.month.equals(month)))
        .get();
  }

  Stream<List<MonthlyAccountBalanceSnapshot>> watchAllForMonth(
      int year, int month) {
    return (select(monthlyAccountBalanceSnapshots)
          ..where((t) => t.year.equals(year) & t.month.equals(month)))
        .watch();
  }

  /// Rebuild seam (US8/T057).
  Future<void> clearAll() {
    return delete(monthlyAccountBalanceSnapshots).go();
  }
}
