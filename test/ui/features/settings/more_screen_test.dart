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
import 'package:feather_ledger/features/settings/presentation/widgets/external_links.dart';
import 'package:flutter/services.dart';

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
  Future<GoRouter> pumpMore(WidgetTester tester,
      {ExternalLinkLauncher? launcher}) async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(harness.db),
        externalLinkLauncherProvider
            .overrideWith((ref) => launcher ?? (uri) async => true),
      ],
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

  testWidgets('feedback asks before opening the email app', (tester) async {
    final opened = <Uri>[];
    await pumpMore(tester, launcher: (uri) async {
      opened.add(uri);
      return true;
    });
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    final feedback = find.widgetWithText(ListTile, 'Feedback');
    await tester.ensureVisible(feedback);
    await tester.tap(feedback);
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Your email app will open to send feedback to support@tangyu.me.'),
        findsOneWidget);
    expect(opened, isEmpty);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(opened, isEmpty);
    await tester.tap(feedback);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open email app'));
    await tester.pumpAndSettle();
    expect(opened.single.scheme, 'mailto');
    expect(opened.single.path, supportEmail);
    expect(opened.single.queryParameters['subject'], 'Accounted For feedback');
  });

  testWidgets('a missing email app offers to copy the address', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await pumpMore(tester, launcher: (uri) async => false);
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    final feedback = find.widgetWithText(ListTile, 'Feedback');
    await tester.ensureVisible(feedback);
    await tester.tap(feedback);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open email app'));
    await tester.pumpAndSettle();
    expect(find.text('Could not open email app'), findsOneWidget);
    await tester.tap(find.text('Copy email'));
    await tester.pumpAndSettle();
    expect(copied, supportEmail);
  });

  testWidgets('support and about links open the corresponding web pages',
      (tester) async {
    final opened = <Uri>[];
    await pumpMore(tester, launcher: (uri) async {
      opened.add(uri);
      return true;
    });
    final support = find.widgetWithText(ListTile, 'Support center');
    await tester.ensureVisible(support);
    await tester.tap(support);
    await tester.pumpAndSettle();
    expect(opened.single.toString(),
        'https://apps.tangyu.me/accounted-for/support/');
    final about = find.widgetWithText(ListTile, 'About');
    await tester.ensureVisible(about);
    await tester.tap(about);
    await tester.pumpAndSettle();
    for (final entry in {
      'App overview': 'https://apps.tangyu.me/accounted-for/',
      'Privacy policy': 'https://apps.tangyu.me/accounted-for/privacy/',
      'Terms of service': 'https://apps.tangyu.me/accounted-for/terms/',
    }.entries) {
      final tile = find.widgetWithText(ListTile, entry.key);
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(opened.last.toString(), entry.value);
    }
  });

  test('Chinese locales use the Chinese website', () {
    for (final locale in [
      const Locale('zh', 'CN'),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
    ]) {
      expect(informationPage(locale, 'privacy/').toString(),
          'https://apps.tangyu.me/zh/accounted-for/privacy/');
    }
  });

  testWidgets('reports when the browser cannot be opened', (tester) async {
    await pumpMore(tester, launcher: (uri) async => false);
    final support = find.widgetWithText(ListTile, 'Support center');
    await tester.ensureVisible(support);
    await tester.tap(support);
    await tester.pumpAndSettle();
    expect(find.text('Could not open link'), findsOneWidget);
  });

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
      'App information and open-source licences',
    ]) {
      if (description == 'App information and open-source licences') {
        await tester.drag(find.byType(ListView).first, const Offset(0, -300));
        await tester.pumpAndSettle();
      }
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

    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
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
