import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_badge.dart';
import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/router/app_router.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/app/theme/category_tokens.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/balance_visibility_provider.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/core/presentation/providers/locale_provider.dart';
import 'package:feather_ledger/features/budget/presentation/screens/budget_screen.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/presentation/models/ledger_day_group.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/screens/search_screen.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_header.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_skeleton.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_transaction_list.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/pending_bill_sheet.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/time_anchor.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/transaction_detail_sheet.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/transaction_tile.dart';
import 'package:feather_ledger/features/reports/presentation/screens/reports_screen.dart';
import 'package:feather_ledger/features/settings/presentation/screens/more_screen.dart';
import 'package:feather_ledger/features/settings/presentation/screens/settings_screen.dart';
import 'package:feather_ledger/shared/presentation/models/account_ui_model.dart';
import 'package:feather_ledger/shared/presentation/models/monthly_summary_ui_model.dart';

import '../../../support/event_sourcing/ledger_service_harness.dart';
import '../../../support/mocks/mock_shared_preferences.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

class _MutableBalanceVisibility extends BalanceVisibilityController {
  @override
  Future<bool> build() async => true;

  @override
  Future<void> toggle() async => state = AsyncData(!(state.value ?? true));
}

class _FixedCurrencyController extends CurrencyController {
  _FixedCurrencyController(this.code);
  final String code;

  @override
  Future<String> build() async => code;
}

class _FixedLocaleController extends LocaleController {
  @override
  Future<Locale?> build() async => const Locale('en');
}

void main() {
  testWidgets(
      'real-router E2E flow: months, sticky rail & card tap, search, pending bill, masking, reports scroll preserve, nav to settings',
      (tester) async {
    tester.view.physicalSize = const Size(412, 840);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final prefsRepo = PreferencesRepositoryImpl(MockSharedPreferences());
    await prefsRepo.setCurrency('CNY');
    await prefsRepo.setLocale(const Locale('en'));
    await prefsRepo.setShowBalance(true);

    final harness = LedgerServiceHarness(preferences: prefsRepo);
    addTearDown(harness.close);

    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final prevMonth = DateTime(now.year, now.month - 1, 1);

    await tester.runAsync(() async {
      // Seed accounts: one included in totals, one excluded.
      await harness.accountService.createAccount(
        commandId: 'cmd-acc-main',
        name: 'Main Card',
        type: AccountType.bank,
        initialBalanceMinor: 100000, // ¥1,000.00
        currencyCode: 'CNY',
        includeInTotals: true,
      );
      await harness.accountService.createAccount(
        commandId: 'cmd-acc-hidden',
        name: 'Excluded Vault',
        type: AccountType.cash,
        initialBalanceMinor: 50000, // ¥500.00 excluded from totals
        currencyCode: 'CNY',
        includeInTotals: false,
      );
      await harness.categoryService.createCategory(
        commandId: 'cmd-cat-food',
        categoryId: 'cat-food',
        name: 'Food',
        iconKey: CategoryTokens.defaultIcons.first.toString(),
        colorInt: CategoryTokens.defaultColor.toARGB32(),
        type: CategoryType.expense,
      );
      await harness.categoryService.createCategory(
        commandId: 'cmd-cat-salary',
        categoryId: 'cat-salary',
        name: 'Salary',
        iconKey: CategoryTokens.defaultIcons[1].toString(),
        colorInt: Colors.green.toARGB32(),
        type: CategoryType.income,
      );

      final accounts = await harness.accountService.watchAllAccounts().first;
      final mainAccountId =
          accounts.firstWhere((a) => a.name == 'Main Card').id;

      // Previous month: +¥200.00 income, -¥30.00 expense.
      await harness.ledgerService.addTransaction(
        commandId: 'cmd-prev-inc',
        amountMinor: 20000,
        type: TransactionKind.income,
        date: DateTime(prevMonth.year, prevMonth.month, 10, 9),
        categoryId: 'cat-salary',
        accountId: mainAccountId,
        note: 'Freelance',
      );
      await harness.ledgerService.addTransaction(
        commandId: 'cmd-prev-exp',
        amountMinor: 3000,
        type: TransactionKind.expense,
        date: DateTime(prevMonth.year, prevMonth.month, 10, 13),
        categoryId: 'cat-food',
        accountId: mainAccountId,
        note: 'Noodles',
      );

      // Current month: top day (20th) has -¥10.00 Espresso + ¥50.00 Refund.
      await harness.ledgerService.addTransaction(
        commandId: 'cmd-cur-exp-top',
        amountMinor: 1000,
        type: TransactionKind.expense,
        date: DateTime(currentMonth.year, currentMonth.month, 20, 10),
        categoryId: 'cat-food',
        accountId: mainAccountId,
        note: 'Espresso',
      );
      await harness.ledgerService.addTransaction(
        commandId: 'cmd-cur-inc-top',
        amountMinor: 5000,
        type: TransactionKind.income,
        date: DateTime(currentMonth.year, currentMonth.month, 20, 14),
        categoryId: 'cat-salary',
        accountId: mainAccountId,
        note: 'Cashback',
      );
      // Additional days (1..15) of -¥1.00 to ensure scrollable timeline.
      for (var d = 1; d <= 15; d++) {
        await harness.ledgerService.addTransaction(
          commandId: 'cmd-cur-day-$d',
          amountMinor: 100,
          type: TransactionKind.expense,
          date: DateTime(currentMonth.year, currentMonth.month, d, 12),
          categoryId: 'cat-food',
          accountId: mainAccountId,
          note: 'Snack $d',
        );
      }

      // Pending planned bill on 18th of current month (-¥25.00).
      final billDate = DateTime(currentMonth.year, currentMonth.month, 18, 9);
      await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 2500,
        accountId: mainAccountId,
        categoryId: 'cat-food',
        description: 'Internet Bill',
        frequency: 'MONTHLY',
        startDate: billDate,
        endDate: billDate,
        mode: RecurringSeriesMode.planned,
      );
      await harness.recurringService.materialize();
    });

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(harness.db),
      preferencesRepositoryProvider.overrideWith((ref) async => prefsRepo),
    ]);
    addTearDown(container.dispose);

    final router = container.read(goRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(LedgerHeader)),
    )!;

    final curMonthLabel = DateFormat.MMM('en').format(currentMonth);
    final prevMonthLabel = DateFormat.MMM('en').format(prevMonth);

    // 1. Real-time Total Balance excludes Hidden Vault (¥1195.00) and shows current month income/expense.
    expect(find.text('¥1195.00'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(LedgerHeader),
        matching: find.text(l10n.totalBalance),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(LedgerHeader),
        matching: find.text(l10n.monthIncome(curMonthLabel)),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(LedgerHeader),
        matching: find.text(l10n.monthExpense(curMonthLabel)),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(LedgerHeader),
        matching: find.text('¥50.00'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(LedgerHeader),
        matching: find.text('¥25.00'),
      ),
      findsOneWidget,
    );

    // 2. Switch to previous month: Total Balance stays ¥1195.00 while month labels & totals update.
    await tester.tap(find.byIcon(LucideIcons.chevronLeft).first);
    await tester.pumpAndSettle();
    expect(find.text('¥1195.00'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(LedgerHeader),
        matching: find.text(l10n.monthIncome(prevMonthLabel)),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(LedgerHeader),
        matching: find.text(l10n.monthExpense(prevMonthLabel)),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(LedgerHeader),
        matching: find.text('¥200.00'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(LedgerHeader),
        matching: find.text('¥30.00'),
      ),
      findsOneWidget,
    );

    // Switch back to current month.
    await tester.tap(find.byIcon(LucideIcons.chevronRight).first);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(LedgerHeader),
        matching: find.text('¥50.00'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(LedgerHeader),
        matching: find.text('¥25.00'),
      ),
      findsOneWidget,
    );

    // 3. Tap LEFT date rail beside day 20's row AND tap RIGHT card row -> both open detail sheet (-¥10.00).
    final espressoRow = find.text('Espresso');
    expect(espressoRow, findsOneWidget);
    final espressoCenter = tester.getCenter(espressoRow);
    final day20Anchor = find.ancestor(
      of: find.text('20'),
      matching: find.byType(TimeAnchor),
    );
    expect(day20Anchor, findsOneWidget);
    final anchorRect = tester.getRect(day20Anchor);
    await tester.tapAt(Offset(anchorRect.center.dx, espressoCenter.dy));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionDetailSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TransactionDetailSheet),
        matching: find.text('-¥10.00'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionDetailSheet), findsNothing);

    await tester.tap(espressoRow);
    await tester.pumpAndSettle();
    expect(find.byType(TransactionDetailSheet), findsOneWidget);
    await tester.tap(find.descendant(
        of: find.byType(TransactionDetailSheet),
        matching: find.byIcon(LucideIcons.x)));
    await tester.pumpAndSettle();

    // 4. Scroll timeline forward & backward; navigate to Search (/ledger/search) and inspect -¥10.00.
    final listFinder = find.byType(LedgerTransactionList);
    final controller =
        tester.widget<LedgerTransactionList>(listFinder).controller;
    await tester.drag(listFinder, const Offset(0, -320));
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
    await tester.drag(listFinder, const Offset(0, 320));
    await tester.pumpAndSettle();

    controller.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.search));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Espresso');
    await tester.pumpAndSettle();
    expect(find.text('-¥10.00'), findsOneWidget);
    await tester.tap(find.text('-¥10.00'));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionDetailSheet), findsOneWidget);
    await tester.tap(find.descendant(
        of: find.byType(TransactionDetailSheet),
        matching: find.byIcon(LucideIcons.x)));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsNothing);

    // 5. Pending bill sheet: post / edit / delete entry reachability.
    final billFinder = find.text('Internet Bill');
    while (tester.getCenter(billFinder).dy > 600) {
      await tester.drag(listFinder, const Offset(0, -150));
      await tester.pumpAndSettle();
    }
    while (tester.getCenter(billFinder).dy < 160) {
      await tester.drag(listFinder, const Offset(0, 150));
      await tester.pumpAndSettle();
    }
    await tester.tap(billFinder);
    await tester.pumpAndSettle();
    expect(find.byType(PendingBillSheet), findsOneWidget);
    expect(find.text(l10n.postInstance), findsOneWidget);
    expect(find.byIcon(LucideIcons.squarePen), findsOneWidget);
    expect(find.byIcon(LucideIcons.ellipsisVertical), findsOneWidget);
    await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
    await tester.pumpAndSettle();
    expect(find.text(l10n.deletePlan), findsOneWidget);
    // Dismiss popup menu, then close sheet.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();

    // 6. Overview eye toggle: masks Total Balance, Month Income, Month Expense, AND collapsed bar balance,
    // while keeping transaction rows (-¥10.00) and daily subtotals readable; restores on second toggle.
    controller.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.eye));
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.eyeOff), findsOneWidget);
    expect(find.textContaining('****'), findsNWidgets(3));
    expect(find.text('¥1195.00'), findsNothing);
    expect(find.text('-¥10.00'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(LedgerTransactionList),
        matching: find.text('¥50.00'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(LedgerTransactionList),
        matching: find.text('¥10.00'),
      ),
      findsOneWidget,
    );

    // Scroll down to collapse header and verify collapsed app-bar balance is
    // also masked. The app bar keeps the theme surface; the shared theme adds
    // the scrolled-under shadow instead of a local tint.
    controller.jumpTo(260);
    await tester.pumpAndSettle();
    final scrolledAppBar =
        tester.widget<SliverAppBar>(find.byType(SliverAppBar));
    expect(scrolledAppBar.backgroundColor, isNull);
    // The bar carries no local elevation override: the shared theme supplies
    // the 1.5 scrolled-under shadow on both themes.
    expect(scrolledAppBar.scrolledUnderElevation, isNull);
    expect(
      Theme.of(tester.element(find.byType(SliverAppBar)))
          .appBarTheme
          .scrolledUnderElevation,
      1.5,
    );
    expect(
      find.descendant(
        of: find.byType(LedgerCompactBalance),
        matching: find.text('******'),
      ),
      findsOneWidget,
    );

    // Scroll back up and restore visibility.
    controller.jumpTo(0);
    await tester.pumpAndSettle();
    final topAppBar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
    expect(topAppBar.backgroundColor, isNull);
    expect(topAppBar.scrolledUnderElevation, isNull);
    await tester.tap(find.byIcon(LucideIcons.eyeOff));
    await tester.pumpAndSettle();
    expect(find.text('¥1195.00'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(LedgerHeader),
        matching: find.text('¥50.00'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(LedgerHeader),
        matching: find.text('¥25.00'),
      ),
      findsOneWidget,
    );

    // 7. Tap overview card -> /ledger/reports opens selected month -> pop back -> scroll position preserved.
    controller.jumpTo(16);
    await tester.pumpAndSettle();
    final savedOffset = controller.offset;
    expect(savedOffset, 16);
    await tester.tap(find.text(l10n.totalBalance));
    await tester.pumpAndSettle();
    expect(find.byType(ReportsScreen), findsOneWidget);
    expect(
      find.text(DateFormat.yMMMM('en').format(currentMonth)),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ReportsScreen), findsNothing);
    expect(controller.offset, savedOffset);

    // 8. Bottom nav tabs: Ledger -> Budget -> More -> Settings -> Backup/Restore reachable -> pop to More.
    await tester.tap(find.text(l10n.budget));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetScreen), findsOneWidget);

    await tester.tap(find.text(l10n.more));
    await tester.pumpAndSettle();
    expect(find.byType(MoreScreen), findsOneWidget);

    await tester.tap(find.text(l10n.settings));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text(l10n.backupNow), findsOneWidget);
    expect(find.text(l10n.restoreFromBackup), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(MoreScreen), findsOneWidget);
  });

  final themeVariants = <String, ThemeData>{
    'default-light': AppTheme.lightTheme,
    'dynamic-light': AppTheme.buildLight(
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A73E8),
        brightness: Brightness.light,
      ),
    ),
    'default-dark': AppTheme.darkTheme,
    'dynamic-dark': AppTheme.buildDark(
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A73E8),
        brightness: Brightness.dark,
      ),
    ),
  };

  const matrixAccount = AccountEntity(
    id: 'acc-1',
    name: 'Wallet',
    type: AccountType.cash,
    currencyCode: 'CNY',
    balanceMinor: 50000,
    archived: false,
    lastUpdatedEventId: 1,
  );
  final matrixCategory = CategoryEntity(
    id: 'cat-1',
    name: 'Food',
    iconKey: CategoryTokens.defaultIcons.first.toString(),
    colorInt: CategoryTokens.defaultColor.toARGB32(),
    type: CategoryType.expense,
  );

  for (final width in [360.0, 800.0]) {
    for (final entry in themeVariants.entries) {
      testWidgets(
          'surface hierarchy, WCAG contrast, hit targets, and tail clearance (${entry.key} @ ${width.toInt()}dp)',
          (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        tester.view.padding = const FakeViewPadding(bottom: 24);
        tester.view.viewPadding = const FakeViewPadding(bottom: 24);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);

        final harness = LedgerServiceHarness();
        addTearDown(harness.close);

        final now = DateTime.now();
        final todayDate = DateTime(now.year, now.month, now.day, 12);

        final container = ProviderContainer(overrides: [
          appDatabaseProvider.overrideWithValue(harness.db),
          currencyControllerProvider
              .overrideWith(() => _FixedCurrencyController('CNY')),
          localeControllerProvider.overrideWith(_FixedLocaleController.new),
          balanceVisibilityControllerProvider
              .overrideWith(_MutableBalanceVisibility.new),
          accountUiListProvider.overrideWith((ref) => const AsyncData([])),
          categoryListProvider.overrideWith((ref, type) => Stream.value([])),
          ledgerMonthlyTransactionsProvider.overrideWith((ref, month) {
            final days = <LedgerDayGroup>[
              LedgerDayGroup(
                date: todayDate,
                transactions: [
                  TransactionTileUiModel(
                    id: 'tx-today-exp',
                    amount: 1000,
                    type: TransactionKind.expense,
                    date: todayDate,
                    note: 'Coffee',
                    category: matrixCategory,
                    account: matrixAccount,
                    displayAmount: '10.00',
                    displaySign: '-',
                  ),
                  TransactionTileUiModel(
                    id: 'bill-today-pending',
                    amount: 2500,
                    type: TransactionKind.expense,
                    date: todayDate,
                    note: 'Rent',
                    category: matrixCategory,
                    account: matrixAccount,
                    isPending: true,
                    displayAmount: '25.00',
                    displaySign: '-',
                  ),
                ],
                displayExpense: '¥10.00',
              ),
              for (var i = 1; i <= 10; i++)
                LedgerDayGroup(
                  date: todayDate.subtract(Duration(days: i)),
                  transactions: [
                    TransactionTileUiModel(
                      id: 'tx-past-$i',
                      amount: i == 10 ? 4250 : 1200 + i,
                      type: TransactionKind.expense,
                      date: todayDate.subtract(Duration(days: i)),
                      note: 'Meal $i',
                      category: matrixCategory,
                      account: matrixAccount,
                      displayAmount: i == 10 ? '42.50' : '12.0$i',
                      displaySign: '-',
                    ),
                  ],
                ),
            ];
            return Stream.value(days);
          }),
          ledgerMonthlySummaryProvider.overrideWith(
            (ref, month) => Stream.value(
              const MonthlySummaryUiModel(
                displayBalance: '¥500.00',
                displayIncome: '¥0.00',
                displayExpense: '¥152.50',
              ),
            ),
          ),
        ]);
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: container.read(goRouterProvider),
              theme: entry.value,
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final ctx = tester.element(find.byType(NavigationBar));
        final theme = Theme.of(ctx);
        final scheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        // 1. 4-layer surface hierarchy.
        expect(
          {
            scheme.surface,
            scheme.surfaceContainerLow,
            scheme.surfaceContainer,
            scheme.surfaceContainerHigh,
          }.length,
          4,
        );
        if (isDark) {
          expect(scheme.surface.computeLuminance(),
              lessThan(scheme.surfaceContainerLow.computeLuminance()));
          expect(scheme.surfaceContainerLow.computeLuminance(),
              lessThan(scheme.surfaceContainer.computeLuminance()));
          expect(scheme.surfaceContainer.computeLuminance(),
              lessThan(scheme.surfaceContainerHigh.computeLuminance()));
        } else {
          expect(scheme.surface.computeLuminance(),
              greaterThan(scheme.surfaceContainerLow.computeLuminance()));
          expect(scheme.surfaceContainerLow.computeLuminance(),
              greaterThan(scheme.surfaceContainer.computeLuminance()));
          expect(scheme.surfaceContainer.computeLuminance(),
              greaterThan(scheme.surfaceContainerHigh.computeLuminance()));
        }

        // 2. Programmatic WCAG contrast on rendered foregrounds vs actual backgrounds.
        final wdayLabel = DateFormat('E', 'en').format(todayDate);
        final wdayText = tester.widget<Text>(find.text(wdayLabel).first);
        expect(
          _contrast(wdayText.style!.color!, scheme.surface),
          greaterThanOrEqualTo(4.5),
          reason: 'weekday contrast failed on ${entry.key}',
        );

        final accountText = tester.widget<Text>(find.text('Wallet').first);
        expect(
          _contrast(accountText.style!.color!, scheme.surfaceContainerLow),
          greaterThanOrEqualTo(4.5),
          reason: 'account name contrast failed on ${entry.key}',
        );

        final l10n = AppLocalizations.of(ctx)!;
        final pendingBadgeFinder = find.ancestor(
          of: find.text(l10n.pendingBill),
          matching: find.byType(AppBadge),
        );
        expect(pendingBadgeFinder, findsOneWidget);
        final pendingLabelText =
            tester.widget<Text>(find.text(l10n.pendingBill));
        expect(
          _contrast(
            pendingLabelText.style!.color!,
            scheme.surfaceContainerLow,
          ),
          greaterThanOrEqualTo(4.5),
          reason: 'pending capsule text contrast failed on ${entry.key}',
        );
        expect(
          _contrast(scheme.outline, scheme.surfaceContainerLow),
          greaterThanOrEqualTo(3.0),
          reason: 'pending capsule outline contrast failed on ${entry.key}',
        );

        final expenseText = tester.widget<Text>(find.text('-¥10.00').first);
        expect(
          _contrast(expenseText.style!.color!, scheme.surfaceContainerLow),
          greaterThanOrEqualTo(4.5),
          reason: 'expense amount contrast failed on ${entry.key}',
        );

        final todayDayText = tester.widget<Text>(
          find.descendant(
            of: find.byType(TimeAnchor).first,
            matching: find.text(DateFormat('d', 'en').format(todayDate)),
          ),
        );
        expect(
          _contrast(todayDayText.style!.color!, scheme.primaryContainer),
          greaterThanOrEqualTo(4.5),
          reason: 'today badge contrast failed on ${entry.key}',
        );

        final fab = tester.widget<FloatingActionButton>(
          find.byType(FloatingActionButton),
        );
        final fabBg = fab.backgroundColor ??
            theme.floatingActionButtonTheme.backgroundColor!;
        final fabFg = fab.foregroundColor ??
            theme.floatingActionButtonTheme.foregroundColor!;
        expect(
          _contrast(fabFg, fabBg),
          greaterThanOrEqualTo(4.5),
          reason: 'FAB contrast failed on ${entry.key}',
        );
        expect(
          _contrast(fabBg, scheme.surface),
          greaterThan(1.05),
          reason: 'FAB surface separation failed on ${entry.key}',
        );

        final navBg = theme.navigationBarTheme.backgroundColor!;
        expect(
          _contrast(scheme.onSecondaryContainer, scheme.secondaryContainer),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(scheme.onSurfaceVariant, navBg),
          greaterThanOrEqualTo(4.5),
        );

        // 3. Header icon button hit targets >= 48x48dp.
        for (final icon in [
          LucideIcons.chevronLeft,
          LucideIcons.chevronRight,
          LucideIcons.search,
          LucideIcons.eye,
        ]) {
          final btn = find.ancestor(
            of: find.byIcon(icon),
            matching: find.byType(IconButton),
          );
          expect(btn, findsAtLeastNWidgets(1));
          final size = tester.getSize(btn.first);
          expect(size.width, greaterThanOrEqualTo(48.0),
              reason: '$icon hit width < 48 in ${entry.key}@$width');
          expect(size.height, greaterThanOrEqualTo(48.0),
              reason: '$icon hit height < 48 in ${entry.key}@$width');
        }

        // 4. Day cards inside viewport + bottom scroll last-row clears FAB & visible nav bar.
        final dayCardRect = tester.getRect(find.byType(AppCard).at(1));
        expect(dayCardRect.left, greaterThanOrEqualTo(0));
        expect(dayCardRect.right, lessThanOrEqualTo(width));

        final listFinder = find.byType(LedgerTransactionList);
        final controller =
            tester.widget<LedgerTransactionList>(listFinder).controller;
        controller.jumpTo(controller.position.maxScrollExtent);
        await tester.pumpAndSettle();

        expect(find.byType(NavigationBar), findsOneWidget);
        final lastAmountFinder = find.text('-¥42.50');
        expect(lastAmountFinder, findsOneWidget);
        final viewportRect = tester.getRect(listFinder);
        final lastAmountRect = tester.getRect(lastAmountFinder);
        final fabRect = tester.getRect(find.byType(FloatingActionButton));
        final navRect = tester.getRect(find.byType(NavigationBar));

        expect(lastAmountRect.top, greaterThanOrEqualTo(viewportRect.top));
        expect(lastAmountRect.bottom, lessThanOrEqualTo(viewportRect.bottom));
        expect(lastAmountRect.overlaps(fabRect), isFalse);
        expect(lastAmountRect.overlaps(navRect), isFalse);
      });
    }
  }

  testWidgets(
      'narrow 360dp + textScale 1.8: long account name, failed bill, -¥12,345.67 zero overflow & readable detail',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const longAccountName =
        'Very Long Joint Checking Account Number 1234567890';
    const account = AccountEntity(
      id: 'acc-long',
      name: longAccountName,
      type: AccountType.bank,
      currencyCode: 'CNY',
      balanceMinor: 500000,
      archived: false,
      lastUpdatedEventId: 1,
    );
    final category = CategoryEntity(
      id: 'cat-1',
      name: 'Utilities',
      iconKey: CategoryTokens.defaultIcons.first.toString(),
      colorInt: CategoryTokens.defaultColor.toARGB32(),
      type: CategoryType.expense,
    );

    final harness = LedgerServiceHarness();
    addTearDown(harness.close);

    final now = DateTime.now();
    final date = DateTime(now.year, now.month, 15, 9);
    final billTile = TransactionTileUiModel(
      id: 'bill-failed',
      amount: 1234567,
      type: TransactionKind.expense,
      date: date,
      note: 'Power & Heating',
      category: category,
      account: account,
      isPending: true,
      scheduledStatus: ScheduledTransactionStatus.failed,
      displayAmount: '12,345.67',
      displaySign: '-',
    );

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(harness.db),
      currencyControllerProvider
          .overrideWith(() => _FixedCurrencyController('CNY')),
      localeControllerProvider.overrideWith(_FixedLocaleController.new),
      balanceVisibilityControllerProvider
          .overrideWith(_MutableBalanceVisibility.new),
      accountUiListProvider
          .overrideWith((ref) => AsyncData([AccountUiModel.of(account)])),
      categoryListProvider
          .overrideWith((ref, type) => Stream.value([category])),
      ledgerMonthlyTransactionsProvider.overrideWith(
        (ref, month) => Stream.value([
          LedgerDayGroup(date: date, transactions: [billTile]),
        ]),
      ),
      ledgerMonthlySummaryProvider.overrideWith(
        (ref, month) => Stream.value(
          const MonthlySummaryUiModel(
            displayBalance: '¥5,000.00',
            displayIncome: '¥0.00',
            displayExpense: '¥0.00',
          ),
        ),
      ),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(1.8),
          ),
          child: MaterialApp.router(
            routerConfig: container.read(goRouterProvider),
            theme: AppTheme.darkTheme,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(TransactionTile)),
    )!;

    // Full amount & failed status are fully visible within 360dp viewport.
    final amountFinder = find.text('-¥12,345.67');
    expect(amountFinder, findsOneWidget);
    final amountRect = tester.getRect(amountFinder);
    expect(amountRect.left, greaterThanOrEqualTo(0));
    expect(amountRect.right, lessThanOrEqualTo(360));

    final failedFinder = find.text(l10n.failedBill);
    expect(failedFinder, findsOneWidget);
    final failedRect = tester.getRect(failedFinder);
    expect(failedRect.left, greaterThanOrEqualTo(0));
    expect(failedRect.right, lessThanOrEqualTo(360));

    // Long account name truncates with ellipsis in list row.
    final listAccountFinder = find.descendant(
      of: find.byType(TransactionTile),
      matching: find.text(longAccountName),
    );
    final listAccountText = tester.widget<Text>(listAccountFinder);
    expect(listAccountText.overflow, TextOverflow.ellipsis);
    expect(listAccountText.maxLines, 1);
    expect(
      tester.renderObject<RenderParagraph>(listAccountFinder).didExceedMaxLines,
      isTrue,
    );

    // Tapping opens sheet where full account name is readable without ellipsis.
    await tester.tap(find.byType(TransactionTile));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(PendingBillSheet), findsOneWidget);

    final sheetAccountFinder = find.descendant(
      of: find.byType(PendingBillSheet),
      matching: find.text(longAccountName),
    );
    final sheetAccountText = tester.widget<Text>(sheetAccountFinder);
    expect(sheetAccountText.overflow, isNot(TextOverflow.ellipsis));
    expect(sheetAccountText.maxLines, isNull);
    expect(
      tester
          .renderObject<RenderParagraph>(sheetAccountFinder)
          .didExceedMaxLines,
      isFalse,
    );
  });

  testWidgets(
      'ledger skeleton uses day cards and avatar placeholders without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: LedgerSkeleton(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(AppCard), findsNWidgets(3));
  });
}
