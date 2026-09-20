/// Applies a staged backup restore at startup (spec 004, US4 / FR-025/FR-026).
///
/// Restore is a *replacement*, and it cannot happen while the app runs: the
/// database is held open by a keep-alive provider on a background isolate. So
/// the restore is staged during one run and swapped in at the start of the
/// next — before anything has opened the database.
///
/// This file deliberately depends on `dart:io` only. It must run before the
/// ProviderContainer exists, before SharedPreferences is read, and before the
/// database file is touched; that is also why it unit-tests against a plain
/// temp directory with no Flutter, no Riverpod and no database.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:feather_ledger/core/data/database/database_file.dart';

/// The layout of both the live database directory and the staging area.
///
/// `BackupService` writes this layout; this library consumes it. Keeping the
/// names in one place is what stops the two halves from drifting apart.
abstract final class RestoreLayout {
  /// Live database file name, inside the application support directory. The
  /// same constant the database opener uses — see `database_file.dart`.
  static const liveDb = kDatabaseFileName;

  /// Where the pre-restore database is parked, for manual recovery.
  static const replacedDb = '$kDatabaseFileName.replaced';

  /// SQLite sidecar files. **These must be removed during a swap.**
  ///
  /// If the old database left a `-wal` behind, SQLite will happily replay its
  /// frames into the *restored* database. That is silent corruption which
  /// surfaces as wrong balances weeks later, so it gets its own test.
  static const sidecarSuffixes = ['-wal', '-shm', '-journal'];

  /// Staging directory, inside the application support directory.
  static const stagingDir = 'restore';

  static const stagedDb = 'db.sqlite';
  static const stagedPreferences = 'preferences.json';
  static const stagedManifest = 'manifest.json';

  /// Zero-byte marker. Its **existence** is the "a restore is ready" flag.
  ///
  /// Not a SharedPreferences key: this must be readable before any provider
  /// exists, and a restore also overwrites the preferences, so a flag stored
  /// among them would be written by the thing it gates.
  static const pendingMarker = 'PENDING';

  /// Crash-safe barrier marker, written next to the live database (NOT inside
  /// the staging directory, which is cleared as part of the swap). Carries the
  /// backup's exported-at instant so the restore-confirmation barrier can be
  /// recorded in the database on the next launch even if this one dies before
  /// that happens.
  static const restoreBarrierMarker = 'restore_barrier.json';
}

/// Whether a validated restore is waiting to be applied.
bool hasPendingRestore(Directory supportDir) =>
    File(p.join(_stagingPath(supportDir), RestoreLayout.pendingMarker))
        .existsSync();

/// Swaps a staged restore into place, if one is waiting.
///
/// **Must run before anything reads the database.** `appDatabaseProvider` is
/// keep-alive and backed by a `LazyDatabase`: the moment it is read, the file
/// is open, and these renames either fail or — worse — succeed underneath a
/// live handle.
///
/// Returns the restored preferences, or null when nothing was restored. They
/// are handed back rather than applied here because applying them needs
/// SharedPreferences, which needs a `ProviderContainer` — and the container
/// cannot exist until after the swap. They are also read *before* the staging
/// area is cleared, which is what makes this the only chance to get them.
///
/// A no-op when nothing is staged, and resumable if a previous attempt was
/// interrupted: every step tolerates its own work already being done, and a
/// failure after the old database has been moved away puts it back.
Future<Map<String, Object?>?> applyPendingRestore(Directory supportDir) async {
  if (!hasPendingRestore(supportDir)) return null;

  final staging = Directory(_stagingPath(supportDir));
  final stagedDb = File(p.join(staging.path, RestoreLayout.stagedDb));
  if (!stagedDb.existsSync()) {
    // Marker without a database: a half-written staging area. Leave the live
    // ledger alone and clear the marker so this does not repeat every launch.
    await staging.delete(recursive: true);
    return null;
  }

  final restoredPreferences = _readStagedPreferences(staging);

  final liveDb = File(p.join(supportDir.path, RestoreLayout.liveDb));
  final parkedDb = File(p.join(supportDir.path, RestoreLayout.replacedDb));

  // 1. Move the current database aside. Tolerated as already-done so an
  //    interrupted swap can be resumed rather than wedging startup.
  final parkedExisting = liveDb.existsSync();
  if (parkedExisting) {
    await liveDb.rename(parkedDb.path);
  }

  try {
    // 2. Drop the old database's sidecars. Done after the rename so the live
    //    file name is free, and before the restored file lands.
    for (final suffix in RestoreLayout.sidecarSuffixes) {
      final sidecar = File('${liveDb.path}$suffix');
      if (sidecar.existsSync()) {
        await sidecar.delete();
      }
    }

    // 3. Put the restored database in place.
    await stagedDb.rename(liveDb.path);
  } catch (_) {
    // A failed swap must leave the original ledger intact.
    if (parkedExisting && parkedDb.existsSync()) {
      await parkedDb.rename(liveDb.path);
    }
    rethrow;
  }

  // 4. Committed. Write the restore barrier (if the manifest carries an
  //    exported-at instant) BEFORE clearing staging — a crash between now and
  //    the barrier landing in the database must not lose the window.
  final backupExportedAt = _readStagedExportedAt(staging);
  if (backupExportedAt != null) {
    await _writeRestoreBarrier(supportDir, backupExportedAt);
  }

  // 5. Clear the staging area, marker included — a stale marker would
  //    re-apply a backup the user has already moved past.
  await staging.delete(recursive: true);

  // 6. Best effort: the pre-restore copy is a convenience, not part of the
  //    contract, and its absence must not fail a successful restore.
  try {
    if (parkedDb.existsSync()) await parkedDb.delete();
  } on FileSystemException {
    // Left on disk for manual recovery; nothing to do.
  }

  return restoredPreferences;
}

/// Reads the staged preferences before the staging area is cleared.
///
/// A malformed file yields null rather than failing: the ledger itself has
/// already been restored by this point, and losing the settings is a far
/// smaller loss than refusing a restore that is otherwise fine.
Map<String, Object?>? _readStagedPreferences(Directory staging) {
  final file = File(p.join(staging.path, RestoreLayout.stagedPreferences));
  if (!file.existsSync()) return null;
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    return decoded is Map ? decoded.cast<String, Object?>() : null;
  } catch (_) {
    return null;
  }
}

String _stagingPath(Directory supportDir) =>
    p.join(supportDir.path, RestoreLayout.stagingDir);

/// Reads the backup's exported-at instant from the staged manifest.
///
/// Returns null (never throws) when the manifest is missing or malformed — a
/// restore without a usable timestamp still completes; it simply cannot build
/// a confirmation window and so leaves auto-posting to the ordinary gates.
DateTime? _readStagedExportedAt(Directory staging) {
  final file = File(p.join(staging.path, RestoreLayout.stagedManifest));
  if (!file.existsSync()) return null;
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    final exportedAt = decoded is Map ? decoded['exportedAt'] : null;
    if (exportedAt is! String) return null;
    return DateTime.tryParse(exportedAt)?.toUtc();
  } catch (_) {
    return null;
  }
}

/// Persists the restore barrier atomically (temp write + rename) so a crash
/// mid-write leaves either no marker or a complete one, never a truncated
/// JSON the reader would trip over.
Future<void> _writeRestoreBarrier(
    Directory supportDir, DateTime backupExportedAt) async {
  final target = File(p.join(supportDir.path, RestoreLayout.restoreBarrierMarker));
  final temp = File('${target.path}.tmp');
  await temp.writeAsString(
      jsonEncode({'backupExportedAt': backupExportedAt.toIso8601String()}));
  await temp.rename(target.path);
}

/// The exported-at instant of a restore that was applied but whose barrier has
/// not yet been recorded in the database, or null when none is outstanding.
DateTime? readRestoreBarrier(Directory supportDir) {
  final file = File(p.join(supportDir.path, RestoreLayout.restoreBarrierMarker));
  if (!file.existsSync()) return null;
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    final exportedAt = decoded is Map ? decoded['backupExportedAt'] : null;
    if (exportedAt is! String) return null;
    return DateTime.tryParse(exportedAt)?.toUtc();
  } catch (_) {
    return null;
  }
}

/// Removes the barrier marker after it has been recorded in the database.
Future<void> clearRestoreBarrier(Directory supportDir) async {
  final file = File(p.join(supportDir.path, RestoreLayout.restoreBarrierMarker));
  if (file.existsSync()) {
    await file.delete();
  }
}
