import 'package:intl/intl.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';

/// The value the transaction form's date row shows: "今天 14:30",
/// "9月18日 14:30", "2025年9月18日 14:30".
///
/// [today] is passed in rather than read here — the rule is then a function of
/// its two dates, which is what makes "yesterday" testable at all.
///
/// Three deliberate absences:
/// - **the weekday.** This row answers "when", and the day of the week is the
///   part of that answer nobody reads;
/// - **the year, within the current one.** Almost every entry is made in the
///   year it happens; the year is worth its width only when it differs;
/// - **the 12-hour clock.** `Hm` is the 24-hour skeleton — `jm` would render
///   "3:04 PM" in English.
String transactionDateLabel({
  required DateTime date,
  required DateTime today,
  required String locale,
  required AppLocalizations l10n,
  bool includeTime = true,
}) {
  final relative = _relativeDay(date, today, l10n);
  final day = relative ??
      (date.year == today.year
          ? DateFormat.MMMd(locale).format(date)
          : DateFormat.yMMMd(locale).format(date));
  return includeTime ? '$day ${DateFormat.Hm(locale).format(date)}' : day;
}

/// The same calendar day, or the one either side of it — compared as year,
/// month and day rather than by subtracting, because a day is not always 24
/// hours long (the day a clock shifts is 23 or 25) and the difference in whole
/// days would then be off by one.
String? _relativeDay(DateTime date, DateTime today, AppLocalizations l10n) {
  if (_isSameDay(date, today)) return l10n.today;
  if (_isSameDay(date, DateTime(today.year, today.month, today.day - 1))) {
    return l10n.yesterday;
  }
  if (_isSameDay(date, DateTime(today.year, today.month, today.day + 1))) {
    return l10n.tomorrow;
  }
  return null;
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
