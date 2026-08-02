import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/presentation/models/ledger_day_group.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_timeline.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/time_anchor.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/transaction_tile.dart';

void main() {
  const account = AccountEntity(
    id: 'cash',
    name: 'Cash',
    type: AccountType.cash,
    currencyCode: 'USD',
    balanceMinor: 0,
    archived: false,
    lastUpdatedEventId: 0,
  );

  List<LedgerDayGroup> days(int month, {int transactionsPerDay = 5}) => [
        for (var day = 24; day >= 20; day--)
          LedgerDayGroup(
            date: DateTime(2026, month, day),
            displayExpense: r'$5.00',
            transactions: [
              for (var index = 0; index < transactionsPerDay; index++)
                TransactionTileUiModel(
                  id: '$month-$day-$index',
                  amount: 100,
                  type: TransactionKind.expense,
                  date: DateTime(2026, month, day),
                  note: 'Transaction $month-$day-$index',
                  account: account,
                  displayAmount: '1.00',
                  displaySign: '-',
                  isPending: index == 1,
                  seriesId: index == 1 ? 'series' : null,
                ),
            ],
          ),
      ];

  Finder anchor(int month, int day) => find.byWidgetPredicate(
        (widget) =>
            widget is TimeAnchor && widget.date == DateTime(2026, month, day),
      );

  Future<ScrollPosition> pumpTimeline(
    WidgetTester tester, {
    int transactionsPerDay = 5,
    ValueChanged<TransactionTileUiModel>? onTap,
  }) async {
    final outerController = ScrollController();
    addTearDown(outerController.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('en')],
      home: Scaffold(
        body: NestedScrollView(
          controller: outerController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: const SliverAppBar(
                pinned: true,
                expandedHeight: 180,
                title: Text('Ledger'),
              ),
            ),
          ],
          body: PageView.builder(
            itemCount: 2,
            itemBuilder: (context, page) => CustomScrollView(
              key: PageStorageKey('month-$page'),
              slivers: [
                SliverOverlapInjector(
                  handle:
                      NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                ),
                LedgerTimeline(
                  overlapHandle:
                      NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  days: days(11 - page, transactionsPerDay: transactionsPerDay),
                  onTransactionTap: onTap,
                ),
              ],
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    // Collapse the outer header first, just as a vertical gesture does in
    // production. Assertions then use the inner list's own scroll position.
    outerController.jumpTo(180 - kToolbarHeight);
    await tester.pumpAndSettle();
    return Scrollable.of(tester.element(find.byType(TransactionTile).first))
        .position;
  }

  for (final count in [1, 5]) {
    testWidgets(
        'next date pushes the pinned date out ($count transactions/day)',
        (tester) async {
      final position = await pumpTimeline(tester, transactionsPerDay: count);
      final pinLine = tester.getBottomLeft(find.byType(AppBar)).dy;
      final nextStart = tester.getTopLeft(anchor(11, 23)).dy;
      final height = tester.getSize(anchor(11, 24)).height;
      expect(
          tester.getTopLeft(anchor(11, 24)).dy,
          closeTo(
              tester.getTopLeft(find.byType(TransactionTile).first).dy, 0.01),
          reason:
              'the date shares the first row, without extra header spacing');

      // Before contact, the first date stays pinned beneath the app bar.
      position.jumpTo(nextStart - pinLine - height - 8);
      await tester.pump();
      expect(tester.getTopLeft(anchor(11, 24)).dy, closeTo(pinLine, 0.01));

      // Halfway through contact, both dates move together without overlap.
      position.jumpTo(nextStart - pinLine - height / 2);
      await tester.pump();
      expect(tester.getTopLeft(anchor(11, 24)).dy,
          closeTo(pinLine - height / 2, 0.01));
      expect(tester.getBottomLeft(anchor(11, 24)).dy,
          closeTo(tester.getTopLeft(anchor(11, 23)).dy, 0.01));

      position.jumpTo(nextStart - pinLine);
      await tester.pump();
      expect(tester.getTopLeft(anchor(11, 23)).dy, closeTo(pinLine, 0.01));

      // Reverse scrolling restores the earlier date at the same boundary.
      position.jumpTo(nextStart - pinLine - height / 2);
      await tester.pump();
      expect(tester.getBottomLeft(anchor(11, 24)).dy,
          closeTo(tester.getTopLeft(anchor(11, 23)).dy, 0.01));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('recorded and pending rows remain tappable beside a pinned date',
      (tester) async {
    final tapped = <TransactionTileUiModel>[];
    final position = await pumpTimeline(tester, onTap: tapped.add);
    position.jumpTo(20);
    await tester.pump();

    await tester.tap(find.text('Transaction 11-24-0'));
    await tester.tap(find.text('Transaction 11-24-1'));
    expect(tapped.map((tx) => tx.id), ['11-24-0', '11-24-1']);
    expect(tapped.last.isPending, isTrue);
    // The date rail used to be part of the row's hit target. Keep that full
    // width rather than letting the pinned date intercept the tap.
    await tester.tapAt(Offset(
      8,
      tester.getBottomLeft(find.byType(TransactionTile).first).dy - 4,
    ));
    expect(tapped.last.id, '11-24-0');
    expect(tapped, hasLength(3));

    await tester.drag(find.byType(PageView), const Offset(-700, 0));
    await tester.pumpAndSettle();
    expect(anchor(10, 24), findsOneWidget);
    await tester.tap(find.text('Transaction 10-24-0'));
    expect(tapped.last.id, '10-24-0');
    expect(tester.takeException(), isNull);
  });
}
