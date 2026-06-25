import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/features/settings/domain/models/backup_manifest.dart';

/// Manifest parsing and its three refusals (spec 004, US4 / T023).
void main() {
  Map<String, dynamic> validJson() => {
        'format': 'feather-ledger-backup',
        'formatVersion': 1,
        'schemaVersion': 1,
        'appVersion': '1.0.0+1',
        'exportedAt': '2026-09-21T14:30:00.000Z',
        'databaseBytes': 245760,
        'preferenceKeys': ['app_theme_mode', 'currency_code'],
        'eventCount': 812,
        'lastGlobalSequenceNumber': 812,
        'seriesCount': 3,
      };

  test('round-trips through JSON', () {
    final original = BackupManifest.fromJson(validJson());

    final restored = BackupManifest.fromJson(original.toJson());

    expect(restored.format, BackupManifest.formatName);
    expect(restored.formatVersion, 1);
    expect(restored.schemaVersion, 1);
    expect(restored.appVersion, '1.0.0+1');
    expect(restored.exportedAt.toUtc(), DateTime.utc(2026, 9, 21, 14, 30));
    expect(restored.databaseBytes, 245760);
    expect(restored.preferenceKeys, ['app_theme_mode', 'currency_code']);
    expect(restored.eventCount, 812);
    expect(restored.lastGlobalSequenceNumber, 812);
    expect(restored.seriesCount, 3);
  });

  test('refuses a file that is not one of ours', () {
    final json = validJson()..['format'] = 'some-other-tool';

    expect(
      () => BackupManifest.fromJson(json),
      throwsA(isA<BackupFormatException>()),
      reason: 'restoring a foreign zip would replace the ledger with garbage',
    );
  });

  test('refuses a container version it is too old to read', () {
    final json = validJson()..['formatVersion'] = 2;

    expect(() => BackupManifest.fromJson(json),
        throwsA(isA<BackupFormatException>()));
  });

  test('refuses a manifest with no format version', () {
    final json = validJson()..remove('formatVersion');

    expect(() => BackupManifest.fromJson(json),
        throwsA(isA<BackupFormatException>()));
  });

  test('refuses a manifest missing required fields', () {
    final json = validJson()..remove('eventCount');

    expect(() => BackupManifest.fromJson(json),
        throwsA(isA<BackupFormatException>()),
        reason: 'the counts drive the "this discards N events" warning');
  });

  test('carries the counts the restore warning depends on', () {
    final manifest = BackupManifest.fromJson(validJson());

    // The dialog reads these two to say what a replacement costs.
    expect(manifest.eventCount, greaterThan(0));
    expect(manifest.lastGlobalSequenceNumber, isNotNull);
  });
}
