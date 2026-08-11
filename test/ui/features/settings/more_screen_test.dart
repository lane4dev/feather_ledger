import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/router/app_router.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/features/settings/presentation/screens/about_screen.dart';
import 'package:feather_ledger/features/settings/presentation/screens/account_management_screen.dart';
import 'package:feather_ledger/features/settings/presentation/screens/settings_screen.dart';

import '../../../support/event_sourcing/ledger_service_harness.dart';

/// The more tab's entries (spec 004): each one says what it opens, and each
/// one opens it *over* the shell.
///
/// Driven through the real router on purpose — the thing under test is the
/// route wiring, and a hand-built GoRouter in the test would assert against
/// the test's own idea of it. The database is the usual in-memory harness so
/// the screens behind the tiles have something to read.
void main() {
  late LedgerServiceHarness harness;

  setUp(() => harness = LedgerServiceHarness());
  tearDown(() => harness.close());

  /// Pumps the whole app and lands on the more tab.
  Future<GoRouter> pumpMore(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(harness.db)],
    );
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.lightTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
        ),
      ),
    );

    router.go('/more');
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('every entry carries a line saying what it opens',
      (tester) async {
    await pumpMore(tester);

    // Read off the screen rather than off the ARB: the point is that the
    // tiles pass a subtitle at all.
    for (final description in [
      'Theme, language and currency',
      'Your accounts and their balances',
      'Income and expense categories',
      'Tell us what you think',
      'Version details and open-source licences',
    ]) {
      expect(find.text(description), findsOneWidget,
          reason: '$description is missing from its tile');
    }
  });

  testWidgets('an entry opens its page over the shell, nav bar and all',
      (tester) async {
    await pumpMore(tester);
    expect(find.byType(NavigationBar), findsOneWidget,
        reason: 'the more tab itself lives inside the shell');

    await tester.tap(find.widgetWithText(ListTile, 'Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing,
        reason: 'a page opened from more is not a fourth tab');
  });

  testWidgets('the management entries reach their top-level routes',
      (tester) async {
    // These two are not routed under /more at all — the pickers already open
    // them at /accounts_management and /categories_management, and the more
    // tab is a second door to the same room, not a second room.
    await pumpMore(tester);

    await tester.tap(find.widgetWithText(ListTile, 'Accounts'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountManagementScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('the same holds for the entries that are not in this slice',
      (tester) async {
    await pumpMore(tester);

    await tester.ensureVisible(find.widgetWithText(ListTile, 'About'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'About'));
    await tester.pumpAndSettle();

    expect(find.byType(AboutScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('back returns to the tab, bottom bar included', (tester) async {
    final router = await pumpMore(tester);

    await tester.tap(find.widgetWithText(ListTile, 'Settings'));
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Theme, language and currency'), findsOneWidget);
  });
}
