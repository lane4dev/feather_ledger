import 'package:flutter/material.dart';
import 'package:feather_ledger/features/ledger/data/notifications/recurring_reminders.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_bottom_action_bar.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/domain/services/ledger_service.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/shared/presentation/models/account_ui_model.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/screens/transaction_form_screen.dart';
import 'package:feather_ledger/features/budget/domain/entities/budget_entities.dart';
import 'package:feather_ledger/features/budget/presentation/view_model/transaction_budget_hint_provider.dart';
import '../../../support/fakes/recording_services.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_amount_input.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_form_row.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_selection_sheet.dart';

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
          // The budget hint banner would open a real database from a form
          // test that has no budget fixture; an empty stream keeps it idle.
          transactionBudgetHintProvider.overrideWith(
            (ref, arg) => const Stream<CategoryBudgetHint>.empty(),
          ),
          accountUiListProvider
              .overrideWithValue(AsyncData([AccountUiModel.of(cash)])),
          categoryListProvider.overrideWith(
            (ref, type) => Stream.value(
                type == CategoryType.expense ? const [rent] : const []),
          ),
          ledgerServiceProvider.overrideWithValue(ledger),
          recurringServiceProvider.overrideWithValue(recurring),
          recurringRemindersProvider.overrideWithValue(_FakeReminders()),
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

  /// Taps a row by its label rather than by its position: the form groups
  /// category first, so positional indexes move whenever the layout does.
  Finder selectorRow(String label) => find.ancestor(
        of: find.text(label),
        matching: find.byType(LedgerFormRow),
      );

  /// Fills in an expense: amount, category, account — in default mode, where
  /// the fields are date, account, category (the frequency row only exists in
  /// a series mode, and every test that fills the form starts there).
  Future<void> fillExpense(WidgetTester tester) async {
    await tester.enterText(
      find.descendant(
        of: find.byType(LedgerAmountInput),
        matching: find.byType(TextFormField),
      ),
      '500.00',
    );
    await tester.tap(selectorRow('Account'));
    await settle(tester);
    await tester.tap(inSheet('Cash'));
    await settle(tester);
    await tester.tap(selectorRow('Category'));
    await settle(tester);
    await tester.tap(find.text('Rent'));
    await settle(tester);
  }

  /// Saves. The form scrolls, and with the repeat row added the button can
  /// sit below the fold — an unscrolled tap would land on whatever is under
  /// the finger instead.
  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await settle(tester);
  }

  /// The repeat picker's options, as opposed to the row that opens it: the
  /// row shows the current rule, and that rule is one of the options.
  Finder inDialog(String text) => find.descendant(
        of: find.byType(SimpleDialog),
        matching: find.text(text),
      );

  /// Picks a form mode chip.
  Future<void> chooseMode(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await settle(tester);
  }

  /// Opens the repeat picker — the row in the schedule card, which only
  /// exists once a series mode has put it there.
  Future<void> chooseRepeat(WidgetTester tester, String label) async {
    await tester.tap(selectorRow('Repeat'));
    await settle(tester);
    await tester.tap(inDialog(label));
    await settle(tester);
  }

  testWidgets('default mode shows the modes, not a frequency', (tester) async {
    await pumpForm(tester);

    for (final label in ['Default', 'Planned', 'Repeating']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Repeat'), findsNothing,
        reason: 'a default entry repeats by no rule — there is nothing to ask');
    expect(find.text('Attachments'), findsOneWidget);

    // The mode owns the frequency: entering a series mode reveals the row,
    // already carrying its MONTHLY floor.
    await chooseMode(tester, 'Repeating');
    expect(find.text('Repeat'), findsOneWidget);
    expect(find.text('month'), findsOneWidget);

    await teardownTree(tester);
  });

  testWidgets(
      'the schedule card only appears for a series, with a zap for auto-post',
      (tester) async {
    await pumpForm(tester);
    expect(find.byType(AnimatedSize), findsOneWidget);
    expect(find.byIcon(LucideIcons.zap), findsNothing);

    await chooseMode(tester, 'Repeating');
    expect(find.byIcon(LucideIcons.repeat), findsOneWidget);
    expect(find.byIcon(LucideIcons.zap), findsOneWidget,
        reason: 'auto-post is not the same idea as repeat');
    expect(find.text('Auto-post'), findsOneWidget);

    await chooseMode(tester, 'Default');
    expect(find.text('Auto-post'), findsNothing);
    await teardownTree(tester);
  });

  testWidgets('the repeat picker is a dialog, with the rule in force marked',
      (tester) async {
    // Four plain options in the middle of a form is a menu, not a sheet: the
    // account and category pickers open one because their lists are long and
    // carry icons, balances and a way through to managing them. "Does not
    // repeat" is not among them — the mode already answered that.
    await pumpForm(tester);
    await chooseMode(tester, 'Repeating');
    await tester.tap(selectorRow('Repeat'));
    await settle(tester);

    expect(find.byType(SimpleDialog), findsOneWidget);
    expect(inDialog('Does not repeat'), findsNothing);
    expect(inDialog('day'), findsOneWidget);
    expect(inDialog('week'), findsOneWidget);
    expect(inDialog('month'), findsOneWidget);
    expect(inDialog('year'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SimpleDialog),
        matching: find.byIcon(LucideIcons.check),
      ),
      findsOneWidget,
      reason: 'the option in force is the one marked, and only it',
    );

    // Tapping the option in force closes without changing anything.
    await tester.tap(inDialog('month'));
    await settle(tester);

    expect(find.byType(SimpleDialog), findsNothing);

    await teardownTree(tester);
  });

  testWidgets('custom repeat settings are saved for a repeating series',
      (tester) async {
    await pumpForm(tester);
    await fillExpense(tester);
    await chooseMode(tester, 'Repeating');
    await chooseRepeat(tester, 'Custom');
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<String>));
    await settle(tester);
    await tester.tap(find.text('week').last);
    await settle(tester);
    expect(find.byType(FilterChip), findsNWidgets(7));
    await tester.enterText(
        find.descendant(
            of: find.byKey(const ValueKey('repeat-interval')),
            matching: find.byType(TextFormField)),
        '2');
    final countOption = find.byWidgetPredicate(
        (widget) => widget is Radio<int> && widget.value == 2);
    await tester.tap(countOption);
    await settle(tester);
    await tester.enterText(
        find.descendant(
            of: find.byKey(const ValueKey('repeat-count')),
            matching: find.byType(TextFormField)),
        '16');
    await settle(tester);
    final dialogSave = find.descendant(
        of: find.byType(AlertDialog), matching: find.text('Save'));
    await tester.tap(dialogSave);
    await settle(tester);
    expect(find.text('Custom'), findsOneWidget);
    await save(tester);
    expect(recurring.created.single['frequency'], 'WEEKLY');
    expect(recurring.created.single['weekdays'], isNotEmpty);
    expect(recurring.created.single['interval'], 2);
    expect(recurring.created.single['countLimit'], 16);
    expect(recurring.created.single['autoPost'], isFalse);
    await teardownTree(tester);
  });

  testWidgets('planned transaction stores the selected reminder',
      (tester) async {
    await pumpForm(tester);
    await fillExpense(tester);
    await chooseMode(tester, 'Planned');
    await tester.tap(find.text('None'));
    await settle(tester);
    await tester.tap(find.text('15 minutes before'));
    await settle(tester);
    expect(find.text('15 minutes before'), findsOneWidget);
    await save(tester);
    expect(recurring.created.single['reminderMinutes'], 15);
    expect(ledger.addedTransactions, isEmpty);
    await teardownTree(tester);
  });

  testWidgets(
      'custom reminder is converted to minutes for a repeating transaction',
      (tester) async {
    await pumpForm(tester);
    await fillExpense(tester);
    await chooseMode(tester, 'Repeating');
    await tester.tap(find.text('None'));
    await settle(tester);
    await tester.tap(find.text('Custom').last);
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '2');
    await tester.tap(find.byType(DropdownButton<int>));
    await settle(tester);
    await tester.tap(find.text('Hours').last);
    await settle(tester);
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.text('Save')));
    await settle(tester);
    expect(find.text('120 minutes before'), findsOneWidget);
    await save(tester);
    expect(recurring.created.single['reminderMinutes'], 120);
    await teardownTree(tester);
  });

  testWidgets('a transfer cannot repeat', (tester) async {
    // A series has one account, so a transfer is not representable
    // (ADR-0002) — the row, and the modes that would need it, are absent
    // rather than disabled.
    await pumpForm(tester);
    await tester.tap(find.text('Transfer'));
    await settle(tester);

    expect(find.text('Repeat'), findsNothing);
    expect(find.text('Repeating'), findsNothing,
        reason: 'a transfer has no modes to choose between');

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
    expect(find.text('Repeating'), findsNothing,
        reason: 'a correction states what it already is');

    await teardownTree(tester);
  });

  for (final editing in [false, true]) {
    testWidgets('save bar follows the keyboard when editing is $editing',
        (tester) async {
      final tile = editing
          ? TransactionTileUiModel(
              id: 'tx_1',
              amount: 50000,
              type: TransactionKind.expense,
              date: DateTime(2026, 11, 1),
              note: 'Rent',
              category: rent,
              account: cash,
              displayAmount: '500.00',
              displaySign: '-',
            )
          : null;
      await pumpForm(tester, transaction: tile);
      expect(find.byType(AppBottomActionBar), findsOneWidget);

      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      await settle(tester);
      expect(find.byType(AppBottomActionBar), findsNothing);

      tester.view.viewInsets = FakeViewPadding.zero;
      await settle(tester);
      expect(find.byType(AppBottomActionBar), findsOneWidget);
      await teardownTree(tester);
    });
  }

  testWidgets(
      'saving a repeating entry creates only the series starting on the chosen date',
      (tester) async {
    await pumpForm(tester);
    await fillExpense(tester);
    expect(find.text('Attachments'), findsOneWidget);
    await chooseMode(tester, 'Repeating');
    expect(find.text('Attachments'), findsNothing);
    await tester.enterText(find.byType(TextFormField).last, 'Rent');

    await save(tester);

    // No ad-hoc movement — the series starts on the chosen day and its first
    // occurrence waits in the pending list (unless auto-post is enabled).
    expect(ledger.addedTransactions, isEmpty);

    expect(recurring.created, hasLength(1));
    final series = recurring.created.single;
    expect(series['frequency'], 'MONTHLY');
    expect(series['amountMinor'], 50000);
    expect(series['accountId'], 'acc_cash');
    expect(series['categoryId'], 'cat_rent');
    expect(series['description'], 'Rent');
    expect(series['autoPost'], isFalse,
        reason: '重复 waits for the user 记入, instance by instance');

    final now = DateTime.now();
    final start = series['startDate']! as DateTime;
    expect(DateTime(start.year, start.month, start.day),
        DateTime(now.year, now.month, now.day));

    await teardownTree(tester);
  });

  testWidgets('picking a frequency keeps the series anchored on the chosen date',
      (tester) async {
    await pumpForm(tester);
    await fillExpense(tester);
    await chooseMode(tester, 'Repeating');
    await chooseRepeat(tester, 'week');

    await save(tester);

    expect(ledger.addedTransactions, isEmpty);
    expect(recurring.created.single['frequency'], 'WEEKLY');
    final now = DateTime.now();
    final start = recurring.created.single['startDate']! as DateTime;
    expect(DateTime(start.year, start.month, start.day),
        DateTime(now.year, now.month, now.day));

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

  testWidgets('leaving a series mode drops the rule with it', (tester) async {
    await pumpForm(tester);
    await fillExpense(tester);
    await chooseMode(tester, 'Repeating');
    await chooseMode(tester, 'Default');

    expect(find.text('Repeat'), findsNothing,
        reason: 'a default entry has no frequency to carry');

    await save(tester);

    expect(ledger.addedTransactions, hasLength(1));
    expect(recurring.created, isEmpty);

    await teardownTree(tester);
  });

  testWidgets('a repeating entry that fails is a failed save', (tester) async {
    recurring.failure = LedgerErrorCode.categoryTypeMismatch;

    await pumpForm(tester);
    await fillExpense(tester);
    await chooseMode(tester, 'Repeating');

    await save(tester);

    expect(ledger.addedTransactions, isEmpty);
    expect(recurring.created, isEmpty);
    expect(find.text('Category type does not match the transaction type'),
        findsOneWidget);

    await teardownTree(tester);
  });

  testWidgets('a repeating entry starts a manual series by default',
      (tester) async {
    await pumpForm(tester);
    await fillExpense(tester);
    await chooseMode(tester, 'Repeating');

    await save(tester);

    expect(ledger.addedTransactions, isEmpty);
    final series = recurring.created.single;
    expect(series['frequency'], 'MONTHLY');
    expect(series['autoPost'], isFalse);
    final now = DateTime.now();
    final start = series['startDate']! as DateTime;
    expect(DateTime(start.year, start.month, start.day),
        DateTime(now.year, now.month, now.day));

    await teardownTree(tester);
  });

  testWidgets('a planned entry creates the bill and records nothing',
      (tester) async {
    await pumpForm(tester);
    await fillExpense(tester);

    // The attachments row goes with the recording: a series row carries no
    // files, and a hidden picked-files list would be a leak.
    expect(find.text('Attachments'), findsOneWidget);
    await chooseMode(tester, 'Planned');
    expect(find.text('Attachments'), findsNothing);

    await save(tester);

    // No money moved — the plan is a one-shot series whose single instance
    // is the bill, waiting in the pending list.
    expect(ledger.addedTransactions, isEmpty);
    expect(recurring.created, hasLength(1));
    final series = recurring.created.single;
    expect(series['amountMinor'], 50000);
    expect(series['accountId'], 'acc_cash');
    expect(series['categoryId'], 'cat_rent');
    expect(series['description'], 'Rent',
        reason: 'the note is empty, so the series takes the category name');
    expect(series['autoPost'], isFalse,
        reason: '计划 waits for the user 记入, like any other pending bill');
    // The form's date carries the time it was opened; the contract is only
    // "the one bill is on the day the user chose".
    final now = DateTime.now();
    expect(series['startDate'], series['endDate'],
        reason: 'a one-shot rule: UNTIL at its own start is exactly one bill');
    final start = series['startDate'] as DateTime;
    expect(DateTime(start.year, start.month, start.day),
        DateTime(now.year, now.month, now.day));

    await teardownTree(tester);
  });

  testWidgets('a planned entry that fails is a failed save', (tester) async {
    // 计划 has no entry to fall back on — the series is the whole save, so a
    // rejected series is a rejected save, reported as one.
    recurring.failure = LedgerErrorCode.categoryTypeMismatch;

    await pumpForm(tester);
    await fillExpense(tester);
    await chooseMode(tester, 'Planned');

    await save(tester);

    expect(ledger.addedTransactions, isEmpty);
    expect(recurring.created, isEmpty);
    expect(find.textContaining('Saved. The repeat could not be set up'),
        findsNothing,
        reason: 'nothing was recorded, so that message would lie');
    expect(find.text('Category type does not match the transaction type'),
        findsOneWidget);

    await teardownTree(tester);
  });
}

class _FakeReminders implements RecurringReminders {
  @override
  bool get supported => true;
  @override
  Future<void> initialize(
      {String postLabel = 'Post', String skipLabel = 'Skip'}) async {}
  @override
  Future<bool> requestPermission(
          {String postLabel = 'Post', String skipLabel = 'Skip'}) async =>
      true;
  @override
  Future<void> start(
      {required String title,
      required String channelName,
      String postLabel = 'Post',
      String skipLabel = 'Skip'}) async {}
  @override
  bool get hasPendingResponses => false;
  @override
  void deferAutoPostCatchUp() {}
  @override
  bool takeDeferredAutoPostCatchUp() => false;
  @override
  Stream<void> get responsesChanged => const Stream.empty();
  @override
  List<NotificationResponse> takeResponses() => [];
  @override
  void dispose() {}
  @override
  void recheck() {}
}
