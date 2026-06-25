import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:feather_ledger/app/bootstrap/pending_restore.dart';
import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/settings/domain/models/backup_manifest.dart';
import 'package:feather_ledger/features/settings/domain/services/backup_service.dart';

import '../../../../support/event_sourcing/ledger_service_harness.dart';
import '../../../../support/mocks/mock_shared_preferences.dart';

/// Backup and staged restore (spec 004, US4 / T024, T027, T028).
///
/// Real database, real files, real zip — the parts being tested are the
/// archive contents and the refusal behaviour, and faking either would test
/// nothing. Only the share sheet is out of scope (platform IO).
void main() {
  late LedgerServiceHarness harness;
  late Directory supportDir;
  late MockSharedPreferences mockPrefs;
  late PreferencesRepository preferences;

  setUp(() {
    harness = LedgerServiceHarness();
    supportDir = Directory.systemTemp.createTempSync('feather_backup_test');
    mockPrefs = MockSharedPreferences();
    preferences = PreferencesRepositoryImpl(mockPrefs);
  });

  tearDown(() async {
    await harness.close();
    if (supportDir.existsSync()) supportDir.deleteSync(recursive: true);
    mockPrefs.reset();
  });

  BackupService service() => BackupService(
        harness.db,
        preferences,
        supportDir: supportDir,
        tempDir: supportDir,
        appVersion: '1.0.0+1',
      );

  /// Seeds one expense so the ledger has events to count.
  Future<void> seedExpense() async {
    await harness.accountService.createAccount(
      commandId: 'cmd_acc',
      name: 'Cash',
      type: AccountType.cash,
      initialBalanceMinor: 0,
      currencyCode: 'USD',
    );
    await harness.categoryService.createCategory(
      commandId: 'cmd_cat',
      name: 'Food',
      iconKey: '1',
      colorInt: 0xFF000000,
      type: CategoryType.expense,
    );
    final accountId =
        (await harness.db.accountDao.getAllAccounts()).single.id;
    final categoryId =
        (await harness.db.categoriesDao.getAllCategories()).single.id;
    await harness.ledgerService.addTransaction(
      commandId: 'cmd_expense',
      amountMinor: 5000,
      type: TransactionKind.expense,
      date: DateTime(2026, 1, 10),
      categoryId: categoryId,
      accountId: accountId,
    );
  }

  String builtArchivePath(Result<String> result) {
    expect(result, isA<Success<String>>());
    return (result as Success<String>).value;
  }

  Archive readArchive(String path) =>
      ZipDecoder().decodeBytes(File(path).readAsBytesSync());

  File stagingMarker() => File(p.join(
      supportDir.path, RestoreLayout.stagingDir, RestoreLayout.pendingMarker));

  group('buildArchive', () {
    test('produces a three-entry archive with a matching manifest', () async {
      await seedExpense();
      await preferences.setCurrency('CNY');
      await preferences.setShowBalance(false);

      final path = builtArchivePath(await service().buildArchive());
      final archive = readArchive(path);

      expect(
        archive.where((f) => f.isFile).map((f) => f.name).toSet(),
        {
          RestoreLayout.stagedManifest,
          RestoreLayout.stagedDb,
          RestoreLayout.stagedPreferences,
        },
      );

      final manifest = BackupManifest.fromJson(
        jsonDecode(utf8.decode(
            archive.findFile(RestoreLayout.stagedManifest)!.content)),
      );
      expect(manifest.schemaVersion, harness.db.schemaVersion);
      expect(manifest.appVersion, '1.0.0+1');
      // 2 accounts... no: 1 account + 1 category + 1 transaction + 1 opening
      // balance = 4 events. Asserted against the database rather than a
      // literal so the fixture can change without a false failure.
      expect(manifest.eventCount, await harness.db.eventsDao.countAll());
      expect(manifest.lastGlobalSequenceNumber,
          await harness.db.eventsDao.getMaxGsn());
      expect(manifest.preferenceKeys, ['currency_code', 'show_balance']);
      expect(manifest.databaseBytes, greaterThan(0));
    });

    test('the snapshot is a complete SQLite database', () async {
      await seedExpense();

      final path = builtArchivePath(await service().buildArchive());
      final dbBytes = readArchive(path)
          .findFile(RestoreLayout.stagedDb)!
          .content;

      // SQLite's own file magic — proves the snapshot is a database rather
      // than a partial or truncated file.
      expect(utf8.decode(dbBytes.sublist(0, 15)), 'SQLite format 3');

      // And the archive containing it is accepted end to end.
      expect(await service().stageRestore(File(path)), isA<Success<void>>());
      expect(stagingMarker().existsSync(), isTrue);
    });
  });

  group('stageRestore', () {
    /// Writes a valid archive, optionally corrupting one of its entries.
    Future<File> archiveFile({
      Archive Function(Archive valid)? corrupt,
    }) async {
      await seedExpense();
      final path = builtArchivePath(await service().buildArchive());
      final valid = readArchive(path);

      final target = File(p.join(supportDir.path, 'picked.flbackup'));
      if (corrupt == null) {
        await target.writeAsBytes(await File(path).readAsBytes());
      } else {
        await target.writeAsBytes(
            ZipEncoder().encodeBytes(corrupt(valid)));
      }
      return target;
    }

    test('stages a good backup and writes the pending marker last', () async {
      final picked = await archiveFile();

      final result = await service().stageRestore(picked);

      expect(result, isA<Success<void>>());
      expect(stagingMarker().existsSync(), isTrue);
      expect(
        Directory(p.join(supportDir.path, RestoreLayout.stagingDir))
            .listSync()
            .map((e) => p.basename(e.path))
            .toSet(),
        containsAll([
          RestoreLayout.stagedDb,
          RestoreLayout.stagedPreferences,
          RestoreLayout.stagedManifest,
          RestoreLayout.pendingMarker,
        ]),
      );
    });

    test('refuses a zip that is not one of ours, leaving no marker',
        () async {
      final foreign = File(p.join(supportDir.path, 'foreign.zip'));
      await foreign.writeAsBytes(ZipEncoder().encodeBytes(
        Archive()..addFile(ArchiveFile.string('holiday-photos.txt', 'hi')),
      ));

      final result = await service().stageRestore(foreign);

      expect(result, isA<Failure<void>>());
      expect(stagingMarker().existsSync(), isFalse,
          reason: 'a refusal must not leave the ledger marked for replacement');
    });

    test('refuses a backup from a future schema version, leaving no marker',
        () async {
      // Rewrite only the manifest; the database bytes stay valid, so this
      // isolates the version gate rather than the integrity gate.
      final picked = await archiveFile(corrupt: (valid) {
        final manifest = jsonDecode(
          utf8.decode(valid.findFile(RestoreLayout.stagedManifest)!.content),
        ) as Map<String, dynamic>;
        manifest['schemaVersion'] = 99;
        return Archive()
          ..addFile(ArchiveFile.string(
              RestoreLayout.stagedManifest, jsonEncode(manifest)))
          ..addFile(ArchiveFile.bytes(RestoreLayout.stagedDb,
              valid.findFile(RestoreLayout.stagedDb)!.content))
          ..addFile(ArchiveFile.string(RestoreLayout.stagedPreferences, '{}'));
      });

      final result = await service().stageRestore(picked);

      expect(result, isA<Failure<void>>());
      expect(stagingMarker().existsSync(), isFalse);
    });

    test('refuses a truncated database inside an otherwise valid archive',
        () async {
      // The zip is well-formed and its CRC matches; only SQLite can tell that
      // the database is unusable. This is the check CRC32 cannot make.
      final picked = await archiveFile(corrupt: (valid) {
        final dbBytes = valid.findFile(RestoreLayout.stagedDb)!.content;
        return Archive()
          ..addFile(ArchiveFile.string(
              RestoreLayout.stagedManifest,
              utf8.decode(
                  valid.findFile(RestoreLayout.stagedManifest)!.content)))
          ..addFile(ArchiveFile.bytes(RestoreLayout.stagedDb,
              dbBytes.sublist(0, dbBytes.length ~/ 3)))
          ..addFile(ArchiveFile.string(RestoreLayout.stagedPreferences, '{}'));
      });

      final result = await service().stageRestore(picked);

      expect(result, isA<Failure<void>>());
      expect(stagingMarker().existsSync(), isFalse,
          reason: 'a corrupt restore must not be armed');
    });

    test('carries the event counts the restore warning needs', () async {
      await seedExpense();
      final archive = readArchive(builtArchivePath(await service().buildArchive()));
      final manifest = BackupManifest.fromJson(jsonDecode(utf8.decode(
          archive.findFile(RestoreLayout.stagedManifest)!.content)));

      expect(manifest.eventCount, greaterThan(0),
          reason: 'the dialog states how many events a restore discards');
    });
  });

  group('BackupPreview.discardedEventCount', () {
    // The number the user acts on when confirming a destructive action, so
    // it is worth pinning on its own rather than only through the dialog.
    BackupPreview preview({required int backup, required int current}) =>
        BackupPreview(
          manifest: BackupManifest(
            schemaVersion: 1,
            appVersion: '1.0.0+1',
            exportedAt: DateTime.utc(2026, 9, 21),
            databaseBytes: 0,
            preferenceKeys: const [],
            eventCount: backup,
            lastGlobalSequenceNumber: backup,
            seriesCount: 0,
          ),
          currentEventCount: current,
        );

    test('counts the events the backup does not have', () {
      expect(preview(backup: 100, current: 140).discardedEventCount, 40);
    });

    test('is zero when the backup is current', () {
      expect(preview(backup: 140, current: 140).discardedEventCount, 0);
    });

    test('never goes negative when the backup is newer', () {
      // Restoring an older app's backup onto a fresh install: nothing is
      // lost, and "-40 events will be discarded" would be nonsense.
      expect(preview(backup: 140, current: 100).discardedEventCount, 0);
    });
  });
}
