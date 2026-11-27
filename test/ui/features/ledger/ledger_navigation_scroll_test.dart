import 'dart:async';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/router/app_router.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/app/theme/category_tokens.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/core/presentation/providers/balance_visibility_provider.dart';
import 'package:feather_ledger/features/ledger/presentation/models/ledger_day_group.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/screens/transaction_form_screen.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_empty.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_transaction_list.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_header.dart';
import 'package:feather_ledger/features/reports/presentation/providers/reports_providers.dart';
import 'package:feather_ledger/features/reports/presentation/screens/reports_screen.dart';
import 'package:feather_ledger/features/budget/presentation/screens/budget_screen.dart';
import 'package:feather_ledger/shared/presentation/models/monthly_summary_ui_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../support/event_sourcing/ledger_service_harness.dart';

class _Visibility extends BalanceVisibilityController {
  @override
  Future<bool> build() async => true;

  @override
  Future<void> toggle() async => state = AsyncData(!(state.value ?? true));
}

void main() {
  testWidgets('ledger card opens reports for its month and budget is a tab',
      (tester) async {
    final harness = LedgerServiceHarness();
    addTearDown(harness.close);
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(harness.db),
      balanceVisibilityControllerProvider.overrideWith(_Visibility.new),
      accountUiListProvider.overrideWith((ref) => const AsyncData([])),
      categoryListProvider.overrideWith((ref, type) => Stream.value([])),
      ledgerMonthlyTransactionsProvider
          .overrideWith((ref, month) => Stream.value([])),
      ledgerMonthlySummaryProvider.overrideWith((ref, month) => Stream.value(
          const MonthlySummaryUiModel(
              displayBalance: r'$0',
              displayIncome: r'$0',
              displayExpense: r'$0'))),
    ]);
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.chevronLeft).first);
    await tester.pumpAndSettle();
    final ledgerMonth = container.read(ledgerViewModelProvider).selectedDate;

    await tester.tap(find.byIcon(LucideIcons.eye));
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.eyeOff), findsOneWidget);
    expect(find.byType(ReportsScreen), findsNothing);

    final card = find
        .byKey(tester.widget<LedgerHeader>(find.byType(LedgerHeader)).cardKey!);
    final cardRect = tester.getRect(card);
    await tester.tap(find.text('Total Balance'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final surface = find.byKey(const ValueKey('report-transition-surface'));
    expect(surface, findsOneWidget);
    final openingRect = tester.getRect(surface);
    expect(openingRect.width, greaterThan(cardRect.width));
    expect(openingRect.height, greaterThan(cardRect.height));
    await tester.pumpAndSettle();
    expect(find.byType(ReportsScreen), findsOneWidget);
    expect(
        find.text(DateFormat.yMMMM('en').format(ledgerMonth)), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    final otherMonth = DateTime(ledgerMonth.year, ledgerMonth.month - 1);
    container.read(selectedDateProvider.notifier).setMonth(otherMonth);
    await tester.pumpAndSettle();
    expect(
        find.text(DateFormat.yMMMM('en').format(otherMonth)), findsOneWidget);
    router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(surface, findsOneWidget);
    expect(tester.getRect(surface).height,
        lessThan(tester.getSize(find.byType(MaterialApp)).height));
    await tester.pumpAndSettle();
    expect(container.read(ledgerViewModelProvider).selectedDate, ledgerMonth);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('Total Balance'));
    await tester.pumpAndSettle();
    expect(
        find.text(DateFormat.yMMMM('en').format(ledgerMonth)), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Budget'));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetScreen), findsOneWidget);
    expect(find.byType(ReportsScreen), findsNothing);
  });

  testWidgets('an empty month cannot scroll or hide navigation',
      (tester) async {
    final harness = LedgerServiceHarness();
    addTearDown(harness.close);
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(harness.db),
      accountUiListProvider.overrideWith((ref) => const AsyncData([])),
      categoryListProvider.overrideWith((ref, type) => Stream.value([])),
      ledgerMonthlyTransactionsProvider
          .overrideWith((ref, month) => Stream.value([])),
      ledgerMonthlySummaryProvider.overrideWith((ref, month) => Stream.value(
          const MonthlySummaryUiModel(
              displayBalance: r'$0',
              displayIncome: r'$0',
              displayExpense: r'$0'))),
    ]);
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales),
    ));
    await tester.pumpAndSettle();
    final list = find.byType(LedgerTransactionList);
    final controller = tester.widget<LedgerTransactionList>(list).controller;
    for (final delta in [const Offset(0, -400), const Offset(0, 400)]) {
      await tester.drag(list, delta);
      await tester.pumpAndSettle();
      expect(controller.offset, 0);
      expect(find.byType(NavigationBar), findsOneWidget);
    }
  });

  testWidgets('deleting the last records leaves navigation in place',
      (tester) async {
    final harness = LedgerServiceHarness();
    addTearDown(harness.close);
    final changes = StreamController<List<LedgerDayGroup>>.broadcast();
    addTearDown(changes.close);
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(harness.db),
      accountUiListProvider.overrideWith((ref) => const AsyncData([])),
      categoryListProvider.overrideWith((ref, type) => Stream.value([])),
      ledgerMonthlyTransactionsProvider
          .overrideWith((ref, month) => changes.stream),
      ledgerMonthlySummaryProvider.overrideWith((ref, month) => Stream.value(
          const MonthlySummaryUiModel(
              displayBalance: r'$0',
              displayIncome: r'$0',
              displayExpense: r'$0'))),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
          routerConfig: container.read(goRouterProvider),
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales),
    ));
    await tester.pump();
    final now = DateTime.now();
    changes.add(List.generate(
        20,
        (i) => LedgerDayGroup(
            date: DateTime(now.year, now.month, i + 1),
            transactions: const [])));
    await tester.pumpAndSettle();
    final list = find.byType(LedgerTransactionList);
    final controller = tester.widget<LedgerTransactionList>(list).controller;
    await tester.drag(list, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    changes.add([]);
    await tester.pumpAndSettle();
    expect(controller.offset, 0);
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.drag(list, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(controller.offset, 0);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('management buttons stay in their route during transitions',
      (tester) async {
    final harness = LedgerServiceHarness();
    addTearDown(harness.close);
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(harness.db),
      accountUiListProvider.overrideWith((ref) => const AsyncData([])),
      categoryListProvider.overrideWith((ref, type) => Stream.value([])),
      ledgerMonthlyTransactionsProvider
          .overrideWith((ref, month) => Stream.value([])),
      ledgerMonthlySummaryProvider.overrideWith((ref, month) => Stream.value(
          const MonthlySummaryUiModel(
              displayBalance: r'$0',
              displayIncome: r'$0',
              displayExpense: r'$0'))),
    ]);
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales),
    ));
    await tester.pumpAndSettle();
    expect(await tester.binding.handlePopRoute(), isFalse);
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    router.push('/more/about');
    await tester.pumpAndSettle();
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/ledger');
    for (final route in ['/accounts_management', '/categories_management']) {
      router.push(route);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final button = tester
          .widget<FloatingActionButton>(find.byType(FloatingActionButton).last);
      expect(button.heroTag, isNull);
      expect(
          find.descendant(
              of: find.byType(FloatingActionButton).last,
              matching: find.byType(Hero)),
          findsNothing);
      await tester.pumpAndSettle();
      router.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
          tester
              .widgetList<FloatingActionButton>(
                  find.byType(FloatingActionButton))
              .where((button) => button.heroTag == null),
          isNotEmpty);
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<FloatingActionButton>(find.byType(FloatingActionButton))
              .heroTag,
          isNotNull);
    }
  });

  testWidgets('ledger scrolling keeps the navigation bar in place',
      (tester) async {
    tester.view.padding = const FakeViewPadding(bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    final harness = LedgerServiceHarness();
    addTearDown(harness.close);
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(harness.db),
      accountUiListProvider.overrideWith((ref) => const AsyncData([])),
      categoryListProvider.overrideWith((ref, type) => Stream.value([])),
      ledgerMonthlyTransactionsProvider.overrideWith((ref, month) =>
          Stream.value(List.generate(
              20,
              (i) => LedgerDayGroup(
                  date: DateTime(month.year, month.month, i + 1),
                  transactions: const [])))),
      ledgerMonthlySummaryProvider.overrideWith((ref, month) => Stream.value(
          const MonthlySummaryUiModel(
              displayBalance: r'$100',
              displayIncome: r'$0',
              displayExpense: r'$0'))),
    ]);
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    final buttonPosition = tester.getTopLeft(find.byType(FloatingActionButton));
    final navTop = tester.getTopLeft(find.byType(NavigationBar)).dy;

    Future<void> expectChromeInPlace() async {
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.getTopLeft(find.byType(NavigationBar)).dy, navTop);
      expect(
          tester.getTopLeft(find.byType(FloatingActionButton)), buttonPosition);
    }

    await tester.drag(
        find.byType(LedgerTransactionList), const Offset(0, -500));
    await expectChromeInPlace();
    await tester.drag(find.byType(PageView), const Offset(-700, 0));
    await expectChromeInPlace();
    await tester.drag(
        find.byType(LedgerTransactionList), const Offset(0, -500));
    await expectChromeInPlace();
    await tester.drag(find.byType(PageView), const Offset(700, 0));
    await expectChromeInPlace();
    await tester.drag(
        find.byType(LedgerTransactionList), const Offset(0, -150));
    await expectChromeInPlace();
    await tester.drag(find.byType(LedgerTransactionList), const Offset(0, 150));
    await expectChromeInPlace();
    await tester.drag(
        find.byType(LedgerTransactionList), const Offset(0, -150));
    await expectChromeInPlace();
    await tester.tap(find.byType(LedgerCompactBalance));
    await expectChromeInPlace();
    router.go('/more');
    await tester.pumpAndSettle();
    // The More tab has no FAB, but the bar keeps its place.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.getTopLeft(find.byType(NavigationBar)).dy, navTop);
    router.go('/accounts_management');
    await tester.pumpAndSettle();
    expect(
        tester.getTopLeft(find.byType(FloatingActionButton)), buttonPosition);
    router.go('/categories_management');
    await tester.pumpAndSettle();
    expect(
        tester.getTopLeft(find.byType(FloatingActionButton)), buttonPosition);
  });

  testWidgets(
      'bottom navigation renders 3 tabs with solid ledger book icon and fab styling',
      (tester) async {
    final harness = LedgerServiceHarness();
    addTearDown(harness.close);
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(harness.db),
      accountUiListProvider.overrideWith((ref) => const AsyncData([])),
      categoryListProvider.overrideWith((ref, type) => Stream.value([])),
      ledgerMonthlyTransactionsProvider
          .overrideWith((ref, month) => Stream.value([])),
      ledgerMonthlySummaryProvider.overrideWith((ref, month) => Stream.value(
          const MonthlySummaryUiModel(
              displayBalance: r'$0',
              displayIncome: r'$0',
              displayExpense: r'$0'))),
    ]);
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.destinations, hasLength(3));
    expect(
      navBar.destinations
          .map((destination) => (destination as NavigationDestination).label)
          .toList(),
      ['Ledger', 'Budget', 'More'],
    );

    final navContext = tester.element(find.byType(NavigationBar));
    final navTheme = NavigationBarTheme.of(navContext);
    // Light mode: white bar, pale cyan selected pill, deep-teal accent.
    expect(navTheme.backgroundColor, const Color(0xFFFFFFFF));
    expect(navTheme.indicatorColor, const Color(0xFFDFF0F7));

    // Selected Ledger tab shows solid book CustomPaint in onSecondaryContainer;
    // unselected tabs show Lucide outline icons.
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byKey(const ValueKey('ledger-selected-book-icon')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(LucideIcons.book),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(LucideIcons.wallet),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(LucideIcons.ellipsis),
      ),
      findsOneWidget,
    );

    final selectedBookTheme = IconTheme.of(
      tester.element(find.byKey(const ValueKey('ledger-selected-book-icon'))),
    );
    expect(selectedBookTheme.color, const Color(0xFF0F4C5C));

    // FAB styling & navigation to /ledger/add.
    final fabTheme = Theme.of(tester.element(find.byType(FloatingActionButton)))
        .floatingActionButtonTheme;
    expect(fabTheme.backgroundColor, const Color(0xFF14637A));
    expect(fabTheme.foregroundColor, const Color(0xFFFFFFFF));
    expect(
      find.descendant(
        of: find.byType(FloatingActionButton),
        matching: find.byIcon(LucideIcons.plus),
      ),
      findsOneWidget,
    );

    // Switch to Budget and More: Ledger reverts to outline LucideIcons.book.
    await tester.tap(find.text('Budget'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byKey(const ValueKey('ledger-selected-book-icon')),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(LucideIcons.book),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(LucideIcons.book),
      ),
      findsOneWidget,
    );

    // Return to Ledger and tap FAB -> TransactionFormScreen.
    await tester.tap(find.text('Ledger'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionFormScreen), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  const tailAccount = AccountEntity(
    id: 'acc-1',
    name: 'Wallet',
    type: AccountType.cash,
    currencyCode: 'USD',
    balanceMinor: 50000,
    archived: false,
    lastUpdatedEventId: 1,
  );
  final tailCategory = CategoryEntity(
    id: 'cat-1',
    name: 'Food',
    iconKey: CategoryTokens.defaultIcons.first.toString(),
    colorInt: CategoryTokens.defaultColor.toARGB32(),
    type: CategoryType.expense,
  );
  final tailThemes = <String, ThemeData>{
    'light': AppTheme.lightTheme,
    'dark': AppTheme.darkTheme,
    'dynamic-light': AppTheme.buildLight(ColorScheme.fromSeed(
      seedColor: const Color(0xFF1A73E8),
      brightness: Brightness.light,
    )),
    'dynamic-dark': AppTheme.buildDark(ColorScheme.fromSeed(
      seedColor: const Color(0xFF1A73E8),
      brightness: Brightness.dark,
    )),
  };

  for (final width in [360.0, 800.0]) {
    for (final entry in tailThemes.entries) {
      testWidgets(
          'last transaction amount clears FAB and visible nav bar (${entry.key} @ ${width.toInt()}dp)',
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
        final container = ProviderContainer(overrides: [
          appDatabaseProvider.overrideWithValue(harness.db),
          accountUiListProvider.overrideWith((ref) => const AsyncData([])),
          categoryListProvider.overrideWith((ref, type) => Stream.value([])),
          ledgerMonthlyTransactionsProvider.overrideWith((ref, month) {
            final days = List.generate(12, (i) {
              final day = 12 - i;
              final date = DateTime(month.year, month.month, day, 12);
              final isLastDay = i == 11;
              if (isLastDay) {
                return LedgerDayGroup(
                  date: date,
                  transactions: [
                    TransactionTileUiModel(
                      id: 'tx-last',
                      amount: 4250,
                      type: TransactionKind.expense,
                      date: date,
                      note: 'Late snack',
                      category: tailCategory,
                      account: tailAccount,
                      displayAmount: '42.50',
                      displaySign: '-',
                    ),
                  ],
                );
              }
              return LedgerDayGroup(
                date: date,
                transactions: [
                  TransactionTileUiModel(
                    id: 'tx-$i',
                    amount: 1000 + i,
                    type: TransactionKind.expense,
                    date: date,
                    note: 'Meal $i',
                    category: tailCategory,
                    account: tailAccount,
                    displayAmount: '10.0$i',
                    displaySign: '-',
                  ),
                ],
              );
            });
            return Stream.value(days);
          }),
          ledgerMonthlySummaryProvider.overrideWith((ref, month) =>
              Stream.value(const MonthlySummaryUiModel(
                  displayBalance: r'$500.00',
                  displayIncome: r'$0.00',
                  displayExpense: r'$152.50'))),
        ]);
        addTearDown(container.dispose);

        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: container.read(goRouterProvider),
            theme: entry.value,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ));
        await tester.pumpAndSettle();

        final listFinder = find.byType(LedgerTransactionList);
        final controller =
            tester.widget<LedgerTransactionList>(listFinder).controller;
        expect(controller.position.maxScrollExtent, greaterThan(0),
            reason: '${entry.key}@$width should scroll');

        void assertLastAmountClearsChrome({required bool expectNavBarVisible}) {
          final viewportRect = tester.getRect(listFinder);
          final amountFinder = find.text(r'-$42.50');
          expect(amountFinder, findsOneWidget,
              reason: 'last amount missing in ${entry.key}@$width');
          final amountRect = tester.getRect(amountFinder);
          final fabRect = tester.getRect(find.byType(FloatingActionButton));

          expect(amountRect.top, greaterThanOrEqualTo(viewportRect.top),
              reason: '${entry.key}@$width amount clipped at top');
          expect(amountRect.bottom, lessThanOrEqualTo(viewportRect.bottom),
              reason: '${entry.key}@$width amount clipped at bottom');
          expect(amountRect.left, greaterThanOrEqualTo(viewportRect.left));
          expect(amountRect.right, lessThanOrEqualTo(viewportRect.right));
          expect(amountRect.overlaps(fabRect), isFalse,
              reason: '${entry.key}@$width amount overlaps FAB');

          if (expectNavBarVisible) {
            final navRect = tester.getRect(find.byType(NavigationBar));
            expect(amountRect.overlaps(navRect), isFalse,
                reason: '${entry.key}@$width amount overlaps NavigationBar');
          }
        }

        // 1. At maxScrollExtent with NavigationBar visible.
        controller.jumpTo(controller.position.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(find.byType(NavigationBar), findsOneWidget);
        assertLastAmountClearsChrome(expectNavBarVisible: true);

        // 2. Scroll down by drag: the bar stays put, the amount still clears
        // both the FAB and the bar.
        controller.jumpTo(0);
        await tester.pumpAndSettle();
        for (var step = 0; step < 5; step++) {
          await tester.drag(listFinder, const Offset(0, -600));
          await tester.pumpAndSettle();
        }
        expect(find.byType(NavigationBar), findsOneWidget);
        assertLastAmountClearsChrome(expectNavBarVisible: true);

        // 3. Slight scroll up keeps it visible too.
        await tester.drag(listFinder, const Offset(0, 40));
        await tester.pumpAndSettle();
        expect(find.byType(NavigationBar), findsOneWidget);
        assertLastAmountClearsChrome(expectNavBarVisible: true);
      });
    }
  }

  testWidgets(
      'deleting the single remaining transaction leaves empty month unscrollable without tail spacer',
      (tester) async {
    const account = AccountEntity(
      id: 'acc-1',
      name: 'Wallet',
      type: AccountType.cash,
      currencyCode: 'USD',
      balanceMinor: 5000,
      archived: false,
      lastUpdatedEventId: 1,
    );
    final category = CategoryEntity(
      id: 'cat-1',
      name: 'Food',
      iconKey: CategoryTokens.defaultIcons.first.toString(),
      colorInt: CategoryTokens.defaultColor.toARGB32(),
      type: CategoryType.expense,
    );

    final harness = LedgerServiceHarness();
    addTearDown(harness.close);
    final changes = StreamController<List<LedgerDayGroup>>.broadcast();
    addTearDown(changes.close);
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(harness.db),
      accountUiListProvider.overrideWith((ref) => const AsyncData([])),
      categoryListProvider.overrideWith((ref, type) => Stream.value([])),
      ledgerMonthlyTransactionsProvider
          .overrideWith((ref, month) => changes.stream),
      ledgerMonthlySummaryProvider.overrideWith((ref, month) => Stream.value(
          const MonthlySummaryUiModel(
              displayBalance: r'$50.00',
              displayIncome: r'$0.00',
              displayExpense: r'$12.00'))),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: container.read(goRouterProvider),
        theme: AppTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pump();

    final now = DateTime.now();
    final date = DateTime(now.year, now.month, 15, 12);
    changes.add([
      LedgerDayGroup(
        date: date,
        transactions: [
          TransactionTileUiModel(
            id: 'tx-only',
            amount: 1200,
            type: TransactionKind.expense,
            date: date,
            note: 'Coffee',
            category: category,
            account: account,
            displayAmount: '12.00',
            displaySign: '-',
          ),
        ],
      ),
    ]);
    await tester.pumpAndSettle();

    final listFinder = find.byType(LedgerTransactionList);
    final scrollFinder = find.descendant(
      of: listFinder,
      matching: find.byType(CustomScrollView),
    );
    expect(
      tester.widget<CustomScrollView>(scrollFinder).physics,
      isNot(isA<NeverScrollableScrollPhysics>()),
    );
    expect(find.text(r'-$12.00'), findsOneWidget);

    // Delete the only transaction -> empty month restores NeverScrollableScrollPhysics.
    changes.add(const []);
    await tester.pumpAndSettle();

    expect(find.byType(LedgerEmpty), findsOneWidget);
    expect(
      tester.widget<CustomScrollView>(scrollFinder).physics,
      isA<NeverScrollableScrollPhysics>(),
    );
    final controller =
        tester.widget<LedgerTransactionList>(listFinder).controller;
    expect(controller.offset, 0);
    await tester.drag(listFinder, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(controller.offset, 0);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
