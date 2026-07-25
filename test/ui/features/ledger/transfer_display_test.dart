import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/features/ledger/domain/queries/get_transaction_history_query.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/transaction_detail_sheet.dart';

/// A transfer must not borrow income or expense presentation (spec 004,
/// FR-005). The detail sheet used to colour every transfer with the income
/// green and prefix it with '+', because both were derived from a two-way
/// `expense ? … : …` check that quietly treated transfer as "the other one".
/// `transaction_tile.dart` had it right; this pins the sheet to the same rule.
void main() {
  const cash = AccountEntity(
    id: 'acc_cash',
    name: 'Cash',
    type: AccountType.cash,
    currencyCode: 'USD',
    balanceMinor: 0,
    archived: false,
    lastUpdatedEventId: 0,
  );
  const bank = AccountEntity(
    id: 'acc_bank',
    name: 'Bank',
    type: AccountType.bank,
    currencyCode: 'USD',
    balanceMinor: 0,
    archived: false,
    lastUpdatedEventId: 0,
  );

  TransactionTileUiModel tile({
    required TransactionKind type,
    required String displaySign,
  }) =>
      TransactionTileUiModel(
        id: 'tx_under_test',
        amount: 10000,
        type: type,
        date: DateTime(2026, 1, 10),
        note: 'note',
        category: type == TransactionKind.transfer || type.isBalancePurpose
            ? null
            : const CategoryEntity(
                id: 'cat_food',
                name: 'Food',
                iconKey: '1',
                colorInt: 0xFF000000,
                type: CategoryType.expense,
              ),
        account: cash,
        toAccount: type == TransactionKind.transfer ? bank : null,
        displayAmount: '100.00',
        displaySign: displaySign,
      );

  Future<void> pumpSheet(
      WidgetTester tester, TransactionTileUiModel model) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currencyControllerProvider.overrideWith(_FixedCurrency.new),
          // The sheet writes the ledger's symbol, which the accounts decide —
          // with none, it falls through to the preference above.
          accountListProvider.overrideWithValue(const AsyncData([])),
          getTransactionHistoryProvider(model.id).overrideWith(
            (ref) => Future<List<TransactionHistoryEntry>>.value(const []),
          ),
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
          home: Scaffold(
            body: TransactionDetailSheet(transaction: model),
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  /// The hero amount line, found by the amount it renders.
  Text heroAmount(WidgetTester tester) {
    final matches = tester
        .widgetList<Text>(find.byType(Text))
        .where((t) => (t.data ?? '').contains('100.00'))
        .toList();
    expect(matches, hasLength(1), reason: 'expected one amount line');

    final hero = matches.single;
    expect(hero.style, isNotNull,
        reason: 'the amount line carries the colour under test');
    return hero;
  }

  testWidgets('a transfer renders with no sign and the neutral colour',
      (tester) async {
    await pumpSheet(
        tester, tile(type: TransactionKind.transfer, displaySign: ''));

    final hero = heroAmount(tester);
    expect(hero.data!.trimLeft().startsWith('+'), isFalse,
        reason: "transfers previously rendered with a leading '+'");
    expect(hero.data!.trimLeft().startsWith('-'), isFalse);

    final semantics = AppTheme.lightTheme.extension<AppSemanticColors>()!;
    expect(hero.style?.color, isNot(semantics.income),
        reason: 'a transfer is not income');
    expect(hero.style?.color, isNot(semantics.expense),
        reason: 'a transfer is not expense');
    expect(hero.style?.color, AppTheme.lightTheme.colorScheme.onSurface);
  });

  testWidgets('an expense still renders signed and in the expense colour',
      (tester) async {
    await pumpSheet(
        tester, tile(type: TransactionKind.expense, displaySign: '-'));

    final hero = heroAmount(tester);
    expect(hero.data!.trimLeft().startsWith('-'), isTrue);
    expect(
      hero.style?.color,
      AppTheme.lightTheme.extension<AppSemanticColors>()!.expense,
    );
  });

  testWidgets('a transfer shows both legs and no category row', (tester) async {
    await pumpSheet(
        tester, tile(type: TransactionKind.transfer, displaySign: ''));

    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('Bank'), findsOneWidget);
    expect(find.text('From'), findsOneWidget);
    expect(find.text('To'), findsOneWidget);

    // A transfer has no category, so the category snapshot must not appear.
    expect(find.text('Food'), findsNothing);
  });

  testWidgets('an opening balance names its purpose instead of a category',
      (tester) async {
    await pumpSheet(
        tester, tile(type: TransactionKind.openingBalance, displaySign: '+'));

    expect(find.text('Initial Balance'), findsNWidgets(2),
        reason: 'the heading and read-only type explain this system record');
    expect(find.text('Food'), findsNothing);
    expect(find.text('Type'), findsOneWidget);
  });
}

/// Pins the display currency so the sheet does not read SharedPreferences.
class _FixedCurrency extends CurrencyController {
  @override
  Future<String> build() async => 'USD';
}
