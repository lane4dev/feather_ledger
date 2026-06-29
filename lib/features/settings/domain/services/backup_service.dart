import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

import 'package:feather_ledger/app/bootstrap/pending_restore.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/settings/domain/models/backup_manifest.dart';

part 'backup_service.g.dart';

/// What a restore would cost, for the confirmation dialog (FR-024).
///
/// A restore is a *replacement*, never a merge, so the honest thing to show
/// before it happens is how much would be thrown away.
class BackupPreview {
  final BackupManifest manifest;
  final int currentEventCount;

  const BackupPreview({
    required this.manifest,
    required this.currentEventCount,
  });

  /// Events present now that the backup does not contain. Zero when the
  /// backup is the same age or newer than the current ledger.
  int get discardedEventCount {
    final difference = currentEventCount - manifest.eventCount;
    return difference > 0 ? difference : 0;
  }
}

/// Whole-ledger backup and staged restore (spec 004, US4).
///
/// A backup is one file: a zip holding the database, the preferences and a
/// manifest. One file rather than three loose ones because the only way a
/// backup leaves this app is the platform share sheet, which shares *files* —
/// three of them would have to be re-picked individually on restore, with
/// nothing stopping a mismatched combination.
///
/// The database inside is produced by `VACUUM INTO`, not by copying
/// `db.sqlite`: a copy can catch a journal mid-flight, while `VACUUM INTO`
/// writes a clean, self-contained snapshot.
///
/// Restore is staged, never applied in place — see [RestoreLayout] for why.
class BackupService {
  final AppDatabase _db;
  final PreferencesRepository _preferences;
  final Directory _supportDir;
  final Directory _tempDir;
  final String _appVersion;

  BackupService(
    this._db,
    this._preferences, {
    required Directory supportDir,
    required Directory tempDir,
    required String appVersion,
  })  : _supportDir = supportDir,
        _tempDir = tempDir,
        _appVersion = appVersion;

  /// Builds the archive and returns the path it was written to.
  ///
  /// Separate from [createBackup] so the archive can be inspected without a
  /// platform share channel. The caller owns the file.
  Future<Result<String>> buildArchive() {
    return guard(() async {
      final workDir = await _tempDir.createTemp('fl_backup_');
      final snapshot = File(p.join(workDir.path, RestoreLayout.stagedDb));

      // VACUUM INTO requires the target not to exist, and must not run inside
      // a transaction. The path is interpolated because the statement takes a
      // filename *expression*, not a bound parameter.
      final escaped = snapshot.path.replaceAll("'", "''");
      await _db.customStatement("VACUUM INTO '$escaped'");

      final exported = _preferences.exportAll();
      final manifest = BackupManifest(
        schemaVersion: _db.schemaVersion,
        appVersion: _appVersion,
        exportedAt: DateTime.now().toUtc(),
        databaseBytes: await snapshot.length(),
        preferenceKeys: exported.keys.toList()..sort(),
        eventCount: await _db.eventsDao.countAll(),
        lastGlobalSequenceNumber: await _db.eventsDao.getMaxGsn() ?? 0,
        seriesCount: (await _db.recurringDao.getAllSeries()).length,
      );

      final archive = Archive()
        ..addFile(ArchiveFile.string(
            RestoreLayout.stagedManifest, jsonEncode(manifest.toJson())))
        ..addFile(ArchiveFile.bytes(
            RestoreLayout.stagedDb, await snapshot.readAsBytes()))
        ..addFile(ArchiveFile.string(
            RestoreLayout.stagedPreferences, jsonEncode(exported)));

      final output = File(p.join(
        workDir.path,
        'feather_ledger_backup_${_timestamp(manifest.exportedAt)}.flbackup',
      ));
      await output.writeAsBytes(ZipEncoder().encodeBytes(archive));
      return output.path;
    });
  }

  /// Builds the archive and hands it to the platform share sheet.
  Future<Result<String>> createBackup() {
    return guard(() async {
      final built = await buildArchive();
      return built.when(
        success: (path) async {
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(path, mimeType: 'application/zip')],
            ),
          );
          return path;
        },
        failure: (code, message) => throw CommandRejected(code, message),
      );
    });
  }

  /// Reads an archive's manifest without staging it, so the confirmation
  /// dialog can say what restoring it would discard.
  Future<Result<BackupPreview>> preview(File picked) {
    return guard(() async {
      final archive = _decodeArchive(await picked.readAsBytes());
      return BackupPreview(
        manifest: _readManifest(archive),
        currentEventCount: await _db.eventsDao.countAll(),
      );
    });
  }

  /// Validates an archive and stages it for the next launch (FR-023/FR-025).
  ///
  /// Takes a plain [File] rather than the picker's `XFile` so the service
  /// stays independent of whichever picker the UI happens to use.
  ///
  /// Everything is validated **before** the pending marker is written: the
  /// marker's existence is what commits the restore, so a refusal must leave
  /// the current ledger untouched and no marker behind.
  Future<Result<void>> stageRestore(File picked) {
    return guard(() async {
      final archive = _decodeArchive(await picked.readAsBytes());
      final manifest = _readManifest(archive);

      if (manifest.schemaVersion != _db.schemaVersion) {
        throw BackupFormatException(
            'Backup is schema v${manifest.schemaVersion}; this app reads '
            'v${_db.schemaVersion}.');
      }

      final dbEntry = archive.findFile(RestoreLayout.stagedDb);
      if (dbEntry == null) {
        throw const BackupFormatException('Backup contains no database');
      }

      final staging =
          Directory(p.join(_supportDir.path, RestoreLayout.stagingDir));
      if (staging.existsSync()) await staging.delete(recursive: true);
      await staging.create(recursive: true);

      try {
        final stagedDb = File(p.join(staging.path, RestoreLayout.stagedDb));
        await stagedDb.writeAsBytes(dbEntry.content);
        await _verifyDatabase(stagedDb);

        final prefsEntry = archive.findFile(RestoreLayout.stagedPreferences);
        if (prefsEntry != null) {
          await File(p.join(staging.path, RestoreLayout.stagedPreferences))
              .writeAsBytes(prefsEntry.content);
        }
        await File(p.join(staging.path, RestoreLayout.stagedManifest))
            .writeAsString(jsonEncode(manifest.toJson()));

        // Commit point — written last, only once everything above passed.
        await File(p.join(staging.path, RestoreLayout.pendingMarker))
            .writeAsString('');
      } catch (_) {
        await staging.delete(recursive: true);
        rethrow;
      }
    });
  }

  Archive _decodeArchive(Uint8List bytes) {
    try {
      return ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw BackupFormatException('Not a readable backup archive: $e');
    }
  }

  BackupManifest _readManifest(Archive archive) {
    final entry = archive.findFile(RestoreLayout.stagedManifest);
    if (entry == null) {
      throw const BackupFormatException('Backup contains no manifest');
    }
    final decoded = jsonDecode(utf8.decode(entry.content));
    if (decoded is! Map<String, dynamic>) {
      throw const BackupFormatException('Backup manifest is not an object');
    }
    return BackupManifest.fromJson(decoded);
  }

  /// Proves the staged database is openable and internally consistent.
  ///
  /// This is the check a zip's CRC32 cannot make: the CRC proves the bytes
  /// arrived intact, not that SQLite can use them.
  Future<void> _verifyDatabase(File staged) async {
    // Read the schema version out of the SQLite header rather than by opening
    // the file: opening it through drift would run the migration strategy,
    // which could rewrite the very copy under validation. user_version is a
    // big-endian uint32 at byte offset 60 of the 100-byte header.
    final handle = await staged.open();
    try {
      final header = await handle.read(64);
      if (header.length < 64) {
        throw const BackupFormatException('Backup database is truncated');
      }
      final version =
          ByteData.sublistView(header, 60, 64).getUint32(0, Endian.big);
      if (version != _db.schemaVersion) {
        throw BackupFormatException(
            'Backup database is schema v$version; this app reads '
            'v${_db.schemaVersion}.');
      }
    } finally {
      await handle.close();
    }

    final probe = AppDatabase.internal(NativeDatabase(staged));
    try {
      final rows = await probe.customSelect('PRAGMA integrity_check').get();
      final verdict = rows.isEmpty ? null : rows.first.data.values.first;
      if (verdict != 'ok') {
        throw BackupFormatException('Backup database failed its integrity '
            'check: $verdict');
      }

      // A consistent SQLite file is not necessarily *this* application's
      // database. `integrity_check` and the schema version both pass for a
      // database written before the event-sourcing migration — it carries
      // user_version 1 and a perfectly valid set of older tables — and
      // installing it makes the app die on the first event-store query, with
      // the user's current ledger already replaced. Reading through the real
      // DAO is what proves the schema is one this build can use.
      try {
        await probe.eventsDao.countAll();
      } catch (e) {
        throw BackupFormatException(
            'Backup is a Feather Ledger database this version cannot read '
            '(its schema predates the event store): $e');
      }
    } finally {
      await probe.close();
    }
  }

  static String _timestamp(DateTime utc) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${utc.year}${two(utc.month)}${two(utc.day)}'
        'T${two(utc.hour)}${two(utc.minute)}${two(utc.second)}';
  }
}

@riverpod
Future<BackupService> backupService(Ref ref) async {
  final db = ref.watch(appDatabaseProvider);
  final preferences = await ref.watch(preferencesRepositoryProvider.future);
  final supportDir = await getApplicationSupportDirectory();
  final tempDir = await getTemporaryDirectory();
  final info = await PackageInfo.fromPlatform();

  return BackupService(
    db,
    preferences,
    supportDir: supportDir,
    tempDir: tempDir,
    appVersion: '${info.version}+${info.buildNumber}',
  );
}
