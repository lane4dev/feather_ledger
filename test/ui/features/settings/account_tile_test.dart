import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/features/settings/presentation/screens/account_management_screen.dart';
import 'package:feather_ledger/features/settings/presentation/widgets/account_form_sheet.dart';
import 'package:feather_ledger/features/settings/presentation/widgets/account_tile.dart';
import 'package:feather_ledger/shared/presentation/models/account_ui_model.dart';

void main() {
  AccountUiModel account({
    String? id,
    AccountType type = AccountType.cash,
    bool archived = false,
    bool includeInTotals = true,
    String name = 'Everyday account',
    int balanceMinor = 123456,
    String currencyCode = 'USD',
  }) =>
      AccountUiModel.of(AccountEntity(
        id: id ?? type.name,
        name: name,
        type: type,
        currencyCode: currencyCode,
        balanceMinor: balanceMinor,
        archived: archived,
        includeInTotals: includeInTotals,
        lastUpdatedEventId: 0,
      ));

  Widget wrap(
    Widget child, {
    bool dark = false,
    Locale locale = const Locale('en'),
    double textScale = 1,
    List<AccountUiModel> accounts = const [],
    CurrencyController? currency,
  }) =>
      ProviderScope(
        overrides: [
          currencyControllerProvider
              .overrideWith(() => currency ?? _FixedCurrency()),
          accountUiListProvider.overrideWithValue(AsyncData(accounts)),
        ],
        child: MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: child,
        ),
      );

  for (final dark in [false, true]) {
    testWidgets(
        'four account types render as cards and preserve signed balances (dark=$dark)',
        (tester) async {
      await tester.pumpWidget(wrap(
          Scaffold(
            body: SingleChildScrollView(
                child: Column(children: [
              for (final type in AccountType.values)
                AccountTile(
                    account: account(
                        type: type,
                        balanceMinor:
                            type == AccountType.credit ? -123456 : 123456)),
            ])),
          ),
          dark: dark));
      await tester.pumpAndSettle();
      expect(find.byType(Card), findsNWidgets(4));
      expect(find.byType(CircleAvatar), findsNothing);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('Bank account'), findsOneWidget);
      expect(find.text('Credit card'), findsOneWidget);
      expect(find.text('Other account'), findsOneWidget);
      expect(find.text(r'- $1234.56'), findsOneWidget);
      final amount = tester.widget<Text>(find.text(r'- $1234.56'));
      final context = tester.element(find.byType(AccountTile).first);
      expect(amount.style!.fontFeatures,
          contains(const FontFeature.tabularFigures()));
      expect(amount.style!.color, isNot(Theme.of(context).colorScheme.error));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('whole card remains a tap target', (tester) async {
    var taps = 0;
    await tester.pumpWidget(wrap(Scaffold(
        body: AccountTile(
      account: account(),
      onTap: () => taps++,
    ))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Everyday account'));
    await tester.tap(find.text(r'$1234.56'));
    expect(taps, 2);
  });

  for (final locale in [
    const Locale('en'),
    const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ]) {
    testWidgets('type and both independent statuses are localized for $locale',
        (tester) async {
      await tester.pumpWidget(wrap(
          Scaffold(
              body: AccountTile(
            account: account(
                type: AccountType.credit,
                archived: true,
                includeInTotals: false),
          )),
          locale: locale));
      await tester.pumpAndSettle();
      final l10n =
          AppLocalizations.of(tester.element(find.byType(AccountTile)))!;
      expect(find.text(l10n.accountTypeCredit), findsOneWidget);
      expect(find.text(l10n.accountExcludedFromTotals), findsOneWidget);
      expect(find.text(l10n.accountArchived), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'long name and large negative balance fit a narrow enlarged-text card',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap(
        Scaffold(
          body: SingleChildScrollView(
              child: AccountTile(
                  account: account(
            name: 'A very long account name that should wrap gracefully',
            balanceMinor: -1234567890123,
            archived: true,
            includeInTotals: false,
          ))),
        ),
        textScale: 1.8));
    await tester.pumpAndSettle();
    expect(find.text(r'- $12345678901.23'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a mixed list shows the code beside a shared symbol',
      (tester) async {
    await tester.pumpWidget(wrap(Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [
          AccountTile(
              account: account(
                  id: 'cny',
                  currencyCode: 'CNY',
                  name: 'Yuan wallet',
                  balanceMinor: 10000),
              showCurrencyCode: true),
          AccountTile(
              account: account(
                  id: 'jpy',
                  currencyCode: 'JPY',
                  name: 'Yen wallet',
                  balanceMinor: 10000),
              showCurrencyCode: true),
        ]),
      ),
    )));
    await tester.pumpAndSettle();
    expect(find.text('¥100.00 CNY'), findsOneWidget);
    expect(find.text('¥100.00 JPY'), findsOneWidget);
    expect(find.text('¥100.00'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('management defaults to the current currency and filters locally',
      (tester) async {
    final recording = _RecordingCurrency();
    await tester.pumpWidget(wrap(
      const AccountManagementScreen(),
      accounts: [
        account(
            id: 'cny',
            currencyCode: 'CNY',
            name: 'Yuan wallet',
            balanceMinor: 10000),
        account(
            id: 'jpy',
            currencyCode: 'JPY',
            name: 'Yen wallet',
            balanceMinor: 20000),
      ],
      currency: recording,
    ));
    await tester.pumpAndSettle();

    // The default filter is the current currency (USD), so neither account
    // shows until the user switches to the mixed view.
    expect(find.text('Yuan wallet'), findsNothing);
    expect(find.text('Yen wallet'), findsNothing);

    await tester.tap(find.byIcon(LucideIcons.filter));
    await tester.pumpAndSettle();
    await tester.tap(find.text(r'$ (Dollar)').last);
    await tester.pumpAndSettle();
    expect(find.byType(SimpleDialogOption), findsNWidgets(6));
    expect(find.byIcon(LucideIcons.check), findsOneWidget);
    await tester.tap(find.text('All currencies').last);
    await tester.pumpAndSettle();
    expect(find.text('Yuan wallet'), findsNothing,
        reason: 'the selection is a draft until applied');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Yuan wallet'), findsOneWidget);
    expect(find.text('Yen wallet'), findsOneWidget);
    expect(find.text('¥100.00 CNY'), findsOneWidget);
    expect(find.text('¥200.00 JPY'), findsOneWidget);

    // Switching the view is a local concern: the global setting is untouched.
    expect(recording.setCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('currency filter dismisses drafts and clear shows all currencies',
      (tester) async {
    await tester.pumpWidget(wrap(const AccountManagementScreen(), accounts: [
      account(id: 'usd', name: 'Dollar', currencyCode: 'USD'),
      account(id: 'jpy', name: 'Yen', currencyCode: 'JPY'),
    ]));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.filter));
    await tester.pumpAndSettle();
    await tester.tap(find.text(r'$ (Dollar)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('All currencies').last);
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Apply'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Dollar'), findsOneWidget);
    expect(find.text('Yen'), findsNothing);

    await tester.tap(find.byIcon(LucideIcons.filter));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('Dollar'), findsOneWidget);
    expect(find.text('Yen'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.filter));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All currencies').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('¥ (Yen)').last);
    await tester.pumpAndSettle();
    expect(find.text('Dollar'), findsOneWidget,
        reason: 'the chosen currency is still a draft');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.text('Dollar'), findsNothing);
    expect(find.text('Yen'), findsOneWidget);
  });

  testWidgets('currency filter fits a narrow screen with enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester
        .pumpWidget(wrap(const AccountManagementScreen(), textScale: 1.6));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.filter));
    await tester.pumpAndSettle();
    await tester.tap(find.text(r'$ (Dollar)').last);
    await tester.pumpAndSettle();
    expect(find.byType(SimpleDialog), findsOneWidget);
    Navigator.of(tester.element(find.byType(SimpleDialog))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Apply'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'management card opens its existing account form; FAB opens a new one',
      (tester) async {
    final model = account();
    await tester
        .pumpWidget(wrap(const AccountManagementScreen(), accounts: [model]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Everyday account'));
    await tester.pumpAndSettle();
    expect(
        tester.widget<AccountFormSheet>(find.byType(AccountFormSheet)).account,
        same(model.account));
    Navigator.of(tester.element(find.byType(AccountFormSheet))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pumpAndSettle();
    expect(
        tester.widget<AccountFormSheet>(find.byType(AccountFormSheet)).account,
        isNull);
    expect(tester.takeException(), isNull);
  });
}

class _FixedCurrency extends CurrencyController {
  @override
  Future<String> build() async => 'USD';
}

class _RecordingCurrency extends CurrencyController {
  var setCalls = 0;

  @override
  Future<String> build() async => 'USD';

  @override
  Future<void> setCurrency(String currencyCode) async {
    setCalls++;
  }
}
