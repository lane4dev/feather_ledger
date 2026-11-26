import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/design_system/app_icon_button.dart';
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
import 'package:feather_ledger/features/budget/presentation/widgets/budget_category_detail_sections.dart';
import 'package:feather_ledger/features/budget/presentation/widgets/budget_note_card.dart';
import 'package:feather_ledger/features/budget/presentation/widgets/budget_trend_chart.dart';
import 'package:feather_ledger/features/ledger/data/repositories/ledger_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/pending_bill_sheet.dart';

const _may = YearMonth(2026, 5);

class _StubBudgetService implements BudgetService {
  MonthBudgetSummary summary;
  final StreamController<MonthBudgetSummary> _updates =
      StreamController<MonthBudgetSummary>.broadcast();
  Result<void>? clearResult;
  Result<void>? noteResult;
  String? savedNote;
  BudgetEditScope? lastScope;

  _StubBudgetService(this.summary);

  void emit(MonthBudgetSummary next) {
    summary = next;
    _updates.add(next);
  }

  void close() => _updates.close();

  @override
  Stream<MonthBudgetSummary> watchMonthBudget({
    required String currencyCode,
    required YearMonth month,
  }) async* {
    yield summary;
    yield* _updates.stream;
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
  }) async =>
      false;

  @override
  Future<Result<void>> setCategoryBudget({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
    required int amountMinor,
    required BudgetEditScope scope,
  }) async =>
      unitResult;

  @override
  Future<Result<void>> clearCategoryBudget({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
    required BudgetEditScope scope,
  }) async {
    lastScope = scope;
    return clearResult ?? unitResult;
  }

  @override
  Future<Result<void>> saveReviewNote({
    required String currencyCode,
    required YearMonth month,
    String? categoryId,
    required String note,
  }) async {
    if (noteResult != null) return noteResult!;
    if (note.runes.length > 500) {
      return const Result.failure(
          LedgerErrorCode.budgetNoteTooLong, 'too long');
    }
    savedNote = note;
    return unitResult;
  }
}

const _cashAccount = AccountEntity(
  id: 'acc-1',
  name: 'Cash',
  type: AccountType.cash,
  currencyCode: 'USD',
  balanceMinor: 10000,
  archived: false,
  lastUpdatedEventId: 1,
);

const _diningCategory = CategoryEntity(
  id: 'dining',
  name: 'Dining',
  iconKey: 'utensils',
  colorInt: 0xFFE65100,
  type: CategoryType.expense,
);

class _StubRecurringService implements RecurringService {
  final List<({String seriesId, String occurrenceKey})> materializeCalls = [];
  final List<({String scheduledId, RecurringScope scope})> deleteCalls = [];
  Result<ScheduledTransactionEntity>? materializeResult;

  @override
  Future<Result<ScheduledTransactionEntity>> ensureMaterialized({
    required String seriesId,
    required String occurrenceKey,
  }) async {
    materializeCalls.add((seriesId: seriesId, occurrenceKey: occurrenceKey));
    if (materializeResult != null) return materializeResult!;
    return Result.success(
      ScheduledTransactionEntity(
        id: 'mat-uuid-1',
        seriesId: seriesId,
        occurrenceKey: occurrenceKey,
        scheduledDate: DateTime(2026, 11, 1, 9, 0),
        kind: TransactionKind.expense,
        category: _diningCategory,
        account: _cashAccount,
        recurringTransactionSeries: RecurringTransactionSeriesEntity(
          id: seriesId,
          description: 'Monthly Rent',
          amountMinor: 300000,
          type: RecurringSeriesKind.expense,
          categoryId: _diningCategory.id,
          accountId: _cashAccount.id,
          frequency: 'MONTHLY',
          startDate: DateTime(2026, 5, 1, 9, 0),
          autoPost: false,
          mode: RecurringSeriesMode.repeating,
        ),
      ),
    );
  }

  @override
  Future<Result<void>> deleteBill(
    String scheduledId, {
    required RecurringScope scope,
  }) async {
    deleteCalls.add((scheduledId: scheduledId, scope: scope));
    return unitResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
      account: _cashAccount,
      category: _diningCategory,
    );
  }

  @override
  Future<ScheduledTransactionEntity?> getScheduledTransaction(String id) async {
    return ScheduledTransactionEntity(
      id: id,
      seriesId: 'series-1',
      occurrenceKey: 'occurrence-1',
      scheduledDate: DateTime(2026, 5, 20),
      amountOverrideMinor: 10000,
      memoOverride: 'Expense 4',
      kind: TransactionKind.expense,
      category: _diningCategory,
      account: _cashAccount,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

BudgetTrendPoint _point(
  YearMonth month, {
  int? budgetMinor,
  required int actualMinor,
  bool hasReviewNote = false,
}) =>
    BudgetTrendPoint(
      month: month,
      budgetMinor: budgetMinor,
      actualMinor: actualMinor,
      pendingMinor: 0,
      hasReviewNote: hasReviewNote,
    );

/// Hand-built chart points, for asserting what the monthly trend renders with
/// the same data the detail page receives.
BudgetTrendPointUiModel _chartPoint(
  YearMonth ym, {
  int? budgetMinor,
  required int actualMinor,
  bool hasReviewNote = false,
}) =>
    BudgetTrendPointUiModel(
      ym: ym,
      shortLabel: '${ym.month}',
      budgetMinor: budgetMinor,
      actualMinor: actualMinor,
      budgetChartValue: (budgetMinor ?? 0) / 100.0,
      actualChartValue: actualMinor / 100.0,
      budgetDisplay: budgetMinor == null
          ? null
          : '¥${(budgetMinor / 100).toStringAsFixed(2)}',
      actualDisplay: '¥${(actualMinor / 100).toStringAsFixed(2)}',
      hasReviewNote: hasReviewNote,
    );

List<BudgetContributionTx> _defaultContributions() => [
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
    ];

MonthBudgetSummary buildSummary({
  YearMonth month = _may,
  int? budgetMinor = 100000,
  int actualMinor = 45000,
  int pendingMinor = 0,
  int committedActualMinor = 0,
  int committedBaselineMinor = 0,
  int? lastMonthActualMinor = 80000,
  int? threeMonthAvgMinor = 75000,
  bool isAnomaly = false,
  double? anomalyDeltaRatio,
  bool archived = false,
  String? note = 'Old note',
  List<BudgetTrendPoint>? sixMonthTrend,
  List<BudgetTrendPoint>? monthTrend,
  List<BudgetContributionTx>? contributions,
}) {
  final contributions_ = contributions ?? _defaultContributions();
  final dining = CategoryBudgetSummary(
    categoryId: 'dining',
    categoryName: 'Dining',
    iconKey: 'utensils',
    colorInt: 0xFFE65100,
    isArchived: archived,
    archiveYm: archived ? month : null,
    budgetMinor: budgetMinor,
    hasFutureRulesAfter: false,
    committedActualMinor: committedActualMinor,
    discretionaryActualMinor: actualMinor - committedActualMinor,
    actualMinor: actualMinor,
    pendingMinor: pendingMinor,
    projectedRemainingMinor:
        budgetMinor == null ? null : budgetMinor - actualMinor - pendingMinor,
    lastMonthActualMinor: lastMonthActualMinor,
    threeMonthAvgMinor: threeMonthAvgMinor,
    committedBaselineMinor: committedBaselineMinor,
    isAnomaly: isAnomaly,
    anomalyDeltaRatio: anomalyDeltaRatio,
    riskLevel: budgetMinor != null && actualMinor > budgetMinor
        ? BudgetRiskLevel.overBudget
        : BudgetRiskLevel.inBudget,
    sixMonthTrend: sixMonthTrend ??
        [
          _point(month,
              budgetMinor: budgetMinor,
              actualMinor: actualMinor,
              hasReviewNote: note != null),
        ],
    topTransactions: contributions_.take(3).toList(),
    allTransactions: contributions_,
    reviewNote: note,
  );
  return MonthBudgetSummary(
    currencyCode: 'USD',
    month: month,
    mode: BudgetMode.track,
    hasAnyActiveAccount: true,
    totalBudgetMinor: budgetMinor ?? 0,
    budgetedActualMinor: actualMinor,
    budgetedPendingMinor: pendingMinor,
    projectedRemainingMinor:
        budgetMinor == null ? 0 : budgetMinor - actualMinor - pendingMinor,
    budgetedRemainingActualMinor:
        budgetMinor == null ? 0 : budgetMinor - actualMinor,
    allExpenseActualMinor: actualMinor,
    allExpensePendingMinor: pendingMinor,
    unbudgetedActualMinor: 0,
    unbudgetedPendingMinor: 0,
    inBudgetCount: 1,
    budgetedCategoryCount: budgetMinor == null ? 0 : 1,
    complianceRate: 1.0,
    hasAnyBudget: budgetMinor != null,
    hasUnbudgetedActivity: false,
    hasLeftoverPendingInReview: false,
    budgetedCategories: archived || budgetMinor == null ? const [] : [dining],
    unbudgetedActiveCategories:
        !archived && budgetMinor == null ? [dining] : const [],
    remainingActiveCategories: archived ? [dining] : const [],
    overBudgetTop3: const [],
    underBudgetTop3: const [],
    unbudgetedAlertsTop3: const [],
    monthTrend6Months: monthTrend ??
        [
          _point(month,
              budgetMinor: budgetMinor,
              actualMinor: actualMinor,
              hasReviewNote: note != null),
        ],
    monthReviewNote: null,
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  Future<GoRouter> pumpDetail(
    WidgetTester tester, {
    required _StubBudgetService service,
    required Size size,
    YearMonth month = _may,
    double textScale = 1.0,
    ThemeData? theme,
    RecurringService? recurringService,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(service.close);
    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showBudgetCategoryDetail(
                context,
                month: month,
                categoryId: 'dining',
              ),
              child: const Text('Open detail'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/ledger/edit',
        builder: (_, state) => Scaffold(
          body: Text('Editing ${(state.extra as TransactionTileUiModel).id}'),
        ),
      ),
      GoRoute(
        path: '/ledger/edit-bill',
        builder: (_, state) => Scaffold(
          body: Text(
              'Editing bill ${(state.extra as TransactionTileUiModel).id}'),
        ),
      ),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        budgetClockProvider
            .overrideWithValue(FixedClock(DateTime(2026, 5, 15))),
        budgetServiceProvider.overrideWithValue(service),
        if (recurringService != null)
          recurringServiceProvider.overrideWithValue(recurringService),
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
    return router;
  }

  Future<void> pumpMonthlyChart(
      WidgetTester tester, List<BudgetTrendPointUiModel> points) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: BudgetTrendChart(points: points),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  List<BarChartRodData> rods(WidgetTester tester) {
    final chart = tester.widget<BarChart>(find.byType(BarChart));
    return [
      for (final group in chart.data.barGroups) group.barRods.single,
    ];
  }

  /// ScaffoldMessenger queues snack bars: clear the visible one before
  /// asserting on the next, or the new message sits behind it.
  final noteField = find.descendant(
    of: find.byKey(const ValueKey('budget-note-field')),
    matching: find.byType(TextField),
  );

  Future<void> openNoteSheet(WidgetTester tester) async {
    final card = find.byType(BudgetNoteCard);
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
  }

  Future<void> dismissSnackBar(WidgetTester tester) async {
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger).first)
        .clearSnackBars();
    await tester.pumpAndSettle();
  }

  Finder inProgressCard(Finder matching) => find.descendant(
      of: find.byType(BudgetCategoryProgressCard), matching: matching);

  Finder inCompositionCard(Finder matching) => find.descendant(
      of: find.byType(BudgetCategoryCompositionCard), matching: matching);

  testWidgets('an anomaly is explained in words, not just a percentage',
      (tester) async {
    final service = _StubBudgetService(buildSummary(
      actualMinor: 300000,
      threeMonthAvgMinor: 75000,
      isAnomaly: true,
      anomalyDeltaRatio: 3.0,
    ));
    await pumpDetail(tester, service: service, size: const Size(400, 700));

    expect(
      find.text('Spending is 300% above the 3-month average of \$750.00.'),
      findsOneWidget,
    );
    // The explanation names what was compared against; a bare "+300%" label
    // is not enough.
    expect(find.text('+300% vs 3m avg'), findsNothing);
  });

  testWidgets(
      'the monthly trend can draw while this category chart stays hidden',
      (tester) async {
    // The month trend has three usable months; this category's own window has
    // only the selected month.
    final monthTrend = [
      for (var i = 3; i <= 5; i++)
        _point(YearMonth(2026, i),
            budgetMinor: 100000, actualMinor: 30000 + i * 1000),
      _point(const YearMonth(2026, 6), budgetMinor: 100000, actualMinor: 38000),
    ];
    final service = _StubBudgetService(buildSummary(
      sixMonthTrend: [_point(_may, budgetMinor: 100000, actualMinor: 45000)],
      monthTrend: monthTrend,
    ));
    await pumpDetail(tester, service: service, size: const Size(400, 700));

    // No title, legend, card or spacing for the category chart.
    expect(find.text('6-Month Budget vs Actual'), findsNothing);
    expect(find.byType(BarChart), findsNothing);

    await pumpMonthlyChart(tester, [
      for (final point in monthTrend)
        _chartPoint(point.month,
            budgetMinor: point.budgetMinor, actualMinor: point.actualMinor),
    ]);
    expect(find.text('6-Month Budget vs Actual'), findsOneWidget);
    expect(find.text('All actual spend'), findsOneWidget);
  });

  testWidgets(
      'this category chart can draw while the monthly trend stays hidden',
      (tester) async {
    final categoryTrend = [
      for (var i = 3; i <= 5; i++)
        _point(YearMonth(2026, i),
            budgetMinor: 100000, actualMinor: 30000 + i * 1000),
    ];
    final service = _StubBudgetService(buildSummary(
      sixMonthTrend: categoryTrend,
      monthTrend: [_point(_may, budgetMinor: 100000, actualMinor: 45000)],
    ));
    await pumpDetail(tester, service: service, size: const Size(400, 700));

    expect(find.text('6-Month Budget vs Actual'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('Actual spend'), findsOneWidget);

    await pumpMonthlyChart(
        tester, [_chartPoint(_may, budgetMinor: 100000, actualMinor: 45000)]);
    expect(find.text('6-Month Budget vs Actual'), findsNothing);
    expect(find.byType(BarChart), findsNothing);
  });

  testWidgets('overrun colour needs a budget and actual strictly over it',
      (tester) async {
    final service = _StubBudgetService(buildSummary(
      sixMonthTrend: [
        _point(const YearMonth(2026, 3), budgetMinor: null, actualMinor: 50000),
        _point(const YearMonth(2026, 4),
            budgetMinor: 100000, actualMinor: 120000),
        _point(const YearMonth(2026, 5),
            budgetMinor: 100000, actualMinor: 100000),
      ],
    ));
    await pumpDetail(tester, service: service, size: const Size(900, 1200));

    final bars = rods(tester);
    final context = tester.element(find.byType(BudgetTrendChart));
    final primary = Theme.of(context).colorScheme.primary;
    final expense = Theme.of(context).extension<AppSemanticColors>()!.expense;

    // March had no budget, May spent exactly the budget: neither is an overrun.
    expect(bars[0].color, primary);
    expect(bars[1].color, expense);
    expect(bars[2].color, primary);
  });

  testWidgets('posted and pending contributions open their edit routes',
      (tester) async {
    final service = _StubBudgetService(buildSummary(contributions: [
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
      BudgetContributionTx(
        transactionId: 'bill-4',
        sourceScheduledBillId: 'bill-4',
        scheduledBillId: 'bill-4',
        description: 'Gym',
        occurredAt: DateTime(2026, 5, 10),
        amountMinor: 20000,
        isPending: true,
        accountName: 'Cash',
      ),
    ]));
    final router =
        await pumpDetail(tester, service: service, size: const Size(900, 1200));

    await tester.tap(find.text('Lunch'));
    await tester.pumpAndSettle();
    expect(find.text('Editing tx-1'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gym'));
    await tester.pumpAndSettle();
    expect(find.text('Editing bill bill-4'), findsOneWidget);
  });

  testWidgets(
      'tapping a far-future virtual pending bill materializes it and opens '
      'PendingBillSheet with edit and skip flows', (tester) async {
    final recurring = _StubRecurringService();
    const nov2026 = YearMonth(2026, 11);
    final service = _StubBudgetService(buildSummary(
      month: nov2026,
      actualMinor: 0,
      pendingMinor: 300000,
      committedBaselineMinor: 300000,
      contributions: [
        BudgetContributionTx(
          transactionId: 'virtual:series-rent:2026-11-01',
          sourceScheduledBillId: null,
          scheduledBillId: null,
          seriesId: 'series-rent',
          occurrenceKey: '2026-11-01',
          isVirtual: true,
          description: 'Monthly Rent',
          occurredAt: DateTime(2026, 11, 1, 9, 0),
          amountMinor: 300000,
          isPending: true,
          accountName: 'Cash',
        ),
      ],
    ));
    final router = await pumpDetail(
      tester,
      service: service,
      month: nov2026,
      size: const Size(900, 1200),
      recurringService: recurring,
    );

    await tester.tap(find.text('Monthly Rent'));
    await tester.pumpAndSettle();

    expect(recurring.materializeCalls, [
      (seriesId: 'series-rent', occurrenceKey: '2026-11-01'),
    ]);
    expect(find.byType(PendingBillSheet), findsOneWidget);

    // Edit action from PendingBillSheet routes to /ledger/edit-bill with the
    // newly materialized UUID.
    await tester.tap(find.byIcon(LucideIcons.squarePen));
    await tester.pumpAndSettle();
    expect(find.text('Editing bill mat-uuid-1'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();

    // Tapping again opens PendingBillSheet where the user can skip the bill.
    await tester.tap(find.text('Monthly Rent'));
    await tester.pumpAndSettle();
    expect(find.byType(PendingBillSheet), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byType(PendingBillSheet),
      matching: find.byIcon(LucideIcons.ellipsisVertical),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip this bill'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(recurring.deleteCalls, [
      (scheduledId: 'mat-uuid-1', scope: RecurringScope.thisOnly),
    ]);
    expect(find.byType(PendingBillSheet), findsNothing);
  });

  testWidgets(
      'tapping a virtual pending bill shows localized SnackBar when '
      'materialization is rejected', (tester) async {
    final recurring = _StubRecurringService()
      ..materializeResult = const Result.failure(
        LedgerErrorCode.recurringSeriesStopped,
        'Series stopped',
      );
    const nov2026 = YearMonth(2026, 11);
    final service = _StubBudgetService(buildSummary(
      month: nov2026,
      actualMinor: 0,
      pendingMinor: 300000,
      committedBaselineMinor: 300000,
      contributions: [
        BudgetContributionTx(
          transactionId: 'virtual:series-rent:2026-11-01',
          sourceScheduledBillId: null,
          scheduledBillId: null,
          seriesId: 'series-rent',
          occurrenceKey: '2026-11-01',
          isVirtual: true,
          description: 'Monthly Rent',
          occurredAt: DateTime(2026, 11, 1, 9, 0),
          amountMinor: 300000,
          isPending: true,
          accountName: 'Cash',
        ),
      ],
    ));
    await pumpDetail(
      tester,
      service: service,
      month: nov2026,
      size: const Size(900, 1200),
      recurringService: recurring,
    );

    await tester.tap(find.text('Monthly Rent'));
    await tester.pumpAndSettle();

    expect(find.byType(PendingBillSheet), findsNothing);
    expect(find.text('This recurring rule has been stopped'), findsOneWidget);
  });

  testWidgets(
      'tapping a virtual pending bill from View all contributions materializes '
      'it and opens PendingBillSheet', (tester) async {
    final recurring = _StubRecurringService();
    const nov2026 = YearMonth(2026, 11);
    final service = _StubBudgetService(buildSummary(
      month: nov2026,
      actualMinor: 0,
      pendingMinor: 400000,
      committedBaselineMinor: 400000,
      contributions: [
        for (var i = 1; i <= 4; i++)
          BudgetContributionTx(
            transactionId: 'virtual:series-week:2026-11-0$i',
            sourceScheduledBillId: null,
            scheduledBillId: null,
            seriesId: 'series-week',
            occurrenceKey: '2026-11-0$i',
            isVirtual: true,
            description: 'Weekly Bill $i',
            occurredAt: DateTime(2026, 11, i, 9, 0),
            amountMinor: 100000,
            isPending: true,
            accountName: 'Cash',
          ),
      ],
    ));
    await pumpDetail(
      tester,
      service: service,
      month: nov2026,
      size: const Size(900, 1200),
      recurringService: recurring,
    );

    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Weekly Bill 4'));
    await tester.pumpAndSettle();

    expect(recurring.materializeCalls, [
      (seriesId: 'series-week', occurrenceKey: '2026-11-04'),
    ]);
    expect(find.byType(PendingBillSheet), findsOneWidget);
  });

  testWidgets('contributions share one card with a meta-only subtitle',
      (tester) async {
    final service = _StubBudgetService(buildSummary(contributions: [
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
      BudgetContributionTx(
        transactionId: 'bill-4',
        sourceScheduledBillId: 'bill-4',
        scheduledBillId: 'bill-4',
        description: 'Gym',
        occurredAt: DateTime(2026, 5, 10),
        amountMinor: 20000,
        isPending: true,
        accountName: 'Bank',
      ),
    ]));
    await pumpDetail(tester, service: service, size: const Size(900, 1200));

    // Both rows live inside one grouped card, not one card per transaction.
    final card =
        find.ancestor(of: find.text('Lunch'), matching: find.byType(AppCard));
    expect(card, findsOneWidget);
    expect(
        find.descendant(of: card, matching: find.text('Gym')), findsOneWidget);

    // The subtitle is meta only: the kind prefix lives in the amount's sign.
    expect(find.textContaining('Expense ·'), findsNothing);
    expect(find.text('5/10 00:00 · Cash'), findsOneWidget);
    expect(find.text('5/10 00:00 · Bank'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    // Committed vs flexible is the composition card's story; repeating it on
    // every contribution row adds a label with no decision behind it.
    expect(find.descendant(of: card, matching: find.text('Committed')),
        findsNothing);
    expect(find.descendant(of: card, matching: find.text('Discretionary')),
        findsNothing);
  });

  testWidgets(
      'the app bar carries a circular avatar and a visible adjust action',
      (tester) async {
    final service = _StubBudgetService(buildSummary());
    await pumpDetail(tester, service: service, size: const Size(900, 1200));

    final avatar = tester.widget<Container>(
      find.byKey(const ValueKey('budget-detail-avatar')),
    );
    expect((avatar.decoration! as BoxDecoration).shape, BoxShape.circle);
    expect(find.text('Adjust budget'), findsOneWidget);

    // The category name wears the same title role as every other app bar,
    // and the bar leaves its surface to the shared theme.
    final appBar = find.byType(AppBar);
    final theme = Theme.of(tester.element(appBar));
    final name = tester.widget<Text>(
      find.descendant(of: appBar, matching: find.text('Dining')),
    );
    expect(name.style, theme.appBarTheme.titleTextStyle);
    expect(tester.widget<AppBar>(appBar).backgroundColor, isNull);

    await tester.tap(find.text('Adjust budget'));
    await tester.pumpAndSettle();
    expect(find.text('Dining budget'), findsOneWidget);
  });

  testWidgets('the progress card headlines projected remaining with one bar',
      (tester) async {
    final service = _StubBudgetService(buildSummary(pendingMinor: 20000));
    await pumpDetail(tester, service: service, size: const Size(400, 700));

    // ¥1000 budget − ¥450 spent − ¥200 pending = ¥350 projected left.
    expect(
        inProgressCard(find.text('Projected left \$350.00')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('budget-detail-bar-actual')), findsOneWidget);
    expect(find.byKey(const ValueKey('budget-detail-bar-pending')),
        findsOneWidget);

    final widths = [
      for (final key in const [
        'budget-detail-metric-spent',
        'budget-detail-metric-pending',
        'budget-detail-metric-budget',
      ])
        tester.getSize(find.byKey(ValueKey(key))).width,
    ];
    expect(widths[0], closeTo(widths[1], 0.5));
    expect(widths[1], closeTo(widths[2], 0.5));
  });

  testWidgets('the note card opens the shared sheet and cancel keeps the note',
      (tester) async {
    final service = _StubBudgetService(buildSummary());
    await pumpDetail(tester, service: service, size: const Size(900, 1200));

    expect(find.text('Old note'), findsOneWidget);
    await openNoteSheet(tester);

    expect(tester.widget<TextField>(noteField).controller!.text, 'Old note');

    await tester.enterText(noteField, 'Unsaved thought');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(service.savedNote, isNull);
    expect(find.text('Old note'), findsOneWidget);
  });

  testWidgets('a 500-character note saves and a 501-character note is refused',
      (tester) async {
    final service = _StubBudgetService(buildSummary());
    await pumpDetail(tester, service: service, size: const Size(900, 1200));

    await openNoteSheet(tester);
    await tester.enterText(noteField, 'x' * 500);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();
    expect(service.savedNote, 'x' * 500);
    expect(find.text('Review note saved'), findsOneWidget);
    await dismissSnackBar(tester);

    service.savedNote = null;
    await openNoteSheet(tester);
    await tester.enterText(noteField, 'y' * 501);
    await tester.pumpAndSettle();

    expect(find.text('501/500'), findsOneWidget);
    final save = find.widgetWithText(AppButton, 'Save note');
    expect(tester.widget<AppButton>(save).onPressed, isNull);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(service.savedNote, isNull);
    // The oversized draft stays where the user left it.
    expect(tester.widget<TextField>(noteField).controller!.text, 'y' * 501);
  });

  testWidgets('an empty note clears it and a failed save keeps the draft',
      (tester) async {
    final service = _StubBudgetService(buildSummary());
    await pumpDetail(tester, service: service, size: const Size(900, 1200));

    await openNoteSheet(tester);
    await tester.enterText(noteField, '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();
    expect(service.savedNote, '');
    await dismissSnackBar(tester);

    service.noteResult = const Result.failure(
        LedgerErrorCode.categoryArchived, 'category is archived');
    await openNoteSheet(tester);
    await tester.enterText(noteField, 'Draft note');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();
    expect(find.text('Category is archived'), findsOneWidget);
    expect(tester.widget<TextField>(noteField).controller!.text, 'Draft note');
  });

  testWidgets('the shared sheet deletes the note and undo restores it',
      (tester) async {
    final service = _StubBudgetService(buildSummary());
    await pumpDetail(tester, service: service, size: const Size(900, 1200));

    await openNoteSheet(tester);
    await tester.tap(find.byKey(const ValueKey('budget-note-delete')));
    await tester.pumpAndSettle();

    expect(service.savedNote, '');
    expect(find.text('Review note deleted'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(service.savedNote, 'Old note');
  });

  testWidgets('the empty note prompt fits a narrow, large-text page',
      (tester) async {
    final service = _StubBudgetService(buildSummary(note: null));
    await pumpDetail(tester,
        service: service, size: const Size(320, 740), textScale: 1.6);

    await tester.scrollUntilVisible(find.byType(BudgetNoteCard), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text("Jot down this category's review"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('archived categories show their note read-only without a menu',
      (tester) async {
    final service = _StubBudgetService(buildSummary(
      archived: true,
      note: 'Kept from April',
    ));
    await pumpDetail(tester, service: service, size: const Size(400, 700));

    expect(find.text('Archived'), findsOneWidget);
    expect(find.text('Kept from April'), findsOneWidget);
    expect(
      find.text(
          'Archived category — historical budgets and notes are read-only.'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Save note'), findsNothing);
    expect(find.byKey(const ValueKey('budget-note-edit')), findsNothing);
    expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
  });

  testWidgets('removing the budget refreshes the note and its chart marker',
      (tester) async {
    final trend = [
      _point(const YearMonth(2026, 4), budgetMinor: 90000, actualMinor: 30000),
      _point(_may,
          budgetMinor: 100000, actualMinor: 45000, hasReviewNote: true),
    ];
    final service = _StubBudgetService(buildSummary(sixMonthTrend: trend));
    await pumpDetail(tester, service: service, size: const Size(900, 1200));

    final marker =
        find.byKey(const ValueKey('budget-trend-note-marker-2026-05'));
    expect(marker, findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete budget'));
    await tester.pumpAndSettle();
    expect(service.lastScope, BudgetEditScope.thisMonthOnly);
    expect(find.text('Budget deleted'), findsOneWidget);

    // The write lands as a new stream value: the note above the field and the
    // chart marker both come from it, never from a cached copy.
    service.emit(buildSummary(
      budgetMinor: null,
      note: null,
      sixMonthTrend: [
        _point(const YearMonth(2026, 4),
            budgetMinor: 90000, actualMinor: 30000),
        _point(_may, budgetMinor: null, actualMinor: 45000),
      ],
    ));
    await tester.pumpAndSettle();

    expect(marker, findsNothing);
    expect(find.text('Old note'), findsNothing);
    expect(find.text("Jot down this category's review"), findsOneWidget);

    // With no budget left there is nothing to delete, so the overflow menu
    // (whose only item is 删除预算) leaves the app bar. 调预算 stays.
    expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
    expect(find.text('Delete budget'), findsNothing);
    expect(find.text('Adjust budget'), findsOneWidget);
  });

  testWidgets('a note arriving from the stream never overwrites a live draft',
      (tester) async {
    final service = _StubBudgetService(buildSummary());
    await pumpDetail(tester, service: service, size: const Size(900, 1200));

    await openNoteSheet(tester);
    await tester.enterText(noteField, 'Unsaved thought');
    await tester.pumpAndSettle();

    service.emit(buildSummary(note: 'Saved elsewhere'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(noteField).controller!.text,
      'Unsaved thought',
    );
  });

  testWidgets(
      'a closed month reports actual only; the open month shows pending',
      (tester) async {
    // April is behind the clock (May 2026): its pending figure is not part of
    // the story it tells.
    final aprilService = _StubBudgetService(buildSummary(
      month: const YearMonth(2026, 4),
      pendingMinor: 20000,
    ));
    await pumpDetail(
      tester,
      service: aprilService,
      month: const YearMonth(2026, 4),
      size: const Size(900, 1200),
    );
    expect(inProgressCard(find.text('Pending')), findsNothing);
    expect(inCompositionCard(find.text('Pending')), findsNothing);

    final mayService = _StubBudgetService(buildSummary(pendingMinor: 20000));
    await pumpDetail(tester, service: mayService, size: const Size(900, 1200));
    expect(inProgressCard(find.text('Pending')), findsOneWidget);
    expect(inCompositionCard(find.text('Pending')), findsNothing);
  });

  testWidgets('category detail never renders the removed materialized-only hint',
      (tester) async {
    final hint = find.text('Only generated recurring bills are included.');
    final service = _StubBudgetService(buildSummary(pendingMinor: 20000));
    await pumpDetail(tester, service: service, size: const Size(900, 1200));
    expect(hint, findsNothing);
  });

  final richSummary = buildSummary(
    actualMinor: 300000,
    pendingMinor: 20000,
    committedActualMinor: 120000,
    committedBaselineMinor: 150000,
    threeMonthAvgMinor: 75000,
    isAnomaly: true,
    anomalyDeltaRatio: 3.0,
    contributions: [
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
      BudgetContributionTx(
        transactionId: 'tx-4',
        sourceScheduledBillId: 'bill-4',
        scheduledBillId: 'bill-4',
        description: 'Expense 4',
        occurredAt: DateTime(2026, 5, 10),
        amountMinor: 10000,
        isPending: true,
        accountName: 'Cash',
      ),
    ],
  );

  for (final config in const [
    (label: 'light 400x700', size: Size(400, 700), textScale: 1.0, dark: false),
    (label: 'dark 400x700', size: Size(400, 700), textScale: 1.0, dark: true),
    (
      label: 'narrow 320dp at 1.5x text',
      size: Size(320, 740),
      textScale: 1.5,
      dark: false
    ),
    (
      label: 'narrow 320dp at 1.6x text',
      size: Size(320, 740),
      textScale: 1.6,
      dark: false
    ),
    (label: 'wide 900dp', size: Size(900, 1200), textScale: 1.0, dark: false),
  ]) {
    testWidgets('sections stay unclipped and reachable at ${config.label}',
        (tester) async {
      final service = _StubBudgetService(richSummary);
      await pumpDetail(
        tester,
        service: service,
        size: config.size,
        textScale: config.textScale,
        theme: config.dark ? AppTheme.darkTheme : null,
      );

      // Back affordance: at least the design system's control height.
      final back = find.byType(AppIconButton).first;
      expect(tester.getSize(back).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(back).width, greaterThanOrEqualTo(48));

      // The composition card is reachable by scrolling at every width, and
      // none of its figures is truncated with an ellipsis or a line cap.
      await tester.scrollUntilVisible(find.text('Spending composition'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(find.text('Spending composition'), findsOneWidget);
      for (final text in tester.widgetList<Text>(find.descendant(
        of: find.byType(BudgetCategoryCompositionCard),
        matching: find.byType(Text),
      ))) {
        expect(text.overflow, isNot(TextOverflow.ellipsis));
        expect(text.maxLines, isNull);
      }
      expect(inCompositionCard(find.text('Committed')), findsOneWidget);
      expect(
          inCompositionCard(
              find.text('Committed \$1500.00 · Last mo \$800.00')),
          findsOneWidget);
      expect(inCompositionCard(find.text('3-mo avg \$750.00')), findsNothing);
      expect(
        tester.getSize(find.byType(BudgetCategoryCompositionCard)).width,
        lessThanOrEqualTo(config.size.width),
      );

      await tester.scrollUntilVisible(find.byType(BudgetNoteCard), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await openNoteSheet(tester);
      final save = find.widgetWithText(AppButton, 'Save note');
      expect(tester.getSize(save).height, greaterThanOrEqualTo(40));
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(service.savedNote, 'Old note');
      expect(find.text('Review note saved'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  }
}
