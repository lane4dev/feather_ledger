import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/presentation/mappers/transaction_ui_mapper.dart';
import 'package:feather_ledger/features/ledger/presentation/models/ledger_day_group.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_receipt_content.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_timeline.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/search_transaction_tile.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/transaction_tile.dart';
import 'package:feather_ledger/features/settings/presentation/widgets/account_tile.dart';
import 'package:feather_ledger/shared/presentation/models/account_ui_model.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_Hans');
    await initializeDateFormatting('en');
  });

  const mapper = TransactionUiMapper();
  const cash = AccountEntity(
    id: 'acc_cash',
    name: 'Cash',
    type: AccountType.cash,
    currencyCode: 'CNY',
    balanceMinor: 10000,
    archived: false,
    lastUpdatedEventId: 1,
  );
  const bank = AccountEntity(
    id: 'acc_bank',
    name: 'Bank',
    type: AccountType.bank,
    currencyCode: 'CNY',
    balanceMinor: 20000,
    archived: false,
    lastUpdatedEventId: 1,
  );
  const food = CategoryEntity(
    id: 'cat_food',
    name: 'Food',
    iconKey: 'utensils',
    colorInt: 0xFF0F766E,
    type: CategoryType.expense,
  );

  TransactionEntity tx({
    required String id,
    required TransactionKind type,
    required int amount,
    String? note,
  }) =>
      TransactionEntity(
        id: id,
        amount: amount,
        type: type,
        date: DateTime(2026, 11, 5, 9, 30),
        note: note,
        account: cash,
        toAccount: type == TransactionKind.transfer ? bank : null,
        category: type == TransactionKind.transfer ? null : food,
        eventId: 1,
      );

  Widget wrap(
    Widget child, {
    required bool dark,
    Locale locale = const Locale('en'),
  }) =>
      MaterialApp(
        theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: child),
      );

  for (final dark in [false, true]) {
    for (final width in [360.0, 800.0]) {
      testWidgets(
          'renders compact readonly amounts across ledger, search, receipt, '
          'and accounts without overflow (dark=$dark, width=$width)',
          (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        final expenseTile = mapper.toTile(
          tx(
            id: 'exp-1',
            type: TransactionKind.expense,
            amount: -1000,
            note: 'Lunch',
          ),
        );
        final incomeTile = mapper.toTile(
          tx(
            id: 'inc-1',
            type: TransactionKind.income,
            amount: 1000,
            note: 'Bonus',
          ),
        );
        final transferTile = mapper.toTile(
          tx(
            id: 'trf-1',
            type: TransactionKind.transfer,
            amount: 2000,
            note: 'Move',
          ),
        );
        final overdrawnJpy = AccountUiModel.of(const AccountEntity(
          id: 'jpy-card',
          name: 'JPY Credit Card',
          type: AccountType.credit,
          currencyCode: 'JPY',
          balanceMinor: -1234,
          archived: false,
          lastUpdatedEventId: 1,
        ));

        await tester.pumpWidget(wrap(
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TransactionTile(
                  transaction: expenseTile,
                  currencySymbol: '¥',
                ),
                TransactionTile(
                  transaction: incomeTile,
                  currencySymbol: '¥',
                ),
                TransactionTile(
                  transaction: transferTile,
                  currencySymbol: '¥',
                ),
                SearchTransactionTile(
                  transaction: expenseTile,
                  currencySymbol: '¥',
                  onTap: () {},
                ),
                LedgerReceiptContent(
                  transaction: expenseTile,
                  currencySymbol: '¥',
                ),
                AccountTile(
                  account: overdrawnJpy,
                  showCurrencyCode: true,
                ),
              ],
            ),
          ),
          dark: dark,
        ));
        await tester.pumpAndSettle();

        expect(find.text('-¥10.00'), findsNWidgets(3));
        expect(find.text('+¥10.00'), findsOneWidget);
        expect(find.text('¥20.00'), findsOneWidget);
        expect(find.text(' ¥20.00'), findsNothing);
        expect(find.text('-¥12.34 JPY'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('day subtotal renders label-carried expense amount cleanly',
      (tester) async {
    final expenseTile = mapper.toTile(
      tx(
        id: 'exp-1',
        type: TransactionKind.expense,
        amount: -1000,
        note: 'Lunch',
      ),
    );
    final groups = LedgerDayGroup.group([expenseTile], currencySymbol: '¥');

    await tester.pumpWidget(wrap(
      CustomScrollView(
        slivers: [
          LedgerTimeline(days: groups, currencySymbol: '¥'),
        ],
      ),
      dark: false,
      locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('支出: '), findsOneWidget);
    expect(find.text('¥10.00'), findsOneWidget);
    expect(find.text('-¥10.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
