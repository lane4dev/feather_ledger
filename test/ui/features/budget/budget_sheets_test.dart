import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/budget/domain/entities/budget_entities.dart';
import 'package:feather_ledger/features/budget/domain/services/budget_service.dart';
import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';
import 'package:feather_ledger/features/budget/presentation/models/budget_ui_models.dart';
import 'package:feather_ledger/features/budget/presentation/screens/budget_category_detail_screen.dart';
import 'package:feather_ledger/features/budget/presentation/widgets/budget_edit_sheet.dart';
import 'package:feather_ledger/features/budget/presentation/widgets/budget_note_card.dart';
import 'package:feather_ledger/features/ledger/data/repositories/ledger_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/shared/presentation/widgets/transaction_list_tile.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_amount_input.dart';

class _StubBudgetService implements BudgetService {
  final MonthBudgetSummary summary;
  final Stream<MonthBudgetSummary>? updates;
  bool hasFuture = false;
  bool failFutureProbe = false;
  Result<void>? clearResult;
  String? savedNote;
  BudgetEditScope? lastScope;
  int? lastAmountMinor;
  int clearCalls = 0;

  _StubBudgetService(this.summary, {this.updates});

  @override
  Stream<MonthBudgetSummary> watchMonthBudget({
    required String currencyCode,
    required YearMonth month,
  }) async* {
    yield summary;
    if (updates != null) yield* updates!;
  }

  @override
  Stream<CategoryBudgetHint> watchTransactionBudgetHint({
    required String currencyCode,
    required YearMonth month,
    required String categoryId,
  }) =>
      const Stream.empty();

  @override
  Future<bool> hasFutureRulesAfter({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
  }) async {
    if (failFutureProbe) throw StateError('database is closed');
    return hasFuture;
  }

  @override
  Future<Result<void>> setCategoryBudget({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
    required int amountMinor,
    required BudgetEditScope scope,
  }) async {
    lastAmountMinor = amountMinor;
    lastScope = scope;
    return unitResult;
  }

  @override
  Future<Result<void>> clearCategoryBudget({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
    required BudgetEditScope scope,
  }) async {
    lastScope = scope;
    clearCalls++;
    return clearResult ?? unitResult;
  }

  @override
  Future<Result<void>> saveReviewNote({
    required String currencyCode,
    required YearMonth month,
    String? categoryId,
    required String note,
  }) async {
    if (note.trim().runes.length > 500) {
      return const Result.failure(
          LedgerErrorCode.budgetNoteTooLong, 'too long');
    }
    savedNote = note.trim();
    return unitResult;
  }
}

class _StubLedgerRepository implements LedgerRepository {
  @override
  Future<TransactionEntity?> getTransaction(String id) async {
    return TransactionEntity(
      id: id,
      note: 'Lunch',
      amount: -4500,
      type: TransactionKind.expense,
      date: DateTime(2026, 5, 10),
      eventId: 1,
      account: const AccountEntity(
        id: 'acc-1',
        name: 'Cash',
        type: AccountType.cash,
        currencyCode: 'USD',
        balanceMinor: 10000,
        archived: false,
        lastUpdatedEventId: 1,
      ),
      category: const CategoryEntity(
        id: 'dining',
        name: 'Dining',
        iconKey: 'utensils',
        colorInt: 0xFFE65100,
        type: CategoryType.expense,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  MonthBudgetSummary buildSummary({
    bool includeMore = false,
    bool archived = false,
    bool unbudgeted = false,
  }) {
    final contributions = [
      BudgetContributionTx(
        transactionId: 'tx-1',
        sourceScheduledBillId: null,
        scheduledBillId: null,
        description: 'Lunch',
        occurredAt: DateTime(2026, 5, 10),
        amountMinor: 45000,
        isPending: false,
        accountName: 'Cash',
      ),
      if (includeMore) ...[
        for (var i = 2; i <= 4; i++)
          BudgetContributionTx(
            transactionId: 'tx-$i',
            sourceScheduledBillId: i == 4 ? 'bill-4' : null,
            scheduledBillId: i == 4 ? 'bill-4' : null,
            description: 'Expense $i',
            occurredAt: DateTime(2026, 5, i),
            amountMinor: 10000 ~/ i,
            isPending: i == 4,
            accountName: 'Cash',
          ),
      ],
    ];
    final dining = CategoryBudgetSummary(
      categoryId: 'dining',
      categoryName: 'Dining',
      iconKey: 'utensils',
      colorInt: 0xFFE65100,
      isArchived: archived,
      archiveYm: archived ? const YearMonth(2026, 5) : null,
      budgetMinor: unbudgeted ? null : 100000,
      hasFutureRulesAfter: false,
      committedActualMinor: 0,
      discretionaryActualMinor: 45000,
      actualMinor: 45000,
      pendingMinor: 0,
      projectedRemainingMinor: 55000,
      lastMonthActualMinor: 80000,
      threeMonthAvgMinor: 75000,
      committedBaselineMinor: 0,
      isAnomaly: false,
      anomalyDeltaRatio: null,
      riskLevel: BudgetRiskLevel.inBudget,
      sixMonthTrend: const [
        BudgetTrendPoint(
          month: YearMonth(2026, 5),
          budgetMinor: 100000,
          actualMinor: 45000,
          pendingMinor: 0,
          hasReviewNote: false,
        ),
      ],
      topTransactions: contributions.take(3).toList(),
      allTransactions: contributions,
      reviewNote: 'Old note',
    );
    return MonthBudgetSummary(
      currencyCode: 'USD',
      month: const YearMonth(2026, 5),
      mode: BudgetMode.track,
      hasAnyActiveAccount: true,
      totalBudgetMinor: 100000,
      budgetedActualMinor: 45000,
      budgetedPendingMinor: 0,
      projectedRemainingMinor: 55000,
      budgetedRemainingActualMinor: 55000,
      allExpenseActualMinor: 45000,
      allExpensePendingMinor: 0,
      unbudgetedActualMinor: 0,
      unbudgetedPendingMinor: 0,
      inBudgetCount: 1,
      budgetedCategoryCount: 1,
      complianceRate: 1.0,
      hasAnyBudget: true,
      hasUnbudgetedActivity: false,
      hasLeftoverPendingInReview: false,
      budgetedCategories: archived || unbudgeted ? const [] : [dining],
      unbudgetedActiveCategories: unbudgeted ? [dining] : const [],
      remainingActiveCategories: archived ? [dining] : const [],
      overBudgetTop3: const [],
      underBudgetTop3: const [],
      unbudgetedAlertsTop3: const [],
      monthTrend6Months: const [
        BudgetTrendPoint(
          month: YearMonth(2026, 5),
          budgetMinor: 100000,
          actualMinor: 45000,
          pendingMinor: 0,
          hasReviewNote: false,
        ),
      ],
      monthReviewNote: null,
    );
  }

  Future<void> pumpDetail(
    WidgetTester tester, {
    required _StubBudgetService service,
    required Size size,
    double textScale = 1.0,
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showBudgetCategoryDetail(
                context,
                month: const YearMonth(2026, 5),
                categoryId: 'dining',
              ),
              child: const Text('Open detail'),
            ),
          ),
        ),
      ),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        budgetClockProvider
            .overrideWithValue(FixedClock(DateTime(2026, 5, 15))),
        budgetServiceProvider.overrideWithValue(service),
        ledgerRepositoryProvider.overrideWithValue(_StubLedgerRepository()),
        ledgerCurrencyProvider.overrideWithValue('USD'),
        displayCurrencySymbolProvider.overrideWithValue('\$'),
      ],
      child: MaterialApp.router(
        theme: theme ?? AppTheme.lightTheme,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.tap(find.text('Open detail'));
    await tester.pumpAndSettle();
  }

  Future<void> openClearDialog(WidgetTester tester) async {
    await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete budget'));
    await tester.pumpAndSettle();
  }

  testWidgets('clear failure surfaces the localized error', (tester) async {
    final service = _StubBudgetService(buildSummary())
      ..clearResult = const Result.failure(
          LedgerErrorCode.categoryArchived, 'category is archived');
    await pumpDetail(tester, service: service, size: const Size(400, 700));

    await openClearDialog(tester);
    await tester.tap(find.text('Delete budget'));
    await tester.pumpAndSettle();

    expect(service.lastScope, BudgetEditScope.thisMonthOnly);
    expect(find.text('Category is archived'), findsOneWidget);
  });

  testWidgets('cancelling the clear dialog keeps the budget and its note',
      (tester) async {
    final service = _StubBudgetService(buildSummary());
    await pumpDetail(tester, service: service, size: const Size(400, 700));

    await openClearDialog(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(service.clearCalls, 0);
    expect(service.lastScope, isNull);
    // The category note is still the one the (undone) clear would have deleted.
    expect(find.text('Old note'), findsOneWidget);
    expect(find.text('Budget deleted'), findsNothing);
  });

  testWidgets('archived category is read only and has no overflow menu',
      (tester) async {
    final service = _StubBudgetService(buildSummary(archived: true));
    await pumpDetail(tester, service: service, size: const Size(400, 700));

    expect(find.text('Archived'), findsOneWidget);
    expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
  });

  testWidgets('a category without a budget offers no delete action',
      (tester) async {
    final service = _StubBudgetService(buildSummary(unbudgeted: true));
    await pumpDetail(tester, service: service, size: const Size(400, 700));

    // There is no budget to remove, so the overflow menu itself is absent:
    // 调预算 is the only way to give the category a budget.
    expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
    expect(find.text('Delete budget'), findsNothing);
    expect(find.text('Adjust budget'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(service.lastScope, isNull);
  });

  for (final config in const [
    (label: '400x700', size: Size(400, 700), textScale: 1.0, dark: false),
    (
      label: '430x932 with 1.6x text',
      size: Size(430, 932),
      textScale: 1.6,
      dark: false
    ),
    (label: 'dark 400x700', size: Size(400, 700), textScale: 1.0, dark: true),
    (
      label: 'wide 1200x2400',
      size: Size(1200, 2400),
      textScale: 1.0,
      dark: false
    ),
  ]) {
    testWidgets(
        'clear dialog copy stays readable and reachable at '
        '${config.label}', (tester) async {
      final service = _StubBudgetService(buildSummary())..hasFuture = true;
      await pumpDetail(
        tester,
        service: service,
        size: config.size,
        textScale: config.textScale,
        theme: config.dark ? AppTheme.darkTheme : null,
      );

      await openClearDialog(tester);
      expect(find.textContaining('Dining budget for May 2026'), findsOneWidget);
      // Large text pushes the scope control below the fold; it stays reachable
      // by scrolling the dialog body.
      await tester.ensureVisible(find.text('This & following months'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('This & following months'));
      await tester.pumpAndSettle();

      expect(find.textContaining('from May 2026 onward'), findsOneWidget);
      expect(find.textContaining('will also be removed'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
      // Long copy scrolls inside the dialog rather than pushing the
      // destructive action out of reach.
      await tester.drag(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(SingleChildScrollView),
        ),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete budget'));
      await tester.pumpAndSettle();

      expect(service.lastScope, BudgetEditScope.thisAndFollowing);
    });
  }

  testWidgets('view all shows every contribution and preserves an unsaved note',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final updates = StreamController<MonthBudgetSummary>.broadcast();
    addTearDown(updates.close);
    final service = _StubBudgetService(buildSummary(includeMore: true),
        updates: updates.stream);
    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                        onPressed: () => showBudgetCategoryDetail(context,
                            month: const YearMonth(2026, 5),
                            categoryId: 'dining'),
                        child: const Text('Open'),
                      )))),
      GoRoute(
          path: '/ledger/edit',
          builder: (_, state) => Scaffold(
              body: Text(
                  'Editing ${(state.extra as TransactionTileUiModel).id}'))),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        budgetClockProvider
            .overrideWithValue(FixedClock(DateTime(2026, 5, 15))),
        budgetServiceProvider.overrideWithValue(service),
        ledgerRepositoryProvider.overrideWithValue(_StubLedgerRepository()),
        ledgerCurrencyProvider.overrideWithValue('USD'),
        displayCurrencySymbolProvider.overrideWithValue('\$'),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final slide = find.ancestor(
        of: find.byType(BudgetCategoryDetailScreen),
        matching: find.byType(SlideTransition));
    expect(slide, findsWidgets);
    expect(tester.widget<SlideTransition>(slide.first).position.value.dy,
        greaterThan(0));
    expect(tester.widget<SlideTransition>(slide.first).position.value.dx, 0);
    await tester.pumpAndSettle();
    expect(find.text('Old note'), findsOneWidget);
    await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
    await tester.pumpAndSettle();
    expect(find.text('Delete budget'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adjust budget'));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetEditSheet), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Delete budget'), findsNothing);
    await tester.tap(find.descendant(
        of: find.byType(BudgetEditSheet),
        matching: find.byIcon(LucideIcons.x)));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetEditSheet), findsNothing);
    expect(find.text('Old note'), findsOneWidget);
    await tester.tap(find.text('Adjust budget'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.descendant(
            of: find.byType(BudgetEditSheet),
            matching: find.byType(TextFormField)),
        '1200');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(service.lastAmountMinor, 120000);
    expect(find.byType(BudgetEditSheet), findsNothing);
    updates.add(buildSummary(includeMore: true));
    await tester.pumpAndSettle();
    expect(find.text('Old note'), findsOneWidget);
    service.lastScope = null;
    service.hasFuture = true;
    tester.view.physicalSize = const Size(320, 740);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete budget'));
    await tester.pumpAndSettle();
    // The safe default is this month only, so the future-rule warning stays
    // away until the wider scope is picked; the copy still names the category,
    // the month and the note the clear deletes.
    expect(find.text('This month only'), findsOneWidget);
    expect(find.textContaining('Dining budget for May 2026'), findsOneWidget);
    expect(find.textContaining("this month's category review note"),
        findsOneWidget);
    expect(find.textContaining('will also be removed'), findsNothing);
    await tester.tap(find.text('This & following months'));
    await tester.pumpAndSettle();
    expect(find.textContaining('May 2026 onward'), findsOneWidget);
    expect(find.textContaining('will also be removed'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.lastScope, isNull);
    await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete budget'));
    await tester.pumpAndSettle();
    expect(service.lastScope, BudgetEditScope.thisMonthOnly);
    service.lastScope = null;
    await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('This & following months'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete budget'));
    await tester.pumpAndSettle();
    expect(service.lastScope, BudgetEditScope.thisAndFollowing);
    tester.view.physicalSize = const Size(1200, 2400);
    await tester.pumpAndSettle();
    expect(find.text('Expense 4'), findsNothing);
    await tester.ensureVisible(find.text('View all'));
    final viewAll = find.widgetWithText(AppButton, 'View all');
    // The action sits in the section header, level with its title.
    expect(
        (tester.getCenter(viewAll).dy -
                tester.getCenter(find.text('Top contributing expenses')).dy)
            .abs(),
        lessThan(4));
    final arrow = find.descendant(
        of: viewAll, matching: find.byIcon(LucideIcons.chevronRight));
    expect(arrow, findsOneWidget);
    expect(tester.getCenter(arrow).dx,
        greaterThan(tester.getCenter(find.text('View all')).dx));
    debugPrint('VIEWALL ${tester.getRect(viewAll)}');
    debugPrint('NOTE ${tester.getRect(find.text('Category review note'))}');
    debugPrint(
        'TITLE ${tester.getRect(find.text('Top contributing expenses'))}');
    expect(tester.getTopLeft(find.text('Category review note')).dy,
        greaterThan(tester.getBottomLeft(viewAll).dy));
    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();
    expect(find.text('Expense 4'), findsOneWidget);
    // The page title names the category; the app bar counts its entries.
    expect(find.text('Dining spending'), findsOneWidget);
    expect(find.textContaining('4 items', findRichText: true), findsOneWidget);
    expect(find.textContaining('Total \$558.33', findRichText: true),
        findsOneWidget);
    // The count and total sit in the app bar, after the title.
    expect(
        find.descendant(
            of: find.byType(AppBar),
            matching: find.textContaining('4 items', findRichText: true)),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(AppBar),
            matching:
                find.textContaining('Total \$558.33', findRichText: true)),
        findsOneWidget);
    expect(
        tester
            .getTopLeft(find.textContaining('4 items', findRichText: true))
            .dx,
        greaterThan(tester.getTopRight(find.text('Dining spending')).dx));
    final titleRow = tester
        .widgetList<Row>(find.ancestor(
            of: find.text('Dining spending'), matching: find.byType(Row)))
        .first;
    expect(titleRow.crossAxisAlignment, CrossAxisAlignment.baseline);
    expect(titleRow.textBaseline, TextBaseline.alphabetic);
    final summaryFinder =
        find.byKey(const ValueKey('budget-contributions-summary'));
    // The title keeps the theme's regular weight; only the summary is bold.
    expect(tester.widget<Text>(find.text('Dining spending')).style?.fontWeight,
        isNot(FontWeight.w700));
    final summary = tester.widget<Text>(summaryFinder);
    final spans = (summary.textSpan! as TextSpan)
        .children!
        .cast<TextSpan>()
        .where((span) => (span.text ?? '').trim().isNotEmpty)
        .toList();
    expect(spans, hasLength(2));
    for (final span in spans) {
      expect(span.style?.fontWeight, FontWeight.w700, reason: span.text);
    }
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('1 item · \$25.00'), findsOneWidget);
    expect(find.text('Posted'), findsOneWidget);
    expect(find.text('3 items · \$533.33'), findsOneWidget);
    final pendingCard =
        find.byKey(const ValueKey('budget-contribution-group-pending'));
    final postedCard =
        find.byKey(const ValueKey('budget-contribution-group-posted'));
    expect(pendingCard, findsOneWidget);
    expect(postedCard, findsOneWidget);
    for (final headerSummary in ['1 item · \$25.00', '3 items · \$533.33']) {
      expect(tester.getTopRight(find.text(headerSummary)).dx,
          tester.getTopRight(pendingCard).dx,
          reason: headerSummary);
    }
    // Pending rows carry the Fixed tag instead of repeating the group title.
    expect(find.text('Committed'), findsOneWidget);
    expect(find.byKey(const ValueKey('budget-contribution-group-pending')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('budget-contribution-group-posted')),
        findsOneWidget);
    expect(find.textContaining('Cash'), findsWidgets);
    await tester.tap(find.text('Expense 2'));
    await tester.pumpAndSettle();
    expect(find.text('Editing tx-2'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Expense 4'), findsOneWidget);
    updates.add(buildSummary());
    await tester.pumpAndSettle();
    expect(find.text('Expense 4'), findsNothing);
    expect(find.text('Lunch'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(BudgetNoteCard), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets(
      'budget detail navigates to /ledger/edit and validates Review Note length',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final service = _StubBudgetService(buildSummary());
    String? pushedEditId;

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showBudgetCategoryDetail(
                  ctx,
                  month: const YearMonth(2026, 5),
                  categoryId: 'dining',
                ),
                child: const Text('Open drilldown'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/ledger/edit',
          builder: (_, state) {
            final tile = state.extra as TransactionTileUiModel?;
            pushedEditId = tile?.id;
            return const Scaffold(body: Text('Edit Screen'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          budgetClockProvider
              .overrideWithValue(FixedClock(DateTime(2026, 5, 15))),
          budgetServiceProvider.overrideWithValue(service),
          ledgerRepositoryProvider.overrideWithValue(_StubLedgerRepository()),
          ledgerCurrencyProvider.overrideWithValue('USD'),
          displayCurrencySymbolProvider.overrideWithValue('\$'),
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

    await tester.tap(find.text('Open drilldown'));
    await tester.pumpAndSettle();

    expect(find.byType(BudgetCategoryDetailScreen), findsOneWidget);
    expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);

    // The category note opens the same sheet as the month note.
    await tester.tap(find.byType(BudgetNoteCard));
    await tester.pumpAndSettle();
    final noteField = find.descendant(
      of: find.byKey(const ValueKey('budget-note-field')),
      matching: find.byType(TextField),
    );

    // Too long note disables the save button and keeps the draft.
    await tester.enterText(noteField, 'x' * 501);
    await tester.pumpAndSettle();
    expect(find.text('501/500'), findsOneWidget);
    expect(
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, 'Save note'))
          .onPressed,
      isNull,
    );
    expect(service.savedNote, isNull);

    // Valid note saves and closes the sheet.
    await tester.enterText(noteField, 'Good month');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();
    expect(service.savedNote, 'Good month');
    expect(find.byKey(const ValueKey('budget-note-field')), findsNothing);

    // Tapping TOP transaction pushes /ledger/edit
    await tester.ensureVisible(find.text('Lunch'));
    await tester.tap(find.text('Lunch'));
    await tester.pumpAndSettle();
    expect(pushedEditId, 'tx-1');
    expect(find.text('Edit Screen'), findsOneWidget);
  });

  testWidgets(
      'BudgetEditSheet enforces >0 save guard, fills baseline chips, and '
      'forces scope picker when future breakpoints exist', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final service = _StubBudgetService(buildSummary())..hasFuture = true;
    const row = BudgetCategoryRowUiModel(
      categoryId: 'dining',
      name: 'Dining',
      titleDisplay: 'Dining · May 2026',
      iconKey: 'utensils',
      colorInt: 0xFFE65100,
      archived: false,
      isBudgetEditable: true,
      budgetMinor: null, // Unset in May, BUT future rule exists!
      lastMonthActualMinor: 80000,
      threeMonthAvgMinor: 75000,
      committedBaselineMinor: 15000,
      budgetDisplay: null,
      actualDisplay: '\$200.00',
      pendingDisplay: null,
      varianceDisplay: null,
      isOverBudget: false,
      committedActualDisplay: '\$0.00',
      discretionaryActualDisplay: '\$200.00',
      committedBaselineDisplay: '\$150.00',
      lastMonthActualDisplay: '\$800.00',
      threeMonthAvgDisplay: '\$750.00',
      actualProgress: 0,
      pendingProgress: 0,
      riskLevel: BudgetRiskLevel.inBudget,
      isAnomaly: false,
      anomalyPercent: null,
      trend6Months: [],
      topContributions: [],
      reviewNote: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          budgetServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: BudgetEditSheet(
              row: row,
              currencyCode: 'USD',
              currencySymbol: '\$',
              month: const YearMonth(2026, 5),
              isHistoricalMonth: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Future breakpoints exist -> scope picker MUST appear with warning
    expect(find.text('This & following months'), findsOneWidget);
    expect(find.textContaining('will be replaced'), findsOneWidget);

    // Entering 0 shows hint & keeps Save disabled
    await tester.enterText(
      find.descendant(
        of: find.byType(LedgerAmountInput),
        matching: find.byType(TextFormField),
      ),
      '0',
    );
    await tester.pump();
    expect(find.textContaining('greater than 0'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(service.lastAmountMinor, isNull);

    // Tapping baseline chip fills amount and enables Save
    await tester.tap(find.textContaining('Last mo'));
    await tester.pump();
    await tester.tap(find.text('This month only'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(service.lastAmountMinor, 80000);
    expect(service.lastScope, BudgetEditScope.thisMonthOnly);
  });

  testWidgets('a failed future-rules probe says so and leaves the sheet usable',
      (tester) async {
    final service = _StubBudgetService(buildSummary())..failFutureProbe = true;
    const row = BudgetCategoryRowUiModel(
      categoryId: 'dining',
      name: 'Dining',
      titleDisplay: 'Dining · May 2026',
      iconKey: 'utensils',
      colorInt: 0xFFE65100,
      archived: false,
      isBudgetEditable: true,
      budgetMinor: 100000,
      lastMonthActualMinor: 80000,
      threeMonthAvgMinor: 75000,
      committedBaselineMinor: 15000,
      budgetDisplay: '\$1000.00',
      actualDisplay: '\$200.00',
      pendingDisplay: null,
      varianceDisplay: null,
      isOverBudget: false,
      committedActualDisplay: '\$0.00',
      discretionaryActualDisplay: '\$200.00',
      committedBaselineDisplay: '\$150.00',
      lastMonthActualDisplay: '\$800.00',
      threeMonthAvgDisplay: '\$750.00',
      actualProgress: 0,
      pendingProgress: 0,
      riskLevel: BudgetRiskLevel.inBudget,
      isAnomaly: false,
      anomalyPercent: null,
      trend6Months: [],
      topContributions: [],
      reviewNote: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          budgetServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: BudgetEditSheet(
              row: row,
              currencyCode: 'USD',
              currencySymbol: '\$',
              month: const YearMonth(2026, 5),
              isHistoricalMonth: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The failure is named in the user's language, never as an exception.
    expect(
        find.text('Something went wrong. Please try again.'), findsOneWidget);
    expect(find.textContaining('StateError'), findsNothing);

    // And the sheet can still save: an unknown probe is not a veto.
    await tester.tap(find.text('This month only'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(service.lastAmountMinor, 100000);
  });
  testWidgets('the sheet header, amount and full-width scope align at 320dp',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final service = _StubBudgetService(buildSummary());
    const row = BudgetCategoryRowUiModel(
      categoryId: 'dining',
      name: 'Dining',
      titleDisplay: 'Dining · May 2026',
      iconKey: 'utensils',
      colorInt: 0xFFE65100,
      archived: false,
      isBudgetEditable: true,
      budgetMinor: 100000,
      lastMonthActualMinor: 80000,
      threeMonthAvgMinor: 75000,
      committedBaselineMinor: 15000,
      budgetDisplay: '\$1000.00',
      actualDisplay: '\$200.00',
      pendingDisplay: null,
      varianceDisplay: null,
      isOverBudget: false,
      committedActualDisplay: '\$150.00',
      discretionaryActualDisplay: '\$50.00',
      committedBaselineDisplay: '\$150.00',
      lastMonthActualDisplay: '\$800.00',
      threeMonthAvgDisplay: '\$750.00',
      actualProgress: 0.2,
      pendingProgress: 0,
      riskLevel: BudgetRiskLevel.inBudget,
      isAnomaly: false,
      anomalyPercent: null,
      trend6Months: [],
      topContributions: [],
      reviewNote: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [budgetServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: BudgetEditSheet(
              row: row,
              currencyCode: 'USD',
              currencySymbol: '\$',
              month: YearMonth(2026, 5),
              isHistoricalMonth: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // A 28dp circular badge, the category-led title and the month context.
    expect(find.text('Dining budget'), findsOneWidget);
    expect(find.text('May 2026'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('budget-sheet-avatar'))),
      const Size(28, 28),
    );
    expect(
      (tester
              .widget<Container>(
                  find.byKey(const ValueKey('budget-sheet-avatar')))
              .decoration! as BoxDecoration)
          .shape,
      BoxShape.circle,
    );

    // The reference chips never wrap to a second line.
    expect(
        find.byKey(const ValueKey('budget-reference-chips')), findsOneWidget);
    expect(
      tester
          .widget<SingleChildScrollView>(
              find.byKey(const ValueKey('budget-reference-chips')))
          .scrollDirection,
      Axis.horizontal,
    );

    // The amount borrows the neutral colour, and the field carries controls
    // that suppress selection droplets while keeping the caret.
    final field = tester.widget<TextField>(find.descendant(
      of: find.byType(LedgerAmountInput),
      matching: find.byType(TextField),
    ));
    expect(field.selectionControls, isNotNull);
    expect(
      tester
          .widget<Text>(find.descendant(
              of: find.byType(LedgerAmountInput), matching: find.text('\$ ')))
          .style!
          .fontSize,
      lessThan(Theme.of(tester.element(find.byType(LedgerAmountInput)))
          .textTheme
          .displayMedium!
          .fontSize!),
    );

    // The scope switch and the save button share both edges.
    final scopeWidth = tester
        .getSize(find.byKey(const ValueKey('budget-scope-selector')))
        .width;
    final saveWidth =
        tester.getSize(find.widgetWithText(AppButton, 'Save')).width;
    expect(scopeWidth, closeTo(saveWidth, 0.5));
  });

  testWidgets('the keyboard leaves the amount controls on screen',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.resetViewInsets);

    final service = _StubBudgetService(buildSummary());
    const row = BudgetCategoryRowUiModel(
      categoryId: 'dining',
      name: 'Dining',
      titleDisplay: 'Dining · May 2026',
      iconKey: 'utensils',
      colorInt: 0xFFE65100,
      archived: false,
      isBudgetEditable: true,
      budgetMinor: 100000,
      budgetDisplay: '\$1000.00',
      actualDisplay: '\$200.00',
      pendingDisplay: null,
      varianceDisplay: null,
      isOverBudget: false,
      committedActualDisplay: '\$0.00',
      discretionaryActualDisplay: '\$200.00',
      committedBaselineDisplay: '\$0.00',
      lastMonthActualDisplay: '\$800.00',
      threeMonthAvgDisplay: '\$750.00',
      lastMonthActualMinor: 80000,
      threeMonthAvgMinor: 75000,
      committedBaselineMinor: 0,
      actualProgress: 0.2,
      pendingProgress: 0,
      riskLevel: BudgetRiskLevel.inBudget,
      isAnomaly: false,
      anomalyPercent: null,
      trend6Months: [],
      topContributions: [],
      reviewNote: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [budgetServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: BudgetEditSheet(
              row: row,
              currencyCode: 'USD',
              currencySymbol: '\$',
              month: YearMonth(2026, 5),
              isHistoricalMonth: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.text('Save')).bottom,
      lessThanOrEqualTo(800 - 320),
    );
  });
  testWidgets('the clear dialog shows a warning icon and bolds the amount',
      (tester) async {
    final service = _StubBudgetService(buildSummary());
    await pumpDetail(tester, service: service, size: const Size(400, 700));
    await openClearDialog(tester);

    expect(find.byIcon(LucideIcons.trash2), findsOneWidget);

    List<String> boldParts(String sentence) {
      final rich = tester.widget<RichText>(find.byWidgetPredicate((widget) =>
          widget is RichText && widget.text.toPlainText().contains(sentence)));
      final parts = <String>[];
      void walk(InlineSpan span) {
        if (span is TextSpan) {
          if (span.style?.fontWeight == FontWeight.w700) {
            parts.add(span.text ?? '');
          }
          for (final child in span.children ?? const <InlineSpan>[]) {
            walk(child);
          }
        }
      }

      walk(rich.text as TextSpan);
      return parts;
    }

    // This-month copy names the amount in bold, and the sentence keeps the
    // same wording the domain's delete contract promises.
    expect(boldParts('Dining budget for May 2026'), contains('\$1000.00'));

    await tester.tap(find.text('This & following months'));
    await tester.pumpAndSettle();
    expect(boldParts('May 2026 onward'), contains('\$1000.00'));
  });
  testWidgets('the sheet keeps its tonal hierarchy in the dark theme',
      (tester) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final service = _StubBudgetService(buildSummary());
    const row = BudgetCategoryRowUiModel(
      categoryId: 'dining',
      name: 'Dining',
      titleDisplay: 'Dining · May 2026',
      iconKey: 'utensils',
      colorInt: 0xFFE65100,
      archived: false,
      isBudgetEditable: true,
      budgetMinor: 100000,
      budgetDisplay: '\$1000.00',
      actualDisplay: '\$200.00',
      pendingDisplay: null,
      varianceDisplay: null,
      isOverBudget: false,
      committedActualDisplay: '\$0.00',
      discretionaryActualDisplay: '\$200.00',
      committedBaselineDisplay: '\$0.00',
      lastMonthActualDisplay: '\$800.00',
      threeMonthAvgDisplay: '\$750.00',
      lastMonthActualMinor: 80000,
      threeMonthAvgMinor: 75000,
      committedBaselineMinor: 15000,
      actualProgress: 0.2,
      pendingProgress: 0,
      riskLevel: BudgetRiskLevel.inBudget,
      isAnomaly: false,
      anomalyPercent: null,
      trend6Months: [],
      topContributions: [],
      reviewNote: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [budgetServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: BudgetEditSheet(
              row: row,
              currencyCode: 'USD',
              currencySymbol: '\$',
              month: YearMonth(2026, 5),
              isHistoricalMonth: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scheme = AppTheme.darkTheme.colorScheme;
    final selector = tester.widget<SegmentedButton<BudgetEditScope>>(
        find.byKey(const ValueKey('budget-scope-selector')));
    expect(
      selector.style!.backgroundColor!.resolve({WidgetState.selected}),
      scheme.secondaryContainer,
    );
    expect(
      selector.style!.backgroundColor!.resolve(const <WidgetState>{}),
      scheme.surfaceContainerHighest,
    );
    expect(find.text('Dining budget'), findsOneWidget);
  });
  for (final config in const [
    (size: Size(400, 700), scale: 1.0, dark: true),
    (size: Size(320, 740), scale: 1.6, dark: false),
  ]) {
    testWidgets(
        'the contributions page fits ${config.size.width.toInt()}dp at '
        '${config.scale}x ${config.dark ? 'dark' : 'light'}', (tester) async {
      final service = _StubBudgetService(buildSummary(includeMore: true));
      await pumpDetail(
        tester,
        service: service,
        size: config.size,
        textScale: config.scale,
        theme: config.dark ? AppTheme.darkTheme : AppTheme.lightTheme,
      );
      await tester.scrollUntilVisible(
        find.text('View all'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('View all'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View all'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Dining spending'), findsOneWidget);
      expect(
          find.textContaining('4 items', findRichText: true), findsOneWidget);
      expect(find.textContaining('Total \$558.33', findRichText: true),
          findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Posted'), findsOneWidget);

      final pendingCard =
          find.byKey(const ValueKey('budget-contribution-group-pending'));
      final postedCard =
          find.byKey(const ValueKey('budget-contribution-group-posted'));
      expect(tester.getTopLeft(pendingCard).dx, 16);
      expect(tester.getTopRight(pendingCard).dx, config.size.width - 16);
      expect(tester.getTopLeft(postedCard).dx, 16);
      expect(tester.getTopRight(postedCard).dx, config.size.width - 16);
      expect(find.byType(TransactionListTile), findsNWidgets(4));
    });
  }

  testWidgets('the contributions page groups by status on one card edge',
      (tester) async {
    final service = _StubBudgetService(buildSummary(includeMore: true));
    await pumpDetail(tester, service: service, size: const Size(1200, 2400));
    await tester.ensureVisible(find.text('View all'));
    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();

    expect(find.text('Dining spending'), findsOneWidget);
    expect(find.textContaining('4 items', findRichText: true), findsOneWidget);
    expect(find.textContaining('Total \$558.33', findRichText: true),
        findsOneWidget);

    final pendingCard =
        find.byKey(const ValueKey('budget-contribution-group-pending'));
    final postedCard =
        find.byKey(const ValueKey('budget-contribution-group-posted'));
    expect(pendingCard, findsOneWidget);
    expect(postedCard, findsOneWidget);
    // Both cards share the page's 16 dp gutter.
    expect(tester.getTopLeft(pendingCard).dx, 16);
    expect(tester.getTopLeft(postedCard).dx, 16);
    expect(tester.getTopRight(pendingCard).dx, 1184);
    expect(tester.getTopRight(postedCard).dx, 1184);
    // Each group's count and total end on the card's right edge.
    for (final headerSummary in ['1 item · \$25.00', '3 items · \$533.33']) {
      expect(tester.getTopRight(find.text(headerSummary)).dx, 1184,
          reason: headerSummary);
    }

    // Pending rows trade the status pill for Fixed; posted rows carry neither.
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Committed'), findsOneWidget);
    expect(find.byType(TransactionListTile), findsNWidgets(4));
    for (final row in tester
        .widgetList<TransactionListTile>(find.byType(TransactionListTile))) {
      expect(row.showCategoryIcon, isFalse);
      expect(row.showCategoryName, isFalse);
    }
    final heights = [
      for (var i = 0; i < 4; i++)
        tester.getSize(find.byType(TransactionListTile).at(i)).height,
    ];
    expect(heights.every((height) => height >= 60 && height <= 64), isTrue);
  });
}
