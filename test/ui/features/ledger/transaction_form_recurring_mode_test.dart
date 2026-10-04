import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/features/ledger/data/notifications/recurring_reminders.dart';
import 'package:feather_ledger/features/ledger/domain/services/ledger_service.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';
import 'package:feather_ledger/features/ledger/presentation/screens/transaction_form_screen.dart';
import 'package:feather_ledger/features/budget/domain/entities/budget_entities.dart';
import 'package:feather_ledger/features/budget/presentation/view_model/transaction_budget_hint_provider.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_amount_input.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_selection_sheet.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_selector_field.dart';
import 'package:feather_ledger/shared/presentation/models/account_ui_model.dart';

import '../../../support/fakes/recording_services.dart';
import '../../../support/mocks/mock_shared_preferences.dart';

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
  late PreferencesRepositoryImpl preferences;

  setUp(() {
    ledger = RecordingLedgerService();
    recurring = RecordingRecurringService();
    preferences = PreferencesRepositoryImpl(MockSharedPreferences());
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Future<void> pumpForm(WidgetTester tester) async {
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
              builder: (_, __) => const TransactionFormScreen(),
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
          preferencesRepositoryProvider
              .overrideWith((ref) async => preferences),
          accountListProvider.overrideWithValue(const AsyncData([cash])),
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

  Future<void> fillExpense(WidgetTester tester) async {
    await tester.enterText(
      find.descendant(
        of: find.byType(LedgerAmountInput),
        matching: find.byType(TextFormField),
      ),
      '500.00',
    );
    await tester.tap(find.text('Account'));
    await settle(tester);
    await tester.tap(find.descendant(
      of: find.byType(LedgerSelectionSheet<AccountUiModel>),
      matching: find.text('Cash'),
    ));
    await settle(tester);
    await tester.tap(find.text('Category'));
    await settle(tester);
    await tester.tap(find.text('Rent'));
    await settle(tester);
  }

  testWidgets('required account and category errors appear in the value hint',
      (tester) async {
    await pumpForm(tester);
    await tester.enterText(
      find.descendant(
        of: find.byType(LedgerAmountInput),
        matching: find.byType(TextFormField),
      ),
      '500.00',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);

    final fields = tester
        .widgetList<LedgerSelectorField>(find.byType(LedgerSelectorField));
    for (final label in ['Account', 'Category']) {
      final field = fields.singleWhere((field) => field.label == label);
      expect(field.text, 'Required');
      expect(field.errorText, isNull);
    }
    expect(ledger.addedTransactions, isEmpty);
    await teardownTree(tester);
  });

  testWidgets(
      'three entry modes render and auto-post switch appears in both Planned and Repeating',
      (tester) async {
    await pumpForm(tester);

    expect(find.text('Default'), findsOneWidget);
    expect(find.text('Planned'), findsOneWidget);
    expect(find.text('Repeating'), findsOneWidget);
    expect(find.text('Auto-post'), findsNothing);

    await tester.tap(find.text('Planned'));
    await settle(tester);
    expect(find.text('Auto-post'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    await tester.tap(find.text('Repeating'));
    await settle(tester);
    expect(find.text('Auto-post'), findsOneWidget);
    final sw = tester.widget<Switch>(find.byType(Switch));
    expect(sw.value, isFalse);

    await teardownTree(tester);
  });

  testWidgets(
      'planned and repeating remember auto-post independently and persist their values',
      (tester) async {
    await pumpForm(tester);

    // Enable auto-post on Planned only.
    await tester.tap(find.text('Planned'));
    await settle(tester);
    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(preferences.getLastPlannedAutoPost(), isTrue);
    expect(preferences.getLastRepeatingAutoPost(), isFalse);

    // Switching to Repeating shows its own independent remembered value (false).
    await tester.tap(find.text('Repeating'));
    await settle(tester);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    // Switching back to Planned keeps true and saves planned autoPost = true.
    await tester.tap(find.text('Planned'));
    await settle(tester);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    await fillExpense(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);
    expect(recurring.created.single['autoPost'], isTrue);
    expect(recurring.created.single['mode'], RecurringSeriesMode.planned);

    await teardownTree(tester);

    // Reopening the form remembers Planned=true and Repeating=false independently.
    await pumpForm(tester);
    await tester.tap(find.text('Planned'));
    await settle(tester);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    await tester.tap(find.text('Repeating'));
    await settle(tester);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    // Toggle Repeating on and save.
    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(preferences.getLastRepeatingAutoPost(), isTrue);

    await fillExpense(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);
    expect(recurring.created.last['autoPost'], isTrue);
    expect(recurring.created.last['mode'], RecurringSeriesMode.repeating);

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
