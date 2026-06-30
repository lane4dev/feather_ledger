import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/screens/transaction_form_screen.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_state.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_amount_input.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_selection_sheet.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_selector_field.dart';

/// Transfers in the shared transaction form (spec 004, US1 / T016).
///
/// The form carries all three kinds, so what matters here is that selecting
/// transfer swaps the fields to match — two accounts, no category — and that
/// saving routes to the transfer write path rather than the income/expense
/// one. The write path itself is asserted against real services in
/// `transfer_correction_test.dart`.
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
  const yenWallet = AccountEntity(
    id: 'acc_yen',
    name: 'YenWallet',
    type: AccountType.other,
    currencyCode: 'JPY',
    balanceMinor: 0,
    archived: false,
    lastUpdatedEventId: 0,
  );
  const archivedAccount = AccountEntity(
    id: 'acc_old',
    name: 'OldAccount',
    type: AccountType.other,
    currencyCode: 'USD',
    balanceMinor: 0,
    archived: true,
    lastUpdatedEventId: 0,
  );
  const food = CategoryEntity(
    id: 'cat_food',
    name: 'Food',
    iconKey: '1',
    colorInt: 0xFF000000,
    type: CategoryType.expense,
  );

  late _RecordingLedgerViewModel viewModel;

  setUp(() => viewModel = _RecordingLedgerViewModel());

  /// The amount field autofocuses, and a blinking cursor never lets
  /// `pumpAndSettle` settle — pump a bounded number of frames instead.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  /// Always pumped on a route: a successful save calls `context.pop()`, so
  /// even a test that only renders would break the moment it saved.
  Future<void> pumpForm(
    WidgetTester tester, {
    TransactionTileUiModel? transaction,
    TransactionKind initialType = TransactionKind.expense,
  }) async {
    const delegates = [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

    final router = GoRouter(
      initialLocation: '/ledger/form',
      routes: [
        GoRoute(
          path: '/ledger',
          builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
          routes: [
            GoRoute(
              path: 'form',
              builder: (_, __) => TransactionFormScreen(
                transaction: transaction,
                initialType: initialType,
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountListProvider.overrideWith(
            (ref) => Stream.value(const [
              cash,
              bank,
              yenWallet,
              archivedAccount,
            ]),
          ),
          categoryListProvider.overrideWith(
            (ref, type) => Stream.value(
              type == CategoryType.expense ? const [food] : const [],
            ),
          ),
          ledgerViewModelProvider.overrideWith(() => viewModel),
        ],
        child: MaterialApp.router(
          // AppTheme carries the ThemeExtensions (spacing, semantic colours)
          // the form reads through `context.spacing`.
          theme: AppTheme.lightTheme,
          routerConfig: router,
          localizationsDelegates: delegates,
          supportedLocales: const [Locale('en')],
        ),
      ),
    );
    await settle(tester);
  }

  /// Unmounts the tree so the focused text field's cursor timer is cancelled
  /// before the binding checks for pending timers.
  Future<void> teardownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  /// Scopes a text lookup to the open picker sheet. The selector field behind
  /// it renders the chosen account's name too, so an unscoped `find.text`
  /// would match the field rather than an option.
  Finder inSheet(String text) => find.descendant(
        of: find.byType(LedgerSelectionSheet<AccountEntity>),
        matching: find.text(text),
      );

  Future<void> openPicker(WidgetTester tester, int index) async {
    await tester.tap(find.byType(LedgerSelectorField).at(index));
    await settle(tester);
  }

  Future<void> selectKind(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await settle(tester);
  }

  testWidgets('offers all three kinds and starts on the requested one',
      (tester) async {
    await pumpForm(tester, initialType: TransactionKind.transfer);

    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Transfer'), findsOneWidget);
    expect(find.text('New Transfer'), findsOneWidget);
  });

  testWidgets('a transfer shows two accounts and no category', (tester) async {
    await pumpForm(tester, initialType: TransactionKind.transfer);

    expect(find.byType(LedgerSelectorField), findsNWidgets(2),
        reason: 'from and to');
    expect(find.text('From'), findsOneWidget);
    expect(find.text('To'), findsOneWidget);
    // The category row is not rendered at all — a transfer has no category,
    // so there is no state to validate or clear.
    expect(find.text('Category'), findsNothing);
  });

  testWidgets('switching to expense swaps back to one account and a category',
      (tester) async {
    await pumpForm(tester, initialType: TransactionKind.transfer);

    await selectKind(tester, 'Expense');

    expect(find.text('Add Transaction'), findsOneWidget);
    // Category and account — still two fields, different ones.
    expect(find.byType(LedgerSelectorField), findsNWidgets(2));
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('From'), findsNothing);
    expect(find.text('To'), findsNothing);
  });

  testWidgets('the pickers offer only active accounts', (tester) async {
    await pumpForm(tester, initialType: TransactionKind.transfer);

    await openPicker(tester, 0);

    expect(inSheet('Cash'), findsOneWidget);
    expect(inSheet('Bank'), findsOneWidget);
    expect(inSheet('YenWallet'), findsOneWidget);
    expect(inSheet('OldAccount'), findsNothing,
        reason: 'archived accounts are not offered');

    await teardownTree(tester);
  });

  testWidgets('the to picker excludes the from account and other currencies',
      (tester) async {
    await pumpForm(tester, initialType: TransactionKind.transfer);

    await openPicker(tester, 0);
    await tester.tap(inSheet('Cash'));
    await settle(tester);

    await openPicker(tester, 1);

    expect(inSheet('Bank'), findsOneWidget);
    expect(inSheet('Cash'), findsNothing,
        reason: 'a transfer needs two different accounts');
    expect(inSheet('YenWallet'), findsNothing,
        reason: 'cross-currency transfers are out of scope until exchange '
            'rates land — the pair must be unreachable, not rejected later');

    await teardownTree(tester);
  });

  testWidgets('saving a transfer calls addTransfer with the chosen legs',
      (tester) async {
    await pumpForm(tester, initialType: TransactionKind.transfer);

    await tester.enterText(
      find.descendant(
        of: find.byType(LedgerAmountInput),
        matching: find.byType(TextFormField),
      ),
      '250.00',
    );

    await openPicker(tester, 0);
    await tester.tap(inSheet('Cash'));
    await settle(tester);

    await openPicker(tester, 1);
    await tester.tap(inSheet('Bank'));
    await settle(tester);

    await tester.tap(find.text('Save Transaction'));
    await settle(tester);

    expect(viewModel.addedTransfers, hasLength(1));
    final call = viewModel.addedTransfers.single;
    expect(call['amountMinor'], 25000);
    expect(call['fromAccountId'], 'acc_cash');
    expect(call['toAccountId'], 'acc_bank');
    expect(viewModel.addedTransactions, isEmpty,
        reason: 'a transfer must not go down the income/expense path');

    await teardownTree(tester);
  });

  testWidgets('saving an expense still calls addTransaction', (tester) async {
    await pumpForm(tester);

    await tester.enterText(
      find.descendant(
        of: find.byType(LedgerAmountInput),
        matching: find.byType(TextFormField),
      ),
      '30.00',
    );
    await openPicker(tester, 0); // category
    await tester.tap(find.text('Food'));
    await settle(tester);
    await openPicker(tester, 1); // account
    await tester.tap(inSheet('Cash'));
    await settle(tester);

    await tester.tap(find.text('Save Transaction'));
    await settle(tester);

    expect(viewModel.addedTransactions, hasLength(1));
    expect(viewModel.addedTransactions.single['type'],
        TransactionKind.expense);
    expect(viewModel.addedTransfers, isEmpty);

    await teardownTree(tester);
  });

  testWidgets('a transfer is required to name both accounts', (tester) async {
    await pumpForm(tester, initialType: TransactionKind.transfer);

    await tester.enterText(
      find.descendant(
        of: find.byType(LedgerAmountInput),
        matching: find.byType(TextFormField),
      ),
      '250.00',
    );

    await tester.tap(find.text('Save Transaction'));
    await settle(tester);

    expect(find.text('Required'), findsWidgets,
        reason: 'both legs are required');
    expect(viewModel.addedTransfers, isEmpty);

    await teardownTree(tester);
  });

  testWidgets('editing a transfer loads both legs and corrects instead',
      (tester) async {
    final tile = TransactionTileUiModel(
      id: 'tx_transfer',
      amount: 10000,
      type: TransactionKind.transfer,
      date: DateTime(2026, 1, 10),
      note: 'rent',
      // A transfer has no category; the mapper passes an empty one.
      category: const CategoryEntity(
        id: '',
        name: '',
        iconKey: '',
        colorInt: 0,
        type: CategoryType.expense,
      ),
      account: cash,
      toAccount: bank,
      displayAmount: '100.00',
      displaySign: '',
    );

    await pumpForm(tester, transaction: tile);

    // The kind comes from the transaction, not from initialType.
    expect(find.text('Edit Transfer'), findsOneWidget);
    // Both legs are pre-filled, so the fields show the accounts rather than
    // their placeholders. Direction is carried by the up/down icons, the same
    // way the detail sheet carries it with From/To labels.
    expect(find.byType(LedgerSelectorField), findsNWidgets(2));
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('Bank'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byType(LedgerAmountInput),
        matching: find.byType(TextFormField),
      ),
      '300.00',
    );

    await tester.tap(find.text('Save Transaction'));
    await settle(tester);

    expect(viewModel.updatedTransfers, hasLength(1));
    expect(viewModel.updatedTransfers.single['id'], 'tx_transfer');
    expect(viewModel.updatedTransfers.single['amountMinor'], 30000);
    expect(viewModel.addedTransfers, isEmpty);

    await teardownTree(tester);
  });
}

/// A [LedgerViewModel] that records write calls instead of running them.
///
/// `build` is overridden so the real one's keep-alive stream subscriptions
/// (which outlive a widget test and leave pending timers) never start.
class _RecordingLedgerViewModel extends LedgerViewModel {
  final List<Map<String, Object?>> addedTransfers = [];
  final List<Map<String, Object?>> updatedTransfers = [];
  final List<Map<String, Object?>> addedTransactions = [];

  @override
  LedgerViewState build() => LedgerViewState.initial();

  @override
  Future<Result<void>> addTransfer({
    required int amountMinor,
    required String fromAccountId,
    required String toAccountId,
    required DateTime date,
    String? note,
  }) async {
    addedTransfers.add({
      'amountMinor': amountMinor,
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      'note': note,
    });
    return unitResult;
  }

  @override
  Future<Result<void>> updateTransfer({
    required String id,
    required int amountMinor,
    required String fromAccountId,
    required String toAccountId,
    required DateTime date,
    String? note,
  }) async {
    updatedTransfers.add({
      'id': id,
      'amountMinor': amountMinor,
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      'note': note,
    });
    return unitResult;
  }

  @override
  Future<Result<void>> addTransaction({
    required int amountMinor,
    required TransactionKind type,
    required DateTime date,
    required String categoryId,
    required String accountId,
    String? note,
  }) async {
    addedTransactions.add({
      'amountMinor': amountMinor,
      'type': type,
      'categoryId': categoryId,
      'accountId': accountId,
    });
    return unitResult;
  }
}
