import 'package:feather_ledger/app/design_system/app_choice_chips.dart';
import 'package:feather_ledger/app/design_system/app_form_row.dart';
import 'package:feather_ledger/app/design_system/app_text_field.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/settings/presentation/widgets/account_form_sheet.dart';

import '../../../support/event_sourcing/ledger_service_harness.dart';
import '../../../support/mocks/mock_shared_preferences.dart';

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

  Future<void> pumpForm(WidgetTester tester,
      {String? accountId, PreferencesRepository? preferences}) async {
    // The sheet grew a currency row; give the surface enough height that the
    // save action sits on-screen without scrolling in every test.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(harness.db),
        if (preferences != null)
          preferencesRepositoryProvider
              .overrideWith((ref) async => preferences),
      ],
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
    final nameField = tester.widget<AppTextField>(
        find.ancestor(of: name, matching: find.byType(AppTextField)));
    expect(nameField.labelText, 'Name');
    expect(nameField.style,
        Theme.of(tester.element(name)).textTheme.headlineSmall);
    expect(find.byIcon(LucideIcons.tag), findsNothing);
    expect(find.byIcon(LucideIcons.circleDollarSign), findsNothing);
  });

  testWidgets('account types scroll in one row and remain selectable',
      (tester) async {
    await pumpForm(tester);
    tester.view.physicalSize = const Size(320, 1400);
    await tester.pumpAndSettle();
    final choices = find.byType(AppChoiceChips<AccountType>);
    expect(
        tester.widget<AppChoiceChips<AccountType>>(choices).scrollable, isTrue);
    final scroll = find.descendant(
        of: choices,
        matching: find.byKey(const ValueKey('choice-chips-scroll')));
    await tester.drag(scroll, const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other account'));
    await tester.pumpAndSettle();
    expect(tester.widget<AppChoiceChips<AccountType>>(choices).selected,
        AccountType.other);
    expect(tester.takeException(), isNull);
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
    final transaction = (await tester.runAsync(
      () => harness.ledgerService.watchTransactions(DateTime.now()).first,
    ))!
        .single;
    expect(transaction.type, TransactionKind.balanceAdjustment);
    expect(transaction.note, 'Initial Balance');
  });

  testWidgets('editing a balance records a balance correction note',
      (tester) async {
    await harness.accountService.createAccount(
      commandId: 'cmd_seed_balance',
      name: 'Wallet',
      type: AccountType.cash,
      initialBalanceMinor: 0,
      currencyCode: 'USD',
    );
    final id = (await harness.db.accountDao.getAllAccounts()).single.id;
    await pumpForm(tester, accountId: id);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Initial Balance'), '25');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    final transaction = (await tester.runAsync(
      () => harness.ledgerService.watchTransactions(DateTime.now()).first,
    ))!
        .single;
    expect(transaction.type, TransactionKind.balanceAdjustment);
    expect(transaction.note, 'Balance correction');
  });

  testWidgets('an account with transactions offers archive through deletion',
      (tester) async {
    await harness.accountService.createAccount(
        commandId: 'archive_seed',
        name: 'Wallet',
        type: AccountType.cash,
        initialBalanceMinor: 0,
        currencyCode: 'USD');
    final id = (await harness.db.accountDao.getAllAccounts()).single.id;
    await harness.categoryService.createCategory(
        commandId: 'cat',
        name: 'Food',
        iconKey: '1',
        colorInt: 0,
        type: CategoryType.expense);
    final category = (await harness.db.categoriesDao.getAllCategories())
        .firstWhere((c) => c.systemCode == null)
        .id;
    await harness.ledgerService.addTransaction(
        commandId: 'expense',
        amountMinor: 100,
        type: TransactionKind.expense,
        date: DateTime.now(),
        categoryId: category,
        accountId: id);
    await pumpForm(tester, accountId: id);
    expect(find.byTooltip('Archive account'), findsNothing);
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Move records and delete'), findsOneWidget);
    await tester.tap(find.text('Archive account').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('permanently deletes this account'),
        findsOneWidget);
    expect(find.textContaining('Overdue pending bills'), findsOneWidget);
    await tester.tap(find.text('Archive account').last);
    await tester.pumpAndSettle();
    expect((await harness.db.accountDao.getAccountById(id))!.archived, isTrue);
  });

  testWidgets('balance-only account can be deleted directly', (tester) async {
    await harness.accountService.createAccount(
        commandId: 'linked_seed',
        name: 'Wallet',
        type: AccountType.cash,
        initialBalanceMinor: 100,
        currencyCode: 'USD');
    final id = (await harness.db.accountDao.getAllAccounts()).single.id;
    await pumpForm(tester, accountId: id);
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Move records and delete'), findsNothing);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect((await harness.db.accountDao.getAccountById(id))!.deleted, isTrue);
  });

  testWidgets('archived account offers record deletion and migration',
      (tester) async {
    await harness.accountService.createAccount(
      commandId: 'seed_archived',
      name: 'Wallet',
      type: AccountType.cash,
      initialBalanceMinor: 0,
      currencyCode: 'USD',
    );
    final id = (await harness.db.accountDao.getAllAccounts()).single.id;
    await harness.accountService
        .archiveAccount(commandId: 'archive', accountId: id);
    await pumpForm(tester, accountId: id);
    expect(find.byTooltip('Restore account'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete account and records'), findsOneWidget);
    expect(find.text('Move records and delete'), findsOneWidget);
    await tester.tap(find.text('Delete account and records'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect((await harness.db.accountDao.getAccountById(id))!.deleted, isTrue);
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

  testWidgets('a new account is created in the chosen currency',
      (tester) async {
    final preferences = PreferencesRepositoryImpl(MockSharedPreferences());
    await preferences.setCurrency('CNY');
    await pumpForm(tester, preferences: preferences);

    // The currency row opens on the current preference.
    expect(find.text('¥ (Yuan)'), findsOneWidget);

    await tester.tap(find.text('¥ (Yuan)'));
    await tester.pumpAndSettle();

    // All five currencies on offer, the current one checked.
    expect(find.byType(SimpleDialogOption), findsNWidgets(5));
    expect(find.byIcon(LucideIcons.check), findsOneWidget);

    await tester.tap(find.text('€ (Euro)'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Account Name'), 'Travel');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Initial Balance'), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final account = (await harness.db.accountDao.getAllAccounts()).single;
    expect(account.currencyCode, 'EUR');
  });

  testWidgets('an account\'s currency cannot be changed in edit',
      (tester) async {
    await harness.accountService.createAccount(
      commandId: 'cmd_seed_currency',
      name: 'Wallet',
      type: AccountType.cash,
      initialBalanceMinor: 0,
      currencyCode: 'EUR',
    );
    final id = (await harness.db.accountDao.getAllAccounts()).single.id;
    await pumpForm(tester, accountId: id);

    // The form shows the account's own currency, read-only.
    expect(find.text('€ (Euro)'), findsOneWidget);
    final currencyRow = tester.widget<AppFormRow>(find.byType(AppFormRow));
    expect(currencyRow.onTap, isNull);
  });

  testWidgets('adjusting another currency balance stays in that currency',
      (tester) async {
    // The app is looking at the CNY ledger, but the account lives in USD.
    final preferences = PreferencesRepositoryImpl(MockSharedPreferences());
    await preferences.setCurrency('CNY');
    await harness.accountService.createAccount(
      commandId: 'cmd_seed_usd',
      name: 'Dollar wallet',
      type: AccountType.cash,
      initialBalanceMinor: 0,
      currencyCode: 'USD',
    );
    final id = (await harness.db.accountDao.getAllAccounts()).single.id;
    await pumpForm(tester, accountId: id, preferences: preferences);

    final l10n =
        AppLocalizations.of(tester.element(find.byType(AccountFormSheet)))!;

    // The form shows the account's own currency and names the ledger its
    // balance change will be recorded in.
    expect(find.text(r'$ (Dollar)'), findsOneWidget);
    expect(
      find.text(l10n.accountBalanceAdjustmentLedgerHint(r'$ (Dollar)')),
      findsOneWidget,
    );

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Initial Balance'), '25');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    // The generated balance adjustment belongs to the account's currency, not
    // the currency the app happens to be viewing.
    final transaction = (await tester.runAsync(
      () => harness.ledgerService.watchTransactions(DateTime.now()).first,
    ))!
        .single;
    expect(transaction.account.currencyCode, 'USD');
    expect(transaction.amount, 2500);
  });
}
