import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/presentation/models/ledger_day_group.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/theme/ledger_theme.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_timeline.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/time_anchor.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/transaction_tile.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';

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

  for (final scenario in [
    (
      name: 'pending-only (>=2 rows, no countable total)',
      pending: [true, true],
      displayExpense: null as String?,
      dividers: 0,
    ),
    (
      name: 'single posted row (<2 rows)',
      pending: [false],
      displayExpense: r'$1.00' as String?,
      dividers: 0,
    ),
    (
      name: 'posted-only (>=2 rows with countable total)',
      pending: [false, false],
      displayExpense: r'$2.00' as String?,
      dividers: 1,
    ),
    (
      name: 'mixed (>=2 rows with countable total)',
      pending: [false, true],
      displayExpense: r'$1.00' as String?,
      dividers: 1,
    ),
    (
      name: 'posted-only excluded/transfer (>=2 rows, no countable total)',
      pending: [false, false],
      displayExpense: null as String?,
      dividers: 0,
    ),
  ]) {
    testWidgets('${scenario.name} shows the appropriate day divider',
        (tester) async {
      final rows = [
        for (var index = 0; index < scenario.pending.length; index++)
          TransactionTileUiModel(
            id: 'row-$index',
            amount: 100,
            type: TransactionKind.expense,
            date: DateTime(2026, 11, 24),
            note: 'Row $index',
            account: account,
            displayAmount: '1.00',
            displaySign: '-',
            isPending: scenario.pending[index],
          ),
      ];
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: CustomScrollView(slivers: [
            LedgerTimeline(days: [
              LedgerDayGroup(
                date: DateTime(2026, 11, 24),
                transactions: rows,
                displayExpense: scenario.displayExpense,
              ),
            ]),
          ]),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(FeatherDivider), findsNWidgets(scenario.dividers));
      expect(anchor(11, 24), findsOneWidget);
      expect(find.byType(TransactionTile), findsNWidgets(rows.length));
      expect(tester.takeException(), isNull);
    });
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

  testWidgets('uses AppCard.day with surfaceContainerLow, 18dp radius, and 12-16dp gap',
      (tester) async {
    final dayGroups = [
      LedgerDayGroup(
        date: DateTime(2026, 11, 24),
        transactions: [
          TransactionTileUiModel(
            id: 'd1',
            amount: 1000,
            type: TransactionKind.expense,
            date: DateTime(2026, 11, 24),
            note: 'Lunch',
            account: account,
            displayAmount: '10.00',
            displaySign: '-',
          ),
        ],
        displayExpense: r'$10.00',
      ),
      LedgerDayGroup(
        date: DateTime(2026, 11, 23),
        transactions: [
          TransactionTileUiModel(
            id: 'd2',
            amount: 2000,
            type: TransactionKind.expense,
            date: DateTime(2026, 11, 23),
            note: 'Dinner',
            account: account,
            displayAmount: '20.00',
            displaySign: '-',
          ),
        ],
        displayExpense: r'$20.00',
      ),
    ];

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('en')],
      home: Scaffold(
        body: CustomScrollView(
          slivers: [LedgerTimeline(days: dayGroups)],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final cards = tester.widgetList<Card>(find.byType(Card)).toList();
    expect(cards, hasLength(2));
    expect(cards.first.color, AppTheme.darkTheme.colorScheme.surfaceContainerLow);
    final shape = cards.first.shape as RoundedRectangleBorder;
    expect(
      shape.borderRadius,
      BorderRadius.circular(AppTheme.metrics.dayCardRadius),
    );

    final firstCardBox = tester.getRect(find.byType(AppCard).at(0));
    final secondCardBox = tester.getRect(find.byType(AppCard).at(1));
    final gap = secondCardBox.top - firstCardBox.bottom;
    expect(gap, inInclusiveRange(12.0, 16.0));
  });

  testWidgets('single row omits subtotal footer blank space and mixed zh day totals only posted expense',
      (tester) async {
    const food = CategoryEntity(
      id: 'cat_food',
      name: '餐饮',
      iconKey: '1',
      colorInt: 0xFF0F766E,
      type: CategoryType.expense,
    );
    final singleDay = LedgerDayGroup.group([
      TransactionTileUiModel(
        id: 'single',
        amount: 1000,
        type: TransactionKind.expense,
        date: DateTime(2026, 11, 24),
        note: '早餐',
        category: food,
        account: account,
        displayAmount: '10.00',
        displaySign: '-',
      ),
    ], currencySymbol: '¥');

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CustomScrollView(
          slivers: [LedgerTimeline(days: singleDay, currencySymbol: '¥')],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(FeatherDivider), findsNothing);
    expect(find.textContaining('支出'), findsNothing);
    // Card height equals single row height (no blank subtotal footer space).
    expect(
      tester.getSize(find.byType(AppCard)).height,
      closeTo(tester.getSize(find.byType(TransactionTile)).height, 0.5),
    );

    // Mixed day: posted ¥10 + pending ¥20 -> subtotal shows 支出: ¥10.00.
    final mixedDay = LedgerDayGroup.group([
      TransactionTileUiModel(
        id: 'posted',
        amount: 1000,
        type: TransactionKind.expense,
        date: DateTime(2026, 11, 24, 12),
        note: '午餐',
        category: food,
        account: account,
        displayAmount: '10.00',
        displaySign: '-',
      ),
      TransactionTileUiModel(
        id: 'pending',
        amount: 2000,
        type: TransactionKind.expense,
        date: DateTime(2026, 11, 24, 18),
        note: '房租',
        category: food,
        account: account,
        displayAmount: '20.00',
        displaySign: '-',
        isPending: true,
        scheduledStatus: ScheduledTransactionStatus.scheduled,
      ),
    ], currencySymbol: '¥');

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CustomScrollView(
          slivers: [LedgerTimeline(days: mixedDay, currencySymbol: '¥')],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(FeatherDivider), findsOneWidget);
    expect(find.text('支出: '), findsOneWidget);
    expect(find.text('¥10.00'), findsOneWidget);
    expect(find.text('¥30.00'), findsNothing);
  });

  testWidgets('TimeAnchor highlights local today with circular primaryContainer badge',
      (tester) async {
    final today = DateTime(2026, 11, 24);
    final yesterday = DateTime(2026, 11, 23);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('en')],
      home: Scaffold(
        body: Row(
          children: [
            TimeAnchor(date: today, today: today),
            TimeAnchor(date: yesterday, today: today),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final todayContainer = tester.widget<Container>(find.descendant(
      of: find.byWidgetPredicate((w) => w is TimeAnchor && w.date == today),
      matching: find.byType(Container),
    ));
    final decoration = todayContainer.decoration! as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.color, AppTheme.darkTheme.colorScheme.primaryContainer);

    final todayText = tester.widget<Text>(find.text('24'));
    expect(todayText.style?.color,
        AppTheme.darkTheme.colorScheme.onPrimaryContainer);

    // Non-today has no circular badge container.
    expect(
      find.descendant(
        of: find.byWidgetPredicate((w) => w is TimeAnchor && w.date == yesterday),
        matching: find.byType(Container),
      ),
      findsNothing,
    );
    expect(
      tester.getSize(find.byType(TimeAnchor).first).width,
      LedgerTheme.colAnchorWidth,
    );
  });

  testWidgets('TimeAnchor renders numeric day without 日 suffix in Chinese locales',
      (tester) async {
    final targetDate = DateTime(2026, 11, 24);
    for (final locale in const [
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      Locale('zh'),
    ]) {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TimeAnchor(date: targetDate, today: DateTime(2026, 11, 1)),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('24'), findsOneWidget);
      expect(find.text('24日'), findsNothing);
      expect(
        find.text(DateFormat('E', locale.toString()).format(targetDate)),
        findsOneWidget,
      );
    }
  });

  testWidgets('renders cleanly across light/dark/dynamic themes at 360dp and 800dp and large textScale',
      (tester) async {
    final dynamicLight = AppTheme.buildLight(
      ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.light),
    );
    final dynamicDark = AppTheme.buildDark(
      ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
    );

    const longAccount = AccountEntity(
      id: 'acc_long',
      name: 'Super Long Everyday Checking Account Name For Narrow Width Overflow Verification',
      type: AccountType.bank,
      currencyCode: 'USD',
      balanceMinor: 0,
      archived: false,
      lastUpdatedEventId: 0,
    );
    const food = CategoryEntity(
      id: 'cat_food',
      name: 'Dining Out',
      iconKey: '1',
      colorInt: 0xFF0F766E,
      type: CategoryType.expense,
    );

    final groups = LedgerDayGroup.group([
      TransactionTileUiModel(
        id: 't1',
        amount: 123456,
        type: TransactionKind.expense,
        date: DateTime(2026, 11, 24, 18),
        note: 'Team Dinner With Extended Note Text',
        category: food,
        account: longAccount,
        displayAmount: '1234.56',
        displaySign: '-',
        isPending: true,
        scheduledStatus: ScheduledTransactionStatus.failed,
      ),
      TransactionTileUiModel(
        id: 't2',
        amount: 5000,
        type: TransactionKind.income,
        date: DateTime(2026, 11, 24, 9),
        note: null,
        category: food,
        account: longAccount,
        displayAmount: '50.00',
        displaySign: '+',
      ),
    ], currencySymbol: r'$');

    for (final theme in [
      AppTheme.lightTheme,
      AppTheme.darkTheme,
      dynamicLight,
      dynamicDark,
    ]) {
      for (final width in [360.0, 800.0]) {
        await tester.pumpWidget(MediaQuery(
          data: MediaQueryData(
            size: Size(width, 640),
            textScaler: const TextScaler.linear(1.6),
          ),
          child: MaterialApp(
            theme: theme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: const [Locale('en')],
            home: Scaffold(
              body: SizedBox(
                width: width,
                child: CustomScrollView(
                  slivers: [
                    LedgerTimeline(days: groups, currencySymbol: r'$'),
                  ],
                ),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text(r'-$1234.56'), findsOneWidget);
        expect(find.text('Auto-post failed'), findsOneWidget);
        final accountText = tester.widget<Text>(find.text(longAccount.name).first);
        expect(accountText.overflow, TextOverflow.ellipsis);
        expect(accountText.maxLines, 1);
        expect(tester.takeException(), isNull);
      }
    }
  });
}
