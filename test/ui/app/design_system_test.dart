import 'dart:typed_data';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/app/design_system/app_badge.dart';
import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:feather_ledger/app/design_system/app_segmented_control.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/router/app_router.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/balance_visibility_provider.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/core/presentation/providers/locale_provider.dart';
import 'package:feather_ledger/core/presentation/providers/theme_provider.dart';
import 'package:feather_ledger/features/budget/presentation/screens/budget_screen.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_header.dart';
import 'package:feather_ledger/features/settings/presentation/screens/more_screen.dart';
import 'package:feather_ledger/main.dart';
import 'package:feather_ledger/shared/presentation/models/monthly_summary_ui_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../support/event_sourcing/ledger_service_harness.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return x > y ? (x + 0.05) / (y + 0.05) : (y + 0.05) / (x + 0.05);
}

void main() {
  testWidgets('segmented control honors reduced motion', (tester) async {
    var selected = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(body: StatefulBuilder(builder: (context, setState) {
          return AppSegmentedControl<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('First')),
              ButtonSegment(value: 1, label: Text('Second')),
            ],
            selected: selected,
            onSelected: (value) => setState(() => selected = value),
          );
        })),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Second'));
    await tester.pump();
    await tester.pump();
    expect(selected, 1);
    expect(
        tester
            .widgetList<AnimatedPositioned>(find.descendant(
                of: find.byType(AppSegmentedControl<int>),
                matching: find.byType(AnimatedPositioned)))
            .every((surface) => surface.duration == Duration.zero),
        isTrue);
  });

  testWidgets(
      'segmented control raises the selection and separates other items',
      (tester) async {
    var selected = 2;
    final theme = AppTheme.lightTheme;
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: Scaffold(body: StatefulBuilder(builder: (context, setState) {
        return AppSegmentedControl<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Day')),
            ButtonSegment(value: 1, label: Text('Week')),
            ButtonSegment(value: 2, label: Text('Off')),
          ],
          selected: selected,
          onSelected: (value) => setState(() => selected = value),
        );
      })),
    ));
    await tester.pumpAndSettle();
    final indicator = find.byKey(const ValueKey('segment-selection'));
    final surface = tester.widget<Material>(indicator);
    expect(surface.color, theme.colorScheme.secondaryContainer);
    expect(surface.elevation, theme.extension<AppMetrics>()!.subtleElevation);
    final start = tester.getRect(indicator);
    expect(start.left, lessThan(tester.getTopLeft(find.text('Off')).dx));
    final divider = tester.widget<DecoratedBox>(find.descendant(
      of: find.byKey(const ValueKey('segment-divider-1')),
      matching: find.byType(DecoratedBox),
    ));
    expect((divider.decoration as BoxDecoration).color,
        theme.colorScheme.outlineVariant);
    await tester.tap(find.text('Day'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final middle = tester.getRect(indicator);
    expect(middle.left, lessThan(start.left));
    await tester.pumpAndSettle();
    expect(selected, 0);
    final end = tester.getRect(indicator);
    expect(end.left, lessThan(middle.left));
    expect(find.byKey(const ValueKey('segment-selection')), findsOneWidget);
    final button =
        tester.widget<TextButton>(find.widgetWithText(TextButton, 'Day'));
    expect(button.style!.splashFactory, NoSplash.splashFactory);
    final hiddenDivider = tester.widget<DecoratedBox>(find.descendant(
      of: find.byKey(const ValueKey('segment-divider-1')),
      matching: find.byType(DecoratedBox),
    ));
    expect((hiddenDivider.decoration as BoxDecoration).color!.a, 0);
  });

  for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
    final brightness = theme.brightness.name;
    test('$brightness surfaces keep text readable and charts independent', () {
      final scheme = theme.colorScheme;
      final semantics = theme.extension<AppSemanticColors>()!;
      final surfaces = [
        scheme.surface,
        scheme.surfaceContainerLow,
        scheme.surfaceContainer,
        scheme.surfaceContainerHigh,
      ];
      for (final surface in surfaces) {
        expect(contrast(scheme.onSurface, surface), greaterThanOrEqualTo(4.5));
        expect(contrast(scheme.onSurfaceVariant, surface),
            greaterThanOrEqualTo(4.5));
        expect(contrast(scheme.outline, surface), greaterThanOrEqualTo(3.0));
      }
      expect(contrast(scheme.primary, scheme.onPrimary),
          greaterThanOrEqualTo(4.5));
      expect(contrast(scheme.onPrimaryContainer, scheme.primaryContainer),
          greaterThanOrEqualTo(4.5));
      expect(contrast(scheme.onSecondaryContainer, scheme.secondaryContainer),
          greaterThanOrEqualTo(4.5));
      expect(contrast(scheme.onErrorContainer, scheme.errorContainer),
          greaterThanOrEqualTo(4.5));
      expect(contrast(semantics.onIncomeContainer, semantics.incomeContainer),
          greaterThanOrEqualTo(4.5));
      expect(contrast(semantics.onExpenseContainer, semantics.expenseContainer),
          greaterThanOrEqualTo(4.5));
      expect(contrast(semantics.income, scheme.surfaceContainerLow),
          greaterThanOrEqualTo(4.5));
      expect(contrast(semantics.expense, scheme.surfaceContainerLow),
          greaterThanOrEqualTo(4.5));
      expect(semantics.frequency, isNot(scheme.primary));
      expect(theme.navigationBarTheme.backgroundColor, scheme.surfaceContainer);
      expect(theme.floatingActionButtonTheme.backgroundColor,
          scheme.primaryContainer);
      expect(theme.floatingActionButtonTheme.foregroundColor,
          scheme.onPrimaryContainer);

      if (theme.brightness == Brightness.light) {
        expect(scheme.surface, const Color(0xFFF7FAF7));
        expect(scheme.surfaceContainerLow, const Color(0xFFEFF4EF));
        expect(scheme.surfaceContainer, const Color(0xFFE6EDE7));
        expect(scheme.surfaceContainerHigh, const Color(0xFFDFE6E1));
        expect(scheme.onSurface, const Color(0xFF191D1B));
        expect(scheme.onSurfaceVariant, const Color(0xFF424B46));
        expect(scheme.outlineVariant, const Color(0xFFC4CEC7));
        expect(scheme.primaryContainer, const Color(0xFFC5ECDC));
        expect(scheme.onPrimaryContainer, const Color(0xFF153E33));
        expect(scheme.secondaryContainer, const Color(0xFFD6E8DC));
        expect(scheme.onSecondaryContainer, const Color(0xFF263D34));
        expect(semantics.income, const Color(0xFF0F766E));
        expect(semantics.expense, const Color(0xFFC2410C));
        expect(semantics.incomeContainer, const Color(0xFFDAEDDF));
        expect(semantics.onIncomeContainer, const Color(0xFF25392E));
        expect(semantics.expenseContainer, const Color(0xFFF9E5DF));
        expect(semantics.onExpenseContainer, const Color(0xFF572D22));
      } else {
        expect(scheme.surface, const Color(0xFF111413));
        expect(scheme.surfaceContainerLow, const Color(0xFF191D1B));
        expect(scheme.surfaceContainer, const Color(0xFF1B201E));
        expect(scheme.surfaceContainerHigh, const Color(0xFF222826));
        expect(scheme.surface, isNot(const Color(0xFF000000)));
        expect(scheme.onSurface, isNot(const Color(0xFFFFFFFF)));
        expect(scheme.primary, isNot(const Color(0xFFFFFFFF)));
        expect(scheme.primaryContainer, const Color(0xFF1F4E42));
        expect(scheme.onPrimaryContainer, const Color(0xFFA6F2DC));
        expect(semantics.income, const Color(0xFF81C995));
        expect(semantics.expense, const Color(0xFFF2B8B5));
        expect(contrast(semantics.income, scheme.surfaceContainerHigh),
            greaterThanOrEqualTo(4.5));
        expect(contrast(semantics.expense, scheme.surfaceContainerHigh),
            greaterThanOrEqualTo(4.5));
      }
    });

    testWidgets(
        '$brightness shared controls preserve selection, disabled state and tap size',
        (tester) async {
      var taps = 0;
      var selected = 0;
      await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
            body: StatefulBuilder(
                builder: (context, setState) => Column(children: [
                      AppButton(
                          onPressed: () => taps++, child: const Text('Save')),
                      const AppButton(onPressed: null, child: Text('Disabled')),
                      AppIconButton.surface(
                          icon: const Icon(LucideIcons.search),
                          onPressed: () => taps++),
                      AppSegmentedControl<int>(
                        widthFactor: 1,
                        segments: const [
                          ButtonSegment(value: 0, label: Text('Income')),
                          ButtonSegment(value: 1, label: Text('Expense'))
                        ],
                        selected: selected,
                        onSelected: (value) => setState(() => selected = value),
                      ),
                      const AppCard(child: Text('A shared surface')),
                    ])),
          )));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.widgetWithText(FilledButton, 'Save')).height,
          greaterThanOrEqualTo(48));
      expect(tester.getSize(find.byType(IconButton)).width,
          greaterThanOrEqualTo(48));
      await tester.tap(find.text('Save'));
      await tester.tap(find.text('Disabled'));
      await tester.tap(find.text('Expense'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(selected, 1);
      expect(
          tester
              .widget<AppSegmentedControl<int>>(
                  find.byType(AppSegmentedControl<int>))
              .selected,
          1);
      expect(tester.takeException(), isNull);
    });

    for (final locale in [
      const Locale('en'),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
    ]) {
      testWidgets(
          '$brightness $locale summary fits a narrow screen with large text',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 760);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        const summary = MonthlySummaryUiModel(
            displayBalance: r'- $12345678901.23',
            displayIncome: r'$1234567.89',
            displayExpense: r'$9876543.21');
        await tester.pumpWidget(ProviderScope(
            overrides: [
              balanceVisibilityControllerProvider.overrideWith(_Visible.new)
            ],
            child: MaterialApp(
              theme: theme,
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(1.8)),
                  child: child!),
              home: const Scaffold(
                  body: SingleChildScrollView(
                      child: LedgerHeader(summaryAsync: AsyncData(summary)))),
            )));
        await tester.pumpAndSettle();
        expect(find.text(summary.displayBalance), findsOneWidget);
        expect(find.byIcon(LucideIcons.eye), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  test('geometry and semantic colors interpolate for theme transitions', () {
    const original = AppMetrics();
    final larger = original.copyWith(cardRadius: 28, cellRadius: 8);
    final halfway = original.lerp(larger, 0.5);
    expect(halfway.cardRadius, 24);
    expect(halfway.cellRadius, 6);
    final light = AppTheme.lightTheme.extension<AppSemanticColors>()!;
    final dark = AppTheme.darkTheme.extension<AppSemanticColors>()!;
    expect(light.lerp(dark, 1).frequency, dark.frequency);
    expect(light.lerp(dark, 1).incomeContainer, dark.incomeContainer);
    expect(light.lerp(dark, 1).expenseContainer, dark.expenseContainer);
  });

  test('dynamic schemes preserve 4-layer hierarchy and WCAG contrast', () {
    for (final seed in [
      const Color(0xFF1A73E8),
      const Color(0xFFE91E63),
      const Color(0xFFFFEB3B),
      const Color(0xFF00BCD4),
    ]) {
      // Simulate CorePalette.toColorScheme where dark surface collides with
      // surfaceContainerLow (tone 10) and pure white is used on text/primary.
      final rawDark = ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      );
      final brokenDark = rawDark.copyWith(
        surface: rawDark.surfaceContainerLow,
        onSurface: const Color(0xFFFFFFFF),
        primary: const Color(0xFFFFFFFF),
      );
      final dynamicLight = AppTheme.buildLight(
        ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
      );
      final dynamicDark = AppTheme.buildDark(brokenDark);

      final lightScheme = dynamicLight.colorScheme;
      expect(
        lightScheme.surface.computeLuminance(),
        greaterThan(lightScheme.surfaceContainerLow.computeLuminance()),
      );
      expect(
        lightScheme.surfaceContainerLow.computeLuminance(),
        greaterThan(lightScheme.surfaceContainer.computeLuminance()),
      );
      expect(
        lightScheme.surfaceContainer.computeLuminance(),
        greaterThan(lightScheme.surfaceContainerHigh.computeLuminance()),
      );

      final darkScheme = dynamicDark.colorScheme;
      expect(darkScheme.surface, isNot(const Color(0xFF000000)));
      expect(darkScheme.onSurface, isNot(const Color(0xFFFFFFFF)));
      expect(darkScheme.primary, isNot(const Color(0xFFFFFFFF)));
      expect(
        darkScheme.surface.computeLuminance(),
        lessThan(darkScheme.surfaceContainerLow.computeLuminance()),
      );
      expect(
        darkScheme.surfaceContainerLow.computeLuminance(),
        lessThan(darkScheme.surfaceContainer.computeLuminance()),
      );
      expect(
        darkScheme.surfaceContainer.computeLuminance(),
        lessThan(darkScheme.surfaceContainerHigh.computeLuminance()),
      );

      for (final theme in [dynamicLight, dynamicDark]) {
        final s = theme.colorScheme;
        final sem = theme.extension<AppSemanticColors>()!;
        final surfaces = [
          s.surface,
          s.surfaceContainerLow,
          s.surfaceContainer,
          s.surfaceContainerHigh,
        ];
        for (final bg in surfaces) {
          expect(contrast(s.onSurface, bg), greaterThanOrEqualTo(4.5));
          expect(contrast(s.onSurfaceVariant, bg), greaterThanOrEqualTo(4.5));
          expect(contrast(s.outline, bg), greaterThanOrEqualTo(3.0));
          expect(contrast(s.primary, bg), greaterThanOrEqualTo(3.0));
        }
        expect(contrast(s.onPrimary, s.primary), greaterThanOrEqualTo(4.5));
        expect(contrast(s.onPrimaryContainer, s.primaryContainer),
            greaterThanOrEqualTo(4.5));
        expect(contrast(s.onSecondaryContainer, s.secondaryContainer),
            greaterThanOrEqualTo(4.5));
        expect(contrast(s.onErrorContainer, s.errorContainer),
            greaterThanOrEqualTo(4.5));
        expect(contrast(sem.income, s.surfaceContainerLow),
            greaterThanOrEqualTo(4.5));
        expect(contrast(sem.expense, s.surfaceContainerLow),
            greaterThanOrEqualTo(4.5));
        expect(contrast(sem.onIncomeContainer, sem.incomeContainer),
            greaterThanOrEqualTo(4.5));
        expect(contrast(sem.onExpenseContainer, sem.expenseContainer),
            greaterThanOrEqualTo(4.5));
      }
    }
  });

  testWidgets(
      'card, badge, icon button variants and tabular numerals meet spec',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Builder(builder: (context) {
          final balanceStyle = AppTypography.balance(context);
          final amountStyle = AppTypography.amount(context);
          final statStyle = AppTypography.statistic(context);
          final inputStyle = AppTypography.amountInput(context);
          final compactAmountStyle = AppTypography.compactAmount(context);
          for (final style in [
            balanceStyle,
            amountStyle,
            statStyle,
            inputStyle,
            compactAmountStyle,
          ]) {
            expect(
              style.fontFeatures,
              contains(const FontFeature.tabularFigures()),
            );
          }
          return Column(
            children: [
              const AppCard(
                key: ValueKey('default-card'),
                child: Text('Default'),
              ),
              const AppCard.overview(
                key: ValueKey('overview-card'),
                child: Text('Overview'),
              ),
              const AppCard.day(
                key: ValueKey('day-card'),
                child: Text('Day'),
              ),
              const AppBadge.outlined(
                key: ValueKey('outlined-pill'),
                label: 'Pending',
                icon: LucideIcons.clock,
              ),
              const AppBadge.error(
                key: ValueKey('error-pill'),
                label: 'Failed',
                icon: LucideIcons.circleAlert,
              ),
              AppIconButton(
                key: const ValueKey('eye-button'),
                icon: const Icon(LucideIcons.eye),
                iconSize: 18,
                onPressed: () {},
              ),
            ],
          );
        }),
      ),
    ));
    await tester.pumpAndSettle();

    final scheme = AppTheme.lightTheme.colorScheme;
    final defaultCard = tester.widget<Card>(find.descendant(
      of: find.byKey(const ValueKey('default-card')),
      matching: find.byType(Card),
    ));
    expect(defaultCard.shape, isNull);
    expect(AppTheme.metrics.cardRadius, 20);

    final overviewCard = tester.widget<Card>(find.descendant(
      of: find.byKey(const ValueKey('overview-card')),
      matching: find.byType(Card),
    ));
    expect(overviewCard.color, scheme.surfaceContainerHigh);
    expect(
      (overviewCard.shape as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(24),
    );

    final dayCard = tester.widget<Card>(find.descendant(
      of: find.byKey(const ValueKey('day-card')),
      matching: find.byType(Card),
    ));
    expect(dayCard.color, scheme.surfaceContainerLow);
    final dayRadius =
        ((dayCard.shape as RoundedRectangleBorder).borderRadius as BorderRadius)
            .topLeft
            .x;
    expect(dayRadius, inInclusiveRange(16, 18));

    final outlinedBox = tester.widget<DecoratedBox>(find.descendant(
      of: find.byKey(const ValueKey('outlined-pill')),
      matching: find.byType(DecoratedBox),
    ));
    final outlinedDec = outlinedBox.decoration as BoxDecoration;
    expect(outlinedDec.color, scheme.surfaceContainerLow);
    expect((outlinedDec.border! as Border).top.color, scheme.outline);

    final errorBox = tester.widget<DecoratedBox>(find.descendant(
      of: find.byKey(const ValueKey('error-pill')),
      matching: find.byType(DecoratedBox),
    ));
    final errorDec = errorBox.decoration as BoxDecoration;
    expect(errorDec.color, scheme.errorContainer);

    final eyeSize = tester.getSize(find.byKey(const ValueKey('eye-button')));
    expect(eyeSize.width, greaterThanOrEqualTo(48));
    expect(eyeSize.height, greaterThanOrEqualTo(48));
  });

  group('FeatherLedgerApp dynamic color and ThemeMode fallback', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(DynamicColorPlugin.channel, null);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(DynamicColorPlugin.channel, null);
    });

    Int32List sampleCorePalettePayload(double hue) {
      const tones = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 95, 99, 100];
      final paletteSpecs = <(double h, double s)>[
        (hue, 0.70), // primary
        (hue, 0.25), // secondary
        ((hue + 60) % 360, 0.35), // tertiary
        (hue, 0.08), // neutral
        (hue, 0.14), // neutralVariant
      ];
      return Int32List.fromList([
        for (final (h, s) in paletteSpecs)
          for (final tone in tones)
            HSLColor.fromAHSL(1, h, s, tone / 100.0).toColor().toARGB32(),
      ]);
    }

    Future<ProviderContainer> pumpAppWithOverrides(
      WidgetTester tester,
      LedgerServiceHarness harness, {
      ThemeMode initialThemeMode = ThemeMode.light,
    }) async {
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(harness.db),
        themeModeControllerProvider
            .overrideWith(() => _TestThemeModeController(initialThemeMode)),
        localeControllerProvider.overrideWith(_EnglishLocaleController.new),
        balanceVisibilityControllerProvider.overrideWith(_Visible.new),
        accountUiListProvider.overrideWith((ref) => const AsyncData([])),
        categoryListProvider.overrideWith((ref, type) => Stream.value([])),
        ledgerMonthlyTransactionsProvider
            .overrideWith((ref, month) => Stream.value([])),
        ledgerMonthlySummaryProvider.overrideWith((ref, month) => Stream.value(
            const MonthlySummaryUiModel(
                displayBalance: r'$0',
                displayIncome: r'$0',
                displayExpense: r'$0'))),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const FeatherLedgerApp(),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets(
        'falls back to default 4-layer palette when dynamic color is absent',
        (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              DynamicColorPlugin.channel, (_) async => null);
      final harness = LedgerServiceHarness();
      addTearDown(harness.close);

      final container = await pumpAppWithOverrides(tester, harness,
          initialThemeMode: ThemeMode.light);
      expect(
        Theme.of(tester.element(find.byType(NavigationBar))).colorScheme.surface,
        const Color(0xFFF7FAF7),
      );

      await container
          .read(themeModeControllerProvider.notifier)
          .setTheme(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(NavigationBar))).colorScheme.surface,
        const Color(0xFF111413),
      );

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await container
          .read(themeModeControllerProvider.notifier)
          .setTheme(ThemeMode.system);
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(NavigationBar))).colorScheme.surface,
        const Color(0xFFF7FAF7),
      );
    });

    testWidgets('falls back gracefully when dynamic color channel throws',
        (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(DynamicColorPlugin.channel, (call) async {
        throw PlatformException(code: 'UNAVAILABLE', message: 'not supported');
      });
      final harness = LedgerServiceHarness();
      addTearDown(harness.close);

      await pumpAppWithOverrides(tester, harness,
          initialThemeMode: ThemeMode.dark);
      expect(tester.takeException(), isNull);
      expect(
        Theme.of(tester.element(find.byType(NavigationBar))).colorScheme.surface,
        const Color(0xFF111413),
      );
    });

    testWidgets('applies dynamic CorePalette for light and dark themes',
        (tester) async {
      final payload = sampleCorePalettePayload(230);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(DynamicColorPlugin.channel, (call) async {
        if (call.method == DynamicColorPlugin.methodName) {
          return payload;
        }
        return null;
      });
      final harness = LedgerServiceHarness();
      addTearDown(harness.close);

      final container = await pumpAppWithOverrides(tester, harness,
          initialThemeMode: ThemeMode.light);
      final lightContext = tester.element(find.byType(NavigationBar));
      final lightScheme = Theme.of(lightContext).colorScheme;
      expect(lightScheme.surface, isNot(const Color(0xFFF7FAF7)));
      expect(
        lightScheme.surface.computeLuminance(),
        greaterThan(lightScheme.surfaceContainerLow.computeLuminance()),
      );

      await container
          .read(themeModeControllerProvider.notifier)
          .setTheme(ThemeMode.dark);
      await tester.pumpAndSettle();
      final darkContext = tester.element(find.byType(NavigationBar));
      final darkScheme = Theme.of(darkContext).colorScheme;
      expect(darkScheme.surface, isNot(const Color(0xFF111413)));
      expect(darkScheme.surface, isNot(const Color(0xFF000000)));
      expect(
        darkScheme.surface.computeLuminance(),
        lessThan(darkScheme.surfaceContainerLow.computeLuminance()),
      );
    });

    testWidgets('applies dynamic accent color when CorePalette is null',
        (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(DynamicColorPlugin.channel, (call) async {
        if (call.method == DynamicColorPlugin.accentColorMethodName) {
          return const Color(0xFF6750A4).toARGB32();
        }
        return null;
      });
      final harness = LedgerServiceHarness();
      addTearDown(harness.close);

      await pumpAppWithOverrides(tester, harness,
          initialThemeMode: ThemeMode.light);
      final scheme =
          Theme.of(tester.element(find.byType(NavigationBar))).colorScheme;
      expect(scheme.surface, isNot(const Color(0xFFF7FAF7)));
    });
  });

  for (final width in [360.0, 800.0]) {
    testWidgets(
        'routing across Ledger, Budget and More preserves surface roles and theme switching at ${width.toInt()}dp',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final harness = LedgerServiceHarness();
      addTearDown(harness.close);
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(harness.db),
        themeModeControllerProvider
            .overrideWith(() => _TestThemeModeController(ThemeMode.light)),
        localeControllerProvider.overrideWith(_EnglishLocaleController.new),
        balanceVisibilityControllerProvider.overrideWith(_Visible.new),
        accountUiListProvider.overrideWith((ref) => const AsyncData([])),
        categoryListProvider.overrideWith((ref, type) => Stream.value([])),
        ledgerMonthlyTransactionsProvider
            .overrideWith((ref, month) => Stream.value([])),
        ledgerMonthlySummaryProvider.overrideWith((ref, month) => Stream.value(
            const MonthlySummaryUiModel(
                displayBalance: r'$100.00',
                displayIncome: r'$150.00',
                displayExpense: r'$50.00'))),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const FeatherLedgerApp(),
        ),
      );
      await tester.pumpAndSettle();

      void verifySurfaceRoles(ThemeMode expectedMode) {
        final brightness = expectedMode == ThemeMode.dark
            ? Brightness.dark
            : Brightness.light;
        final navBar =
            tester.widget<NavigationBar>(find.byType(NavigationBar));
        final context = tester.element(find.byType(NavigationBar));
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        expect(theme.brightness, brightness);
        expect(theme.scaffoldBackgroundColor, scheme.surface);
        expect(
          navBar.backgroundColor ?? theme.navigationBarTheme.backgroundColor,
          scheme.surfaceContainer,
        );
        expect(
          theme.navigationBarTheme.indicatorColor,
          scheme.secondaryContainer,
        );
      }

      verifySurfaceRoles(ThemeMode.light);

      // Navigate across Ledger -> Budget -> More
      await tester.tap(find.text('Budget'));
      await tester.pumpAndSettle();
      expect(find.byType(BudgetScreen), findsOneWidget);
      verifySurfaceRoles(ThemeMode.light);

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(find.byType(MoreScreen), findsOneWidget);
      verifySurfaceRoles(ThemeMode.light);

      // Switch to dark mode while navigating back to Ledger
      await container
          .read(themeModeControllerProvider.notifier)
          .setTheme(ThemeMode.dark);
      await tester.pumpAndSettle();
      verifySurfaceRoles(ThemeMode.dark);

      final router = container.read(goRouterProvider);
      router.go('/ledger');
      await tester.pumpAndSettle();
      verifySurfaceRoles(ThemeMode.dark);
      expect(tester.takeException(), isNull);
    });
  }
}

class _Visible extends BalanceVisibilityController {
  @override
  Future<bool> build() async => true;
}

class _TestThemeModeController extends ThemeModeController {
  _TestThemeModeController(this._initial);

  final ThemeMode _initial;

  @override
  Future<ThemeMode> build() async => _initial;

  @override
  Future<void> setTheme(ThemeMode mode) async {
    state = AsyncData(mode);
  }
}

class _EnglishLocaleController extends LocaleController {
  @override
  Future<Locale?> build() async => const Locale('en');
}
