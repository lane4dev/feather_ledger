import 'dart:async';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/presentation/providers/balance_visibility_provider.dart';
import 'package:feather_ledger/features/ledger/presentation/screens/ledger_screen.dart';
import 'package:feather_ledger/features/ledger/presentation/models/ledger_day_group.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_header.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_transaction_list.dart';
import 'package:feather_ledger/shared/presentation/models/monthly_summary_ui_model.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_month_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _VisibleBalance extends BalanceVisibilityController {
  @override
  Future<bool> build() async => true;
}

void main() {
  final today = DateTime.now();
  final current = DateTime(today.year, today.month);
  final next = DateTime(today.year, today.month + 1);
  const first = MonthlySummaryUiModel(
      displayBalance: r'$100', displayIncome: r'$100', displayExpense: r'$0');
  const second = MonthlySummaryUiModel(
      displayBalance: r'$200', displayIncome: r'$200', displayExpense: r'$0');

  testWidgets('scrolling shows the month and balance; tapping returns to top',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
        overrides: [
          balanceVisibilityControllerProvider.overrideWith(_VisibleBalance.new),
          displayCurrencySymbolProvider.overrideWith((ref) => r'$'),
          ledgerMonthlySummaryProvider
              .overrideWith((ref, month) => Stream.value(first)),
          ledgerMonthlyTransactionsProvider.overrideWith((ref, month) =>
              Stream.value(List.generate(
                  20,
                  (i) => LedgerDayGroup(
                      date: DateTime(month.year, month.month, i + 1),
                      transactions: const [])))),
        ],
        child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LedgerScreen())));
    await tester.pumpAndSettle();
    expect(find.byType(LedgerMonthSwitcher), findsOneWidget);
    await tester.drag(
        find.byType(LedgerTransactionList), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.byType(LedgerMonthSwitcher), findsNothing);
    expect(find.byType(LedgerCompactBalance), findsOneWidget);
    expect(find.text(DateFormat.yMMM('en').format(current)), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-700, 0));
    await tester.pumpAndSettle();
    expect(find.byType(LedgerMonthSwitcher), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(700, 0));
    await tester.pumpAndSettle();
    expect(find.byType(LedgerCompactBalance), findsOneWidget);
    await tester.tap(find.byType(LedgerCompactBalance));
    await tester.pumpAndSettle();
    expect(find.byType(LedgerMonthSwitcher), findsOneWidget);
    expect(find.byType(LedgerCompactBalance), findsNothing);
  });

  testWidgets('keeps the summary layout while another month loads',
      (tester) async {
    final streams = <DateTime, StreamController<MonthlySummaryUiModel>>{};
    addTearDown(() async {
      for (final stream in streams.values) {
        await stream.close();
      }
    });
    await tester.pumpWidget(ProviderScope(
        overrides: [
          balanceVisibilityControllerProvider.overrideWith(_VisibleBalance.new),
          displayCurrencySymbolProvider.overrideWith((ref) => r'$'),
          ledgerMonthlySummaryProvider.overrideWith((ref, month) => streams
              .putIfAbsent(month, () => StreamController.broadcast())
              .stream),
          ledgerMonthlyTransactionsProvider
              .overrideWith((ref, month) => Stream.value([])),
        ],
        child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LedgerScreen())));
    await tester.pump();
    streams[current]!.add(first);
    await tester.pump();
    await tester.pump();
    final card = find.descendant(
        of: find.byType(LedgerHeader), matching: find.byType(Card));
    final height = tester.getSize(card).height;
    expect(find.text(r'$100'), findsWidgets);
    expect(streams.containsKey(next), isTrue,
        reason: 'the next month is prefetched');

    await tester.tap(find.byIcon(LucideIcons.chevronRight));
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text(r'$100'), findsNothing);
    expect(find.text('—'), findsWidgets);
    expect(tester.getSize(card).height, closeTo(height, 0.01));
    streams[next]!.add(second);
    await tester.pump();
    await tester.pump();
    expect(find.text(r'$200'), findsWidgets);
    expect(tester.getSize(card).height, closeTo(height, 0.01));
  });

  testWidgets(
      'uses the prefetched adjacent month without a loading placeholder',
      (tester) async {
    final subscriptions = <DateTime>[];
    await tester.pumpWidget(ProviderScope(
        overrides: [
          balanceVisibilityControllerProvider.overrideWith(_VisibleBalance.new),
          displayCurrencySymbolProvider.overrideWith((ref) => r'$'),
          ledgerMonthlySummaryProvider.overrideWith((ref, month) {
            subscriptions.add(month);
            return Stream.value(month == next ? second : first);
          }),
          ledgerMonthlyTransactionsProvider
              .overrideWith((ref, month) => Stream.value([])),
        ],
        child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LedgerScreen())));
    await tester.pump();
    await tester.pump();
    expect(subscriptions,
        containsAll([current, next, DateTime(today.year, today.month - 1)]));
    await tester.tap(find.byIcon(LucideIcons.chevronRight));
    await tester.pumpAndSettle();
    expect(find.text(r'$200'), findsWidgets);
    expect(find.text('—'), findsNothing);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-700, 0));
    await tester.pumpAndSettle();
    final afterNext = DateTime(today.year, today.month + 2);
    expect(find.text(DateFormat.yMMMM('en').format(afterNext)), findsOneWidget);
  });

  testWidgets('a distant month selection stays on the selected month',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
        overrides: [
          balanceVisibilityControllerProvider.overrideWith(_VisibleBalance.new),
          displayCurrencySymbolProvider.overrideWith((ref) => r'$'),
          ledgerMonthlySummaryProvider
              .overrideWith((ref, month) => Stream.value(first)),
          ledgerMonthlyTransactionsProvider
              .overrideWith((ref, month) => Stream.value([])),
        ],
        child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LedgerScreen())));
    await tester.pumpAndSettle();
    await tester.tap(find.text(DateFormat.yMMMM('en').format(current)));
    await tester.pumpAndSettle();
    final target = DateTime(current.year + 1, current.month);
    await tester.tap(find.byTooltip('Next Year'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byType(FeatherMonthPicker),
        matching: find.text(DateFormat.MMM('en').format(target))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final movingPage = tester.widget<PageView>(find.byType(PageView).first);
    final startIndex = (current.year - 2000) * 12 + current.month - 1;
    final targetIndex = (target.year - 2000) * 12 + target.month - 1;
    expect(movingPage.controller!.page, greaterThan(startIndex));
    expect(movingPage.controller!.page, lessThan(targetIndex));
    await tester.pumpAndSettle();
    expect(find.text(DateFormat.yMMMM('en').format(target)), findsOneWidget);
    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.controller!.page, closeTo(targetIndex, 0.01));
  });

  testWidgets('dragging the header moves the card and list together',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
        overrides: [
          balanceVisibilityControllerProvider.overrideWith(_VisibleBalance.new),
          displayCurrencySymbolProvider.overrideWith((ref) => r'$'),
          ledgerMonthlySummaryProvider.overrideWith(
              (ref, month) => Stream.value(month == next ? second : first)),
          ledgerMonthlyTransactionsProvider
              .overrideWith((ref, month) => Stream.value([])),
        ],
        child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LedgerScreen())));
    await tester.pumpAndSettle();
    final page = find.byKey(ValueKey(current));
    final header =
        find.descendant(of: page, matching: find.byType(LedgerHeader));
    final list =
        find.descendant(of: page, matching: find.byType(LedgerTransactionList));
    final headerX = tester.getTopLeft(header).dx;
    final listX = tester.getTopLeft(list).dx;
    final search = find.byIcon(LucideIcons.search);
    final switcher = find.byType(LedgerMonthSwitcher);
    final searchPosition = tester.getTopLeft(search);
    final switcherPosition = tester.getTopLeft(switcher);
    final gesture = await tester.startGesture(tester.getCenter(header));
    await gesture.moveBy(const Offset(-50, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-150, 0));
    await tester.pump();
    expect(tester.getTopLeft(header).dx, lessThan(headerX - 50));
    expect(tester.getTopLeft(list).dx - listX,
        closeTo(tester.getTopLeft(header).dx - headerX, 0.1));
    expect(tester.getTopLeft(search), searchPosition);
    expect(tester.getTopLeft(switcher), switcherPosition);
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
