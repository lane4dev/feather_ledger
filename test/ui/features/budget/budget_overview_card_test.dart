import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/features/budget/domain/entities/budget_entities.dart';
import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';
import 'package:feather_ledger/features/budget/presentation/mappers/budget_ui_mapper.dart';
import 'package:feather_ledger/features/budget/presentation/widgets/budget_overview_card.dart';

/// Geometry is compared against the card's measured surface, never against a
/// hardcoded pixel width: the same ratios have to hold at 320dp and at 900dp.
const double _barInset = 20; // AppMetrics.cardPadding
const double _tolerance = 0.75;

const _surfaceKey = ValueKey('budget-overview-surface');
const _dashedOutlineKey = ValueKey('budget-overview-dashed-outline');
const _amountKey = ValueKey('budget-overview-main-amount');
const _actualKey = ValueKey('budget-overview-bar-actual');
const _pendingKey = ValueKey('budget-overview-bar-pending');
const _baselineKey = ValueKey('budget-overview-bar-baseline');
const _hatchKey = ValueKey('budget-hero-baseline-hatch');
const _tickKey = ValueKey('budget-overview-today-tick');

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  group('track', () {
    testWidgets('reads as one number over its evidence', (tester) async {
      await _pump(tester, summary: _track());

      expect(find.text('Projected left'), findsOneWidget);
      expect(find.text('¥130.00'), findsOneWidget);
      expect(find.text('On budget 1/1'), findsOneWidget);

      // Track is the only mode that does not name itself: it is the default.
      expect(find.text('Track'), findsNothing);
      expect(find.text('Review'), findsNothing);
      expect(find.text('Plan'), findsNothing);

      expect(find.text('Spent'), findsOneWidget);
      expect(find.text('¥40.00'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('¥30.00'), findsOneWidget);
      expect(find.text('Total budget'), findsOneWidget);
      expect(find.text('¥200.00'), findsOneWidget);

      // The all-expense side-note and the fixed/discretionary chips belong to
      // the sections below, not to the headline.
      expect(find.textContaining('All expenses'), findsNothing);
      expect(find.text('Committed spending'), findsNothing);
      expect(find.text('Discretionary spending'), findsNothing);
    });

    testWidgets('segments and today tick sit at the ratios it reports',
        (tester) async {
      await _pump(tester, summary: _track());

      final card = _surface(tester).rect;
      final barWidth = card.width - _barInset * 2;

      final actual = tester.getRect(find.byKey(_actualKey));
      final pending = tester.getRect(find.byKey(_pendingKey));
      expect(actual.left, closeTo(card.left + _barInset, _tolerance));
      expect(actual.width, closeTo(barWidth * 0.2, _tolerance));
      expect(pending.left, closeTo(actual.right, _tolerance));
      expect(pending.width, closeTo(barWidth * 0.15, _tolerance));

      // 16 May in a 31-day month.
      final tick = tester.getRect(find.byKey(_tickKey));
      expect(
        tick.center.dx,
        closeTo(card.left + _barInset + barWidth * 16 / 31, _tolerance),
      );
      // The tick is a full-height rule through the bar, not a dot on it.
      expect(tick.height, greaterThan(actual.height));
    });

    testWidgets('an overrun fills the bar and still prints the real size',
        (tester) async {
      await _pump(
        tester,
        summary: _track(
          budgetedActualMinor: 25000,
          budgetedPendingMinor: 0,
          projectedRemainingMinor: -5000,
        ),
      );

      expect(find.text('Projected over'), findsOneWidget);
      expect(find.text('-¥50.00'), findsOneWidget);
      expect(find.byKey(_pendingKey), findsNothing);

      final card = _surface(tester).rect;
      final actual = tester.getRect(find.byKey(_actualKey));
      expect(actual.width, closeTo(card.width - _barInset * 2, _tolerance));
    });

    testWidgets('the amount is set in tabular figures at the shared scale',
        (tester) async {
      await _pump(tester, summary: _track());

      final amount = tester.widget<Text>(find.byKey(_amountKey));
      final spans = (amount.textSpan! as TextSpan).children!.cast<TextSpan>();

      expect(spans, hasLength(3));
      for (final span in spans) {
        expect(
          span.style!.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      }
      expect(spans[0].style!.fontSize, AppTypography.overviewSymbolSize);
      expect(spans[1].style!.fontSize, AppTypography.overviewWholeSize);
      expect(spans[2].style!.fontSize, AppTypography.overviewFractionSize);
      expect(spans[1].text, '130');
      expect(spans[2].text, '.00');
    });

    testWidgets('carries the live tint and its hairline', (tester) async {
      await _pump(tester, summary: _track());

      final decoration = _surface(tester).decoration;
      expect(decoration.gradient, isNotNull);
      expect(decoration.border, isNotNull);
      expect(find.byKey(_dashedOutlineKey), findsNothing);
      // A real spend bar is a solid fill; only the plan baseline is hatched.
      expect(find.byKey(_hatchKey), findsNothing);
    });
  });

  group('review', () {
    testWidgets('reports what the month ended with, without a pending column',
        (tester) async {
      await _pump(tester, summary: _review());

      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Monthly surplus'), findsOneWidget);
      expect(find.text('¥160.00'), findsOneWidget);

      expect(find.text('Spent'), findsOneWidget);
      expect(find.text('Budget used'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);
      expect(find.text('Total budget'), findsOneWidget);
      expect(find.text('Pending'), findsNothing);

      expect(find.byKey(_actualKey), findsOneWidget);
      expect(find.byKey(_pendingKey), findsNothing);
      // A closed month has no today.
      expect(find.byKey(_tickKey), findsNothing);
      expect(find.byKey(_dashedOutlineKey), findsNothing);
    });

    testWidgets('an overspent month says so', (tester) async {
      await _pump(tester, summary: _review(budgetedActualMinor: 25000));

      expect(find.text('Monthly overspend'), findsOneWidget);
      expect(find.text('-¥50.00'), findsOneWidget);
      expect(find.text('125%'), findsOneWidget);
    });
  });

  group('plan', () {
    testWidgets('shows what the baseline has not pinned down', (tester) async {
      await _pump(tester, summary: _plan());

      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('Available to spend'), findsOneWidget);
      expect(find.text('¥140.00'), findsOneWidget);

      expect(find.text('Committed baseline'), findsOneWidget);
      expect(find.text('¥60.00'), findsOneWidget);
      expect(find.text('Baseline share'), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);
      expect(find.text('¥200.00'), findsOneWidget);

      // A month that has not started has nothing spent, only commitments.
      expect(find.byKey(_actualKey), findsNothing);
      expect(find.byKey(_pendingKey), findsNothing);
      expect(find.byKey(_tickKey), findsNothing);
    });

    testWidgets('hides compliance and keeps the label flush left',
        (tester) async {
      await _pump(tester, summary: _plan());

      // A month that has not happened has no compliance to report.
      expect(find.text('On budget 1/1'), findsNothing);
      expect(find.text('Plan'), findsOneWidget);

      final label = tester.getRect(find.text('Available to spend'));
      final amount = tester.getRect(find.text('¥140.00'));
      final footer = tester.getRect(find.text('Committed baseline'));
      expect(label.left, closeTo(amount.left, _tolerance));
      expect(label.left, closeTo(footer.left, _tolerance));
    });

    testWidgets('draws a dashed outline instead of a hairline', (tester) async {
      await _pump(tester, summary: _plan());

      expect(find.byKey(_dashedOutlineKey), findsOneWidget);
      final decoration = _surface(tester).decoration;
      expect(decoration.border, isNull);
    });

    testWidgets('the baseline bar stops at the baseline share', (tester) async {
      await _pump(tester, summary: _plan());

      final card = _surface(tester).rect;
      final baseline = tester.getRect(find.byKey(_baselineKey));
      expect(
        baseline.width,
        closeTo((card.width - _barInset * 2) * 0.3, _tolerance),
      );
    });

    testWidgets('hatches the baseline so it reads as a reference, not spend',
        (tester) async {
      await _pump(tester, summary: _plan());

      final hatch = find.byKey(_hatchKey);
      expect(hatch, findsOneWidget);
      // The stripes cover exactly the baseline segment.
      expect(
        tester.getRect(hatch),
        tester.getRect(find.byKey(_baselineKey)),
      );
    });

    testWidgets('a baseline past the budget fills the bar and prints the gap',
        (tester) async {
      await _pump(tester, summary: _plan(budgetedBaselineMinor: 25000));

      expect(find.text('-¥50.00'), findsOneWidget);
      final card = _surface(tester).rect;
      final baseline = tester.getRect(find.byKey(_baselineKey));
      expect(
        baseline.width,
        closeTo(card.width - _barInset * 2, _tolerance),
      );
    });
  });

  group('edges', () {
    testWidgets('no budget anywhere prints a dash, not a zero', (tester) async {
      await _pump(
        tester,
        summary: _summary(
          mode: BudgetMode.track,
          totalBudgetMinor: 0,
          hasAnyBudget: false,
          budgetedCategories: const [],
        ),
      );

      final amount = tester.widget<Text>(find.byKey(_amountKey));
      expect(amount.data, '—');
      expect(find.byKey(_actualKey), findsNothing);
      expect(find.byKey(_pendingKey), findsNothing);
      // Amount and total-budget column both read `—`.
      expect(find.text('—'), findsNWidgets(2));
    });

    testWidgets('survives a zero denominator', (tester) async {
      await _pump(
        tester,
        summary: _review(totalBudgetMinor: 0, budgetedCategories: const []),
      );

      expect(find.text('—'), findsWidgets);
      expect(find.text('0%'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('layout', () {
    testWidgets('narrow (320dp) at 1.6× text keeps one row of figures',
        (tester) async {
      await _pump(
        tester,
        summary: _track(),
        size: const Size(320, 700),
        textScale: 1.6,
      );

      expect(tester.takeException(), isNull);
      expect(_surface(tester).rect.width, closeTo(320, _tolerance));

      final labelTops = [
        'Spent',
        'Pending',
        'Total budget',
      ].map((label) => tester.getTopLeft(find.text(label)).dy).toSet();
      expect(labelTops, hasLength(1));

      final valueTops = [
        '¥40.00',
        '¥30.00',
        '¥200.00',
      ].map((value) => tester.getTopLeft(find.text(value)).dy).toSet();
      expect(valueTops, hasLength(1));
    });

    testWidgets('wide (900dp) keeps the same proportions', (tester) async {
      await _pump(
        tester,
        summary: _track(),
        size: const Size(900, 700),
        cardWidth: 720,
      );

      final card = _surface(tester).rect;
      expect(card.width, closeTo(720, _tolerance));
      final barWidth = card.width - _barInset * 2;
      expect(
        tester.getRect(find.byKey(_actualKey)).width,
        closeTo(barWidth * 0.2, _tolerance),
      );
      expect(
        tester.getRect(find.byKey(_tickKey)).center.dx,
        closeTo(card.left + _barInset + barWidth * 16 / 31, _tolerance),
      );
    });

    testWidgets('dark theme mixes the surface against the dark base',
        (tester) async {
      await _pump(
        tester,
        summary: _track(),
        theme: AppTheme.darkTheme,
        size: const Size(400, 700),
      );

      final scheme = AppTheme.darkTheme.colorScheme;
      final decoration = _surface(tester).decoration;
      expect(decoration.gradient!.colors.first,
          isNot(scheme.surfaceContainerHigh));
      expect(find.text('¥130.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('honours reduce motion', (tester) async {
      await _pump(tester, summary: _track(), disableAnimations: true);
      expect(
        tester.widget<AnimatedContainer>(find.byKey(_surfaceKey)).duration,
        Duration.zero,
      );
      final still = tester.widgetList<AnimatedSwitcher>(
        find.byType(AnimatedSwitcher),
      );
      expect(still, isNotEmpty);
      expect(still.every((switcher) => switcher.duration == Duration.zero),
          isTrue);

      await _pump(tester, summary: _track());
      expect(
        tester.widget<AnimatedContainer>(find.byKey(_surfaceKey)).duration,
        BudgetOverviewCard.transitionDuration,
      );
      final animated = tester.widgetList<AnimatedSwitcher>(
        find.byType(AnimatedSwitcher),
      );
      expect(
        animated.every((switcher) =>
            switcher.duration == BudgetOverviewCard.transitionDuration),
        isTrue,
      );
    });
  });
}

/// Pumps the card alone at a given viewport, with the mapper producing the
/// model so the test covers the seam the screen actually uses.
Future<void> _pump(
  WidgetTester tester, {
  required MonthBudgetSummary summary,
  ThemeData? theme,
  Size size = const Size(400, 700),
  double textScale = 1,
  double cardWidth = 360,
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final model = const BudgetUiMapper().mapScreen(
    summary,
    currencySymbol: '¥',
    locale: 'en',
    today: DateTime(2026, 5, 16),
  );

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
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: cardWidth,
            child: BudgetOverviewCard(overview: model.overview),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

({Rect rect, BoxDecoration decoration}) _surface(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(find.byKey(_surfaceKey));
  return (
    rect: tester.getRect(find.byKey(_surfaceKey)),
    decoration: container.decoration! as BoxDecoration,
  );
}

/// ¥200 budget, ¥40 spent, ¥30 billed and unposted — the spec's locked example.
MonthBudgetSummary _track({
  int totalBudgetMinor = 20000,
  int budgetedActualMinor = 4000,
  int budgetedPendingMinor = 3000,
  int projectedRemainingMinor = 13000,
}) {
  return _summary(
    mode: BudgetMode.track,
    totalBudgetMinor: totalBudgetMinor,
    budgetedActualMinor: budgetedActualMinor,
    budgetedPendingMinor: budgetedPendingMinor,
    projectedRemainingMinor: projectedRemainingMinor,
    budgetedRemainingActualMinor: totalBudgetMinor - budgetedActualMinor,
  );
}

/// April is closed, so the card compares the month as a reading, not a live
/// number.
MonthBudgetSummary _review({
  int totalBudgetMinor = 20000,
  int budgetedActualMinor = 4000,
  List<CategoryBudgetSummary>? budgetedCategories,
}) {
  return _summary(
    mode: BudgetMode.review,
    month: const YearMonth(2026, 4),
    totalBudgetMinor: totalBudgetMinor,
    budgetedActualMinor: budgetedActualMinor,
    budgetedPendingMinor: 0,
    projectedRemainingMinor: budgetedActualMinor,
    budgetedRemainingActualMinor: totalBudgetMinor - budgetedActualMinor,
    budgetedCategories: budgetedCategories ?? [_cat()],
  );
}

/// June has not started: ¥60 of its ¥200 is committed inside budgeted
/// categories, and another ¥20 is committed somewhere unbudgeted.
MonthBudgetSummary _plan({int budgetedBaselineMinor = 6000}) {
  return _summary(
    mode: BudgetMode.plan,
    month: const YearMonth(2026, 6),
    budgetedActualMinor: 0,
    budgetedPendingMinor: 0,
    projectedRemainingMinor: 20000,
    budgetedRemainingActualMinor: 20000,
    budgetedCategories: [_cat(committedBaselineMinor: budgetedBaselineMinor)],
    unbudgetedActiveCategories: [
      _cat(
        categoryId: 'travel',
        budgetMinor: null,
        committedBaselineMinor: 2000,
      ),
    ],
  );
}

MonthBudgetSummary _summary({
  required BudgetMode mode,
  YearMonth month = const YearMonth(2026, 5),
  int totalBudgetMinor = 20000,
  int budgetedActualMinor = 4000,
  int budgetedPendingMinor = 3000,
  int projectedRemainingMinor = 13000,
  int budgetedRemainingActualMinor = 16000,
  bool hasAnyBudget = true,
  List<CategoryBudgetSummary>? budgetedCategories,
  List<CategoryBudgetSummary> unbudgetedActiveCategories = const [],
}) {
  return MonthBudgetSummary(
    currencyCode: 'CNY',
    month: month,
    mode: mode,
    hasAnyActiveAccount: true,
    totalBudgetMinor: totalBudgetMinor,
    budgetedActualMinor: budgetedActualMinor,
    budgetedPendingMinor: budgetedPendingMinor,
    projectedRemainingMinor: projectedRemainingMinor,
    budgetedRemainingActualMinor: budgetedRemainingActualMinor,
    allExpenseActualMinor: budgetedActualMinor,
    allExpensePendingMinor: budgetedPendingMinor,
    unbudgetedActualMinor: 0,
    unbudgetedPendingMinor: 0,
    inBudgetCount: 1,
    budgetedCategoryCount: 1,
    complianceRate: 1.0,
    hasAnyBudget: hasAnyBudget,
    hasUnbudgetedActivity: unbudgetedActiveCategories.isNotEmpty,
    hasLeftoverPendingInReview: mode == BudgetMode.review,
    hasHighFrequencyPending: false,
    isFarFutureMaterializedOnly: mode == BudgetMode.plan,
    budgetedCategories: budgetedCategories ?? [_cat()],
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
  String categoryId = 'dining',
  int? budgetMinor = 20000,
  int actualMinor = 4000,
  int pendingMinor = 0,
  int committedBaselineMinor = 0,
}) {
  return CategoryBudgetSummary(
    categoryId: categoryId,
    categoryName: 'Dining',
    iconKey: 'utensils',
    colorInt: 0xFFE65100,
    isArchived: false,
    archiveYm: null,
    budgetMinor: budgetMinor,
    hasFutureRulesAfter: false,
    committedActualMinor: actualMinor,
    discretionaryActualMinor: 0,
    actualMinor: actualMinor,
    pendingMinor: pendingMinor,
    projectedRemainingMinor: budgetMinor == null ? null : 10000,
    lastMonthActualMinor: 0,
    threeMonthAvgMinor: 0,
    committedBaselineMinor: committedBaselineMinor,
    isAnomaly: false,
    anomalyDeltaRatio: null,
    riskLevel: BudgetRiskLevel.inBudget,
    sixMonthTrend: const [],
    topTransactions: const [],
    reviewNote: null,
  );
}
