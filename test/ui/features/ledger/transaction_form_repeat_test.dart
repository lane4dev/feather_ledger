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
import 'package:feather_ledger/shared/presentation/models/account_ui_model.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/screens/transaction_form_screen.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_state.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/recurring_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_amount_input.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_selection_sheet.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_selector_field.dart';

/// Setting a repeat rule on a new entry (spec 004, US2 / D3).
///
/// Saving with a rule does two things, in order: records the movement that
/// just happened, then starts a series for the ones that have not. The order
/// is the contract — the money moved either way.
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
  const rent = CategoryEntity(
    id: 'cat_rent',
    name: 'Rent',
    iconKey: '1',
    colorInt: 0xFF000000,
    type: CategoryType.expense,
  );

  late _RecordingLedgerViewModel ledger;
  late _RecordingRecurringViewModel recurring;

  setUp(() {
    ledger = _RecordingLedgerViewModel();
    recurring = _RecordingRecurringViewModel();
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Future<void> pumpForm(
    WidgetTester tester, {
    TransactionTileUiModel? transaction,
  }) async {
    // The form is taller than a phone once the repeat row is on it. A tall
    // test viewport keeps every control on screen, so the taps below reach
    // what they name instead of needing to scroll first — `ensureVisible`
    // deadlocks here, because its scroll future only advances on a pump.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
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
          accountUiListProvider.overrideWithValue(
              AsyncData([AccountUiModel.of(cash)])),
          categoryListProvider.overrideWith(
            (ref, type) =>
                Stream.value(type == CategoryType.expense ? const [rent] : const []),
          ),
          ledgerViewModelProvider.overrideWith(() => ledger),
          recurringViewModelProvider.overrideWith(() => recurring),
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

  Future<void> teardownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  Finder inSheet(String text) => find.descendant(
        of: find.byType(LedgerSelectionSheet<AccountUiModel>),
        matching: find.text(text),
      );

  /// Fills in an expense: amount, category, account.
  Future<void> fillExpense(WidgetTester tester) async {
    await tester.enterText(
      find.descendant(
        of: find.byType(LedgerAmountInput),
        matching: find.byType(TextFormField),
      ),
      '500.00',
    );
    await tester.tap(find.byType(LedgerSelectorField).at(0)); // category
    await settle(tester);
    await tester.tap(find.text('Rent'));
    await settle(tester);
    await tester.tap(find.byType(LedgerSelectorField).at(1)); // account
    await settle(tester);
    await tester.tap(inSheet('Cash'));
    await settle(tester);
  }

  /// Saves. The form scrolls, and with the repeat row added the button can
  /// sit below the fold — an unscrolled tap would land on whatever is under
  /// the finger instead.
  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save Transaction'));
    await settle(tester);
  }

  /// Opens the repeat picker — the last selector on the form.
  Future<void> chooseRepeat(WidgetTester tester, String label) async {
    final fields = find.byType(LedgerSelectorField);
    await tester.tap(fields.at(fields.evaluate().length - 1));
    await settle(tester);
    await tester.tap(find.text(label));
    await settle(tester);
  }

  testWidgets('a new expense offers a repeat rule, defaulting to none',
      (tester) async {
    await pumpForm(tester);

    expect(find.text('Repeat'), findsOneWidget);
    expect(find.text('Does not repeat'), findsNothing,
        reason: 'the untouched form shows the placeholder, not the option');

    await teardownTree(tester);
  });

  testWidgets('a transfer cannot repeat', (tester) async {
    // A series has one account, so a transfer is not representable
    // (ADR-0002) — the row is absent rather than disabled.
    await pumpForm(tester);
    await tester.tap(find.text('Transfer'));
    await settle(tester);

    expect(find.text('Repeat'), findsNothing);

    await teardownTree(tester);
  });

  testWidgets('editing an entry does not offer to change its rule',
      (tester) async {
    final tile = TransactionTileUiModel(
      id: 'tx_1',
      amount: 500000,
      type: TransactionKind.expense,
      date: DateTime(2026, 11, 1),
      note: 'Rent',
      category: rent,
      account: cash,
      displayAmount: '500.00',
      displaySign: '-',
    );

    await pumpForm(tester, transaction: tile);

    expect(find.text('Edit Transaction'), findsOneWidget);
    expect(find.text('Repeat'), findsNothing,
        reason: 'changing a rule is "deactivate and create another"');

    await teardownTree(tester);
  });

  testWidgets('saving with a rule records the entry, then starts the series',
      (tester) async {
    await pumpForm(tester);
    await fillExpense(tester);
    await chooseRepeat(tester, 'month');
    await tester.enterText(find.byType(TextFormField).last, 'Rent');

    await save(tester);

    // The movement that happened…
    expect(ledger.addedTransactions, hasLength(1));
    expect(ledger.addedTransactions.single['amountMinor'], 50000);
    expect(ledger.addedTransactions.single['type'], TransactionKind.expense);

    // …and the rule for the ones that have not.
    expect(recurring.created, hasLength(1));
    final series = recurring.created.single;
    expect(series['frequency'], 'MONTHLY');
    expect(series['amountMinor'], 50000);
    expect(series['accountId'], 'acc_cash');
    expect(series['categoryId'], 'cat_rent');
    expect(series['description'], 'Rent');

    // The series starts one period AFTER the entry just recorded, so the two
    // never describe the same month.
    final now = DateTime.now();
    expect(series['startDate'], DateTime(now.year, now.month + 1, now.day));

    await teardownTree(tester);
  });

  testWidgets('saving without a rule records only the entry', (tester) async {
    await pumpForm(tester);
    await fillExpense(tester);

    await save(tester);

    expect(ledger.addedTransactions, hasLength(1));
    expect(recurring.created, isEmpty);

    await teardownTree(tester);
  });

  testWidgets('a failed rule does not lose the recorded entry', (tester) async {
    // The two are separate aggregates. Unwinding a real movement because a
    // schedule could not be created would destroy a correct record to tidy up
    // a different problem.
    recurring.failure = LedgerErrorCode.categoryTypeMismatch;

    await pumpForm(tester);
    await fillExpense(tester);
    await chooseRepeat(tester, 'month');

    await save(tester);

    expect(ledger.addedTransactions, hasLength(1),
        reason: 'the entry stands');
    expect(find.textContaining('Saved. The repeat could not be set up'),
        findsOneWidget);

    await teardownTree(tester);
  });
}

class _RecordingLedgerViewModel extends LedgerViewModel {
  final List<Map<String, Object?>> addedTransactions = [];

  @override
  LedgerViewState build() => LedgerViewState.initial();

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

class _RecordingRecurringViewModel extends RecurringViewModel {
  final List<Map<String, Object?>> created = [];
  LedgerErrorCode? failure;

  @override
  void build() {}

  @override
  Future<Result<void>> createSeries({
    required RecurringSeriesKind type,
    required int amountMinor,
    required String accountId,
    required String categoryId,
    required String description,
    required String frequency,
    required DateTime startDate,
  }) async {
    if (failure != null) return Failure(failure!, 'rejected');
    created.add({
      'type': type,
      'amountMinor': amountMinor,
      'accountId': accountId,
      'categoryId': categoryId,
      'description': description,
      'frequency': frequency,
      'startDate': startDate,
    });
    return unitResult;
  }
}
