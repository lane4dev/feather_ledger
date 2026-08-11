import 'package:feather_ledger/app/design_system/app_choice_chips.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/settings/presentation/widgets/account_form_sheet.dart';

import '../../../support/event_sourcing/ledger_service_harness.dart';

/// The account form (account management's add/edit sheet).
///
/// Driven against the real service chain on the harness database: the sheet
/// writes events, and `includeInTotals` is only meaningfully tested if the
/// thing that ends up in the projection is what the switch was set to.
void main() {
  late LedgerServiceHarness harness;

  setUp(() async {
    harness = LedgerServiceHarness();
    await harness.seedSystemCategories();
  });
  tearDown(() => harness.close());

  Future<void> pumpForm(WidgetTester tester, {String? accountId}) async {
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(harness.db)],
    );
    addTearDown(container.dispose);

    final account = accountId == null
        ? null
        : await harness.accountRepository.getAccount(accountId);

    // A real router with the sheet *pushed*, because saving pops it: the pop
    // is part of the flow, and asserting on a mutation that only happens
    // before a crash would be asserting on half of it.
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: SizedBox()),
        ),
        GoRoute(
          path: '/form',
          builder: (context, state) =>
              Scaffold(body: AccountFormSheet(account: account)),
        ),
      ],
    );
    addTearDown(router.dispose);

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
    await tester.pumpAndSettle();
    unawaited(router.push('/form'));
    await tester.pumpAndSettle();
  }

  /// Where a labelled field sits down the sheet, for comparing reading order.
  double topOf(WidgetTester tester, Finder finder) =>
      tester.getTopLeft(finder).dy;

  testWidgets('the name comes first and the balance last', (tester) async {
    await pumpForm(tester);

    final name = find.widgetWithText(TextFormField, 'Account Name');
    final balance = find.widgetWithText(TextFormField, 'Initial Balance');
    final type = find.byType(AppChoiceChips<AccountType>);

    expect(name, findsOneWidget);
    expect(balance, findsOneWidget);
    expect(topOf(tester, name), lessThan(topOf(tester, type)),
        reason: 'an account is what it is called before what it holds');
    expect(topOf(tester, type), lessThan(topOf(tester, balance)));
  });

  testWidgets('a new account counts toward the totals unless told otherwise',
      (tester) async {
    await pumpForm(tester);

    final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(toggle.value, isTrue);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Account Name'), 'Wallet');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Initial Balance'), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final account = (await harness.db.accountDao.getAllAccounts()).single;
    expect(account.name, 'Wallet');
    expect(account.includeInTotals, isTrue);
  });

  testWidgets('a debt can be typed as the opening balance', (tester) async {
    // A credit card starts owing money. Until this field admitted a minus, the
    // only way to express that was a value seeded from elsewhere — and such a
    // value could be shown but never re-typed.
    await pumpForm(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Account Name'), 'Card');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Initial Balance'), '-500');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final account = (await harness.db.accountDao.getAllAccounts()).single;
    expect(account.balanceMinor, -50000,
        reason: 'a negative opening balance is a real balance');
  });

  testWidgets('an existing debt stays editable', (tester) async {
    await harness.accountService.createAccount(
      commandId: 'cmd_debt',
      name: 'Card',
      type: AccountType.credit,
      initialBalanceMinor: -50000,
      currencyCode: 'USD',
    );
    final id = (await harness.db.accountDao.getAllAccounts()).single.id;
    await pumpForm(tester, accountId: id);

    // Seeded with its sign, and — the point — an edit that keeps the sign is
    // accepted rather than reverted to the value the field was given.
    expect(find.text('-500.00'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Initial Balance'), '-750.00');
    await tester.pump();

    expect(find.text('-750.00'), findsOneWidget);
    expect(find.text('-500.00'), findsNothing);
  });

  testWidgets('turning it off reaches the projection', (tester) async {
    await pumpForm(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Account Name'), 'Held');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Initial Balance'), '0');
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final account = (await harness.db.accountDao.getAllAccounts()).single;
    expect(account.includeInTotals, isFalse);
    expect(account.balanceMinor, 0, reason: 'a flag moves no money');
  });

  testWidgets('editing shows the account as it stands, and can change it',
      (tester) async {
    await harness.accountService.createAccount(
      commandId: 'cmd_seed',
      name: 'Wallet',
      type: AccountType.cash,
      initialBalanceMinor: 0,
      currencyCode: 'USD',
    );
    final id = (await harness.db.accountDao.getAllAccounts()).single.id;
    await pumpForm(tester, accountId: id);

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
      reason: 'the switch reads the account, not a default',
    );

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final account = await harness.db.accountDao.getAccountById(id);
    expect(account!.includeInTotals, isFalse);
  });
}
