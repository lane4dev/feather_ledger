import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/features/budget/domain/entities/budget_entities.dart';
import 'package:feather_ledger/features/budget/domain/services/budget_service.dart';
import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';
import 'package:feather_ledger/features/ledger/data/notifications/recurring_reminders.dart';
import 'package:feather_ledger/features/ledger/domain/services/ledger_service.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/screens/transaction_form_screen.dart';
import 'package:feather_ledger/features/budget/presentation/widgets/transaction_budget_hint_banner.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_amount_input.dart';
import 'package:feather_ledger/shared/presentation/models/account_ui_model.dart';

import '../../../support/fakes/recording_services.dart';
import '../../../support/mocks/mock_shared_preferences.dart';

class _FakeReminders implements RecurringReminders {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubHintBudgetService implements BudgetService {
  final Map<(String currency, YearMonth ym, String cat), CategoryBudgetHint>
      hints;

  _StubHintBudgetService(this.hints);

  @override
  Stream<CategoryBudgetHint> watchTransactionBudgetHint({
    required String currencyCode,
    required YearMonth month,
    required String categoryId,
  }) {
    return Stream.value(
      hints[(currencyCode, month, categoryId)] ??
          CategoryBudgetHint(
            currencyCode: currencyCode,
            month: month,
            categoryId: categoryId,
            isCategoryArchived: false,
            effectiveBudgetMinor: null,
            actualMinor: 0,
            pendingMinor: 0,
          ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const includedCash = AccountEntity(
    id: 'acc_cash',
    name: 'Cash',
    type: AccountType.cash,
    currencyCode: 'USD',
    balanceMinor: 100000,
    archived: false,
    includeInTotals: true,
    lastUpdatedEventId: 0,
  );
  const excludedWallet = AccountEntity(
    id: 'acc_excl',
    name: 'Excluded',
    type: AccountType.cash,
    currencyCode: 'USD',
    balanceMinor: 50000,
    archived: false,
    includeInTotals: false,
    lastUpdatedEventId: 0,
  );
  const dining = CategoryEntity(
    id: 'cat_dining',
    name: 'Dining',
    iconKey: 'utensils',
    colorInt: 0xFFE65100,
    type: CategoryType.expense,
  );
  const travel = CategoryEntity(
    id: 'cat_travel',
    name: 'Travel',
    iconKey: 'plane',
    colorInt: 0xFF1565C0,
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

  Future<void> pumpForm(
    WidgetTester tester, {
    TransactionTileUiModel? editTile,
    required Map<(String currency, YearMonth ym, String cat), CategoryBudgetHint>
        hints,
    required DateTime now,
  }) async {
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
              builder: (_, __) => TransactionFormScreen(transaction: editTile),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          budgetClockProvider.overrideWithValue(FixedClock(now)),
          budgetServiceProvider.overrideWithValue(_StubHintBudgetService(hints)),
          preferencesRepositoryProvider
              .overrideWith((ref) async => preferences),
          accountListProvider.overrideWithValue(
            const AsyncData([includedCash, excludedWallet]),
          ),
          accountUiListProvider.overrideWithValue(
            AsyncData([
              AccountUiModel.of(includedCash),
              AccountUiModel.of(excludedWallet),
            ]),
          ),
          categoryListProvider.overrideWith(
            (ref, type) => Stream.value(
              type == CategoryType.expense ? const [dining, travel] : const [],
            ),
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
    await tester.pumpAndSettle();
  }

  testWidgets(
      'shows excluded-account hint, updates on over-budget without blocking save',
      (tester) async {
    final now = DateTime.now();
    final ym = YearMonth.fromDate(now);
    await pumpForm(
      tester,
      now: now,
      hints: {
        ('USD', ym, 'cat_dining'): CategoryBudgetHint(
          currencyCode: 'USD',
          month: ym,
          categoryId: 'cat_dining',
          isCategoryArchived: false,
          effectiveBudgetMinor: 10000, // $100
          actualMinor: 6000, // $60
          pendingMinor: 0,
        ),
      },
    );

    // Pick Category = Dining
    await tester.tap(find.text('Category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dining').last);
    await tester.pumpAndSettle();

    // Initially remaining $40.00 -> after $0.00 = $40.00
    expect(find.textContaining('\$40.00'), findsWidgets);

    // Enter $60 -> over budget by $20.00
    await tester.enterText(
      find.descendant(
        of: find.byType(LedgerAmountInput),
        matching: find.byType(TextFormField),
      ),
      '60',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Budget exceeded by \$20.00'), findsOneWidget);

    // Pick Excluded account -> excluded notice replaces over-budget calculation
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluded').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Excluded from budget totals'), findsOneWidget);

    // Switch back to Cash (over budget again) and verify Save is NOT blocked
    await tester.tap(find.text('Excluded'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cash').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Budget exceeded by \$20.00'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(ledger.addedTransactions, hasLength(1));
    expect(ledger.addedTransactions.single['amountMinor'], 6000);
  });

  testWidgets('the budget hint is read-only and never takes a tap',
      (tester) async {
    final now = DateTime.now();
    final ym = YearMonth.fromDate(now);
    await pumpForm(
      tester,
      now: now,
      hints: {
        ('USD', ym, 'cat_dining'): CategoryBudgetHint(
          currencyCode: 'USD',
          month: ym,
          categoryId: 'cat_dining',
          isCategoryArchived: false,
          effectiveBudgetMinor: 10000,
          actualMinor: 6000,
          pendingMinor: 0,
        ),
      },
    );

    await tester.tap(find.text('Category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dining').last);
    await tester.pumpAndSettle();

    final banner = find.byType(TransactionBudgetHintBanner);
    expect(banner, findsOneWidget);
    expect(find.textContaining('\$40.00'), findsWidgets);
    // Reading the hint is the whole interaction: no ink, no buttons, nothing
    // that can hide the form behind a sheet or navigate away.
    expect(
      find.descendant(of: banner, matching: find.byType(InkWell)),
      findsNothing,
    );
    expect(
      find.descendant(of: banner, matching: find.byType(TextButton)),
      findsNothing,
    );
    await tester.tap(banner, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.textContaining('\$40.00'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'edit mode keeps form-locked currency and subtracts original only when '
      'same month & category', (tester) async {
    final now = DateTime(2026, 5, 10);
    const may = YearMonth(2026, 5);
    final editTile = TransactionTileUiModel(
      id: 'tx-edit',
      note: 'Dinner',
      date: now,
      amount: 3000, // $30 already in May's Dining $80 actual
      displayAmount: '\$30.00',
      displaySign: '-',
      type: TransactionKind.expense,
      account: includedCash,
      category: dining,
    );

    await pumpForm(
      tester,
      now: now,
      editTile: editTile,
      hints: {
        ('USD', may, 'cat_dining'): const CategoryBudgetHint(
          currencyCode: 'USD',
          month: YearMonth(2026, 5),
          categoryId: 'cat_dining',
          isCategoryArchived: false,
          effectiveBudgetMinor: 10000, // $100
          actualMinor: 8000, // $80 incl $30 original -> base = $50
          pendingMinor: 0,
        ),
        ('USD', may, 'cat_travel'): const CategoryBudgetHint(
          currencyCode: 'USD',
          month: YearMonth(2026, 5),
          categoryId: 'cat_travel',
          isCategoryArchived: false,
          effectiveBudgetMinor: 10000, // $100
          actualMinor: 8000, // $80 (not from this tx!) -> base stays $80
          pendingMinor: 0,
        ),
      },
    );

    // Same category & month: base = 80 - 30 = 50 -> remaining 50 -> after 30 = 20
    expect(find.textContaining('\$50.00'), findsOneWidget);
    expect(find.textContaining('\$20.00'), findsOneWidget);

    // Switch category to Travel -> original does NOT subtract -> 80 + 30 = $10 over
    await tester.tap(find.text('Dining'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Travel').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Budget exceeded by \$10.00'), findsOneWidget);
  });
}
