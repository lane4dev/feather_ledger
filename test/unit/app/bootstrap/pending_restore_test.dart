import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:feather_ledger/app/bootstrap/pending_restore.dart';

/// The restore swap (spec 004, US4 / T026).
///
/// Pure `dart:io` against a temp directory — no Flutter, no Riverpod, no
/// database. That is the point of the seam: this is the one piece of the
/// restore path that must run before any of those exist.
void main() {
  late Directory supportDir;

  setUp(() {
    supportDir = Directory.systemTemp.createTempSync('feather_restore_test');
  });

  tearDown(() {
    if (supportDir.existsSync()) supportDir.deleteSync(recursive: true);
  });

  /// Lays out a staged restore the way BackupService.stageRestore would.
  void stageRestore({
    String database = 'RESTORED',
    bool marker = true,
    String preferences = '{}',
  }) {
    final staging = Directory(p.join(supportDir.path, RestoreLayout.stagingDir))
      ..createSync(recursive: true);
    File(p.join(staging.path, RestoreLayout.stagedDb))
        .writeAsStringSync(database);
    File(p.join(staging.path, RestoreLayout.stagedPreferences))
        .writeAsStringSync(preferences);
    if (marker) {
      File(p.join(staging.path, RestoreLayout.pendingMarker))
          .writeAsStringSync('');
    }
  }

  void writeLiveDatabase(String contents) =>
      File(p.join(supportDir.path, RestoreLayout.liveDb))
          .writeAsStringSync(contents);

  String readLiveDatabase() =>
      File(p.join(supportDir.path, RestoreLayout.liveDb)).readAsStringSync();

  bool liveSidecarExists(String suffix) =>
      File('${p.join(supportDir.path, RestoreLayout.liveDb)}$suffix')
          .existsSync();

  void writeLiveSidecars() {
    for (final suffix in RestoreLayout.sidecarSuffixes) {
      File('${p.join(supportDir.path, RestoreLayout.liveDb)}$suffix')
          .writeAsStringSync('stale');
    }
  }

  bool stagingExists() =>
      Directory(p.join(supportDir.path, RestoreLayout.stagingDir)).existsSync();

  test('does nothing when no restore is staged', () async {
    writeLiveDatabase('CURRENT');

    await applyPendingRestore(supportDir);

    expect(readLiveDatabase(), 'CURRENT');
  });

  test('is a no-op when the staging area holds no pending marker', () async {
    // Staged files but no marker means staging never completed validation,
    // so it must not be applied.
    stageRestore(marker: false);
    writeLiveDatabase('CURRENT');

    await applyPendingRestore(supportDir);

    expect(readLiveDatabase(), 'CURRENT');
  });

  test('swaps the restored database in and clears the staging area', () async {
    stageRestore(database: 'RESTORED');
    writeLiveDatabase('CURRENT');

    await applyPendingRestore(supportDir);

    expect(readLiveDatabase(), 'RESTORED');
    expect(stagingExists(), isFalse,
        reason: 'a consumed marker would re-apply a backup already moved past');
  });

  test('removes the stale sidecars of the database it replaces', () async {
    // The sharpest edge in the whole feature: a leftover -wal would be
    // replayed into the restored database and corrupt it silently.
    stageRestore();
    writeLiveDatabase('CURRENT');
    writeLiveSidecars();
    expect(liveSidecarExists('-wal'), isTrue, reason: 'fixture precondition');

    await applyPendingRestore(supportDir);

    for (final suffix in RestoreLayout.sidecarSuffixes) {
      expect(liveSidecarExists(suffix), isFalse,
          reason: 'a stale $suffix would corrupt the restored database');
    }
  });

  test('creates the database when there was none to replace', () async {
    stageRestore(database: 'RESTORED');

    await applyPendingRestore(supportDir);

    expect(readLiveDatabase(), 'RESTORED');
  });

  test('resumes an interrupted swap instead of wedging', () async {
    // A crash between "park the old database" and "move the new one in"
    // leaves no live database but the marker still set. The next launch has
    // to finish the job.
    stageRestore(database: 'RESTORED');
    File(p.join(supportDir.path, RestoreLayout.replacedDb))
        .writeAsStringSync('CURRENT');

    await applyPendingRestore(supportDir);

    expect(readLiveDatabase(), 'RESTORED');
    expect(stagingExists(), isFalse);
  });

  test('a marker with no staged database leaves the ledger alone', () async {
    // A half-written staging area must not cost the user their ledger.
    final staging = Directory(p.join(supportDir.path, RestoreLayout.stagingDir))
      ..createSync(recursive: true);
    File(p.join(staging.path, RestoreLayout.pendingMarker))
        .writeAsStringSync('');
    writeLiveDatabase('CURRENT');

    await applyPendingRestore(supportDir);

    expect(readLiveDatabase(), 'CURRENT');
    expect(stagingExists(), isFalse, reason: 'the bad staging area is cleared');
  });

  test('hands back the restored preferences before clearing the staging area',
      () async {
    // The caller cannot apply these until a ProviderContainer exists, which
    // is after the swap — so they can only be read here.
    stageRestore(
      preferences: '{"currency_code":"CNY","show_balance":false}',
    );
    writeLiveDatabase('CURRENT');

    final restored = await applyPendingRestore(supportDir);

    expect(restored, {'currency_code': 'CNY', 'show_balance': false});

    // Self-check: the file it came from really is gone.
    expect(stagingExists(), isFalse);
  });

  test('returns null when nothing was staged', () async {
    expect(await applyPendingRestore(supportDir), isNull);
  });

  test('a malformed preferences file does not fail the restore', () async {
    // The ledger has already been swapped by this point; losing the settings
    // is a smaller loss than refusing an otherwise good restore.
    stageRestore(preferences: 'not json at all');
    writeLiveDatabase('CURRENT');

    final restored = await applyPendingRestore(supportDir);

    expect(restored, isNull);
    expect(readLiveDatabase(), 'RESTORED');
  });

  test('hasPendingRestore reports the marker', () {
    expect(hasPendingRestore(supportDir), isFalse);

    stageRestore();

    expect(hasPendingRestore(supportDir), isTrue);
  });
}
