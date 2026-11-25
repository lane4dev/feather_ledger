import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';
import 'package:feather_ledger/features/budget/presentation/screens/budget_category_detail_screen.dart';
import 'package:feather_ledger/features/budget/presentation/screens/budget_review_screen.dart';
import 'package:feather_ledger/features/budget/presentation/widgets/budget_overview_card.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_month_picker.dart';

import '../../../support/budget_screen_harness.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  double topOf(WidgetTester tester, Finder finder) =>
      tester.getTopLeft(finder).dy;

  testWidgets('track month runs overview, budgeted, unbudgeted, review entry',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: FakeBudgetService(
          overrides: {budgetTestMay: monthBudgetSummary(budgetTestMay)}),
      size: const Size(400, 1600),
    );

    expect(find.byType(BudgetOverviewCard), findsOneWidget);
    expect(find.text('Budgeted categories'), findsOneWidget);
    expect(find.text('Unbudgeted spending'), findsOneWidget);
    expect(find.byKey(budgetReviewEntryKey), findsOneWidget);
    expect(find.byKey(budgetReviewBarKey), findsNothing);
    expect(find.byKey(budgetPlanHintKey), findsNothing);
    // Exactly one review entry: the card's title appears once.
    expect(find.text('Monthly Review & Trends'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(budgetReviewEntryKey),
        matching: find.byIcon(LucideIcons.barChart2),
      ),
      findsOneWidget,
    );
    // The entry points forward, so the affordance is explicit.
    expect(
      find.descendant(
        of: find.byKey(budgetReviewEntryKey),
        matching: find.byIcon(LucideIcons.chevronRight),
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
      lessThan(topOf(tester, find.byKey(budgetReviewEntryKey))),
    );
  });

  testWidgets('track entry shows both actuals and keeps the note preview',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: FakeBudgetService(overrides: {
        budgetTestMay: monthBudgetSummary(
          budgetTestMay,
          note: 'Travel spiked on the spring trip',
        ),
      }),
      size: const Size(400, 1600),
    );

    // Track mode is mid-month: the line is what has been spent, not how far
    // past a limit a category went.
    expect(
      find.text('Committed \$0.00 · Discretionary \$3150.00'),
      findsOneWidget,
    );
    expect(find.text('Note: Travel spiked on the spring trip'), findsOneWidget);
    expect(find.textContaining('over by'), findsNothing);
    expect(find.textContaining('unspent'), findsNothing);
    expect(
      find.text('Every budgeted category is still inside its limit'),
      findsNothing,
    );
  });

  testWidgets('review entry prefers the worst overrun over a surplus',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: FakeBudgetService(overrides: {
        // The page still shows May; the summary itself is a closed month so
        // the entry renders in review mode.
        budgetTestMay: monthBudgetSummary(
          budgetTestMay,
          now: DateTime(2026, 6, 10),
          overBudget: [
            budgetAttribution(
                id: 'dining', name: 'Dining', varianceMinor: -40000),
          ],
          underBudget: [
            budgetAttribution(
                id: 'groceries', name: 'Groceries', varianceMinor: 30000),
          ],
        ),
      }),
      size: const Size(400, 1600),
    );

    expect(find.text('Dining over by \$400.00'), findsOneWidget);
    expect(find.textContaining('unspent'), findsNothing);
  });

  testWidgets('review entry falls back to the biggest surplus', (tester) async {
    await pumpBudgetScreen(
      tester,
      service: FakeBudgetService(overrides: {
        budgetTestMay: monthBudgetSummary(
          budgetTestMay,
          now: DateTime(2026, 6, 10),
          underBudget: [
            budgetAttribution(
                id: 'groceries', name: 'Groceries', varianceMinor: 30000),
          ],
        ),
      }),
      size: const Size(400, 1600),
    );

    expect(find.text('Groceries unspent \$300.00'), findsOneWidget);
  });

  testWidgets('review entry says so when every limit still holds',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: FakeBudgetService(overrides: {
        budgetTestMay: monthBudgetSummary(
          budgetTestMay,
          now: DateTime(2026, 6, 10),
        ),
      }),
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
      service: FakeBudgetService(overrides: {
        budgetTestMay: monthBudgetSummary(budgetTestMay),
        budgetTestApril: monthBudgetSummary(
          budgetTestApril,
          overBudget: [
            budgetAttribution(
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

    expect(find.byKey(budgetReviewBarKey), findsOneWidget);
    expect(find.byKey(budgetReviewEntryKey), findsNothing);
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
      lessThan(topOf(tester, find.byKey(budgetReviewBarKey))),
    );
    expect(
      topOf(tester, find.byKey(budgetReviewBarKey)),
      lessThan(topOf(tester, find.text('Budgeted categories'))),
    );

    await tester.tap(find.byKey(budgetReviewBarKey));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetReviewScreen), findsOneWidget);
    expect(find.text('April 2026'), findsOneWidget);
  });

  testWidgets('closed month with nothing to attribute still opens the review',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: FakeBudgetService(overrides: {
        budgetTestMay: monthBudgetSummary(budgetTestMay),
        budgetTestApril: monthBudgetSummary(budgetTestApril),
      }),
      size: const Size(400, 1600),
    );

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();

    expect(
      find.text('Every budgeted category is still inside its limit'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(budgetReviewBarKey));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetReviewScreen), findsOneWidget);
  });

  testWidgets('future month ends in a planning hint, not a review entry',
      (tester) async {
    final plan = monthBudgetSummary(
      budgetTestJune,
      budgeted: [
        budgetCategory(
          id: 'dining',
          name: 'Dining',
          month: budgetTestJune,
          budgetMinor: 100000,
          committedMinor: 60000,
          pendingMinor: 60000,
        ),
        budgetCategory(
          id: 'groceries',
          name: 'Groceries',
          month: budgetTestJune,
          budgetMinor: 50000,
        ),
        budgetCategory(
          id: 'housing',
          name: 'Housing',
          month: budgetTestJune,
          budgetMinor: 200000,
          committedMinor: 150000,
          pendingMinor: 150000,
        ),
      ],
      unbudgeted: [
        budgetCategory(id: 'travel', name: 'Travel', month: budgetTestJune)
      ],
      remaining: [
        budgetCategory(id: 'utils', name: 'Utilities', month: budgetTestJune)
      ],
      hasHighFrequencyPending: true,
    );

    await pumpBudgetScreen(
      tester,
      service: FakeBudgetService(overrides: {
        budgetTestMay: monthBudgetSummary(budgetTestMay),
        budgetTestJune: plan
      }),
      size: const Size(400, 1600),
    );

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('June 2026'), findsOneWidget);

    expect(find.byKey(budgetPlanHintKey), findsOneWidget);
    expect(find.byKey(budgetReviewEntryKey), findsNothing);
    // A future month has no compliance reading yet.
    expect(find.textContaining('On budget'), findsNothing);
    expect(find.byKey(budgetReviewBarKey), findsNothing);
    expect(find.text('Monthly Review & Trends'), findsNothing);
    // The rules the rows show *are* last month's, so the page may say so.
    expect(
      find.textContaining("Last month's rules carry forward"),
      findsOneWidget,
    );
    expect(find.textContaining('Fixed bills \$2100.00'), findsOneWidget);
    expect(
      find.text('Only generated recurring bills are included.'),
      findsOneWidget,
    );
    // The hint says "this month", so it carries the calendar marker.
    expect(
      find.descendant(
        of: find.byKey(budgetPlanHintKey),
        matching: find.byIcon(LucideIcons.calendar),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a scheduled bill outside the budget still counts as fixed',
      (tester) async {
    final plan = monthBudgetSummary(
      budgetTestJune,
      budgeted: [
        budgetCategory(
          id: 'dining',
          name: 'Dining',
          month: budgetTestJune,
          budgetMinor: 100000,
        ),
      ],
      unbudgeted: [
        budgetCategory(
          id: 'travel',
          name: 'Travel',
          month: budgetTestJune,
          committedMinor: 15000,
          pendingMinor: 15000,
        ),
      ],
      remaining: [
        budgetCategory(id: 'utils', name: 'Utilities', month: budgetTestJune),
      ],
    );

    await pumpBudgetScreen(
      tester,
      service: FakeBudgetService(
        overrides: {
          budgetTestMay: monthBudgetSummary(budgetTestMay),
          budgetTestJune: plan,
        },
      ),
      size: const Size(400, 1600),
    );

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('June 2026'), findsOneWidget);

    // The bill sits in a category nobody has budgeted yet; the hint counts it
    // anyway, because it is money the month has already committed.
    expect(find.textContaining('Fixed bills \$150.00'), findsOneWidget);
    expect(find.textContaining('Nothing scheduled'), findsNothing);
  });

  testWidgets('future month drops the carry-forward claim once a limit differs',
      (tester) async {
    final replanned = monthBudgetSummary(
      budgetTestJune,
      budgeted: [
        budgetCategory(
          id: 'dining',
          name: 'Dining',
          month: budgetTestJune,
          budgetMinor: 120000,
          prevBudgetMinor: 100000,
        ),
      ],
      unbudgeted: const [],
      remaining: [
        budgetCategory(id: 'utils', name: 'Utilities', month: budgetTestJune)
      ],
    );

    await pumpBudgetScreen(
      tester,
      service: FakeBudgetService(
        overrides: {
          budgetTestMay: monthBudgetSummary(budgetTestMay),
          budgetTestJune: replanned
        },
      ),
      size: const Size(400, 1600),
    );

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();

    expect(find.byKey(budgetPlanHintKey), findsOneWidget);
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
      service: FakeBudgetService(
          overrides: {budgetTestMay: monthBudgetSummary(budgetTestMay)}),
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

  testWidgets('the + drawer lists unbudgeted categories, spending first',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: FakeBudgetService(
          overrides: {budgetTestMay: monthBudgetSummary(budgetTestMay)}),
    );

    expect(find.text('Utilities'), findsNothing);
    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    expect(find.text('Choose category'), findsOneWidget);
    // Travel spent ¥250 this month without a budget; Utilities spent nothing.
    // The drawer opens on Travel, because that is the limit worth setting.
    expect(
      find.descendant(of: sheet, matching: find.byType(ListTile)),
      findsNWidgets(2),
    );
    final names = tester
        .widgetList<ListTile>(
          find.descendant(of: sheet, matching: find.byType(ListTile)),
        )
        .map((tile) => (tile.title! as Text).data)
        .toList();
    expect(names, ['Travel', 'Utilities']);
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

  testWidgets('the + action disappears when no category lacks a budget',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: FakeBudgetService(overrides: {
        budgetTestMay: monthBudgetSummary(
          budgetTestMay,
          unbudgeted: const [],
          remaining: const [],
        ),
      }),
    );

    expect(find.byIcon(LucideIcons.plus), findsNothing);
  });

  testWidgets('arrows, swipe and the month picker move across years',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: FakeBudgetService(
          overrides: {budgetTestMay: monthBudgetSummary(budgetTestMay)}),
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
      service: FakeBudgetService(overrides: {
        budgetTestMay: monthBudgetSummary(budgetTestMay),
        budgetTestApril: monthBudgetSummary(budgetTestApril),
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
    await tester.tap(find.byKey(budgetReviewEntryKey));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetReviewScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BudgetReviewScreen), findsNothing);
    // Back on the same month, still scrolled where the entry was tapped.
    expect(find.text('May 2026'), findsOneWidget);
    expect(find.byKey(budgetReviewEntryKey), findsOneWidget);

    // A closed month entered from its bar returns to that month too.
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('April 2026'), findsOneWidget);
    await tester.tap(find.byKey(budgetReviewBarKey));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('April 2026'), findsOneWidget);
    expect(find.byKey(budgetReviewBarKey), findsOneWidget);
  });

  testWidgets('the last action on the page clears the bottom bar',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: FakeBudgetService(
          overrides: {budgetTestMay: monthBudgetSummary(budgetTestMay)}),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    final viewport = tester.getRect(find.byType(ListView));
    final entry = tester.getRect(find.byKey(budgetReviewEntryKey));
    expect(viewport.bottom - entry.bottom, greaterThanOrEqualTo(88));
    expect(find.byKey(budgetReviewEntryKey).hitTestable(), findsOneWidget);
  });

  for (final (label, theme) in [
    ('light', AppTheme.lightTheme),
    ('dark', AppTheme.darkTheme),
  ]) {
    testWidgets('$label 400x700 shows the overview and at least three rows',
        (tester) async {
      await pumpBudgetScreen(
        tester,
        service: FakeBudgetService(
            overrides: {budgetTestMay: monthBudgetSummary(budgetTestMay)}),
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
      service: FakeBudgetService(
          overrides: {budgetTestMay: monthBudgetSummary(budgetTestMay)}),
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
      service: FakeBudgetService(
          overrides: {budgetTestMay: monthBudgetSummary(budgetTestMay)}),
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
      service: FakeBudgetService(overrides: {
        budgetTestMay: monthBudgetSummary(budgetTestMay,
            hasAnyActiveAccount: false, budgeted: const []),
      }),
    );

    expect(find.text('Create an account to start budgeting'), findsOneWidget);
    expect(
      find.text('No active accounts exist for USD yet.'),
      findsOneWidget,
    );
    expect(find.text('Manage Accounts'), findsOneWidget);
    expect(find.byType(BudgetOverviewCard), findsNothing);
    expect(find.byKey(budgetReviewEntryKey), findsNothing);
  });

  testWidgets('a month with no budget offers the first-budget entry',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: FakeBudgetService(overrides: {
        budgetTestMay: monthBudgetSummary(
          budgetTestMay,
          budgeted: const [],
          unbudgeted: [
            budgetCategory(
                id: 'travel',
                name: 'Travel',
                month: budgetTestMay,
                actualMinor: 25000),
          ],
          remaining: [
            budgetCategory(id: 'utils', name: 'Utilities', month: budgetTestMay)
          ],
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

  testWidgets('a year boundary keeps review, track and plan apart',
      (tester) async {
    // January 2026 is the tracked month, so December 2025 is closed and
    // February 2026 is planned. The three-mode comparison must cross the year
    // the same way it crosses any other month boundary.
    final january = DateTime(2026, 1, 15);
    const dec = YearMonth(2025, 12);
    const jan = YearMonth(2026, 1);
    const feb = YearMonth(2026, 2);
    await pumpBudgetScreen(
      tester,
      now: january,
      service: FakeBudgetService(overrides: {
        dec: monthBudgetSummary(dec, now: january),
        jan: monthBudgetSummary(jan, now: january),
        feb: monthBudgetSummary(feb, now: january),
      }),
      size: const Size(400, 1600),
    );

    expect(find.text('January 2026'), findsOneWidget);
    expect(find.byKey(budgetReviewEntryKey), findsOneWidget);
    expect(find.byKey(budgetReviewBarKey), findsNothing);
    expect(find.byKey(budgetPlanHintKey), findsNothing);

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('December 2025'), findsOneWidget);
    expect(find.byKey(budgetReviewBarKey), findsOneWidget);
    expect(find.byKey(budgetReviewEntryKey), findsNothing);
    expect(find.byKey(budgetPlanHintKey), findsNothing);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('January 2026'), findsOneWidget);
    expect(find.byKey(budgetReviewEntryKey), findsOneWidget);
    expect(find.byKey(budgetReviewBarKey), findsNothing);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('February 2026'), findsOneWidget);
    expect(find.byKey(budgetPlanHintKey), findsOneWidget);
    expect(find.byKey(budgetReviewEntryKey), findsNothing);
    expect(find.byKey(budgetReviewBarKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('L1 to L2 to L3 and back keeps the month and the scroll offset',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: FakeBudgetService(overrides: {
        budgetTestMay: monthBudgetSummary(
          budgetTestMay,
          overBudget: [
            budgetAttribution(
                id: 'dining', name: 'Dining', varianceMinor: -40000),
          ],
        ),
      }),
    );

    double homeScrollOffset() => tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position
        .pixels;

    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    final homeOffset = homeScrollOffset();
    expect(homeOffset, greaterThan(0));

    await tester.tap(find.byKey(budgetReviewEntryKey));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetReviewScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('budget-attribution-dining')));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetCategoryDetailScreen), findsOneWidget);

    // Back through L2 lands on L2, not on the home.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BudgetCategoryDetailScreen), findsNothing);
    expect(find.byType(BudgetReviewScreen), findsOneWidget);
    expect(find.text('May 2026'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BudgetReviewScreen), findsNothing);
    expect(find.text('May 2026'), findsOneWidget);
    expect(homeScrollOffset(), closeTo(homeOffset, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('an archived row in a closed month stays read-only',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: FakeBudgetService(overrides: {
        budgetTestMay: monthBudgetSummary(budgetTestMay),
        budgetTestApril: monthBudgetSummary(
          budgetTestApril,
          budgeted: [
            budgetCategory(
              id: 'dining',
              name: 'Dining',
              month: budgetTestApril,
              budgetMinor: 100000,
              actualMinor: 40000,
              isArchived: true,
            ),
            budgetCategory(
              id: 'groceries',
              name: 'Groceries',
              month: budgetTestApril,
              budgetMinor: 50000,
              actualMinor: 20000,
            ),
          ],
          unbudgeted: const [],
        ),
      }),
      size: const Size(400, 1600),
    );

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('April 2026'), findsOneWidget);

    await tester.tap(find.text('Dining'));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetCategoryDetailScreen), findsOneWidget);
    // The row keeps its history but offers neither an edit nor a delete.
    expect(find.text('Archived'), findsOneWidget);
    expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the app bar takes a shallow tint once the month scrolls',
      (tester) async {
    await pumpBudgetScreen(tester, service: FakeBudgetService());
    final appBar = find.byType(AppBar);
    expect(tester.widget<AppBar>(appBar).backgroundColor, isNull);

    await tester.drag(find.byType(ListView).first, const Offset(0, -320));
    await tester.pump();

    final scheme = Theme.of(tester.element(appBar)).colorScheme;
    expect(
      tester.widget<AppBar>(appBar).backgroundColor,
      scheme.surfaceContainer,
    );

    await tester.drag(find.byType(ListView).first, const Offset(0, 400));
    await tester.pump();
    expect(tester.widget<AppBar>(appBar).backgroundColor, isNull);
  });
}
