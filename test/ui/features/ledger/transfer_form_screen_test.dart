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
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/screens/transfer_form_screen.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_state.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_amount_input.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_selection_sheet.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_selector_field.dart';

/// Transfer form behaviour (spec 004, US1 / T016).
///
/// This covers the form's own wiring: what the pickers offer and which view
/// model method the form calls, with what arguments. The write path itself
/// (event pair, balances, refusals) is asserted against the real services in
/// `transfer_correction_test.dart` — a widget test does not need the whole
/// DI graph to prove the form is wired up.
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

  /// Records the calls the form makes instead of touching a database.
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

  Future<void> pumpForm(WidgetTester tester, {GoRouter? router}) async {
    const delegates = [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

    final app = router == null
        ? MaterialApp(
            // AppTheme carries the ThemeExtensions (spacing, semantic
            // colours) the form reads through `context.spacing`.
            theme: AppTheme.lightTheme,
            localizationsDelegates: delegates,
            supportedLocales: const [Locale('en')],
            home: const TransferFormScreen(),
          )
        : MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
            localizationsDelegates: delegates,
            supportedLocales: const [Locale('en')],
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
          ledgerViewModelProvider.overrideWith(() => viewModel),
        ],
        child: app,
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

  /// Opens the bottom sheet for the picker at [index] (0 = from, 1 = to).
  Future<void> openPicker(WidgetTester tester, int index) async {
    await tester.tap(find.byType(LedgerSelectorField).at(index));
    await settle(tester);
  }

  /// Scopes a text lookup to the open picker sheet. The selector field behind
  /// it renders the chosen account's name too, so an unscoped `find.text`
  /// would match the field rather than an option.
  Finder inSheet(String text) => find.descendant(
        of: find.byType(LedgerSelectionSheet<AccountEntity>),
        matching: find.text(text),
      );

  testWidgets('renders the create form with a from and a to row',
      (tester) async {
    await pumpForm(tester);

    expect(find.text('New Transfer'), findsOneWidget);
    expect(find.byType(LedgerAmountInput), findsOneWidget);
    expect(find.byType(LedgerSelectorField), findsNWidgets(2));
    expect(find.text('From'), findsOneWidget);
    expect(find.text('To'), findsOneWidget);

    await teardownTree(tester);
  });

  testWidgets('the from picker offers only active accounts', (tester) async {
    await pumpForm(tester);

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
    await pumpForm(tester);

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

  testWidgets('saving calls addTransfer with the chosen legs and amount',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/ledger/transfer',
      routes: [
        GoRoute(
          path: '/ledger',
          builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
          routes: [
            GoRoute(
              path: 'transfer',
              builder: (_, __) => const TransferFormScreen(),
            ),
          ],
        ),
      ],
    );
    await pumpForm(tester, router: router);

    await tester.enterText(
      find.descendant(
        of: find.byType(LedgerAmountInput),
        matching: find.byType(TextFormField),
      ),
      '250.00',
    );

    await openPicker(tester, 0);
    await tester.tap(find.text('Cash'));
    await settle(tester);

    await openPicker(tester, 1);
    await tester.tap(find.text('Bank'));
    await settle(tester);

    await tester.tap(find.text('Save Transaction'));
    await settle(tester);

    expect(viewModel.addedTransfers, hasLength(1));
    final call = viewModel.addedTransfers.single;
    expect(call['amountMinor'], 25000);
    expect(call['fromAccountId'], 'acc_cash');
    expect(call['toAccountId'], 'acc_bank');
    expect(viewModel.updatedTransfers, isEmpty,
        reason: 'creating must not go through the correction path');

    await teardownTree(tester);
  });

  testWidgets('an edit loads the existing legs and corrects instead of adding',
      (tester) async {
    // Edit mode is reached through /ledger/edit with the tile as `extra`.
    final tile = _transferTile(from: cash, to: bank);
    final router = GoRouter(
      initialLocation: '/ledger/edit',
      routes: [
        GoRoute(
          path: '/ledger',
          builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, __) => TransferFormScreen(transaction: tile),
            ),
          ],
        ),
      ],
    );
    await pumpForm(tester, router: router);

    expect(find.text('Edit Transfer'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byType(LedgerAmountInput),
        matching: find.byType(TextFormField),
      ),
      '300.00',
    );

    await tester.tap(find.text('Save Transaction'));
    await settle(tester);

    expect(viewModel.addedTransfers, isEmpty);
    expect(viewModel.updatedTransfers, hasLength(1));
    expect(viewModel.updatedTransfers.single['id'], 'tx_transfer');
    expect(viewModel.updatedTransfers.single['amountMinor'], 30000);

    await teardownTree(tester);
  });
}

/// A transfer tile as the ledger list would build it.
///
/// The form only reads amount/date/note/account/toAccount, so the display
/// fields are filled with the values the real mapper would produce.
TransactionTileUiModel _transferTile({
  required AccountEntity from,
  required AccountEntity to,
}) =>
    TransactionTileUiModel(
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
      account: from,
      toAccount: to,
      displayAmount: '100.00',
      displaySign: '',
    );

/// A [LedgerViewModel] that records write calls instead of running them.
///
/// `build` is overridden so the real one's keep-alive stream subscriptions
/// (which outlive a widget test and leave pending timers) never start.
class _RecordingLedgerViewModel extends LedgerViewModel {
  final List<Map<String, Object?>> addedTransfers = [];
  final List<Map<String, Object?>> updatedTransfers = [];

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
}
