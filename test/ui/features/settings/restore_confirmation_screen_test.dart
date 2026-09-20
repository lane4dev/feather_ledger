import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';
import 'package:feather_ledger/features/settings/presentation/screens/settings_screen.dart';

import '../../../support/mocks/mock_shared_preferences.dart';

/// The restore-confirmation section on the settings screen (spec 006, US62).
///
/// A pure UI test: the summary provider is canned and the service is faked, so
/// the test does not depend on Drift streams resolving inside the fake-async
/// test clock. The real confirm/reject/latch behaviour lives in
/// `test/unit/features/settings/domain/restore_confirmation_test.dart`.
void main() {
  late _FakeRecurringService service;

  setUp(() {
    service = _FakeRecurringService();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWith(
              (ref) async => PreferencesRepositoryImpl(MockSharedPreferences())),
          pendingRestoreConfirmationSummariesProvider.overrideWith((ref) async => [
                RestoreConfirmationSummary(
                  batchId: 'batch1',
                  currencyCode: 'USD',
                  count: 2,
                  firstDate: DateTime(2026, 1, 1),
                  lastDate: DateTime(2026, 1, 2),
                ),
              ]),
          recurringServiceProvider.overrideWithValue(service),
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

  testWidgets('a pending restore batch is listed with count, range and risk',
      (tester) async {
    await pump(tester);

    expect(find.text('Restore confirmation'), findsOneWidget);
    expect(find.text('2 bills'), findsOneWidget);
    expect(
      find.textContaining('may have been recorded on another device'),
      findsOneWidget,
    );
  });

  testWidgets('turning a restore batch manual rejects it', (tester) async {
    await pump(tester);

    await tester.tap(find.text('2 bills'));
    await tester.pumpAndSettle();

    expect(find.text('Turn manual'), findsOneWidget);
    expect(find.text('Post'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);

    await tester.tap(find.text('Turn manual'));
    await tester.pumpAndSettle();

    expect(service.rejected, ['batch1']);
  });

  testWidgets('deferring keeps the section and records nothing', (tester) async {
    await pump(tester);

    await tester.tap(find.text('2 bills'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();

    expect(service.confirmed, isEmpty);
    expect(service.rejected, isEmpty);
    expect(find.text('Restore confirmation'), findsOneWidget);
  });
}

class _FakeRecurringService implements RecurringService {
  final List<String> confirmed = [];
  final List<String> rejected = [];

  @override
  Future<void> confirmRestoreBatch(String batchId) async {
    confirmed.add(batchId);
  }

  @override
  Future<void> rejectRestoreBatch(String batchId) async {
    rejected.add(batchId);
  }

  @override
  Future<List<ScheduledTransactionEntity>> restoreConfirmationEligible(
          String batchId) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
