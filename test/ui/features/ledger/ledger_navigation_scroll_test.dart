import 'dart:async';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/router/app_router.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/features/ledger/presentation/models/ledger_day_group.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_transaction_list.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_header.dart';
import 'package:feather_ledger/shared/presentation/models/monthly_summary_ui_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/event_sourcing/ledger_service_harness.dart';

void main() {
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

  testWidgets('deleting the last records restores navigation', (tester) async {
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
    expect(find.byType(NavigationBar), findsNothing);
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

  testWidgets('ledger scrolling hides and restores navigation', (tester) async {
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
    final visibleTop = tester.getTopLeft(find.byType(NavigationBar)).dy;
    await tester.drag(
        find.byType(LedgerTransactionList), const Offset(0, -500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
        tester.getTopLeft(find.byType(FloatingActionButton)), buttonPosition);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.getTopLeft(find.byType(NavigationBar)).dy,
        greaterThan(visibleTop));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(
        tester.getTopLeft(find.byType(FloatingActionButton)), buttonPosition);
    await tester.drag(find.byType(PageView), const Offset(-700, 0));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.drag(
        find.byType(LedgerTransactionList), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    await tester.drag(find.byType(PageView), const Offset(700, 0));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.drag(
        find.byType(LedgerTransactionList), const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    await tester.drag(find.byType(LedgerTransactionList), const Offset(0, 150));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.drag(
        find.byType(LedgerTransactionList), const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.byType(LedgerCompactBalance));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.drag(
        find.byType(LedgerTransactionList), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    router.go('/more');
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    router.go('/accounts_management');
    await tester.pumpAndSettle();
    expect(
        tester.getTopLeft(find.byType(FloatingActionButton)), buttonPosition);
    router.go('/categories_management');
    await tester.pumpAndSettle();
    expect(
        tester.getTopLeft(find.byType(FloatingActionButton)), buttonPosition);
  });
}
