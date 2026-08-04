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
    AccountType type = AccountType.cash,
    bool archived = false,
    bool includeInTotals = true,
    String name = 'Everyday account',
    int balanceMinor = 123456,
  }) =>
      AccountUiModel.of(AccountEntity(
        id: type.name,
        name: name,
        type: type,
        currencyCode: 'USD',
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
  }) =>
      ProviderScope(
        overrides: [
          currencyControllerProvider.overrideWith(_FixedCurrency.new),
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
