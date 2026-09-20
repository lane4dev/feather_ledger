import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/settings/presentation/screens/settings_screen.dart';

import '../../../support/mocks/mock_shared_preferences.dart';

void main() {
  late MockSharedPreferences mockPrefs;
  late PreferencesRepository preferences;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    preferences = PreferencesRepositoryImpl(mockPrefs);
  });

  tearDown(() => mockPrefs.reset());

  Future<void> pump(WidgetTester tester) async {
    // The settings list is long; give the test surface enough height so the
    // switch rows are all on screen.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider
              .overrideWith((ref) async => preferences),
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

  testWidgets('the three switches default off and toggle independently',
      (tester) async {
    await pump(tester);

    final planned = find.widgetWithText(SwitchListTile, 'Planned');
    final subscription = find.widgetWithText(SwitchListTile, 'Subscription');
    final repeating = find.widgetWithText(SwitchListTile, 'Repeating');

    expect(planned, findsOneWidget);
    expect(subscription, findsOneWidget);
    expect(repeating, findsOneWidget);

    expect(tester.widget<SwitchListTile>(planned).value, isFalse);
    expect(tester.widget<SwitchListTile>(subscription).value, isFalse);
    expect(tester.widget<SwitchListTile>(repeating).value, isFalse);

    await tester.tap(subscription);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(subscription).value, isTrue);
    expect(tester.widget<SwitchListTile>(planned).value, isFalse);
    expect(tester.widget<SwitchListTile>(repeating).value, isFalse);

    expect(
      preferences.getAutoPostEnabled(RecurringSeriesMode.subscription),
      isTrue,
      reason: 'toggling must persist the local choice',
    );
    expect(
      preferences.getAutoPostEnabled(RecurringSeriesMode.planned),
      isFalse,
      reason: 'the three switches are independent',
    );
  });
}
