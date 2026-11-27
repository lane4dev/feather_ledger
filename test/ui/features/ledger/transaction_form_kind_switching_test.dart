import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/features/budget/domain/entities/budget_entities.dart';
import 'package:feather_ledger/features/budget/presentation/view_model/transaction_budget_hint_provider.dart';
import 'package:feather_ledger/features/ledger/domain/services/ledger_service.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/screens/transaction_form_screen.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_type_selector.dart';
import 'package:feather_ledger/shared/presentation/models/account_ui_model.dart';

import '../../../support/fakes/recording_services.dart';

/// Switching an ordinary posted entry between income and expense, and the
/// kinds that must stay fixed (spec: editable kind control).
void main() {
  const cash = AccountEntity(
    id: 'acc_cash',
    name: 'Cash',
    type: AccountType.cash,
    currencyCode: 'USD',
    balanceMinor: 100000,
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
  const rent = CategoryEntity(
    id: 'cat_rent',
    name: 'Rent',
    iconKey: '1',
    colorInt: 0xFF000000,
    type: CategoryType.expense,
  );
  const salary = CategoryEntity(
    id: 'cat_salary',
    name: 'Salary',
    iconKey: '2',
    colorInt: 0xFF000000,
    type: CategoryType.income,
  );

  late RecordingLedgerService ledger;
  late RecordingRecurringService recurring;

  setUp(() {
    ledger = RecordingLedgerService();
    recurring = RecordingRecurringService();
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  TransactionTileUiModel tile({
    TransactionKind type = TransactionKind.expense,
    CategoryEntity? category = rent,
    AccountEntity from = cash,
    AccountEntity? to,
    String? sourceScheduledBillId,
  }) =>
      TransactionTileUiModel(
        id: 'tx_1',
        amount: 90000,
        type: type,
        date: DateTime(2026, 1, 10),
        note: '',
        category: category,
        account: from,
        toAccount: to,
        displayAmount: '900.00',
        displaySign: switch (type) {
          TransactionKind.income => '+',
          TransactionKind.expense => '-',
          _ => '',
        },
        sourceScheduledBillId: sourceScheduledBillId,
      );

  Future<void> pumpForm(
    WidgetTester tester,
    TransactionTileUiModel transaction,
  ) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/ledger/form',
      routes: [
        GoRoute(
          path: '/ledger',
          builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
          routes: [
            GoRoute(
              path: 'form',
              builder: (_, __) =>
                  TransactionFormScreen(transaction: transaction),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionBudgetHintProvider.overrideWith(
            (ref, arg) => const Stream<CategoryBudgetHint>.empty(),
          ),
          accountUiListProvider.overrideWithValue(
            AsyncData([AccountUiModel.of(cash), AccountUiModel.of(bank)]),
          ),
          accountListProvider.overrideWithValue(const AsyncData([cash, bank])),
          categoryListProvider.overrideWith(
            (ref, type) => Stream.value(
              type == CategoryType.income ? const [salary] : const [rent],
            ),
          ),
          ledgerServiceProvider.overrideWithValue(ledger),
          recurringServiceProvider.overrideWithValue(recurring),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
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
    await settle(tester);
  }

  LedgerTypeSelector selector(WidgetTester tester) =>
      tester.widget<LedgerTypeSelector>(find.byType(LedgerTypeSelector));

  AppButton saveButton(WidgetTester tester) => tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Save'),
      );

  testWidgets('an ordinary expense may become an income with a new category',
      (tester) async {
    await pumpForm(tester, tile());

    expect(selector(tester).enabled, isTrue);
    expect(selector(tester).kinds,
        [TransactionKind.income, TransactionKind.expense]);
    expect(selector(tester).selectedType, TransactionKind.expense);
    expect(saveButton(tester).onPressed, isNotNull);
    expect(find.text('Rent'), findsOneWidget);

    await tester.tap(find.text('Income'));
    await settle(tester);

    expect(selector(tester).selectedType, TransactionKind.income);
    expect(find.text('Rent'), findsNothing,
        reason: 'the old category belongs to the other side');
    expect(saveButton(tester).onPressed, isNull,
        reason: 'an income cannot be saved without an income category');

    await tester.tap(find.text('Category'));
    await settle(tester);
    await tester.tap(find.text('Salary'));
    await settle(tester);

    expect(find.text('Salary'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('an ordinary income may become an expense', (tester) async {
    await pumpForm(
      tester,
      tile(type: TransactionKind.income, category: salary),
    );

    expect(selector(tester).enabled, isTrue);
    expect(find.text('Salary'), findsOneWidget);

    await tester.tap(find.text('Expense'));
    await settle(tester);

    expect(selector(tester).selectedType, TransactionKind.expense);
    expect(find.text('Salary'), findsNothing);
    expect(saveButton(tester).onPressed, isNull);

    await tester.tap(find.text('Category'));
    await settle(tester);
    await tester.tap(find.text('Rent'));
    await settle(tester);

    expect(saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('a transfer keeps its read-only kind', (tester) async {
    await pumpForm(
      tester,
      tile(type: TransactionKind.transfer, category: null, to: bank),
    );

    expect(find.byType(LedgerTypeSelector), findsNothing);
    expect(find.text('Transfer'), findsWidgets);
  });

  testWidgets('a balance purpose keeps its read-only kind', (tester) async {
    await pumpForm(
      tester,
      tile(type: TransactionKind.openingBalance, category: null),
    );

    expect(find.byType(LedgerTypeSelector), findsNothing);
  });

  testWidgets('a posted scheduled bill shows a disabled selector',
      (tester) async {
    await pumpForm(tester, tile(sourceScheduledBillId: 'sched_1'));

    expect(find.byType(LedgerTypeSelector), findsOneWidget);
    expect(selector(tester).enabled, isFalse);
    expect(selector(tester).selectedType, TransactionKind.expense);

    await tester.tap(find.text('Income'), warnIfMissed: false);
    await settle(tester);

    expect(selector(tester).selectedType, TransactionKind.expense);
    expect(find.text('Rent'), findsOneWidget,
        reason: 'a disabled tap must not clear the fixed side');
    expect(saveButton(tester).onPressed, isNotNull);
  });
}
