import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/features/reports/presentation/models/report_heatmap_ui_model.dart';
import 'package:feather_ledger/features/reports/presentation/providers/reports_providers.dart';
import 'package:feather_ledger/features/reports/presentation/theme/report_theme.dart';
import 'package:feather_ledger/features/reports/presentation/widgets/report_heatmap.dart';
import 'package:feather_ledger/features/reports/presentation/widgets/report_heatmap_view.dart';

void main() {
  final values = {
    DateTime(2026, 11, 28): -2500,
    DateTime(2026, 11, 29): 10000,
  };

  Widget wrap(
    Widget Function(BuildContext context) builder, {
    Locale locale = const Locale('en'),
    bool dark = false,
    double textScale = 1,
    Stream<Map<DateTime, int>> Function(Ref ref)? heatmapSource,
  }) =>
      ProviderScope(
        retry: (_, __) => null,
        overrides: [
          currencyControllerProvider.overrideWith(_FixedCurrency.new),
          selectedDateProvider.overrideWith(_FixedReportMonth.new),
          if (heatmapSource != null)
            heatmapDataProvider.overrideWith(heatmapSource),
        ],
        child: MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: Scaffold(
            body: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(textScale)),
                child: Builder(builder: builder),
              ),
            ),
          ),
        ),
      );

  Widget chart(BuildContext context,
      {DateTime? month, ValueChanged<DateTime>? onTap}) {
    final l10n = AppLocalizations.of(context)!;
    return ReportHeatmap(
      model: const ReportHeatmapMapper().map(
        selectedMonth: month ?? DateTime(2026, 11),
        dailyNetMinor: values,
        locale: Localizations.localeOf(context).toString(),
        currencySymbol: r'$',
        netFlowLabel: l10n.heatmapNetFlow,
        zeroNetFlowLabel: l10n.heatmapZeroNetFlow,
      ),
      onDayTap: onTap,
    );
  }

  Finder cell(int day) => find.byKey(ValueKey(DateTime(2026, 11, day)));

  for (final dark in [false, true]) {
    testWidgets('signed cells, neutral cells, and tooltips (dark=$dark)',
        (tester) async {
      await tester.pumpWidget(wrap(chart, dark: dark));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(ReportHeatmap));
      expect(
          tester.widget<Material>(cell(28)).color,
          ReportTheme.heatmapColor(
              context, ReportHeatmapDirection.negative, 2));
      expect(
          tester.widget<Material>(cell(29)).color,
          ReportTheme.heatmapColor(
              context, ReportHeatmapDirection.positive, 5));
      expect(tester.widget<Material>(cell(30)).color,
          Theme.of(context).colorScheme.surfaceContainerHighest);
      final semantics = tester.ensureSemantics();
      expect(
          tester
              .getSemantics(find
                  .ancestor(
                    of: cell(29),
                    matching: find.byType(Semantics),
                  )
                  .first)
              .label,
          contains(r'Net flow: $100.00'));
      semantics.dispose();
      await tester.longPress(cell(29));
      await tester.pumpAndSettle();
      expect(find.textContaining(r'Net flow: $100.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'narrow screen scrolls horizontally while weekday labels stay put',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap(chart, textScale: 1.5));
    await tester.pumpAndSettle();
    final weekdayPosition = tester.getTopLeft(find.text('Mon'));
    final before = tester.getTopLeft(cell(29));
    await tester.drag(find.byKey(const ValueKey('report-heatmap-scroll')),
        const Offset(220, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(cell(29)).dx, greaterThan(before.dx));
    expect(tester.getTopLeft(find.text('Mon')), weekdayPosition);
    expect(tester.takeException(), isNull);
  });

  testWidgets('day callbacks and switching months use the new visible dates',
      (tester) async {
    DateTime? tapped;
    await tester.pumpWidget(wrap(
      (context) => chart(context, onTap: (date) => tapped = date),
    ));
    await tester.pumpAndSettle();
    await tester.tap(cell(29));
    expect(tapped, DateTime(2026, 11, 29));

    await tester.pumpWidget(wrap(
      (context) => chart(context, month: DateTime(2027, 1)),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey(DateTime(2027, 1, 31))), findsOneWidget);
    expect(find.byKey(ValueKey(DateTime(2026, 9, 1))), findsNothing);
    expect(find.text('Jan'), findsOneWidget);
    expect(find.text('Dec 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final locale in [
    const Locale('en'),
    const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ]) {
    testWidgets('labels are localized for $locale', (tester) async {
      await tester.pumpWidget(wrap(chart, locale: locale));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(ReportHeatmap));
      final l10n = AppLocalizations.of(context)!;
      expect(find.text(l10n.heatmapNetOutflow), findsOneWidget);
      final dateCell = cell(29);
      expect(find.descendant(of: dateCell, matching: find.text('29')),
          findsOneWidget);
      final cellSize = tester.getSize(dateCell);
      final labelSize = tester
          .getSize(find.descendant(of: dateCell, matching: find.text('29')));
      expect(
          cellSize.width,
          lessThan(Theme.of(context).textTheme.labelSmall!.fontSize! +
              AppTheme.spacing.lg));
      expect(labelSize.width, lessThanOrEqualTo(cellSize.width));
      expect(labelSize.height, lessThanOrEqualTo(cellSize.height));
      final legend = find.byKey(const ValueKey('report-heatmap-legend'));
      final chartRect = tester.getRect(find.byType(ReportHeatmap));
      final legendRect = tester.getRect(legend);
      expect(legendRect.right, closeTo(chartRect.right, 0.01));
      expect(legendRect.bottom, closeTo(chartRect.bottom, 0.01));
      expect(find.textContaining('Darker cells'), findsNothing);
      expect(find.textContaining('颜色越深'), findsNothing);
      expect(find.textContaining('顏色越深'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('report wrapper keeps loading, error and mode selection',
      (tester) async {
    final source = StreamController<Map<DateTime, int>>.broadcast();
    addTearDown(source.close);
    await tester.pumpWidget(wrap(
      (_) => const ReportHeatmapView(),
      heatmapSource: (_) => source.stream,
    ));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    source.addError(Exception('failed'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();
    expect(find.textContaining('failed'), findsOneWidget);
    source.add({DateTime(2026, 11, 29): 3});
    await tester.pumpAndSettle();
    expect(find.byType(ReportHeatmap), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<HeatmapMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Amount').last);
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ReportHeatmapView)),
    );
    expect(container.read(heatmapModeStateProvider), HeatmapMode.amount);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets(
        'frequency has a count legend and primary-color scale (dark=$dark)',
        (tester) async {
      await tester.pumpWidget(wrap(
        (_) => const ReportHeatmapView(),
        heatmapSource: (_) => Stream.value({
          DateTime(2026, 11, 28): 3,
          DateTime(2026, 11, 29): 10,
        }),
        dark: dark,
      ));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(ReportHeatmap));
      expect(tester.widget<Material>(cell(29)).color,
          Theme.of(context).colorScheme.primary);
      expect(
          tester.widget<Material>(cell(28)).color,
          ReportTheme.heatmapColor(context, ReportHeatmapDirection.positive, 3,
              scale: ReportHeatmapScale.frequency));
      expect(tester.widget<Material>(cell(30)).color,
          Theme.of(context).colorScheme.surfaceContainerHighest);
      final legend = find.byKey(const ValueKey('report-heatmap-legend'));
      for (final label in ['0', '10+']) {
        expect(find.descendant(of: legend, matching: find.text(label)),
            findsOneWidget);
      }
      for (final label in ['1', '2', '3–4', '5–9', 'Frequency']) {
        expect(find.descendant(of: legend, matching: find.text(label)),
            findsNothing);
      }
      expect(find.text('Net outflow'), findsNothing);
      expect(find.text('Net inflow'), findsNothing);
      final semantics = tester.ensureSemantics();
      final label = tester
          .getSemantics(find
              .ancestor(
                of: cell(29),
                matching: find.byType(Semantics),
              )
              .first)
          .label;
      expect(label, contains('2026'));
      expect(label, isNot(contains('Net flow')));
      expect(label, isNot(contains(r'$')));
      expect(label, isNot(contains('\n')));
      semantics.dispose();
      // Switching to amount mode replaces the frequency legend.
      await tester.tap(find.byType(DropdownButton<HeatmapMode>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Amount').last);
      await tester.pumpAndSettle();
      expect(find.text('Net outflow'), findsOneWidget);
      expect(find.text('Net inflow'), findsOneWidget);
      expect(find.text('10+'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}

class _FixedCurrency extends CurrencyController {
  @override
  Future<String> build() async => 'USD';
}

class _FixedReportMonth extends SelectedDate {
  @override
  DateTime build() => DateTime(2026, 11);
}
