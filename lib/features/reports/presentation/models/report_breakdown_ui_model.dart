import 'package:feather_ledger/shared/presentation/money_format.dart';

import '../../domain/entities/reports_entities.dart';

/// One slice of a breakdown chart, ready to draw.
///
/// Carries both numbers a chart needs and the text beside it, because the two
/// are the same amount in two forms and computing them apart is how a legend
/// ends up disagreeing with its slice. [chartValue] is a double because
/// fl_chart works in geometry, not money.
class ReportBreakdownItem {
  final String label;

  /// The category's own colour, or the tonal shade used when another slice is
  /// being highlighted.
  final int colorInt;

  final double chartValue;
  final String displayTotal;

  /// The slice's share of the whole, as it is printed on the pie ("42%").
  final String displayShare;

  const ReportBreakdownItem({
    required this.label,
    required this.colorInt,
    required this.chartValue,
    required this.displayTotal,
    required this.displayShare,
  });
}

/// Turns a report's category totals into drawable slices (spec 003, US9).
///
/// The sorting, the top-five cut, the "others" bucket and every amount's
/// written form happen here rather than in the chart widget. All four are
/// money: the bucket is a sum, and a widget that sums has to know what an
/// amount is. This is also the only side that knows the currency.
class ReportBreakdownMapper {
  const ReportBreakdownMapper();

  static const int _topN = 5;

  /// [othersLabel] names the bucket the tail is folded into. It is passed in
  /// rather than resolved here so this stays a pure function of its inputs.
  List<ReportBreakdownItem> toItems(
    List<ReportCategoryTotal> totals, {
    required String currencySymbol,
    required String othersLabel,
    required int othersColorInt,
  }) {
    final sorted = List<ReportCategoryTotal>.from(totals)
      ..sort((a, b) => b.totalMinor.compareTo(a.totalMinor));

    final folded = <({String label, int colorInt, int totalMinor})>[
      for (final item in sorted.length <= _topN ? sorted : sorted.take(_topN))
        (
          label: item.category.name,
          colorInt: item.category.colorInt,
          totalMinor: item.totalMinor,
        ),
    ];

    if (sorted.length > _topN) {
      final tail = sorted.skip(_topN);
      folded.add((
        label: othersLabel,
        colorInt: othersColorInt,
        totalMinor: tail.fold(0, (sum, item) => sum + item.totalMinor),
      ));
    }

    final whole = folded.fold(0, (sum, row) => sum + row.totalMinor);

    return [
      for (final row in folded)
        ReportBreakdownItem(
          label: row.label,
          colorInt: row.colorInt,
          chartValue: row.totalMinor.toDouble(),
          displayTotal: formatMinorWithSymbol(row.totalMinor, currencySymbol),
          displayShare: whole > 0
              ? '${(row.totalMinor / whole * 100).toStringAsFixed(0)}%'
              : '',
        ),
    ];
  }
}
