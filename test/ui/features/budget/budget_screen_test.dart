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

  testWidgets('track month runs overview, budgeted, unbudgeted',
      (tester) async {
    await pumpBudgetScreen(
      tester,
      service: FakeBudgetService(
          overrides: {budgetTestMay: monthBudgetSummary(budgetTestMay)}),
      size: const Size(400, 1600),
    );

    expect(find.byType(BudgetOverviewCard), findsOneWidget);
    expect(find.text('Budgeted'), findsOneWidget);
    expect(find.text('Unbudgeted'), findsOneWidget);
    expect(find.byKey(budgetPlanHintKey), findsNothing);
    // The hero is the only way into the review, so it is tappable and says so.
    expect(find.byKey(budgetOverviewTapKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BudgetOverviewCard),
        matching: find.byIcon(LucideIcons.chevronRight),
      ),
      findsOneWidget,
    );

    expect(
      topOf(tester, find.byType(BudgetOverviewCard)),
      lessThan(topOf(tester, find.text('Budgeted'))),
    );
    expect(
      topOf(tester, find.text('Budgeted')),
      lessThan(topOf(tester, find.text('Unbudgeted'))),
    );
    expect(
      topOf(tester, find.text('Unbudgeted')),
      lessThan(topOf(tester, find.text('Travel'))),
    );

    await tester.tap(find.byKey(budgetOverviewTapKey));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetReviewScreen), findsOneWidget);
  });

  testWidgets('the hero previews the month note on one line', (tester) async {
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

    final preview = find.descendant(
      of: find.byType(BudgetOverviewCard),
      matching: find.text('Travel spiked on the spring trip'),
    );
    expect(preview, findsOneWidget);
    expect(tester.widget<Text>(preview).maxLines, 1);
    expect(find.textContaining('Note: '), findsNothing);
  });

  testWidgets('a closed month opens its review from the hero', (tester) async {
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

    expect(find.byKey(budgetOverviewTapKey), findsOneWidget);
    expect(find.text('Monthly Review & Trends'), findsNothing);
    expect(find.text('Dining over by \$400.00'), findsNothing);

    // The note is previewed on one clipped line rather than spilling onto the
    // page; the full text stays in the widget for the ellipsis to cut.
    final preview = tester.widget<Text>(
      find.textContaining('Travel spiked on the spring trip'),
    );
    expect(preview.maxLines, 1);
    expect(preview.overflow, TextOverflow.ellipsis);

    expect(
      topOf(tester, find.byType(BudgetOverviewCard)),
      lessThan(topOf(tester, find.text('Budgeted'))),
    );

    await tester.tap(find.byKey(budgetOverviewTapKey));
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

    await tester.tap(find.byKey(budgetOverviewTapKey));
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
    // A future month has no compliance reading yet, and no way into a review:
    // nothing there has happened.
    expect(find.textContaining('On budget'), findsNothing);
    expect(find.byKey(budgetOverviewTapKey), findsNothing);
    expect(
      find.descendant(
        of: find.byType(BudgetOverviewCard),
        matching: find.byIcon(LucideIcons.chevronRight),
      ),
      findsNothing,
    );
    expect(find.text('Monthly Review & Trends'), findsNothing);
    // The rules the rows show *are* last month's, so the page may say so.
    expect(
      find.textContaining('Carried from last month'),
      findsOneWidget,
    );
    expect(find.textContaining('\$2100.00 in fixed bills'), findsOneWidget);
    expect(
      find.text('Only generated recurring bills are included.'),
      findsNothing,
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
    expect(find.textContaining('\$150.00 in fixed bills'), findsOneWidget);
    expect(find.textContaining('No fixed bills'), findsNothing);
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
      find.textContaining('No fixed bills'),
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
    expect(find.text('Dining budget'), findsOneWidget);
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
    expect(find.text('Choose a category'), findsOneWidget);
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
    expect(find.text('Utilities budget'), findsOneWidget);
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

    // The hero is pinned to the top of the page, so scroll back to it.
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(budgetOverviewTapKey));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetReviewScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BudgetReviewScreen), findsNothing);
    expect(find.text('May 2026'), findsOneWidget);

    // A closed month entered from its hero returns to that month too.
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('April 2026'), findsOneWidget);
    await tester.tap(find.byKey(budgetOverviewTapKey));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('April 2026'), findsOneWidget);
    expect(find.byKey(budgetOverviewTapKey), findsOneWidget);
  });

  testWidgets('the last row on the page clears the bottom bar', (tester) async {
    await pumpBudgetScreen(
      tester,
      service: FakeBudgetService(
          overrides: {budgetTestMay: monthBudgetSummary(budgetTestMay)}),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    final viewport = tester.getRect(find.byType(ListView));
    final last = tester.getRect(find.text('Travel'));
    expect(viewport.bottom - last.bottom, greaterThanOrEqualTo(88));
    expect(find.text('Travel').hitTestable(), findsOneWidget);
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
    expect(find.text('Budgeted'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('Unbudgeted'), findsOneWidget);

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

    expect(find.text('Add an account first'), findsOneWidget);
    expect(
      find.text('No active accounts in USD.'),
      findsOneWidget,
    );
    expect(find.text('Manage Accounts'), findsOneWidget);
    expect(find.byType(BudgetOverviewCard), findsNothing);
    expect(find.byKey(budgetOverviewTapKey), findsNothing);
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

    expect(find.text('Set your first budget'), findsOneWidget);
    expect(
      topOf(tester, find.byType(BudgetOverviewCard)),
      lessThan(topOf(tester, find.text('Set your first budget'))),
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
    expect(find.byKey(budgetOverviewTapKey), findsOneWidget);
    expect(find.byKey(budgetPlanHintKey), findsNothing);

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('December 2025'), findsOneWidget);
    expect(find.byKey(budgetOverviewTapKey), findsOneWidget);
    expect(find.byKey(budgetPlanHintKey), findsNothing);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('January 2026'), findsOneWidget);
    expect(find.byKey(budgetOverviewTapKey), findsOneWidget);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('February 2026'), findsOneWidget);
    expect(find.byKey(budgetPlanHintKey), findsOneWidget);
    expect(find.byKey(budgetOverviewTapKey), findsNothing);
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

    // The hero is at the top; come back to it before opening the review.
    await tester.drag(find.byType(ListView), const Offset(0, 900));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(budgetOverviewTapKey));
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
    // The scroll position is restored where the hero left it.
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

  testWidgets('one app bar surface while the month scrolls under it',
      (tester) async {
    await pumpBudgetScreen(tester, service: FakeBudgetService());
    final appBar = find.byType(AppBar);
    // No local background: the shared theme owns surface + scrolled shadow.
    expect(tester.widget<AppBar>(appBar).backgroundColor, isNull);

    await tester.drag(find.byType(ListView).first, const Offset(0, -320));
    await tester.pump();

    expect(tester.widget<AppBar>(appBar).backgroundColor, isNull);
    expect(
      Theme.of(tester.element(appBar)).appBarTheme.scrolledUnderElevation,
      1.5,
    );

    await tester.drag(find.byType(ListView).first, const Offset(0, 400));
    await tester.pump();
    expect(tester.widget<AppBar>(appBar).backgroundColor, isNull);
  });
}
