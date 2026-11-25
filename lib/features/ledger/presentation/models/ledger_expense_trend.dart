import 'dart:math' as math;

import 'package:feather_ledger/core/domain/enums.dart';

import 'ledger_day_group.dart';

/// The month's daily spending, oldest first, for the overview card's
/// sparkline.
///
/// The days come from the ledger list the screen already loaded — this is a
/// second reading of the same rows, not a second query. Each point is a day's
/// **expense** total in minor units, zero-filled across gaps: the shape worth
/// seeing is "which days the money left on", and a day with no rows is a day
/// with no spending, not a missing day.
///
/// Transfers are excluded, as they are everywhere money is totalled — moving
/// your own money between accounts is not spending.
class LedgerExpenseTrend {
  /// How many days back the curve reaches. A sparkline is a gesture, not a
  /// chart: two weeks of points is as much as 96dp can say.
  static const int defaultMaxPoints = 14;

  /// Daily expense totals in minor units, oldest first.
  final List<double> points;

  const LedgerExpenseTrend._(this.points);

  const LedgerExpenseTrend.empty() : points = const <double>[];

  /// Whether there is a shape to draw. One point is not a trend, and a flat
  /// run of zeros is a straight line the painter would otherwise report as a
  /// perfect (and meaningless) rise from zero.
  bool get isDrawable => points.length >= 2 && points.any((p) => p > 0);

  /// The highest daily total, used to normalize the curve.
  double get peak => points.isEmpty ? 0 : points.reduce(math.max);

  /// Builds the trend from a month's already-grouped rows.
  ///
  /// [days] is newest-first, the order the ledger list is built in.
  factory LedgerExpenseTrend.fromDays(
    List<LedgerDayGroup> days, {
    int maxPoints = defaultMaxPoints,
  }) {
    if (days.isEmpty) return const LedgerExpenseTrend.empty();

    final spendByDay = <int, int>{};
    for (final day in days) {
      var total = 0;
      for (final tx in day.transactions) {
        // Pending bills have not happened, and a row on an account outside the
        // ledger totals is not part of the month's spending either.
        if (tx.isPending || !tx.account.includeInTotals) continue;
        if (tx.type != TransactionKind.expense) continue;
        total += tx.amount;
      }
      spendByDay[day.date.day] = (spendByDay[day.date.day] ?? 0) + total;
    }

    final newestDay = days.first.date.day;
    final oldestDay = days.last.date.day;
    // A month whose rows all sit in one day still has a day of history behind
    // it, so the window is anchored on the newest row rather than on "today":
    // the card must not change shape because the clock moved.
    final firstDay = math.max(oldestDay, newestDay - maxPoints + 1);
    final points = <double>[
      for (var day = firstDay; day <= newestDay; day++)
        (spendByDay[day] ?? 0).toDouble(),
    ];
    return LedgerExpenseTrend._(List<double>.unmodifiable(points));
  }
}
