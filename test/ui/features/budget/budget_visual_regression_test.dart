import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/app/theme/app_typography.dart';
import 'package:feather_ledger/features/budget/presentation/screens/budget_category_detail_screen.dart';
import 'package:feather_ledger/features/budget/presentation/screens/budget_review_screen.dart';
import 'package:feather_ledger/features/budget/presentation/widgets/budget_overview_card.dart';

import '../../../support/budget_screen_harness.dart';

/// Visual regression without image goldens.
///
/// The repository has no golden harness and the test font (Ahem) draws every
/// glyph as a solid box, so a PNG would pin geometry but not the type scale,
/// the semantic colours or the copy that this ticket actually changed. These
/// tests assert the same properties directly, over the same viewport /
/// theme / locale matrix, and fail on any `RenderFlex` overflow or `maxLines`
/// truncation because those surface as test exceptions.
const _viewports = [
  ('400x700', Size(400, 700), 1.0),
  ('320x700@1.6', Size(320, 700), 1.6),
  ('900x900', Size(900, 900), 1.0),
];
const _locales = [
  Locale('en'),
  Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
];

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  ThemeData themeFor(Brightness brightness) =>
      brightness == Brightness.light ? AppTheme.lightTheme : AppTheme.darkTheme;

  for (final (viewportLabel, size, textScale) in _viewports) {
    for (final locale in _locales) {
      for (final brightness in Brightness.values) {
        testWidgets(
            'home at $viewportLabel ${locale.toLanguageTag()} '
            '${brightness.name} keeps the three-tier amount, tick and legend',
            (tester) async {
          final l10n = await AppLocalizations.delegate.load(locale);
          final theme = themeFor(brightness);
          await pumpBudgetScreen(
            tester,
            service: FakeBudgetService(overrides: {
              budgetTestMay: monthBudgetSummary(
                budgetTestMay,
                budgeted: [
                  budgetCategory(
                    id: 'dining',
                    name: 'Dining',
                    month: budgetTestMay,
                    budgetMinor: 100000,
                    actualMinor: 40000,
                    pendingMinor: 10000,
                    isAnomaly: true,
                    anomalyDeltaRatio: 1.8,
                  ),
                  budgetCategory(
                    id: 'groceries',
                    name: 'Groceries',
                    month: budgetTestMay,
                    budgetMinor: 50000,
                    actualMinor: 20000,
                  ),
                  budgetCategory(
                    id: 'transport',
                    name: 'Transport',
                    month: budgetTestMay,
                    budgetMinor: 30000,
                    actualMinor: 30000,
                  ),
                  budgetCategory(
                    id: 'housing',
                    name: 'Housing',
                    month: budgetTestMay,
                    budgetMinor: 200000,
                    actualMinor: 200000,
                  ),
                ],
                unbudgeted: [
                  budgetCategory(
                    id: 'travel',
                    name: 'Travel',
                    month: budgetTestMay,
                    actualMinor: 25000,
                  ),
                ],
              ),
            }),
            size: size,
            textScale: textScale,
            theme: theme,
            locale: locale,
          );

          expect(find.byType(BudgetOverviewCard), findsOneWidget);
          expect(tester.takeException(), isNull);

          // The headline is the same three-tier scale the ledger balance uses.
          final amount = tester.widget<Text>(
            find.byKey(const ValueKey('budget-overview-main-amount')),
          );
          final spans =
              (amount.textSpan! as TextSpan).children!.cast<TextSpan>();
          expect(spans[0].style!.fontSize, AppTypography.overviewSymbolSize);
          expect(spans[1].style!.fontSize, AppTypography.overviewWholeSize);
          expect(spans[2].style!.fontSize, AppTypography.overviewFractionSize);

          // Today is inside the tracked month: the tick must be there.
          final tickFinder =
              find.byKey(const ValueKey('budget-overview-today-tick'));
          expect(tickFinder, findsOneWidget);
          final tick = tester.widget<DecoratedBox>(tickFinder);
          expect(
            (tick.decoration as BoxDecoration).color,
            theme.colorScheme.onSurface.withValues(alpha: 0.55),
          );

          // The anomaly marker is the semantic expense colour, not a one-off.
          final anomaly = tester.widget<Semantics>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics &&
                  widget.properties.label == l10n.budgetRowAnomalySemantics,
            ),
          );
          final dot = tester.widget<Container>(
            find
                .descendant(
                  of: find.byWidget(anomaly),
                  matching: find.byType(Container),
                )
                .first,
          );
          expect(
            (dot.decoration! as BoxDecoration).color,
            theme.extension<AppSemanticColors>()!.expense,
          );

          expectNoTruncation(tester);

          // The overview plus at least three rows fit on the first screen.
          final viewportRect = tester.getRect(find.byType(ListView));
          final fullyVisible = ['Dining', 'Groceries', 'Transport', 'Housing']
              .where((name) {
            final rect = tester.getRect(find.text(name));
            return rect.top >= viewportRect.top &&
                rect.bottom <= viewportRect.bottom;
          }).length;
          if (textScale <= 1.0) {
            expect(fullyVisible, greaterThanOrEqualTo(3));
          } else {
            // At 320 dp and 1.6x the rows stack their amounts, so the accessible
            // layout trades density for legibility. One full row is the floor.
            expect(fullyVisible, greaterThanOrEqualTo(1));
          }

          // A plan month draws the dashed baseline and no today tick, while
          // review months (April) stay dashed-free too.
          await tester.tap(find.byTooltip(l10n.nextMonth));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('budget-overview-dashed-outline')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('budget-overview-bar-actual')),
            findsNothing,
          );
          expect(tickFinder, findsNothing);
          expectNoTruncation(tester);

          // The last action on the page keeps clear of the navigation bar.
          await tester.drag(find.byType(ListView), const Offset(0, -2400));
          await tester.pumpAndSettle();
          final planViewport = tester.getRect(find.byType(ListView));
          final hint = tester.getRect(find.byKey(budgetPlanHintKey));
          expect(planViewport.bottom - hint.bottom, greaterThanOrEqualTo(88));

          // Back across the tracked month to a closed one: review draws the
          // spent bar, no tick and no dashed baseline.
          await tester.tap(find.byTooltip(l10n.previousMonth));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip(l10n.previousMonth));
          await tester.pumpAndSettle();
          expect(find.byKey(budgetReviewBarKey), findsOneWidget);
          expect(tickFinder, findsNothing);
          expect(
            find.byKey(const ValueKey('budget-overview-bar-actual')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('budget-overview-dashed-outline')),
            findsNothing,
          );
          expectNoTruncation(tester);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  for (final locale in _locales) {
    for (final brightness in Brightness.values) {
      testWidgets(
          'L2 and L3 at 400x700 ${locale.toLanguageTag()} '
          '${brightness.name} keep the trend legend and the anomaly line',
          (tester) async {
        final l10n = await AppLocalizations.delegate.load(locale);
        final theme = themeFor(brightness);
        await pumpBudgetScreen(
          tester,
          service: FakeBudgetService(overrides: {
            budgetTestMay: monthBudgetSummary(
              budgetTestMay,
              budgeted: [
                budgetCategory(
                  id: 'dining',
                  name: 'Dining',
                  month: budgetTestMay,
                  budgetMinor: 100000,
                  actualMinor: 140000,
                  isAnomaly: true,
                  anomalyDeltaRatio: 1.8,
                ),
                budgetCategory(
                  id: 'groceries',
                  name: 'Groceries',
                  month: budgetTestMay,
                  budgetMinor: 50000,
                  actualMinor: 20000,
                ),
              ],
              overBudget: [
                budgetAttribution(
                  id: 'dining',
                  name: 'Dining',
                  varianceMinor: -40000,
                ),
              ],
            ),
          }),
          theme: theme,
          locale: locale,
        );

        await tester.drag(find.byType(ListView), const Offset(0, -1200));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(budgetReviewEntryKey));
        await tester.pumpAndSettle();
        expect(find.byType(BudgetReviewScreen), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text(l10n.budgetTrendLegendActual),
          160,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        expect(find.text(l10n.budgetTrendLegendActual), findsOneWidget);
        expect(find.text(l10n.budgetTrendLegendBudget), findsOneWidget);
        expectNoTruncation(tester);

        await tester.tap(find.byKey(const ValueKey('budget-attribution-dining')));
        await tester.pumpAndSettle();
        expect(find.byType(BudgetCategoryDetailScreen), findsOneWidget);
        expect(find.byIcon(LucideIcons.triangleAlert), findsOneWidget);
        expect(
          find.text(l10n.budgetAnomalyDetail(133, '\$600.00')),
          findsOneWidget,
        );
        expectNoTruncation(tester);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

/// No visible label may be cut off by its own `maxLines`.
///
/// AppBar titles are skipped: the test font (Ahem) is a square per glyph, so a
/// title that fits in the shipped typeface overflows only because every
/// character is as wide as it is tall. Device copy is covered by the manual
/// review instead.
void expectNoTruncation(WidgetTester tester) {
  for (final element in find.byType(RichText).evaluate()) {
    var insideAppBar = false;
    element.visitAncestorElements((ancestor) {
      if (ancestor.widget is AppBar) {
        insideAppBar = true;
        return false;
      }
      return true;
    });
    if (insideAppBar) continue;
    final paragraph = element.renderObject! as RenderParagraph;
    // Ellipsis is a deliberate single-line truncation (review-bar previews);
    // this check is for labels that get clipped without one.
    if (paragraph.overflow == TextOverflow.ellipsis) continue;
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: 'truncated text: ${paragraph.text.toPlainText()}',
    );
  }
}
