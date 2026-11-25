import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/budget/domain/entities/budget_entities.dart';
import 'package:feather_ledger/features/budget/domain/services/budget_service.dart';
import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';
import 'package:feather_ledger/features/budget/presentation/screens/budget_category_detail_screen.dart';
import 'package:feather_ledger/features/budget/presentation/screens/budget_review_screen.dart';
import 'package:feather_ledger/features/budget/presentation/screens/budget_screen.dart';
import 'package:feather_ledger/features/budget/presentation/widgets/budget_overview_card.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_month_picker.dart';

/// The clock the screen runs on: May 2026 is the current (track) month, so
/// April is closed and June is still a plan.
final _today = DateTime(2026, 5, 10);

const _apr = YearMonth(2026, 4);
const _may = YearMonth(2026, 5);
const _jun = YearMonth(2026, 6);

/// The single review entry of a month: compact bar under the hero for a closed
/// month, full-width card at the end of the page for the current one.
const _reviewBarKey = ValueKey('budget-review-bar');
const _reviewEntryKey = ValueKey('budget-review-entry');
const _planHintKey = ValueKey('budget-plan-hint');

BudgetMode _modeOf(YearMonth month) {
  final nowYm = YearMonth.fromDate(_today);
  if (month > nowYm) return BudgetMode.plan;
  if (month < nowYm) return BudgetMode.review;
  return BudgetMode.track;
}

class _FakeBudgetService implements BudgetService {
  final Map<YearMonth, MonthBudgetSummary> overrides;

  _FakeBudgetService({this.overrides = const {}});

  /// Months the PageView pages past get the default fixture for their mode.
  MonthBudgetSummary _summaryFor(YearMonth month) =>
      overrides[month] ?? _summary(month);

  @override
  Stream<MonthBudgetSummary> watchMonthBudget({
    required String currencyCode,
    required YearMonth month,
  }) =>
      Stream.value(_summaryFor(month));

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
  }) async =>
      unitResult;

  @override
  Future<Result<void>> saveReviewNote({
    required String currencyCode,
    required YearMonth month,
    String? categoryId,
    required String note,
  }) async =>
      unitResult;
}

CategoryBudgetSummary _cat({
  required String id,
  required String name,
  required YearMonth month,
  int? budgetMinor,
  int actualMinor = 0,
  int pendingMinor = 0,
  int committedMinor = 0,
  int? prevBudgetMinor,
}) {
  // The plan hint's carry-forward claim reads this category's own trend: a
  // point for the target month's predecessor holding the same limit means the
  // rule carried over unchanged.
  final prevBudget = prevBudgetMinor ?? budgetMinor;
  return CategoryBudgetSummary(
    categoryId: id,
    categoryName: name,
    iconKey: 'utensils',
    colorInt: 0xFFE65100,
    isArchived: false,
    archiveYm: null,
    budgetMinor: budgetMinor,
    hasFutureRulesAfter: false,
    committedActualMinor: committedMinor,
    discretionaryActualMinor: actualMinor - committedMinor,
    actualMinor: actualMinor,
    pendingMinor: pendingMinor,
    projectedRemainingMinor: budgetMinor != null
        ? budgetMinor - actualMinor - pendingMinor
        : null,
    lastMonthActualMinor: 50000,
    threeMonthAvgMinor: 60000,
    committedBaselineMinor: committedMinor,
    isAnomaly: false,
    anomalyDeltaRatio: null,
    riskLevel: BudgetRiskLevel.inBudget,
    sixMonthTrend: [
      for (var back = 5; back >= 0; back--)
        BudgetTrendPoint(
          month: month.addMonths(-back),
          budgetMinor: back == 1 ? prevBudget : budgetMinor,
          actualMinor: actualMinor,
          pendingMinor: 0,
          hasReviewNote: false,
        ),
    ],
    topTransactions: const [],
    reviewNote: null,
  );
}

/// Four normally-named budgeted categories, one unbudgeted spend and one
/// untouched category, with totals derived from the rows so the fixtures can
/// never disagree with the numbers the page shows.
MonthBudgetSummary _summary(
  YearMonth month, {
  bool hasAnyActiveAccount = true,
  List<CategoryBudgetSummary>? budgeted,
  List<CategoryBudgetSummary>? unbudgeted,
  List<CategoryBudgetSummary>? remaining,
  List<BudgetAttributionItem> overBudget = const [],
  List<BudgetAttributionItem> underBudget = const [],
  String? note,
  bool hasHighFrequencyPending = false,
}) {
  final resolvedMode = _modeOf(month);
  final closed = resolvedMode == BudgetMode.review;
  final budgetedRows = budgeted ??
      [
        _cat(
          id: 'dining',
          name: 'Dining',
          month: month,
          budgetMinor: 100000,
          actualMinor: 40000,
          pendingMinor: closed ? 0 : 10000,
        ),
        _cat(
          id: 'groceries',
          name: 'Groceries',
          month: month,
          budgetMinor: 50000,
          actualMinor: 20000,
        ),
        _cat(
          id: 'transport',
          name: 'Transport',
          month: month,
          budgetMinor: 30000,
          actualMinor: 30000,
        ),
        _cat(
          id: 'housing',
          name: 'Housing',
          month: month,
          budgetMinor: 200000,
          actualMinor: 200000,
        ),
      ];
  final unbudgetedRows = unbudgeted ??
      [
        _cat(id: 'travel', name: 'Travel', month: month, actualMinor: 25000),
      ];
  final remainingRows = remaining ??
      [_cat(id: 'utils', name: 'Utilities', month: month)];

  int total(Iterable<int> values) => values.fold(0, (a, b) => a + b);
  int actualOf(List<CategoryBudgetSummary> rows) =>
      total(rows.map((c) => c.actualMinor));
  int pendingOf(List<CategoryBudgetSummary> rows) =>
      total(rows.map((c) => c.pendingMinor));

  final totalBudget =
      total(budgetedRows.map((c) => c.budgetMinor).whereType<int>());
  final budgetedActual = actualOf(budgetedRows);
  final budgetedPending = pendingOf(budgetedRows);
  final unbudgetedActual = actualOf(unbudgetedRows);
  final unbudgetedPending = pendingOf(unbudgetedRows);
  final budgetedCount =
      budgetedRows.where((c) => c.budgetMinor != null).length;
  final inBudget = budgetedRows
      .where((c) =>
          c.budgetMinor != null &&
          c.actualMinor + c.pendingMinor <= c.budgetMinor!)
      .length;
  final allActual = budgetedActual + unbudgetedActual;

  return MonthBudgetSummary(
    currencyCode: 'USD',
    month: month,
    mode: resolvedMode,
    hasAnyActiveAccount: hasAnyActiveAccount,
    totalBudgetMinor: totalBudget,
    budgetedActualMinor: budgetedActual,
    budgetedPendingMinor: budgetedPending,
    projectedRemainingMinor: totalBudget - budgetedActual - budgetedPending,
    budgetedRemainingActualMinor: totalBudget - budgetedActual,
    allExpenseActualMinor: allActual,
    allExpensePendingMinor: budgetedPending + unbudgetedPending,
    unbudgetedActualMinor: unbudgetedActual,
    unbudgetedPendingMinor: unbudgetedPending,
    inBudgetCount: inBudget,
    budgetedCategoryCount: budgetedCount,
    complianceRate: budgetedCount == 0 ? 0 : inBudget / budgetedCount,
    hasAnyBudget: budgetedCount > 0,
    hasUnbudgetedActivity: unbudgetedActual + unbudgetedPending > 0,
    hasLeftoverPendingInReview: closed && budgetedPending > 0,
    hasHighFrequencyPending: hasHighFrequencyPending,
    isFarFutureMaterializedOnly: false,
    budgetedCategories: budgetedRows,
    unbudgetedActiveCategories: unbudgetedRows,
    remainingActiveCategories: remainingRows,
    overBudgetTop3: overBudget,
    underBudgetTop3: underBudget,
    unbudgetedAlertsTop3: [
      if (unbudgetedActual + unbudgetedPending > 0)
        UnbudgetedSpendAlert(
          categoryId: 'travel',
          categoryName: 'Travel',
          iconKey: 'utensils',
          colorInt: 0xFFE65100,
          actualMinor: unbudgetedActual,
          pendingMinor: unbudgetedPending,
          shareOfTotalActual:
              allActual == 0 ? 0 : unbudgetedActual / allActual,
        ),
    ],
    monthTrend6Months: [
      for (var back = 5; back >= 0; back--)
        BudgetTrendPoint(
          month: month.addMonths(-back),
          budgetMinor: totalBudget,
          actualMinor: allActual,
          pendingMinor: 0,
          hasReviewNote: false,
        ),
    ],
    monthReviewNote: note,
  );
}

BudgetAttributionItem _attribution({
  required String id,
  required String name,
  required int varianceMinor,
}) =>
    BudgetAttributionItem(
      categoryId: id,
      categoryName: name,
      iconKey: 'utensils',
      colorInt: 0xFFE65100,
      budgetMinor: 100000,
      actualMinor: 100000 + varianceMinor,
      varianceMinor: varianceMinor,
      shareOfTotalActual: 0.5,
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  Future<void> pumpBudgetScreen(
    WidgetTester tester, {
    required _FakeBudgetService service,
    Size size = const Size(400, 700),
    ThemeData? theme,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          budgetClockProvider.overrideWithValue(FixedClock(_today)),
          budgetServiceProvider.overrideWithValue(service),
          ledgerCurrencyProvider.overrideWithValue('USD'),
          displayCurrencySymbolProvider.overrideWithValue('\$'),
        ],
        child: MaterialApp(
          theme: theme ?? AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: const BudgetScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double topOf(WidgetTester tester, Finder finder) =>
      tester.getTopLeft(finder).dy;

  testWidgets('track month runs overview, budgeted, unbudgeted, review entry',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: _FakeBudgetService(overrides: {_may: _summary(_may)}),
      size: const Size(400, 1600),
    );

    expect(find.byType(BudgetOverviewCard), findsOneWidget);
    expect(find.text('Budgeted categories'), findsOneWidget);
    expect(find.text('Unbudgeted spending'), findsOneWidget);
    expect(find.byKey(_reviewEntryKey), findsOneWidget);
    expect(find.byKey(_reviewBarKey), findsNothing);
    expect(find.byKey(_planHintKey), findsNothing);
    // Exactly one review entry: the card's title appears once.
    expect(find.text('Monthly Review & Trends'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(_reviewEntryKey),
        matching: find.byIcon(LucideIcons.barChart2),
      ),
      findsOneWidget,
    );

    expect(
      topOf(tester, find.byType(BudgetOverviewCard)),
      lessThan(topOf(tester, find.text('Budgeted categories'))),
    );
    expect(
      topOf(tester, find.text('Budgeted categories')),
      lessThan(topOf(tester, find.text('Unbudgeted spending'))),
    );
    expect(
      topOf(tester, find.text('Unbudgeted spending')),
      lessThan(topOf(tester, find.text('Travel'))),
    );
    expect(
      topOf(tester, find.text('Travel')),
      lessThan(topOf(tester, find.byKey(_reviewEntryKey))),
    );
  });

  testWidgets('track entry prefers the worst overrun over a surplus',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: _FakeBudgetService(overrides: {
        _may: _summary(
          _may,
          overBudget: [
            _attribution(
                id: 'dining', name: 'Dining', varianceMinor: -40000),
          ],
          underBudget: [
            _attribution(
                id: 'groceries', name: 'Groceries', varianceMinor: 30000),
          ],
        ),
      }),
      size: const Size(400, 1600),
    );

    expect(find.text('Dining over by \$400.00'), findsOneWidget);
    expect(find.textContaining('unspent'), findsNothing);
  });

  testWidgets('track entry falls back to the biggest surplus', (tester) async {
    await pumpBudgetScreen(
      tester,
      service: _FakeBudgetService(overrides: {
        _may: _summary(
          _may,
          underBudget: [
            _attribution(
                id: 'groceries', name: 'Groceries', varianceMinor: 30000),
          ],
        ),
      }),
      size: const Size(400, 1600),
    );

    expect(find.text('Groceries unspent \$300.00'), findsOneWidget);
  });

  testWidgets('track entry says so when every limit still holds',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: _FakeBudgetService(overrides: {_may: _summary(_may)}),
      size: const Size(400, 1600),
    );

    expect(
      find.text('Every budgeted category is still inside its limit'),
      findsOneWidget,
    );
  });

  testWidgets('closed month puts its only review entry under the hero',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: _FakeBudgetService(overrides: {
        _may: _summary(_may),
        _apr: _summary(
          _apr,
          overBudget: [
            _attribution(
                id: 'dining', name: 'Dining', varianceMinor: -40000),
          ],
          note: 'Travel spiked on the spring trip and never came back down',
        ),
      }),
      size: const Size(400, 1600),
    );

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('April 2026'), findsOneWidget);

    expect(find.byKey(_reviewBarKey), findsOneWidget);
    expect(find.byKey(_reviewEntryKey), findsNothing);
    expect(find.text('Monthly Review & Trends'), findsOneWidget);
    expect(find.text('Dining over by \$400.00'), findsOneWidget);

    // The note is previewed, cut short rather than spilling onto the page.
    final preview = tester.widget<Text>(
      find.textContaining('Note: Travel spiked'),
    );
    expect(preview.data, isNot(contains('came back down')));
    expect(preview.maxLines, 1);

    // Directly under the hero, above the category list.
    expect(
      topOf(tester, find.byType(BudgetOverviewCard)),
      lessThan(topOf(tester, find.byKey(_reviewBarKey))),
    );
    expect(
      topOf(tester, find.byKey(_reviewBarKey)),
      lessThan(topOf(tester, find.text('Budgeted categories'))),
    );

    await tester.tap(find.byKey(_reviewBarKey));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetReviewScreen), findsOneWidget);
    expect(find.text('April 2026'), findsOneWidget);
  });

  testWidgets('closed month with nothing to attribute still opens the review',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: _FakeBudgetService(overrides: {
        _may: _summary(_may),
        _apr: _summary(_apr),
      }),
      size: const Size(400, 1600),
    );

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();

    expect(
      find.text('Every budgeted category is still inside its limit'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(_reviewBarKey));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetReviewScreen), findsOneWidget);
  });

  testWidgets('future month ends in a planning hint, not a review entry',
      (tester) async {
    final plan = _summary(
      _jun,
      budgeted: [
        _cat(
          id: 'dining',
          name: 'Dining',
          month: _jun,
          budgetMinor: 100000,
          committedMinor: 60000,
          pendingMinor: 60000,
        ),
        _cat(
          id: 'groceries',
          name: 'Groceries',
          month: _jun,
          budgetMinor: 50000,
        ),
        _cat(
          id: 'housing',
          name: 'Housing',
          month: _jun,
          budgetMinor: 200000,
          committedMinor: 150000,
          pendingMinor: 150000,
        ),
      ],
      unbudgeted: [_cat(id: 'travel', name: 'Travel', month: _jun)],
      remaining: [_cat(id: 'utils', name: 'Utilities', month: _jun)],
      hasHighFrequencyPending: true,
    );

    await pumpBudgetScreen(
      tester,
      service: _FakeBudgetService(overrides: {_may: _summary(_may), _jun: plan}),
      size: const Size(400, 1600),
    );

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('June 2026'), findsOneWidget);

    expect(find.byKey(_planHintKey), findsOneWidget);
    expect(find.byKey(_reviewEntryKey), findsNothing);
    expect(find.byKey(_reviewBarKey), findsNothing);
    expect(find.text('Monthly Review & Trends'), findsNothing);
    // The rules the rows show *are* last month's, so the page may say so.
    expect(
      find.textContaining("Last month's rules carry forward"),
      findsOneWidget,
    );
    expect(find.textContaining('Fixed bills \$2100.00'), findsOneWidget);
    expect(
      find.text('Includes materialized pending bills only.'),
      findsOneWidget,
    );
  });

  testWidgets('future month drops the carry-forward claim once a limit differs',
      (tester) async {
    final replanned = _summary(
      _jun,
      budgeted: [
        _cat(
          id: 'dining',
          name: 'Dining',
          month: _jun,
          budgetMinor: 120000,
          prevBudgetMinor: 100000,
        ),
      ],
      unbudgeted: const [],
      remaining: [_cat(id: 'utils', name: 'Utilities', month: _jun)],
    );

    await pumpBudgetScreen(
      tester,
      service: _FakeBudgetService(
        overrides: {_may: _summary(_may), _jun: replanned},
      ),
      size: const Size(400, 1600),
    );

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();

    expect(find.byKey(_planHintKey), findsOneWidget);
    expect(find.textContaining('carry forward'), findsNothing);
    expect(
      find.textContaining('Nothing scheduled for this month yet'),
      findsOneWidget,
    );
  });

  testWidgets('a future row opens the editor, a current row opens the detail',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: _FakeBudgetService(overrides: {_may: _summary(_may)}),
    );

    await tester.tap(find.text('Dining'));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetCategoryDetailScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BudgetCategoryDetailScreen), findsNothing);
    expect(find.text('May 2026'), findsOneWidget);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dining'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Set Category Budget'), findsOneWidget);
    expect(find.byType(BudgetCategoryDetailScreen), findsNothing);
  });

  testWidgets('the + drawer offers only categories with no activity',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: _FakeBudgetService(overrides: {_may: _summary(_may)}),
    );

    expect(find.text('Utilities'), findsNothing);
    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    expect(find.text('Choose category'), findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.byType(ListTile)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Utilities')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Dining')),
      findsNothing,
    );

    await tester.tap(
      find.descendant(of: sheet, matching: find.text('Utilities')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Set Category Budget'), findsOneWidget);
  });

  testWidgets('the + action disappears when no category is left untouched',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: _FakeBudgetService(overrides: {
        _may: _summary(_may, remaining: const []),
      }),
    );

    expect(find.byIcon(LucideIcons.plus), findsNothing);
  });

  testWidgets('arrows, swipe and the month picker move across years',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: _FakeBudgetService(overrides: {_may: _summary(_may)}),
    );

    expect(find.text('May 2026'), findsOneWidget);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('June 2026'), findsOneWidget);

    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
    }
    expect(find.text('December 2025'), findsOneWidget);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('January 2026'), findsOneWidget);

    // Horizontal swipe pages the same way the arrows do.
    await tester.fling(find.byType(PageView), const Offset(200, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('December 2025'), findsOneWidget);

    await tester.tap(find.text('December 2025'));
    await tester.pumpAndSettle();
    expect(find.byType(FeatherMonthPicker), findsOneWidget);
  });

  testWidgets('returning from the review and the detail keeps the month',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: _FakeBudgetService(overrides: {
        _may: _summary(_may),
        _apr: _summary(_apr),
      }),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -220));
    await tester.pumpAndSettle();

    final groceries = find.text('Groceries');
    final beforeDetail = tester.getTopLeft(groceries).dy;
    await tester.tap(groceries);
    await tester.pumpAndSettle();
    expect(find.byType(BudgetCategoryDetailScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('May 2026'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Groceries')).dy, beforeDetail);

    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_reviewEntryKey));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetReviewScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BudgetReviewScreen), findsNothing);
    // Back on the same month, still scrolled where the entry was tapped.
    expect(find.text('May 2026'), findsOneWidget);
    expect(find.byKey(_reviewEntryKey), findsOneWidget);

    // A closed month entered from its bar returns to that month too.
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('April 2026'), findsOneWidget);
    await tester.tap(find.byKey(_reviewBarKey));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('April 2026'), findsOneWidget);
    expect(find.byKey(_reviewBarKey), findsOneWidget);
  });

  testWidgets('the last action on the page clears the bottom bar',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: _FakeBudgetService(overrides: {_may: _summary(_may)}),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    final viewport = tester.getRect(find.byType(ListView));
    final entry = tester.getRect(find.byKey(_reviewEntryKey));
    expect(viewport.bottom - entry.bottom, greaterThanOrEqualTo(88));
    expect(find.byKey(_reviewEntryKey).hitTestable(), findsOneWidget);
  });

  for (final (label, theme) in [
    ('light', AppTheme.lightTheme),
    ('dark', AppTheme.darkTheme),
  ]) {
    testWidgets('$label 400x700 shows the overview and at least three rows',
        (tester) async {
      await pumpBudgetScreen(
        tester,
        service: _FakeBudgetService(overrides: {_may: _summary(_may)}),
        theme: theme,
      );

      expect(find.byType(BudgetOverviewCard), findsOneWidget);
      expect(tester.takeException(), isNull);

      final viewport = tester.getRect(find.byType(ListView));
      final fullyVisible = [
        'Dining',
        'Groceries',
        'Transport',
        'Housing',
      ].where((name) {
        final rect = tester.getRect(find.text(name));
        return rect.top >= viewport.top && rect.bottom <= viewport.bottom;
      }).length;
      expect(fullyVisible, greaterThanOrEqualTo(3));
    });
  }

  testWidgets('320dp at 1.5x text keeps the rows readable and tappable',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: _FakeBudgetService(overrides: {_may: _summary(_may)}),
      size: const Size(320, 700),
      textScale: 1.5,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(BudgetOverviewCard), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Travel'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Travel'));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetCategoryDetailScreen), findsOneWidget);
  });

  testWidgets('900dp wide keeps the full names and tappable rows',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: _FakeBudgetService(overrides: {_may: _summary(_may)}),
      size: const Size(900, 700),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Budgeted categories'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('Unbudgeted spending'), findsOneWidget);

    await tester.tap(find.text('Groceries'));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetCategoryDetailScreen), findsOneWidget);
  });

  testWidgets('no accounts leads to account management', (tester) async {
    await pumpBudgetScreen(
      tester,
      service: _FakeBudgetService(overrides: {
        _may: _summary(_may, hasAnyActiveAccount: false, budgeted: const []),
      }),
    );

    expect(find.text('Create an account to start budgeting'), findsOneWidget);
    expect(
      find.text('No active accounts exist for USD yet.'),
      findsOneWidget,
    );
    expect(find.text('Manage Accounts'), findsOneWidget);
    expect(find.byType(BudgetOverviewCard), findsNothing);
    expect(find.byKey(_reviewEntryKey), findsNothing);
  });

  testWidgets('a month with no budget offers the first-budget entry',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: _FakeBudgetService(overrides: {
        _may: _summary(
          _may,
          budgeted: const [],
          unbudgeted: [
            _cat(id: 'travel', name: 'Travel', month: _may, actualMinor: 25000),
          ],
          remaining: [_cat(id: 'utils', name: 'Utilities', month: _may)],
        ),
      }),
      size: const Size(400, 1600),
    );

    expect(find.text('Plan your monthly spending'), findsOneWidget);
    expect(
      topOf(tester, find.byType(BudgetOverviewCard)),
      lessThan(topOf(tester, find.text('Plan your monthly spending'))),
    );
    // Activity still has a home, and untouched categories still have "+".
    expect(find.text('Travel'), findsOneWidget);
    expect(find.byIcon(LucideIcons.plus), findsOneWidget);
  });
}
