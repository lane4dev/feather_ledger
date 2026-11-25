import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/presentation/providers/balance_visibility_provider.dart';
import 'package:feather_ledger/features/ledger/presentation/theme/ledger_theme.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_balance_sparkline.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_header.dart';
import 'package:feather_ledger/shared/presentation/models/monthly_summary_ui_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The ledger's app bar (spec 004).
///
/// Three things it has to get right, each of which was wrong before: the month
/// shares a line with the search action rather than floating below it; the
/// bar is not empty once it collapses; and the collapsed bar is empty exactly
/// never — the boundary between the two states is a single scroll offset.
void main() {
  const summary = MonthlySummaryUiModel(
    displayBalance: r'$1,234.56',
    displayIncome: r'$500.00',
    displayExpense: r'$200.00',
  );

  Widget wrap(Widget child, {bool showBalance = true}) =>
      ProviderScope(
        overrides: [
          balanceVisibilityControllerProvider
              .overrideWith(() => _FixedVisibility(showBalance)),
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
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  // The app's own bar is left-aligned (it matches the budget
                  // tab's), so the harness has to be too or the arrow-hugging
                  // assertions measure a layout the app never renders.
                  centerTitle: false,
                  title: child,
                  actions: [
                    AppIconButton(
                      icon: const Icon(LucideIcons.search),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  group('the collapse boundary', () {
    // The outer scrollable's offset stops at exactly this value, so `>` left
    // the collapsed bar permanently empty.
    test('is crossed when the header is exactly fully collapsed', () {
      expect(isHeaderCollapsed(124, 180), isTrue);
      expect(isHeaderCollapsed(123.9, 180), isFalse);
      expect(isHeaderCollapsed(0, 180), isFalse);
    });
  });

  for (final locale in [
    const Locale('en'),
    const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ]) {
    testWidgets('balance visibility sits beside the label ($locale)',
        (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var opened = 0;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          balanceVisibilityControllerProvider
              .overrideWith(() => _FixedVisibility(true)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: Scaffold(
            body: LedgerHeader(
              summaryAsync: const AsyncData(summary),
              onTap: () => opened++,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final l10n =
          AppLocalizations.of(tester.element(find.byType(LedgerHeader)))!;
      final label = tester.getRect(find.text(l10n.totalBalance));
      final eye = tester.getRect(find.byIcon(LucideIcons.eye));
      final arrow = tester.getRect(find.byIcon(LucideIcons.chevronRight));
      expect(eye.left, greaterThanOrEqualTo(label.right));
      expect(eye.left - label.right, lessThan(24));
      // The chevron is punctuation after the label, not a marker on the card's
      // far edge: it used to be pushed out there and read as floating.
      expect(arrow.left, greaterThan(eye.right));
      expect(arrow.left - eye.right, lessThan(24));
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(LucideIcons.eye));
      await tester.pumpAndSettle();
      expect(find.byIcon(LucideIcons.eyeOff), findsOneWidget);
      expect(opened, 0);
      await tester.tap(find.byIcon(LucideIcons.chevronRight));
      expect(opened, 1);
    });
  }

  group('the month', () {
    testWidgets('shares a centre line with the search action', (tester) async {
      await tester.pumpWidget(wrap(LedgerAppBarTitle(
        selectedDate: DateTime(2026, 11),
        summaryAsync: const AsyncData(summary),
        collapsed: false,
      )));
      await tester.pumpAndSettle();

      final monthCentre = tester.getCenter(find.text('November 2026')).dy;
      final searchCentre = tester.getCenter(find.byIcon(LucideIcons.search)).dy;

      expect((monthCentre - searchCentre).abs(), lessThan(1.0),
          reason: 'they are one row of controls, so they line up');
    });

    testWidgets('keeps its steppers while expanded', (tester) async {
      await tester.pumpWidget(wrap(LedgerAppBarTitle(
        selectedDate: DateTime(2026, 11),
        summaryAsync: const AsyncData(summary),
        collapsed: false,
      )));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.chevronLeft), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    });
  });

  group('once collapsed', () {
    testWidgets('keeps the month and masks the amount while loading',
        (tester) async {
      await tester.pumpWidget(wrap(
        LedgerAppBarTitle(
          selectedDate: DateTime(2026, 11),
          summaryAsync: const AsyncLoading(),
          collapsed: true,
        ),
        showBalance: false,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Nov 2026'), findsOneWidget);
      expect(find.text('******'), findsOneWidget);
    });

    Future<void> pump(WidgetTester tester, {bool showBalance = true}) async {
      await tester.pumpWidget(wrap(
        LedgerAppBarTitle(
          selectedDate: DateTime(2026, 11),
          summaryAsync: const AsyncData(summary),
          collapsed: true,
        ),
        showBalance: showBalance,
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('the bar carries the month and the balance', (tester) async {
      await pump(tester);

      expect(find.text('Nov 2026'), findsOneWidget);
      expect(find.text(r'$1,234.56'), findsOneWidget);
    });

    testWidgets('a hidden balance is masked, not dropped', (tester) async {
      await pump(tester, showBalance: false);

      expect(find.text('Nov 2026'), findsOneWidget,
          reason: 'the month is not a balance and is never hidden');
      expect(find.text('******'), findsOneWidget);
      expect(find.text(r'$1,234.56'), findsNothing);
    });

    testWidgets('the steppers give their room to the balance', (tester) async {
      await pump(tester);

      expect(find.byIcon(LucideIcons.chevronLeft), findsNothing);
      expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
    });
  });

  group('overview card expressive design', () {
    for (final entry in [
      (
        label: 'light 360 en',
        theme: AppTheme.lightTheme,
        width: 360.0,
        locale: const Locale('en'),
      ),
      (
        label: 'dark 360 zh_Hans',
        theme: AppTheme.darkTheme,
        width: 360.0,
        locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      ),
      (
        label: 'light 800 zh_Hant',
        theme: AppTheme.lightTheme,
        width: 800.0,
        locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ),
      (
        label: 'dark 800 zh',
        theme: AppTheme.darkTheme,
        width: 800.0,
        locale: const Locale('zh'),
      ),
    ]) {
      testWidgets(
          'uses overview surface, 50/50 tonal sub-containers, and tabular bold balance (${entry.label})',
          (tester) async {
        tester.view.physicalSize = Size(entry.width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final targetMonth = DateTime(2026, 11);
        await tester.pumpWidget(ProviderScope(
          overrides: [
            balanceVisibilityControllerProvider
                .overrideWith(() => _FixedVisibility(true)),
          ],
          child: MaterialApp(
            theme: entry.theme,
            locale: entry.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: LedgerHeader(
                month: targetMonth,
                summaryAsync: const AsyncData(summary),
                onTap: () {},
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        final ctx = tester.element(find.byType(LedgerHeader));
        final l10n = AppLocalizations.of(ctx)!;
        final scheme = Theme.of(ctx).colorScheme;
        final semantics = Theme.of(ctx).extension<AppSemanticColors>()!;
        final monthAbbr =
            DateFormat.MMM(entry.locale.toString()).format(targetMonth);

        // The hero plate: 24dp radius, a gradient base, a 1dp hairline.
        final plateFinder = find.byWidgetPredicate(
          (w) => w is ClipRRect && w.borderRadius == BorderRadius.circular(24),
        );
        expect(plateFinder, findsOneWidget);
        final plate = tester
            .widgetList<DecoratedBox>(find.descendant(
              of: plateFinder,
              matching: find.byType(DecoratedBox),
            ))
            .map((d) => d.decoration as BoxDecoration)
            .firstWhere((d) => d.border != null);
        expect(
          plate.gradient,
          isA<LinearGradient>(),
          reason: 'a flat fill is what the card used to be',
        );
        expect(plate.border!.top.width, LedgerTheme.overviewBorderWidth);
        expect(plate.border!.top.color.a, greaterThan(0));

        // The balance is three tiers of one string: symbol, units, decimals.
        final balanceFinder =
            find.text(summary.displayBalance, findRichText: true);
        expect(balanceFinder, findsOneWidget);
        final balanceSpans = tester
            .widget<Text>(find.byWidgetPredicate(
              (w) =>
                  w is Text &&
                  w.textSpan?.toPlainText() == summary.displayBalance,
            ))
            .textSpan! as TextSpan;
        final tiers = balanceSpans.children!.cast<TextSpan>();
        expect(tiers.length, 3);
        expect(tiers[0].text, r'$');
        expect(tiers[0].style?.fontSize, LedgerTheme.balanceSymbolSize);
        expect(tiers[0].style?.color, scheme.onSurfaceVariant);
        expect(tiers[1].text, '1,234');
        expect(tiers[1].style?.fontSize, LedgerTheme.balanceWholeSize);
        expect(tiers[1].style?.fontWeight, FontWeight.w700);
        expect(tiers[1].style?.color, scheme.onSurface);
        expect(
          tiers[1].style?.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
        expect(tiers[2].text, '.56');
        expect(tiers[2].style?.fontSize, LedgerTheme.balanceFractionSize);
        expect(tiers[2].style?.color, scheme.onSurfaceVariant);

        // The month's spending rides alongside the balance.
        expect(find.byType(LedgerBalanceSparkline), findsOneWidget);

        // Month income & expense labels reflect the selected month and share 50/50 width.
        final incomeLabelFinder = find.text(l10n.monthIncome(monthAbbr));
        final expenseLabelFinder = find.text(l10n.monthExpense(monthAbbr));
        expect(incomeLabelFinder, findsOneWidget);
        expect(expenseLabelFinder, findsOneWidget);

        final incomeAmountFinder = find.text(summary.displayIncome);
        final expenseAmountFinder = find.text(summary.displayExpense);
        expect(incomeAmountFinder, findsOneWidget);
        expect(expenseAmountFinder, findsOneWidget);

        final incomeAmountText = tester.widget<Text>(incomeAmountFinder);
        final expenseAmountText = tester.widget<Text>(expenseAmountFinder);
        expect(
          incomeAmountText.style?.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
        expect(
          expenseAmountText.style?.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
        expect(
          incomeAmountText.style?.color,
          scheme.onSurface,
          reason: 'the figures sit on the card itself, not on a tinted box',
        );
        expect(
          expenseAmountText.style?.color,
          scheme.onSurface,
          reason: 'the figures sit on the card itself, not on a tinted box',
        );
        // The kind still has its colour — on the icon disc behind the arrow.
        expect(
          find.ancestor(
            of: find.byIcon(LucideIcons.arrowDown),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Container &&
                  w.decoration is BoxDecoration &&
                  (w.decoration! as BoxDecoration).color ==
                      semantics.incomeContainer,
            ),
          ),
          findsOneWidget,
        );

        // The two halves are columns of one bar, not two boxes: equal width,
        // a hairline between them, and each label sits above its own figure.
        final incomeBoxFinder = find
            .ancestor(of: incomeLabelFinder, matching: find.byType(Expanded))
            .last;
        final expenseBoxFinder = find
            .ancestor(of: expenseLabelFinder, matching: find.byType(Expanded))
            .last;
        expect(incomeBoxFinder, findsOneWidget);
        expect(expenseBoxFinder, findsOneWidget);

        final incomeBoxRect = tester.getRect(incomeBoxFinder);
        final expenseBoxRect = tester.getRect(expenseBoxFinder);
        expect(incomeBoxRect.width, closeTo(expenseBoxRect.width, 0.5));
        expect(expenseBoxRect.left, greaterThan(incomeBoxRect.right));

        expect(
          tester.getTopLeft(incomeLabelFinder).dx,
          closeTo(tester.getTopLeft(incomeAmountFinder).dx, 0.5),
        );
        expect(
          tester.getTopLeft(expenseLabelFinder).dx,
          closeTo(tester.getTopLeft(expenseAmountFinder).dx, 0.5),
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
        'eye button updates tooltip and semantic label and masks balance, income, and expense',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          balanceVisibilityControllerProvider
              .overrideWith(() => _FixedVisibility(true)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: LedgerHeader(
              month: DateTime(2026, 11),
              summaryAsync: const AsyncData(summary),
              onTap: () {},
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final l10n =
          AppLocalizations.of(tester.element(find.byType(LedgerHeader)))!;
      final eyeFinder = find.byIcon(LucideIcons.eye);
      expect(find.byTooltip(l10n.hideOverviewAmounts), findsOneWidget);
      final eyeButtonRect = tester.getRect(
        find.ancestor(of: eyeFinder, matching: find.byType(AppIconButton)),
      );
      expect(eyeButtonRect.width, greaterThanOrEqualTo(48));
      expect(eyeButtonRect.height, greaterThanOrEqualTo(48));
      expect(
        tester.getSemantics(find.byTooltip(l10n.hideOverviewAmounts)).tooltip,
        l10n.hideOverviewAmounts,
      );

      await tester.tap(eyeFinder);
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.eyeOff), findsOneWidget);
      expect(find.byTooltip(l10n.showOverviewAmounts), findsOneWidget);
      expect(
        tester.getSemantics(find.byTooltip(l10n.showOverviewAmounts)).tooltip,
        l10n.showOverviewAmounts,
      );
      expect(find.textContaining('****'), findsNWidgets(3));
      expect(find.text(summary.displayBalance, findRichText: true), findsNothing);
      expect(find.text(summary.displayIncome), findsNothing);
      expect(find.text(summary.displayExpense), findsNothing);
    });
  });

  group('compact centered month toolbar', () {
    for (final entry in [
      (width: 360.0, locale: const Locale('en')),
      (
        width: 360.0,
        locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      ),
      (width: 800.0, locale: const Locale('en')),
      (
        width: 800.0,
        locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ),
      (width: 800.0, locale: const Locale('zh')),
    ]) {
      testWidgets(
          'keeps arrows compact around month label with >=48dp hit targets (${entry.width}dp, ${entry.locale})',
          (tester) async {
        tester.view.physicalSize = Size(entry.width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final targetMonth = DateTime(2026, 11);
        await tester.pumpWidget(ProviderScope(
          overrides: [
            balanceVisibilityControllerProvider
                .overrideWith(() => _FixedVisibility(true)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            locale: entry.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    centerTitle: false,
                    title: LedgerAppBarTitle(
                      selectedDate: targetMonth,
                      summaryAsync: const AsyncData(summary),
                      collapsed: false,
                      onMonthChanged: (_) {},
                      onMonthTap: () {},
                    ),
                    actions: [
                      AppIconButton(
                        icon: const Icon(LucideIcons.search),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        final monthStr =
            DateFormat.yMMMM(entry.locale.toString()).format(targetMonth);
        final leftButton = find.ancestor(
          of: find.byIcon(LucideIcons.chevronLeft),
          matching: find.byType(AppIconButton),
        );
        final rightButton = find.ancestor(
          of: find.byIcon(LucideIcons.chevronRight),
          matching: find.byType(AppIconButton),
        );
        final searchButton = find.ancestor(
          of: find.byIcon(LucideIcons.search),
          matching: find.byType(AppIconButton),
        );

        final leftRect = tester.getRect(leftButton);
        final monthRect = tester.getRect(find.text(monthStr));
        final rightRect = tester.getRect(rightButton);
        final searchRect = tester.getRect(searchButton);

        for (final rect in [leftRect, rightRect, searchRect]) {
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
        }

        // Arrows hug the month text rather than stretching to toolbar edges.
        expect(monthRect.left - leftRect.right, lessThan(24));
        expect(rightRect.left - monthRect.right, lessThan(24));
        expect(searchRect.left, greaterThanOrEqualTo(rightRect.right));

        // Left-aligned at every width: the switcher starts at the toolbar's
        // title spacing and grows rightwards, never centred.
        final switcherRect = tester.getRect(find.byType(LedgerMonthSwitcher));
        expect(switcherRect.left, closeTo(leftRect.left, 0.5));
        if (entry.width >= 800) {
          expect(switcherRect.left, lessThan(entry.width / 4));
        } else {
          expect(leftRect.left, greaterThanOrEqualTo(0));
          expect(rightRect.right, lessThanOrEqualTo(searchRect.left));
        }
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('collapsed app bar renders month title hierarchy and tonal balance capsule',
      (tester) async {
    await tester.pumpWidget(wrap(
      LedgerAppBarTitle(
        selectedDate: DateTime(2026, 11),
        summaryAsync: const AsyncData(summary),
        collapsed: true,
      ),
    ));
    await tester.pumpAndSettle();

    final monthText = tester.widget<Text>(find.text('Nov 2026'));
    expect(monthText.style?.fontWeight, FontWeight.w600);
    expect(monthText.style?.color, AppTheme.lightTheme.colorScheme.onSurface);

    expect(find.text('Balance'), findsOneWidget);
    final balanceText = tester.widget<Text>(find.text(r'$1,234.56'));
    expect(
      balanceText.style?.color,
      AppTheme.lightTheme.colorScheme.onSurfaceVariant,
    );

    final capsule = tester.widget<DecoratedBox>(find.ancestor(
      of: find.byType(LedgerCompactBalance),
      matching: find.byType(DecoratedBox),
    ));
    final decoration = capsule.decoration as BoxDecoration;
    expect(
      decoration.color,
      AppTheme.lightTheme.colorScheme.surfaceContainerHigh,
    );
  });
}

class _FixedVisibility extends BalanceVisibilityController {
  _FixedVisibility(this.visible);

  final bool visible;

  @override
  Future<bool> build() async => visible;

  @override
  Future<void> toggle() async => state = AsyncData(!(state.value ?? true));
}
