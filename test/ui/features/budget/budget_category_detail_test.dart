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
import 'package:feather_ledger/features/budget/presentation/widgets/budget_trend_chart.dart';
import 'package:feather_ledger/features/ledger/data/repositories/ledger_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';

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
  Future<ScheduledTransactionEntity?> getScheduledTransaction(
      String id) async {
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
  bool hasHighFrequencyPending = false,
  bool isFarFutureMaterializedOnly = false,
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
    projectedRemainingMinor: budgetMinor == null
        ? 0
        : budgetMinor - actualMinor - pendingMinor,
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
    hasHighFrequencyPending: hasHighFrequencyPending,
    isFarFutureMaterializedOnly: isFarFutureMaterializedOnly,
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
          body: Text(
              'Editing ${(state.extra as TransactionTileUiModel).id}'),
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
      find.text(
          'Spending is 300% above the 3-month average of \$750.00.'),
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
      _point(const YearMonth(2026, 6),
          budgetMinor: 100000, actualMinor: 38000),
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
    expect(find.text('All actual spend'), findsOneWidget);

    await pumpMonthlyChart(tester,
        [_chartPoint(_may, budgetMinor: 100000, actualMinor: 45000)]);
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

  testWidgets('View all round trip keeps an unsaved note draft',
      (tester) async {
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
      for (var i = 2; i <= 4; i++)
        BudgetContributionTx(
          transactionId: 'tx-$i',
          sourceScheduledBillId: null,
          scheduledBillId: null,
          description: 'Expense $i',
          occurredAt: DateTime(2026, 5, 10),
          amountMinor: 10000 ~/ i,
          isPending: false,
          accountName: 'Cash',
        ),
    ];
    final service =
        _StubBudgetService(buildSummary(contributions: contributions));
    await pumpDetail(tester, service: service, size: const Size(900, 1200));

    await tester.enterText(find.byType(TextField), 'Unsaved thought');
    await tester.pumpAndSettle();
    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();
    expect(find.text('Expense 4'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Unsaved thought'), findsOneWidget);
  });

  testWidgets('a 500-character note saves and a 501-character note is refused',
      (tester) async {
    final service = _StubBudgetService(buildSummary());
    await pumpDetail(tester, service: service, size: const Size(900, 1200));

    await tester.enterText(find.byType(TextField), 'x' * 500);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();
    expect(service.savedNote, 'x' * 500);
    expect(find.text('Review note saved'), findsOneWidget);
    await dismissSnackBar(tester);

    service.savedNote = null;
    await tester.enterText(find.byType(TextField), 'y' * 501);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();

    expect(service.savedNote, isNull);
    expect(find.text('Review note cannot exceed 500 characters'),
        findsOneWidget);
    // The oversized draft stays where the user left it.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'y' * 501,
    );
  });

  testWidgets('an empty note clears it and a failed save keeps the draft',
      (tester) async {
    final service = _StubBudgetService(buildSummary());
    await pumpDetail(tester, service: service, size: const Size(900, 1200));

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();
    expect(service.savedNote, '');
    await dismissSnackBar(tester);

    service.noteResult = const Result.failure(
        LedgerErrorCode.categoryArchived, 'category is archived');
    await tester.enterText(find.byType(TextField), 'Draft note');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();
    expect(find.text('Category is archived'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Draft note',
    );
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
    expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
  });

  testWidgets('removing the budget refreshes the note and its chart marker',
      (tester) async {
    final trend = [
      _point(const YearMonth(2026, 4),
          budgetMinor: 90000, actualMinor: 30000),
      _point(_may, budgetMinor: 100000, actualMinor: 45000, hasReviewNote: true),
    ];
    final service = _StubBudgetService(buildSummary(sixMonthTrend: trend));
    await pumpDetail(tester, service: service, size: const Size(900, 1200));

    final marker = find.byKey(const ValueKey('budget-trend-note-marker-2026-05'));
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
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    expect(find.text('0/500'), findsOneWidget);
  });

  testWidgets('a note arriving from the stream never overwrites a live draft',
      (tester) async {
    final service = _StubBudgetService(buildSummary());
    await pumpDetail(tester, service: service, size: const Size(900, 1200));

    await tester.enterText(find.byType(TextField), 'Unsaved thought');
    await tester.pumpAndSettle();

    service.emit(buildSummary(note: 'Saved elsewhere'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Unsaved thought',
    );
  });

  testWidgets('a closed month reports actual only; the open month shows pending',
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
    expect(inCompositionCard(find.text('Pending')), findsOneWidget);
  });

  testWidgets('the materialization hint explains high-frequency pending bills',
      (tester) async {
    final hint = find.text('Includes materialized pending bills only.');
    final plain = _StubBudgetService(buildSummary());
    await pumpDetail(tester, service: plain, size: const Size(900, 1200));
    expect(hint, findsNothing);

    final materialized = _StubBudgetService(buildSummary(
      pendingMinor: 20000,
      hasHighFrequencyPending: true,
    ));
    await pumpDetail(
        tester, service: materialized, size: const Size(900, 1200));
    expect(hint, findsOneWidget);
  });

  final richSummary = buildSummary(
    actualMinor: 300000,
    pendingMinor: 20000,
    committedActualMinor: 120000,
    committedBaselineMinor: 150000,
    threeMonthAvgMinor: 75000,
    isAnomaly: true,
    anomalyDeltaRatio: 3.0,
    hasHighFrequencyPending: true,
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
      await tester.scrollUntilVisible(
          find.text('Spending composition'), 200,
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
      expect(inCompositionCard(find.text('Committed \$1500.00')),
          findsOneWidget);
      expect(inCompositionCard(find.text('Last mo \$800.00')),
          findsOneWidget);
      expect(inCompositionCard(find.text('3-mo avg \$750.00')),
          findsOneWidget);
      expect(
        tester.getSize(find.byType(BudgetCategoryCompositionCard)).width,
        lessThanOrEqualTo(config.size.width),
      );

      await tester.scrollUntilVisible(find.text('Save note'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
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
