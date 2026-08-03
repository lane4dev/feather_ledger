import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:feather_ledger/features/reports/presentation/models/report_heatmap_ui_model.dart';

void main() {
  setUpAll(() => initializeDateFormatting());

  ReportHeatmapUiModel map({
    DateTime? month,
    Map<DateTime, int> values = const {},
    String locale = 'en',
  }) =>
      const ReportHeatmapMapper().map(
        selectedMonth: month ?? DateTime(2026, 11),
        dailyNetMinor: values,
        locale: locale,
        currencySymbol: r'$',
        netFlowLabel: (amount) => 'Net flow: $amount',
        zeroNetFlowLabel: 'Zero net flow',
      );

  List<ReportHeatmapDay> days(ReportHeatmapUiModel model) =>
      model.weeks.expand((week) => week).whereType<ReportHeatmapDay>().toList();

  for (final locale in ['en', 'zh_Hans', 'zh_Hant']) {
    test('three complete months always start on Monday ($locale)', () {
      final model = map(locale: locale);
      final cells = days(model);
      expect(cells, hasLength(91));
      expect(cells.first.date, DateTime(2026, 9, 1));
      expect(cells.last.date, DateTime(2026, 11, 30));
      expect(model.months.map((label) => label.label),
          everyElement(isNot(contains('2026'))));
      expect(cells.map((cell) => cell.dayLabel),
          everyElement(matches(RegExp(r'^\d{1,2}$'))));
      expect(cells.map((cell) => cell.dayLabel),
          cells.map((cell) => cell.date.day.toString()));
      for (final week in model.weeks) {
        expect(week, hasLength(7));
        for (var row = 0; row < 7; row++) {
          if (week[row] case final day?) {
            expect(day.date.weekday, row + DateTime.monday);
          }
        }
      }
      final leading = DateTime(2026, 9, 1).weekday - DateTime.monday;
      expect(model.weeks.first.take(leading), everyElement(isNull));
    });
  }

  test('cross-year range and leap day are included exactly once', () {
    final january = map(month: DateTime(2027, 1));
    expect(january.months.map((month) => month.label),
        ['Nov 2026', 'Dec 2026', 'Jan']);
    final february = map(month: DateTime(2027, 2));
    expect(february.months.map((month) => month.label),
        ['Dec 2026', 'Jan', 'Feb']);
    final crossYear = days(january);
    expect(crossYear, hasLength(92));
    expect(crossYear.first.date, DateTime(2026, 11, 1));
    expect(crossYear.last.date, DateTime(2027, 1, 31));
    final leapYear = days(map(month: DateTime(2024, 2)));
    expect(leapYear, hasLength(91));
    expect(leapYear.last.date, DateTime(2024, 2, 29));
  });

  test('calendar iteration stays at midnight through daylight-saving dates',
      () {
    final cells = days(map(month: DateTime(2024, 4)));
    expect(cells, hasLength(90));
    expect(cells.map((day) => day.date).toSet(), hasLength(90));
    for (var index = 1; index < cells.length; index++) {
      final previous = cells[index - 1].date;
      expect(cells[index].date,
          DateTime(previous.year, previous.month, previous.day + 1));
      expect(cells[index].date.hour, 0);
    }
  });

  test('signed minor units share a five-level magnitude scale', () {
    final model = map(values: {
      DateTime(2026, 11, 1): -2500,
      DateTime(2026, 11, 2): 10000,
      DateTime(2026, 11, 3): 0,
      DateTime(2026, 11, 4): 1,
      DateTime(2025, 1, 1): 999999999,
    });
    ReportHeatmapDay cell(int day) =>
        days(model).singleWhere((cell) => cell.date == DateTime(2026, 11, day));
    expect(cell(1).direction, ReportHeatmapDirection.negative);
    expect(cell(1).level, 2);
    expect(cell(1).tooltip, contains(r'Net flow: - $25.00'));
    expect(cell(2).direction, ReportHeatmapDirection.positive);
    expect(cell(2).level, 5);
    expect(cell(4).level, 1);
    for (final day in [3, 5]) {
      expect(cell(day).direction, ReportHeatmapDirection.zero);
      expect(cell(day).level, 0);
      expect(cell(day).tooltip, contains('Zero net flow'));
    }
  });

  test('timestamps normalize to calendar dates before scaling and formatting',
      () {
    final cells = days(map(values: {
      DateTime(2026, 11, 2, 9): 1000,
      DateTime(2026, 11, 2, 18): -1000,
    }));
    final cell = cells.singleWhere((day) => day.date == DateTime(2026, 11, 2));
    expect(cell.level, 0);
    expect(cell.tooltip, contains('Zero net flow'));
  });

  test('frequency uses fixed count bands and date-only tooltips', () {
    final model = const ReportHeatmapMapper().mapFrequency(
      selectedMonth: DateTime(2026, 11),
      dailyCounts: {
        for (final entry in [0, 1, 2, 3, 4, 5, 9, 10, 1000].indexed)
          DateTime(2026, 11, entry.$1 + 1): entry.$2,
      },
      locale: 'en',
    );
    final cells = days(model).where((day) => day.date.month == 11).toList();
    expect(model.scale, ReportHeatmapScale.frequency);
    expect(model.frequencyLegendLabels, ['0', '1', '2', '3–4', '5–9', '10+']);
    expect(cells.take(9).map((day) => day.level), [0, 1, 2, 3, 3, 4, 4, 5, 5]);
    expect(cells[9].level, 0);
    for (final cell in cells) {
      expect(cell.tooltip, isNot(contains('\n')));
      expect(cell.tooltip, isNot(contains(r'$')));
      expect(cell.tooltip, isNot(contains('Net flow')));
    }
  });

  test('empty data produces neutral cells; Chinese labels are localized', () {
    final model = map(locale: 'zh_Hant');
    expect(days(model).map((day) => day.level), everyElement(0));
    expect(model.months.first.label, contains('9'));
    expect(model.weekdays.first, contains('一'));
    expect(() => model.weeks.clear(), throwsUnsupportedError);
    expect(() => model.weeks.first.clear(), throwsUnsupportedError);
  });
}
