import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/shared/presentation/money_format.dart';

enum ReportHeatmapDirection { negative, zero, positive }

enum ReportHeatmapScale { netFlow, frequency }

@immutable
class ReportHeatmapDay {
  const ReportHeatmapDay({
    required this.date,
    required this.dayLabel,
    required this.tooltip,
    required this.direction,
    required this.level,
  });

  final DateTime date;
  final String dayLabel;
  final String tooltip;
  final ReportHeatmapDirection direction;

  /// Zero is neutral; 1–5 are interpreted using the model's scale.
  final int level;
}

@immutable
class ReportHeatmapMonthLabel {
  const ReportHeatmapMonthLabel(this.column, this.label);

  final int column;
  final String label;
}

@immutable
class ReportHeatmapUiModel {
  ReportHeatmapUiModel({
    required List<List<ReportHeatmapDay?>> weeks,
    required List<String> weekdays,
    required List<ReportHeatmapMonthLabel> months,
    this.scale = ReportHeatmapScale.netFlow,
    List<String> frequencyLegendLabels = const [],
  })  : assert(weeks.isNotEmpty),
        assert(weeks.every((week) => week.length == 7)),
        assert(weekdays.length == 7),
        weeks = List.unmodifiable(
            weeks.map((week) => List<ReportHeatmapDay?>.unmodifiable(week))),
        weekdays = List.unmodifiable(weekdays),
        months = List.unmodifiable(months),
        frequencyLegendLabels = List.unmodifiable(frequencyLegendLabels);

  /// Seven rows per column; null is padding outside the three-month range.
  final List<List<ReportHeatmapDay?>> weeks;
  final List<String> weekdays;
  final List<ReportHeatmapMonthLabel> months;
  final ReportHeatmapScale scale;
  final List<String> frequencyLegendLabels;
}

/// Builds display-only calendar cells from daily net flows or transaction counts.
/// No widget needs to interpret signs, calculate money, or format an amount.
class ReportHeatmapMapper {
  const ReportHeatmapMapper();

  // Fixed count bands keep a day the same shade across months, even if a
  // different day becomes unusually busy. Labels and thresholds stay together.
  static const _frequencyBands = [
    (minimum: 0, label: '0'),
    (minimum: 1, label: '1'),
    (minimum: 2, label: '2'),
    (minimum: 3, label: '3–4'),
    (minimum: 5, label: '5–9'),
    (minimum: 10, label: '10+'),
  ];

  ReportHeatmapUiModel map({
    required DateTime selectedMonth,
    required Map<DateTime, int> dailyNetMinor,
    required String locale,
    required String currencySymbol,
    required String Function(String amount) netFlowLabel,
    required String zeroNetFlowLabel,
  }) =>
      _map(
        selectedMonth: selectedMonth,
        dailyValues: dailyNetMinor,
        locale: locale,
        scale: ReportHeatmapScale.netFlow,
        detailLabel: (value) => value == 0
            ? zeroNetFlowLabel
            : netFlowLabel(formatMinorWithSymbol(value, currencySymbol)),
      );

  ReportHeatmapUiModel mapFrequency({
    required DateTime selectedMonth,
    required Map<DateTime, int> dailyCounts,
    required String locale,
  }) {
    assert(dailyCounts.values.every((count) => count >= 0));
    return _map(
      selectedMonth: selectedMonth,
      dailyValues: dailyCounts,
      locale: locale,
      scale: ReportHeatmapScale.frequency,
    );
  }

  ReportHeatmapUiModel _map({
    required DateTime selectedMonth,
    required Map<DateTime, int> dailyValues,
    required String locale,
    required ReportHeatmapScale scale,
    String Function(int value)? detailLabel,
  }) {
    final start = DateTime(selectedMonth.year, selectedMonth.month - 2, 1);
    final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final normalized = <DateTime, int>{};
    for (final entry in dailyValues.entries) {
      final date = DateTime(entry.key.year, entry.key.month, entry.key.day);
      if (date.isBefore(start) || date.isAfter(end)) continue;
      normalized[date] = (normalized[date] ?? 0) + entry.value;
    }
    final maximum = normalized.values.fold<int>(
      0,
      (maximum, value) => value.abs() > maximum ? value.abs() : maximum,
    );
    final leading = start.weekday - DateTime.monday;
    var cursor = DateTime(start.year, start.month, start.day - leading);
    final weeks = <List<ReportHeatmapDay?>>[];
    final months = <ReportHeatmapMonthLabel>[];
    final dateFormat = DateFormat.yMMMMEEEEd(locale);
    final monthFormat = DateFormat.MMM(locale);
    final previousYearMonthFormat = DateFormat.yMMM(locale);

    while (!cursor.isAfter(end)) {
      final week = <ReportHeatmapDay?>[];
      for (var row = 0; row < 7; row++) {
        final date = cursor;
        if (date.isBefore(start) || date.isAfter(end)) {
          week.add(null);
        } else {
          if (date == start || date.day == 1) {
            months.add(ReportHeatmapMonthLabel(
              weeks.length,
              date.year == selectedMonth.year
                  ? monthFormat.format(date)
                  : previousYearMonthFormat.format(date),
            ));
          }
          final value = normalized[date] ?? 0;
          final dateLabel = dateFormat.format(date);
          week.add(ReportHeatmapDay(
            date: date,
            dayLabel: date.day.toString(),
            tooltip: detailLabel == null
                ? dateLabel
                : '$dateLabel\n${detailLabel(value)}',
            direction: value < 0
                ? ReportHeatmapDirection.negative
                : value > 0
                    ? ReportHeatmapDirection.positive
                    : ReportHeatmapDirection.zero,
            level: scale == ReportHeatmapScale.frequency
                ? _frequencyBands
                    .lastIndexWhere((band) => value >= band.minimum)
                : value == 0
                    ? 0
                    : (value.abs() * 5 + maximum - 1) ~/ maximum,
          ));
        }
        // Calendar arithmetic, rather than 24-hour durations, keeps local
        // dates intact across daylight-saving transitions.
        cursor = DateTime(date.year, date.month, date.day + 1);
      }
      weeks.add(week);
    }

    final weekdayFormat = DateFormat.E(locale);
    return ReportHeatmapUiModel(
      weeks: weeks,
      months: months,
      scale: scale,
      frequencyLegendLabels: scale == ReportHeatmapScale.frequency
          ? _frequencyBands.map((band) => band.label).toList()
          : const [],
      weekdays: [
        for (var row = 0; row < 7; row++)
          weekdayFormat.format(DateTime(2024, 1, 8 + row)),
      ],
    );
  }
}
