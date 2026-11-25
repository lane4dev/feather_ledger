import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/features/budget/domain/entities/budget_entities.dart';
import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';
import 'package:feather_ledger/features/budget/presentation/mappers/budget_ui_mapper.dart';
import 'package:feather_ledger/features/budget/presentation/models/budget_ui_models.dart';
import 'package:feather_ledger/features/budget/presentation/widgets/budget_category_section.dart';

/// ¥200 limit for the row under test unless the fixture says otherwise.
const _budget = 20000;

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  testWidgets('track rows name what is over and what is still billed',
      (tester) async {
    final screen = _map(
      _summary(
        mode: BudgetMode.track,
        budgetedCategories: [
          _cat(
            id: 'dining',
            name: 'Dining',
            actualMinor: 18000,
            pendingMinor: 4000,
          ),
          _cat(id: 'groceries', name: 'Groceries', actualMinor: 4000),
          _cat(id: 'transport', name: 'Transport', actualMinor: 22000),
          _cat(id: 'rent', name: 'Rent', actualMinor: 10000),
        ],
      ),
    );
    final taps = await _pump(tester, screen);

    // ¥200 limit, ¥180 spent, ¥40 billed: over before it happens.
    expect(find.text('Projected over ¥20.00'), findsOneWidget);
    expect(find.text('Includes ¥40.00 pending'), findsOneWidget);
    // ¥220 spent, nothing billed: the overrun is already a fact.
    expect(find.text('Over by ¥20.00'), findsOneWidget);
    expect(find.text('Used 110%'), findsOneWidget);
    expect(find.text('Left ¥160.00'), findsOneWidget);
    expect(find.text('¥180.00 / ¥200.00'), findsOneWidget);
    expect(find.text('¥40.00 / ¥200.00'), findsOneWidget);
    expect(find.text('Budgeted categories'), findsOneWidget);

    await tester.tap(find.text('Dining'));
    await tester.pumpAndSettle();
    expect(taps.opened, ['dining']);
  });

  testWidgets('a long name wraps instead of being cut', (tester) async {
    const name = 'Household supplies and cleaning';
    final screen = _map(
      _summary(
        mode: BudgetMode.track,
        budgetedCategories: [
          _cat(id: 'home', name: name, actualMinor: 4000),
        ],
      ),
    );
    await _pump(tester, screen);

    final label = tester.widget<Text>(find.text(name));
    expect(label.overflow, isNot(TextOverflow.ellipsis));
    expect(label.maxLines, isNull);
    // Wrapping is real: the name is taller than one line of body text.
    expect(tester.getSize(find.text(name)).height, greaterThan(24));
    // And every row still offers a 48dp-tall target.
    final row = find
        .ancestor(of: find.text(name), matching: find.byType(InkWell))
        .first;
    expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
  });

  testWidgets('review rows report a closed month against its limit',
      (tester) async {
    final screen = _map(
      _summary(
        mode: BudgetMode.review,
        budgetedCategories: [
          _cat(id: 'dining', name: 'Dining', actualMinor: 4000),
          _cat(id: 'transport', name: 'Transport', actualMinor: 22000),
        ],
      ),
    );
    await _pump(tester, screen);

    expect(find.text('Used 20%'), findsOneWidget);
    expect(find.text('Unspent ¥160.00'), findsOneWidget);
    expect(find.text('Overspent ¥20.00'), findsOneWidget);
    expect(find.text('¥40.00 / ¥200.00'), findsOneWidget);
    // Nothing left to arrive in a month that has ended.
    expect(find.textContaining('pending'), findsNothing);
  });

  testWidgets('plan rows show the baseline and edit the budget on tap',
      (tester) async {
    final screen = _map(
      _summary(
        mode: BudgetMode.plan,
        budgetedCategories: [
          _cat(
            id: 'dining',
            name: 'Dining',
            actualMinor: 0,
            committedBaselineMinor: 6000,
            threeMonthAvgMinor: 9000,
          ),
          _cat(
            id: 'rent',
            name: 'Rent',
            actualMinor: 0,
            committedBaselineMinor: 0,
          ),
        ],
      ),
    );
    final taps = await _pump(tester, screen);

    expect(find.text('Budget ¥200.00'), findsNWidgets(2));
    expect(find.text('Fixed baseline ¥60.00 · 3-mo avg ¥90.00'), findsOneWidget);
    // No average, no empty reference and no empty bar.
    expect(find.text('Fixed baseline ¥0.00'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('budget-category-bar-rent')),
      findsNothing,
    );
    // A plan row has no detail view to promise.
    expect(find.byIcon(LucideIcons.chevronRight), findsNothing);

    await tester.tap(find.text('Dining'));
    await tester.pumpAndSettle();
    expect(taps.edited, ['dining']);
    expect(taps.opened, isEmpty);
  });

  testWidgets('an anomaly is announced, its ratio is left to the detail',
      (tester) async {
    final handle = tester.ensureSemantics();
    final screen = _map(
      _summary(
        mode: BudgetMode.track,
        budgetedCategories: [
          _cat(
            id: 'dining',
            name: 'Dining',
            actualMinor: 4000,
            threeMonthAvgMinor: 3000,
            isAnomaly: true,
          ),
        ],
      ),
    );
    await _pump(tester, screen);

    expect(
      find.bySemanticsLabel(
        RegExp('Unusually high against its three-month average'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('% vs'), findsNothing);
    handle.dispose();
  });

  testWidgets('the unbudgeted group sums its rows and gates each share',
      (tester) async {
    final screen = _map(
      _summary(
        mode: BudgetMode.track,
        budgetedCategories: const [],
        unbudgetedActualMinor: 100000,
        unbudgetedActiveCategories: [
          _cat(id: 'hobby', name: 'Hobby', budgetMinor: null, actualMinor: 6000),
          _cat(id: 'fuel', name: 'Fuel', budgetMinor: null, actualMinor: 5000),
          _cat(id: 'gadgets', name: 'Gadgets', budgetMinor: null, actualMinor: 4000),
        ],
      ),
    );
    final taps = await _pump(tester, screen);

    expect(find.text('Unbudgeted spending'), findsOneWidget);
    expect(find.text('Spent ¥150.00'), findsOneWidget);
    expect(find.text("6% of month's spend"), findsOneWidget);
    // Exactly 5% still qualifies; 4% is not worth a sentence.
    expect(find.text("5% of month's spend"), findsOneWidget);
    expect(find.text("4% of month's spend"), findsNothing);
    expect(find.text('Set budget'), findsNWidgets(3));

    final button = find.byType(TextButton).first;
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(button).width, greaterThanOrEqualTo(48));

    await tester.tap(find.text('Set budget').first);
    await tester.pumpAndSettle();
    expect(taps.edited, ['hobby']);

    await tester.tap(find.text('Fuel'));
    await tester.pumpAndSettle();
    expect(taps.opened, ['fuel']);
  });

  testWidgets('a pending-only group is headed by its pending total',
      (tester) async {
    final screen = _map(
      _summary(
        mode: BudgetMode.track,
        budgetedCategories: const [],
        unbudgetedPendingMinor: 6000,
        unbudgetedActiveCategories: [
          _cat(
            id: 'hobby',
            name: 'Hobby',
            budgetMinor: null,
            actualMinor: 0,
            pendingMinor: 6000,
          ),
        ],
      ),
    );
    await _pump(tester, screen);

    expect(find.text('Pending ¥60.00'), findsNWidgets(2));
    expect(find.textContaining('Spent'), findsNothing);
    expect(find.text('¥60.00'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('an archived category stays readable and offers no edit',
      (tester) async {
    final screen = _map(
      _summary(
        mode: BudgetMode.review,
        budgetedCategories: const [],
        unbudgetedActualMinor: 10000,
        unbudgetedActiveCategories: [
          _cat(id: 'hobby', name: 'Hobby', budgetMinor: null, actualMinor: 6000),
          _cat(
            id: 'travel',
            name: 'Travel',
            budgetMinor: null,
            actualMinor: 4000,
            isArchived: true,
          ),
        ],
      ),
    );
    await _pump(tester, screen);

    expect(find.text('Archived'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);
    // Only the editable row offers the action.
    expect(find.text('Set budget'), findsOneWidget);
  });

  testWidgets('the group disappears when nothing was spent outside a budget',
      (tester) async {
    final screen = _map(
      _summary(
        mode: BudgetMode.track,
        budgetedCategories: [_cat(id: 'dining', name: 'Dining')],
      ),
    );
    await _pump(tester, screen);

    expect(find.text('Unbudgeted spending'), findsNothing);
    expect(find.text('Set budget'), findsNothing);
  });

  testWidgets('the bar divides spend from billed and never overflows',
      (tester) async {
    final screen = _map(
      _summary(
        mode: BudgetMode.track,
        budgetedCategories: [
          _cat(
            id: 'dining',
            name: 'Dining',
            actualMinor: 15000,
            pendingMinor: 5000,
          ),
          _cat(id: 'transport', name: 'Transport', actualMinor: 22000),
        ],
      ),
    );
    await _pump(tester, screen);

    final track = find.byKey(const ValueKey('budget-category-bar-dining'));
    final actual = find.byKey(
      const ValueKey('budget-category-bar-actual-dining'),
    );
    final pending = find.byKey(
      const ValueKey('budget-category-bar-pending-dining'),
    );
    expect(tester.getSize(track).height, 4);
    expect(
      tester.getSize(actual).width / tester.getSize(track).width,
      closeTo(0.75, 0.01),
    );
    expect(
      tester.getSize(pending).width / tester.getSize(track).width,
      closeTo(0.25, 0.01),
    );
    // An overrun fills the track and has no billed tail.
    final overTrack = find.byKey(
      const ValueKey('budget-category-bar-transport'),
    );
    final overActual = find.byKey(
      const ValueKey('budget-category-bar-actual-transport'),
    );
    expect(tester.getSize(overActual).width, tester.getSize(overTrack).width);
    expect(
      find.byKey(const ValueKey('budget-category-bar-pending-transport')),
      findsNothing,
    );
  });

  testWidgets('a plan bar covers only the fixed baseline', (tester) async {
    final screen = _map(
      _summary(
        mode: BudgetMode.plan,
        budgetedCategories: [
          _cat(
            id: 'dining',
            name: 'Dining',
            actualMinor: 0,
            committedBaselineMinor: 6000,
          ),
        ],
      ),
    );
    await _pump(tester, screen);

    final track = find.byKey(const ValueKey('budget-category-bar-dining'));
    final baseline = find.byKey(
      const ValueKey('budget-category-bar-baseline-dining'),
    );
    expect(
      tester.getSize(baseline).width / tester.getSize(track).width,
      closeTo(0.3, 0.01),
    );
    expect(
      find.byKey(const ValueKey('budget-category-bar-actual-dining')),
      findsNothing,
    );
    // The baseline is hatched, like the hero bar, so a plan row never reads as
    // money already spent.
    expect(
      find.byKey(const ValueKey('budget-category-bar-baseline-hatch-dining')),
      findsOneWidget,
    );
  });

  testWidgets('a track row fills solidly and carries no baseline hatch',
      (tester) async {
    final screen = _map(
      _summary(
        mode: BudgetMode.track,
        budgetedCategories: [
          _cat(id: 'dining', name: 'Dining', actualMinor: 5000),
        ],
      ),
    );
    await _pump(tester, screen);

    expect(
      find.byKey(const ValueKey('budget-category-bar-baseline-hatch-dining')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('budget-category-bar-actual-dining')),
      findsOneWidget,
    );
  });

  testWidgets('a review row carries no baseline hatch either', (tester) async {
    final screen = _map(
      _summary(
        mode: BudgetMode.review,
        budgetedCategories: [
          _cat(
            id: 'dining',
            name: 'Dining',
            actualMinor: 5000,
            committedBaselineMinor: 6000,
          ),
        ],
      ),
    );
    await _pump(tester, screen);

    expect(
      find.byKey(const ValueKey('budget-category-bar-baseline-hatch-dining')),
      findsNothing,
    );
  });

  testWidgets('dark theme keeps the row shapes and the shortfall colour',
      (tester) async {
    final screen = _map(
      _summary(
        mode: BudgetMode.track,
        budgetedCategories: [
          _cat(id: 'transport', name: 'Transport', actualMinor: 22000),
        ],
      ),
    );
    await _pump(tester, screen, theme: AppTheme.darkTheme);

    final amount = tester.widget<Text>(find.text('Over by ¥20.00'));
    expect(
      amount.style?.color,
      AppTheme.darkTheme.extension<AppSemanticColors>()!.expense,
    );
    expect(find.text('¥220.00 / ¥200.00'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('budget-category-bar-transport')),
      findsOneWidget,
    );
  });

  testWidgets('320dp at 1.6x text stacks the amount under the name',
      (tester) async {
    const name = 'Household supplies and cleaning';
    final screen = _map(
      _summary(
        mode: BudgetMode.track,
        budgetedCategories: [
          _cat(
            id: 'home',
            name: name,
            budgetMinor: 1200000,
            actualMinor: 1180000,
            pendingMinor: 40000,
          ),
        ],
      ),
    );
    await _pump(
      tester,
      screen,
      size: const Size(320, 700),
      textScale: 1.6,
    );

    expect(find.text(name), findsOneWidget);
    expect(find.text('Projected over ¥200.00'), findsOneWidget);
    expect(find.text('Includes ¥400.00 pending'), findsOneWidget);
    expect(find.text('¥11800.00 / ¥12000.00'), findsOneWidget);

    final nameRect = tester.getRect(find.text(name));
    final amountRect = tester.getRect(find.text('Projected over ¥200.00'));
    expect(amountRect.top, greaterThan(nameRect.top));
    // The section fills the page inside its gutter without overflowing it.
    expect(tester.getSize(find.byType(BudgetCategorySection)).width, 288);
  });

  testWidgets('900dp keeps the name and its amount on one line',
      (tester) async {
    final screen = _map(
      _summary(
        mode: BudgetMode.track,
        budgetedCategories: [
          _cat(id: 'dining', name: 'Dining', actualMinor: 4000),
        ],
      ),
    );
    await _pump(tester, screen, size: const Size(900, 700));

    final nameRect = tester.getRect(find.text('Dining'));
    final amountRect = tester.getRect(find.text('Left ¥160.00'));
    expect((amountRect.top - nameRect.top).abs(), lessThan(4));
    expect(amountRect.right, greaterThan(900 - 48));
  });
}

class _Taps {
  final opened = <String>[];
  final edited = <String>[];
}

Future<_Taps> _pump(
  WidgetTester tester,
  BudgetScreenUiModel screen, {
  Size size = const Size(400, 700),
  double textScale = 1,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final taps = _Taps();
  final gutter = size.width <= 360 ? 16.0 : 24.0;
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(gutter),
          child: BudgetCategorySection(
            budgetedRows: screen.budgetedRows,
            unbudgetedActiveRows: screen.unbudgetedActiveRows,
            onRowTap: (row) => taps.opened.add(row.categoryId),
            onSetBudgetTap: (row) => taps.edited.add(row.categoryId),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return taps;
}

BudgetScreenUiModel _map(MonthBudgetSummary summary) =>
    const BudgetUiMapper().mapScreen(
      summary,
      currencySymbol: '¥',
      locale: 'en',
    );

MonthBudgetSummary _summary({
  required BudgetMode mode,
  List<CategoryBudgetSummary> budgetedCategories = const [],
  List<CategoryBudgetSummary> unbudgetedActiveCategories = const [],
  int unbudgetedActualMinor = 0,
  int unbudgetedPendingMinor = 0,
}) {
  final budgetedActual = budgetedCategories.fold<int>(
    0,
    (sum, c) => sum + c.actualMinor,
  );
  final budgetedPending = budgetedCategories.fold<int>(
    0,
    (sum, c) => sum + c.pendingMinor,
  );
  return MonthBudgetSummary(
    currencyCode: 'CNY',
    month: const YearMonth(2026, 5),
    mode: mode,
    hasAnyActiveAccount: true,
    totalBudgetMinor: budgetedCategories.length * _budget,
    budgetedActualMinor: budgetedActual,
    budgetedPendingMinor: budgetedPending,
    projectedRemainingMinor: budgetedCategories.length * _budget -
        budgetedActual -
        budgetedPending,
    budgetedRemainingActualMinor:
        budgetedCategories.length * _budget - budgetedActual,
    allExpenseActualMinor: budgetedActual + unbudgetedActualMinor,
    allExpensePendingMinor: budgetedPending + unbudgetedPendingMinor,
    unbudgetedActualMinor: unbudgetedActualMinor,
    unbudgetedPendingMinor: unbudgetedPendingMinor,
    inBudgetCount: 1,
    budgetedCategoryCount: budgetedCategories.length,
    complianceRate: 1,
    hasAnyBudget: budgetedCategories.isNotEmpty,
    hasUnbudgetedActivity: unbudgetedActiveCategories.isNotEmpty,
    hasLeftoverPendingInReview: false,
    hasHighFrequencyPending: false,
    isFarFutureMaterializedOnly: mode == BudgetMode.plan,
    budgetedCategories: budgetedCategories,
    unbudgetedActiveCategories: unbudgetedActiveCategories,
    remainingActiveCategories: const [],
    overBudgetTop3: const [],
    underBudgetTop3: const [],
    unbudgetedAlertsTop3: const [],
    monthTrend6Months: const [],
    monthReviewNote: null,
  );
}

CategoryBudgetSummary _cat({
  required String id,
  required String name,
  int? budgetMinor = _budget,
  int actualMinor = 0,
  int pendingMinor = 0,
  int committedBaselineMinor = 0,
  int threeMonthAvgMinor = 0,
  bool isAnomaly = false,
  bool isArchived = false,
}) {
  return CategoryBudgetSummary(
    categoryId: id,
    categoryName: name,
    iconKey: 'utensils',
    colorInt: 0xFFE65100,
    isArchived: isArchived,
    archiveYm: null,
    budgetMinor: budgetMinor,
    hasFutureRulesAfter: false,
    committedActualMinor: actualMinor,
    discretionaryActualMinor: 0,
    actualMinor: actualMinor,
    pendingMinor: pendingMinor,
    projectedRemainingMinor: budgetMinor == null ? null : 0,
    lastMonthActualMinor: 0,
    threeMonthAvgMinor: threeMonthAvgMinor,
    committedBaselineMinor: committedBaselineMinor,
    isAnomaly: isAnomaly,
    anomalyDeltaRatio: isAnomaly ? 0.33 : null,
    riskLevel: BudgetRiskLevel.inBudget,
    sixMonthTrend: const [],
    topTransactions: const [],
    reviewNote: null,
  );
}
