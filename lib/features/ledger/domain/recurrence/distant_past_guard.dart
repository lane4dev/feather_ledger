/// Pure local-calendar date calculations for the distant-past recurring start
/// date confirmation guard.
///
/// When creating a repeating series or changing its base schedule to a
/// `startDate` strictly earlier than 2 calendar months before today, the UI
/// prompts the user to choose between generating from today onward or
/// backfilling a bounded number of recent days as manual-review pending bills.
abstract final class DistantPastStartGuard {
  /// Calendar months before today that define the distant-past threshold.
  static const int thresholdMonths = 2;

  /// Default number of recent days offered for manual-review backfill.
  static const int defaultBackfillDays = 30;

  /// Minimum user-enterable backfill window in days.
  static const int minBackfillDays = 1;

  /// Maximum user-enterable backfill window in days.
  static const int maxBackfillDays = 365;

  /// Local civil midnight (`00:00:00`) for [value].
  static DateTime startOfDay(DateTime value) {
    final local = value.isUtc ? value.toLocal() : value;
    return DateTime(local.year, local.month, local.day);
  }

  /// Local civil midnight [months] calendar months before [now], clamping the
  /// day-of-month to the target month's last day (e.g. Apr 30 - 2 months ->
  /// Feb 28/29; Aug 31 - 2 months -> Jun 30).
  static DateTime subtractCalendarMonths(DateTime now, int months) {
    final local = now.isUtc ? now.toLocal() : now;
    final totalMonths = local.year * 12 + (local.month - 1) - months;
    final targetYear = totalMonths ~/ 12;
    final targetMonth = (totalMonths % 12) + 1;
    final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
    final day = local.day <= lastDay ? local.day : lastDay;
    return DateTime(targetYear, targetMonth, day);
  }

  /// Returns `true` when [startDate]'s local civil date is strictly earlier
  /// than [thresholdMonths] (2) calendar months before [now]'s local civil date.
  static bool isDistantPast(DateTime startDate, {required DateTime now}) {
    final localStart = startDate.isUtc ? startDate.toLocal() : startDate;
    final cutoff = subtractCalendarMonths(now, thresholdMonths);
    return startOfDay(localStart).isBefore(cutoff);
  }

  /// Resolves `materializeFrom` for Option 1 ("Generate from today onward"):
  /// local civil midnight of today (`startOfDay(now)`).
  static DateTime fromTodayMaterializeFrom({required DateTime now}) =>
      startOfDay(now);

  /// Resolves `materializeFrom` for Option 2 ("Backfill last [days] days"):
  /// `max(startDate, startOfDay(now - days))` using local civil day arithmetic.
  static DateTime backfillDaysMaterializeFrom({
    required DateTime startDate,
    required DateTime now,
    required int days,
  }) {
    final localNow = now.isUtc ? now.toLocal() : now;
    final localStart = startDate.isUtc ? startDate.toLocal() : startDate;
    final candidate =
        DateTime(localNow.year, localNow.month, localNow.day - days);
    return candidate.isAfter(localStart) ? candidate : localStart;
  }

  /// Parses and validates a backfill-day integer in `[minBackfillDays, maxBackfillDays]`.
  static int? parseBackfillDays(String raw) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null ||
        parsed < minBackfillDays ||
        parsed > maxBackfillDays) {
      return null;
    }
    return parsed;
  }

  /// Returns `true` when any schedule-anchoring field of a repeating series
  /// changed (`date`, `frequency`, `interval`, or `WEEKLY` `weekdays`).
  static bool hasBaseScheduleChanged({
    required DateTime currentDate,
    required DateTime nextDate,
    required String currentFrequency,
    required String nextFrequency,
    required int? currentInterval,
    required int nextInterval,
    required List<int> currentWeekdays,
    required List<int> nextWeekdays,
  }) {
    final normalizedCurrentFreq = currentFrequency.toUpperCase();
    final normalizedNextFreq = nextFrequency.toUpperCase();
    if (!nextDate.isAtSameMomentAs(currentDate) ||
        normalizedNextFreq != normalizedCurrentFreq ||
        nextInterval != (currentInterval ?? 1)) {
      return true;
    }
    if (normalizedNextFreq == 'WEEKLY') {
      return !sameWeekdays(nextWeekdays, currentWeekdays);
    }
    return false;
  }

  /// Compares two ISO weekday lists as sets (order- and duplicate-insensitive).
  static bool sameWeekdays(List<int> a, List<int> b) {
    final sa = a.toSet();
    final sb = b.toSet();
    return sa.length == sb.length && sa.containsAll(sb);
  }
}
