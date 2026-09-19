import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/reports/data/repositories/reports_repository.dart';
import 'package:feather_ledger/features/reports/domain/entities/reports_entities.dart';
import 'package:feather_ledger/features/reports/presentation/screens/reports_screen.dart';
import 'package:feather_ledger/features/reports/presentation/providers/reports_providers.dart';
import 'package:feather_ledger/features/reports/presentation/widgets/report_heatmap.dart';
import 'package:feather_ledger/features/reports/presentation/widgets/report_heatmap_view.dart';
import 'package:feather_ledger/features/reports/presentation/theme/report_theme.dart';
import 'package:feather_ledger/features/reports/presentation/models/report_heatmap_ui_model.dart';

/// Widget test (spec 003, US9/T066): the reports screen renders the
/// snapshot-sourced monthly totals and the breakdown rows — presentation
/// only, no business computation.
class _FakeReportsRepository implements ReportsRepository {
  @override
  Stream<Map<DateTime, int>> watchHeatmapFrequencyData(DateTime month,
          {String currencyCode = 'USD'}) =>
      Stream.value({DateTime(month.year, month.month, 29): 3});

  @override
  Stream<Map<DateTime, int>> watchHeatmapAmountData(DateTime month,
          {String currencyCode = 'USD'}) =>
      Stream.value({DateTime(month.year, month.month, 29): -5000});

  @override
  Stream<List<ReportCategoryTotal>> watchCategoryBreakdown(
          DateTime month, CategoryType type,
          {String currencyCode = 'USD'}) =>
      Stream.value(const [
        ReportCategoryTotal(
          category: CategoryEntity(
            id: 'cat_food',
            name: 'Food',
            iconKey: 'restaurant',
            colorInt: 0xFFFF0000,
            type: CategoryType.expense,
          ),
          totalMinor: 5000,
        ),
      ]);

  @override
  Stream<ReportMonthlyTotals> watchMonthlyTotals(DateTime month,
          {String currencyCode = 'USD'}) =>
      Stream.value(const ReportMonthlyTotals(
        incomeMinor: 10000,
        expenseMinor: -5000,
        balanceMinor: 5000,
      ));
}

void main() {
  Widget app({ReportsRepository? repository, VoidCallback? onBuild}) =>
      ProviderScope(
        overrides: [
          reportsRepositoryProvider
              .overrideWithValue(repository ?? _FakeReportsRepository()),
          selectedDateProvider.overrideWith(_FixedReportMonth.new),
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
          home: onBuild == null
              ? const ReportsScreen()
              : _CountingReportsScreen(onBuild),
        ),
      );

  testWidgets('renders snapshot totals and the category breakdown',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportsRepositoryProvider.overrideWithValue(_FakeReportsRepository()),
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
          home: const ReportsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Monthly totals header: income, expense (absolute) and balance from
    // the snapshot projection.
    expect(find.text('\$100.00'), findsOneWidget);
    expect(find.text('\$50.00'), findsWidgets);
    // Breakdown list: category name from the write-time snapshot.
    expect(find.text('Food'), findsOneWidget);
  });

  testWidgets('page switches counts and net amounts with their own legends',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(ReportHeatmap));
    await tester.pumpAndSettle();
    final cell = find.byKey(ValueKey(DateTime(2026, 11, 29)));
    final context = tester.element(find.byType(ReportHeatmap));
    final frequencyColor = ReportTheme.heatmapColor(
      context,
      ReportHeatmapDirection.positive,
      3,
      scale: ReportHeatmapScale.frequency,
    );
    expect(tester.widget<Material>(cell).color, frequencyColor);
    expect(find.text('10+'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<HeatmapMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Amount').last);
    await tester.pumpAndSettle();
    expect(tester.widget<Material>(cell).color, context.colors.expense);
    expect(find.text('Net outflow'), findsOneWidget);
    expect(find.text('10+'), findsNothing);
    await tester.tap(find.byType(DropdownButton<HeatmapMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Frequency').last);
    await tester.pumpAndSettle();
    expect(tester.widget<Material>(cell).color, frequencyColor);
    expect(find.text('10+'), findsOneWidget);
    expect(find.text('Net outflow'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delayed mode switches preserve height, scroll and parent builds',
      (tester) async {
    tester.view.physicalSize = const Size(500, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _ControlledReportsRepository();
    addTearDown(repository.frequency.close);
    addTearDown(repository.amount.close);
    var pageBuilds = 0;
    await tester
        .pumpWidget(app(repository: repository, onBuild: () => pageBuilds++));
    await tester.pump();
    final body = find.byKey(const ValueKey('report-heatmap-body'));
    final initialHeight = tester.getSize(body).height;
    repository.frequency.add({DateTime(2026, 11, 29): 3});
    await tester.pumpAndSettle();
    expect(tester.getSize(body).height, initialHeight);
    await tester.ensureVisible(find.byType(ReportHeatmapView));
    await tester.pumpAndSettle();
    final horizontal = find.byKey(const ValueKey('report-heatmap-scroll'));
    await tester.drag(horizontal, const Offset(100, 0));
    await tester.pumpAndSettle();
    final horizontalPosition = tester
        .state<ScrollableState>(
          find
              .descendant(of: horizontal, matching: find.byType(Scrollable))
              .first,
        )
        .position;
    final horizontalOffset = horizontalPosition.pixels;
    expect(horizontalOffset, greaterThan(0));
    final verticalPosition = Scrollable.of(
      tester.element(find.byType(ReportHeatmapView)),
    ).position;
    final heading = tester.widget(find.text('Activity Heatmap'));
    final totals = tester.widget(find.text(r'$100.00'));
    final buildsBefore = pageBuilds;

    Future<void> switchMode(String label) async {
      await tester.tap(find.byType(DropdownButton<HeatmapMode>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
    }

    for (final mode in [HeatmapMode.amount, HeatmapMode.frequency]) {
      final heightBefore = tester.getSize(body).height;
      final offsetBefore = verticalPosition.pixels;
      await switchMode(mode == HeatmapMode.amount ? 'Amount' : 'Frequency');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.getSize(body).height, heightBefore);
      expect(verticalPosition.pixels, offsetBefore);
      expect(horizontalPosition.pixels, horizontalOffset);
      expect(pageBuilds, buildsBefore);
      expect(identical(tester.widget(find.text('Activity Heatmap')), heading),
          isTrue);
      expect(identical(tester.widget(find.text(r'$100.00')), totals), isTrue);
      if (mode == HeatmapMode.amount) {
        repository.amount.add({DateTime(2026, 11, 29): -5000});
      } else {
        repository.frequency.add({DateTime(2026, 11, 29): 3});
      }
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(pageBuilds, buildsBefore);
      expect(horizontalPosition.pixels, horizontalOffset);
      expect(tester.takeException(), isNull);
    }
  });
}

class _FixedReportMonth extends SelectedDate {
  @override
  DateTime build() => DateTime(2026, 11);
}

class _CountingReportsScreen extends ReportsScreen {
  const _CountingReportsScreen(this.onBuild);

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onBuild();
    return super.build(context, ref);
  }
}

class _ControlledReportsRepository extends _FakeReportsRepository {
  final frequency = StreamController<Map<DateTime, int>>.broadcast();
  final amount = StreamController<Map<DateTime, int>>.broadcast();

  @override
  Stream<Map<DateTime, int>> watchHeatmapFrequencyData(DateTime month,
          {String currencyCode = 'USD'}) =>
      frequency.stream;

  @override
  Stream<Map<DateTime, int>> watchHeatmapAmountData(DateTime month,
          {String currencyCode = 'USD'}) =>
      amount.stream;
}
