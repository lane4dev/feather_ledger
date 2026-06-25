import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/settings/domain/models/backup_manifest.dart';
import 'package:feather_ledger/features/settings/domain/services/backup_service.dart';
import 'package:feather_ledger/features/settings/presentation/screens/settings_screen.dart';

import '../../../support/event_sourcing/ledger_service_harness.dart';
import '../../../support/mocks/mock_shared_preferences.dart';

/// The settings data entries and the restore dialog sequence
/// (spec 004, US4 / T031).
///
/// [BackupService] is stubbed here on purpose. A `testWidgets` body runs in a
/// fake-async zone where real file I/O never completes, so driving the real
/// service through a tap would hang rather than assert. The service's own
/// behaviour — archive contents, refusal cases, the staged swap — is covered
/// against real files in `backup_service_test.dart`; what is left for this
/// layer is whether the screen asks the right questions in the right order.
void main() {
  late LedgerServiceHarness harness;
  late Directory supportDir;
  late MockSharedPreferences mockPrefs;
  late _FakeBackupService service;

  setUp(() {
    harness = LedgerServiceHarness();
    supportDir = Directory.systemTemp.createTempSync('feather_settings_test');
    mockPrefs = MockSharedPreferences();
    service = _FakeBackupService(harness, mockPrefs, supportDir);
  });

  tearDown(() async {
    await harness.close();
    if (supportDir.existsSync()) supportDir.deleteSync(recursive: true);
    mockPrefs.reset();
  });

  Future<void> pumpSettings(
    WidgetTester tester, {
    File? pickedFile,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backupServiceProvider.overrideWith((ref) => service),
          backupFilePickerProvider.overrideWithValue(() async => pickedFile),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final pickedFile = File('/tmp/whatever.flbackup');

  testWidgets('offers both data entries', (tester) async {
    await pumpSettings(tester);

    expect(find.text('Back up now'), findsOneWidget);
    expect(find.text('Restore from backup'), findsOneWidget);
  });

  testWidgets('restoring states what it would discard before doing anything',
      (tester) async {
    service.previewResult = BackupPreview(
      manifest: _manifest(eventCount: 100),
      currentEventCount: 140,
    );

    await pumpSettings(tester, pickedFile: pickedFile);
    await tester.tap(find.text('Restore from backup'));
    await tester.pumpAndSettle();

    expect(find.text('Replace all data?'), findsOneWidget);
    // A bare "are you sure?" would hide the whole cost of the action.
    expect(
      find.textContaining('restoring discards 40 of them'),
      findsOneWidget,
      reason: 'the dialog must quantify what is thrown away',
    );
  });

  testWidgets('a confirmed restore stages and asks for a restart',
      (tester) async {
    service.previewResult = BackupPreview(
      manifest: _manifest(eventCount: 100),
      currentEventCount: 100,
    );

    await pumpSettings(tester, pickedFile: pickedFile);
    await tester.tap(find.text('Restore from backup'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Restore from backup'));
    await tester.pumpAndSettle();

    expect(service.stagedFiles, [pickedFile]);
    expect(find.text('Restore ready'), findsOneWidget);
    expect(find.textContaining('open it again'), findsOneWidget);
    expect(find.text('Exit now'), findsOneWidget);
  });

  testWidgets('cancelling the confirmation stages nothing', (tester) async {
    service.previewResult = BackupPreview(
      manifest: _manifest(eventCount: 100),
      currentEventCount: 140,
    );

    await pumpSettings(tester, pickedFile: pickedFile);
    await tester.tap(find.text('Restore from backup'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(service.stagedFiles, isEmpty, reason: 'cancel means cancel');
    expect(find.text('Restore ready'), findsNothing);
  });

  testWidgets('cancelling the file dialog does nothing at all', (tester) async {
    await pumpSettings(tester, pickedFile: null);

    await tester.tap(find.text('Restore from backup'));
    await tester.pumpAndSettle();

    expect(find.text('Replace all data?'), findsNothing);
    expect(service.previewCalls, 0,
        reason: 'no file, no preview, no dialog');
  });

  testWidgets('an unreadable backup reports the error and stages nothing',
      (tester) async {
    service.previewFailure = const BackupFormatException('nope');

    await pumpSettings(tester, pickedFile: pickedFile);
    await tester.tap(find.text('Restore from backup'));
    await tester.pumpAndSettle();

    expect(find.text('Replace all data?'), findsNothing);
    expect(service.stagedFiles, isEmpty);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('backing up shares the archive and confirms', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Back up now'));
    await tester.pumpAndSettle();

    expect(service.backupCalls, 1);
    expect(find.text('Backup created'), findsOneWidget);
  });
}

BackupManifest _manifest({required int eventCount}) => BackupManifest(
      schemaVersion: 1,
      appVersion: '1.0.0+1',
      exportedAt: DateTime.utc(2026, 9, 21),
      databaseBytes: 1024,
      preferenceKeys: const [],
      eventCount: eventCount,
      lastGlobalSequenceNumber: eventCount,
      seriesCount: 0,
    );

/// A [BackupService] with its file work removed, so the screen's dialog
/// sequence can be driven without real I/O.
///
/// It still extends the real class — the point is that the screen talks to
/// the same type in tests as in production, so a signature change breaks
/// here too.
class _FakeBackupService extends BackupService {
  _FakeBackupService(
    LedgerServiceHarness harness,
    MockSharedPreferences prefs,
    Directory supportDir,
  ) : super(
          harness.db,
          PreferencesRepositoryImpl(prefs),
          supportDir: supportDir,
          tempDir: supportDir,
          appVersion: '1.0.0+1',
        );

  BackupPreview? previewResult;
  BackupFormatException? previewFailure;
  int previewCalls = 0;
  int backupCalls = 0;
  final List<File> stagedFiles = [];

  @override
  Future<Result<String>> createBackup() async {
    backupCalls++;
    return const Success('/tmp/backup.flbackup');
  }

  @override
  Future<Result<BackupPreview>> preview(File picked) async {
    previewCalls++;
    final failure = previewFailure;
    if (failure != null) {
      return Failure(LedgerErrorCode.unknownEvent, failure.message);
    }
    return Success(previewResult!);
  }

  @override
  Future<Result<void>> stageRestore(File picked) async {
    stagedFiles.add(picked);
    return unitResult;
  }
}
