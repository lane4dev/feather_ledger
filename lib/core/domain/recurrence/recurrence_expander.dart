import 'package:rrule/rrule.dart';

import 'package:feather_ledger/core/domain/enums.dart';

/// Occurrence key for a one-shot planned bill (`(series_id, occurrence_key)`).
const kPlannedOccurrenceKey = 'single';

/// Semantic occurrence key (local civil `YYYY-MM-DD`) for one rule-generated
/// instance.
String scheduledOccurrenceKey(DateTime date) {
  final local = date.isUtc ? date.toLocal() : date;
  return RecurrenceExpander.formatCivilDateKey(
    local.year,
    local.month,
    local.day,
  );
}

/// Builds a wall-clock [DateTime] for one local civil date and time-of-day.
typedef LocalDateTimeBuilder = DateTime Function(
  int year,
  int month,
  int day,
  int hour,
  int minute,
  int second,
);

/// One calendar-anchored occurrence yielded by [RecurrenceExpander].
class RecurrenceOccurrence {
  /// Local civil date key (`YYYY-MM-DD`) for repeating series, or
  /// [kPlannedOccurrenceKey] (`'single'`) for one-shot planned series.
  final String occurrenceKey;

  /// Local wall-clock timestamp combining the occurrence's civil date with the
  /// series's original local time-of-day.
  final DateTime scheduledDate;

  const RecurrenceOccurrence({
    required this.occurrenceKey,
    required this.scheduledDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceOccurrence &&
          other.occurrenceKey == occurrenceKey &&
          other.scheduledDate.isAtSameMomentAs(scheduledDate);

  @override
  int get hashCode =>
      Object.hash(occurrenceKey, scheduledDate.millisecondsSinceEpoch);

  @override
  String toString() =>
      'RecurrenceOccurrence(key: $occurrenceKey, date: $scheduledDate)';
}

/// Pure, immutable recurrence rule specification.
///
/// Acts as the single source of truth for both canonical RRULE serialization
/// and local civil-date expansion across physical materialization and budget
/// virtual projection.
class RecurrenceRuleSpec {
  final RecurringSeriesMode mode;
  final String frequency;
  final int interval;
  final DateTime startDate;
  final DateTime? endDate;
  final int? countLimit;
  final int completedCountOffset;
  final List<int> weekdays;
  final DateTime? materializeFrom;

  const RecurrenceRuleSpec({
    required this.mode,
    required this.frequency,
    this.interval = 1,
    required this.startDate,
    this.endDate,
    this.countLimit,
    this.completedCountOffset = 0,
    this.weekdays = const [],
    this.materializeFrom,
  });

  /// Constructs a spec from stored discrete columns + optional `rrule` text
  /// (reading `BYDAY` through the single canonical parser).
  factory RecurrenceRuleSpec.fromStored({
    required RecurringSeriesMode mode,
    required String frequency,
    int? interval,
    required DateTime startDate,
    DateTime? endDate,
    int? countLimit,
    int completedCountOffset = 0,
    String? rrule,
    DateTime? materializeFrom,
  }) {
    final normalizedFreq = frequency.toUpperCase();
    return RecurrenceRuleSpec(
      mode: mode,
      frequency: normalizedFreq,
      interval: (interval == null || interval < 1) ? 1 : interval,
      startDate: startDate,
      endDate: endDate,
      countLimit: countLimit,
      completedCountOffset: completedCountOffset < 0 ? 0 : completedCountOffset,
      weekdays: normalizedFreq == 'WEEKLY'
          ? RecurrenceExpander.parseWeekdaysFromRrule(rrule)
          : const [],
      materializeFrom: materializeFrom,
    );
  }

  /// Lower bound below which unmaterialized occurrences are excluded from
  /// physical materialization and virtual budget projection.
  DateTime get effectiveMaterializeFrom => materializeFrom ?? startDate;

  /// Effective remaining count passed to RRULE after subtracting occurrences
  /// posted prior to a schedule reset (`completedCountOffset`).
  int? get remainingCountLimit =>
      countLimit == null ? null : countLimit! - completedCountOffset;

  /// Canonical RRULE string derived directly from these structured fields.
  String toRruleString() => RecurrenceExpander.formatRrule(
        frequency: frequency,
        interval: interval,
        endDate: endDate,
        countLimit: countLimit,
        weekdays: weekdays,
      );
}

/// Pure local-civil-date recurrence expander shared by physical materialization
/// and budget virtual projection.
///
/// All RRULE stepping runs in a timezone-free civil calendar
/// (`DateTime.utc(year, month, day)` used purely as a calendar tuple), then
/// reattaches the rule's local wall-clock `(hour, minute, second)` and emits
/// local `YYYY-MM-DD` [RecurrenceOccurrence.occurrenceKey] values. This avoids
/// UTC midnight drift, `BYDAY` weekday shifts, and DST hour drift.
class RecurrenceExpander {
  static const List<String> _weekdayCodes = [
    'MO',
    'TU',
    'WE',
    'TH',
    'FR',
    'SA',
    'SU',
  ];

  static final DateTime _maxCivilBound = DateTime.utc(9999, 12, 31);

  final LocalDateTimeBuilder _buildDateTime;

  const RecurrenceExpander({
    LocalDateTimeBuilder buildDateTime = _defaultLocalDateTime,
  }) : _buildDateTime = buildDateTime;

  static DateTime _defaultLocalDateTime(
    int year,
    int month,
    int day,
    int hour,
    int minute,
    int second,
  ) =>
      DateTime(year, month, day, hour, minute, second);

  static DateTime _asLocalWallTime(DateTime date) =>
      date.isUtc ? date.toLocal() : date;

  static DateTime _toCivilTuple(DateTime localWallTime) =>
      DateTime.utc(localWallTime.year, localWallTime.month, localWallTime.day);

  /// Formats a local civil `(year, month, day)` tuple as `YYYY-MM-DD`.
  static String formatCivilDateKey(int year, int month, int day) {
    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Last moment (`23:59:59.999`) of the local calendar month `(year, month)`.
  static DateTime endOfCalendarMonth(int year, int month) =>
      DateTime(year, month + 1, 0, 23, 59, 59, 999);

  /// Calendar-month-aligned physical materialization horizon end:
  /// `endOfMonth(nowYm + monthsAhead)`. With [monthsAhead] = 1, this covers
  /// the full current month plus the next full calendar month (2 months).
  static DateTime horizonEndForMonth(DateTime now, {int monthsAhead = 1}) {
    final local = _asLocalWallTime(now);
    return endOfCalendarMonth(local.year, local.month + monthsAhead);
  }

  /// First moment (`00:00:00`) of the earliest local calendar month covered by
  /// a [maxMonths]-month historical backfill window inclusive of `now`'s month
  /// (`startOfMonth(nowYm - (maxMonths - 1))`). With [maxMonths] = 12, this is
  /// `startOfMonth(nowYm - 11)` (12 full calendar months).
  static DateTime backfillFloorForMonth(DateTime now, {int maxMonths = 12}) {
    final local = _asLocalWallTime(now);
    return DateTime(local.year, local.month - (maxMonths - 1), 1);
  }

  /// Canonical RRULE serializer using local civil `UNTIL=YYYYMMDD` and sorted
  /// deduplicated `BYDAY` entries.
  static String formatRrule({
    required String frequency,
    required int interval,
    DateTime? endDate,
    int? countLimit,
    List<int> weekdays = const [],
  }) {
    final normalizedFreq = frequency.toUpperCase();
    final buffer = StringBuffer('FREQ=$normalizedFreq');
    if (interval > 1) buffer.write(';INTERVAL=$interval');
    if (countLimit != null) buffer.write(';COUNT=$countLimit');
    if (normalizedFreq == 'WEEKLY' && weekdays.isNotEmpty) {
      final normalizedDays = weekdays
          .where((d) => d >= 1 && d <= 7)
          .toSet()
          .toList()
        ..sort();
      if (normalizedDays.isNotEmpty) {
        buffer.write(
          ';BYDAY=${normalizedDays.map((day) => _weekdayCodes[day - 1]).join(',')}',
        );
      }
    }
    if (endDate != null && countLimit == null) {
      final localEnd = _asLocalWallTime(endDate);
      buffer.write(
        ';UNTIL=${localEnd.year.toString().padLeft(4, '0')}'
        '${localEnd.month.toString().padLeft(2, '0')}'
        '${localEnd.day.toString().padLeft(2, '0')}',
      );
    }
    return buffer.toString();
  }

  /// Single canonical parser for `BYDAY` entries in an RRULE string.
  static List<int> parseWeekdaysFromRrule(String? rrule) {
    final match =
        RegExp(r'(?:^|;)BYDAY=([^;]+)').firstMatch(rrule ?? '')?.group(1);
    if (match == null || match.isEmpty) return const [];
    final days = match
        .split(',')
        .map((code) => _weekdayCodes.indexOf(code.trim().toUpperCase()) + 1)
        .where((day) => day >= 1 && day <= 7)
        .toSet()
        .toList()
      ..sort();
    return days;
  }

  /// Expands occurrences whose scheduled wall-clock timestamp falls within
  /// `[rangeStart, rangeEnd]` (or open/half-open per [includeRangeStart] /
  /// [includeRangeEnd]).
  ///
  /// When [respectMaterializeFrom] is true, occurrences strictly before
  /// `spec.effectiveMaterializeFrom` are omitted while still consuming slots
  /// from `spec.countLimit` starting at `spec.startDate`.
  List<RecurrenceOccurrence> expandInRange(
    RecurrenceRuleSpec spec, {
    DateTime? rangeStart,
    required DateTime rangeEnd,
    bool includeRangeStart = true,
    bool includeRangeEnd = true,
    int? maxCount,
    bool respectMaterializeFrom = true,
  }) {
    if (maxCount != null && maxCount <= 0) return const [];

    final localStart = _asLocalWallTime(spec.startDate);
    final localMaterializeFrom =
        _asLocalWallTime(spec.effectiveMaterializeFrom);

    if (spec.mode == RecurringSeriesMode.planned) {
      final scheduled = _buildDateTime(
        localStart.year,
        localStart.month,
        localStart.day,
        localStart.hour,
        localStart.minute,
        localStart.second,
      );
      final occ = RecurrenceOccurrence(
        occurrenceKey: kPlannedOccurrenceKey,
        scheduledDate: scheduled,
      );
      if (!_matchesBounds(
        occ.scheduledDate,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        includeRangeStart: includeRangeStart,
        includeRangeEnd: includeRangeEnd,
        materializeFrom: respectMaterializeFrom ? localMaterializeFrom : null,
      )) {
        return const [];
      }
      return [occ];
    }

    final remainingCount = spec.remainingCountLimit;
    if (remainingCount != null && remainingCount <= 0) {
      return const [];
    }

    final civilStart = _toCivilTuple(localStart);
    final localRangeEnd = _asLocalWallTime(rangeEnd);
    final civilBefore = _toCivilTuple(localRangeEnd);
    if (civilBefore.isBefore(civilStart)) {
      return const [];
    }

    DateTime? effectiveLower = rangeStart;
    if (respectMaterializeFrom &&
        (effectiveLower == null ||
            localMaterializeFrom.isAfter(effectiveLower))) {
      effectiveLower = localMaterializeFrom;
    }

    DateTime? civilAfter;
    if (effectiveLower != null) {
      final lowerTuple = _toCivilTuple(_asLocalWallTime(effectiveLower));
      if (lowerTuple.isAfter(civilStart)) {
        civilAfter = lowerTuple;
      }
    }

    final anchor = _fastForwardAnchor(spec, civilStart, civilAfter);
    if (anchor.isAfter(civilBefore)) {
      return const [];
    }

    final rule = _buildRule(spec, remainingCount);
    final candidates = rule.getInstances(
      start: anchor,
      after: civilAfter,
      includeAfter: true,
      before: civilBefore,
      includeBefore: true,
    );

    final results = <RecurrenceOccurrence>[];
    for (final civilDate in candidates) {
      final scheduled = _buildDateTime(
        civilDate.year,
        civilDate.month,
        civilDate.day,
        localStart.hour,
        localStart.minute,
        localStart.second,
      );
      if (!_matchesBounds(
        scheduled,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        includeRangeStart: includeRangeStart,
        includeRangeEnd: includeRangeEnd,
        materializeFrom: respectMaterializeFrom ? localMaterializeFrom : null,
      )) {
        continue;
      }
      results.add(
        RecurrenceOccurrence(
          occurrenceKey: formatCivilDateKey(
            civilDate.year,
            civilDate.month,
            civilDate.day,
          ),
          scheduledDate: scheduled,
        ),
      );
      if (maxCount != null && results.length >= maxCount) {
        break;
      }
    }
    return results;
  }

  /// Convenience helper expanding all occurrences falling in the local
  /// calendar month `(year, month)`.
  List<RecurrenceOccurrence> expandForMonth(
    RecurrenceRuleSpec spec,
    int year,
    int month, {
    bool respectMaterializeFrom = true,
  }) {
    final monthStart = _buildDateTime(year, month, 1, 0, 0, 0);
    final lastDay = DateTime(year, month + 1, 0).day;
    final monthEnd = _buildDateTime(year, month, lastDay, 23, 59, 59);
    return expandInRange(
      spec,
      rangeStart: monthStart,
      rangeEnd: monthEnd,
      includeRangeStart: true,
      includeRangeEnd: true,
      respectMaterializeFrom: respectMaterializeFrom,
    );
  }

  /// Finds the first occurrence strictly after [after] (and `>= materializeFrom`
  /// when [respectMaterializeFrom] is true), optionally skipping any
  /// [skipKeys] (e.g. already-posted or skipped occurrences beyond the window).
  RecurrenceOccurrence? firstOccurrenceAfter(
    RecurrenceRuleSpec spec,
    DateTime after, {
    bool respectMaterializeFrom = true,
    Set<String> skipKeys = const {},
  }) {
    final localStart = _asLocalWallTime(spec.startDate);
    final localMaterializeFrom =
        _asLocalWallTime(spec.effectiveMaterializeFrom);

    if (spec.mode == RecurringSeriesMode.planned) {
      if (skipKeys.contains(kPlannedOccurrenceKey)) return null;
      final scheduled = _buildDateTime(
        localStart.year,
        localStart.month,
        localStart.day,
        localStart.hour,
        localStart.minute,
        localStart.second,
      );
      if (!scheduled.isAfter(after)) return null;
      if (respectMaterializeFrom && scheduled.isBefore(localMaterializeFrom)) {
        return null;
      }
      return RecurrenceOccurrence(
        occurrenceKey: kPlannedOccurrenceKey,
        scheduledDate: scheduled,
      );
    }

    final remainingCount = spec.remainingCountLimit;
    if (remainingCount != null && remainingCount <= 0) {
      return null;
    }

    final civilStart = _toCivilTuple(localStart);
    if (_maxCivilBound.isBefore(civilStart)) return null;

    var lowerInstant = after;
    if (respectMaterializeFrom && localMaterializeFrom.isAfter(lowerInstant)) {
      lowerInstant = localMaterializeFrom;
    }
    final lowerTuple = _toCivilTuple(_asLocalWallTime(lowerInstant));
    final civilAfter = lowerTuple.isAfter(civilStart) ? lowerTuple : null;

    final anchor = _fastForwardAnchor(spec, civilStart, civilAfter);

    final rule = _buildRule(spec, remainingCount);
    final candidates = rule.getInstances(
      start: anchor,
      after: civilAfter,
      includeAfter: true,
      before: _maxCivilBound,
      includeBefore: true,
    );

    for (final civilDate in candidates) {
      final scheduled = _buildDateTime(
        civilDate.year,
        civilDate.month,
        civilDate.day,
        localStart.hour,
        localStart.minute,
        localStart.second,
      );
      if (!scheduled.isAfter(after)) continue;
      if (respectMaterializeFrom && scheduled.isBefore(localMaterializeFrom)) {
        continue;
      }
      final key = formatCivilDateKey(
        civilDate.year,
        civilDate.month,
        civilDate.day,
      );
      if (skipKeys.contains(key)) continue;
      return RecurrenceOccurrence(
        occurrenceKey: key,
        scheduledDate: scheduled,
      );
    }
    return null;
  }

  /// Jumps the civil-date iteration anchor by whole periods so unbounded
  /// high-frequency rules (`DAILY` / `WEEKLY`, any interval and `BYDAY`) do not
  /// step through every intervening occurrence when the requested window starts
  /// years after [civilStart].
  ///
  /// Phase always stays anchored to `spec.startDate`:
  /// * `DAILY`: occurrences are `startDate + k * interval` civil days, so the
  ///   anchor is the whole-period multiple at or before [civilLower].
  /// * `WEEKLY`: RRULE weeks are anchored to the Monday of `startDate`'s week
  ///   (`WKST=MO`), and `BYDAY` only selects days inside included weeks, so the
  ///   anchor is the Monday of the whole-period week at or before [civilLower].
  ///
  /// Returns [civilStart] unchanged when [civilLower] is absent, when the rule
  /// is count-limited (every occurrence must be counted from `startDate`), when
  /// the frequency is neither `DAILY` nor `WEEKLY`, or when no whole period can
  /// be skipped.
  static DateTime _fastForwardAnchor(
    RecurrenceRuleSpec spec,
    DateTime civilStart,
    DateTime? civilLower,
  ) {
    if (civilLower == null || spec.remainingCountLimit != null) {
      return civilStart;
    }

    final interval = spec.interval < 1 ? 1 : spec.interval;
    switch (spec.frequency.toUpperCase()) {
      case 'DAILY':
        final dayOffset = civilLower.difference(civilStart).inDays;
        final wholePeriods = dayOffset ~/ interval;
        if (wholePeriods < 1) return civilStart;
        return civilStart.add(Duration(days: wholePeriods * interval));
      case 'WEEKLY':
        final startWeekMonday = civilStart.subtract(
          Duration(days: civilStart.weekday - DateTime.monday),
        );
        final offsetDays = civilLower.difference(startWeekMonday).inDays;
        final stepDays = DateTime.daysPerWeek * interval;
        final wholePeriods = offsetDays ~/ stepDays;
        if (wholePeriods < 1) return civilStart;
        return startWeekMonday.add(Duration(days: wholePeriods * stepDays));
      default:
        return civilStart;
    }
  }

  static bool _matchesBounds(
    DateTime scheduled, {
    required DateTime? rangeStart,
    required DateTime rangeEnd,
    required bool includeRangeStart,
    required bool includeRangeEnd,
    required DateTime? materializeFrom,
  }) {
    if (materializeFrom != null && scheduled.isBefore(materializeFrom)) {
      return false;
    }
    if (rangeStart != null) {
      if (includeRangeStart) {
        if (scheduled.isBefore(rangeStart)) return false;
      } else {
        if (!scheduled.isAfter(rangeStart)) return false;
      }
    }
    if (includeRangeEnd) {
      if (scheduled.isAfter(rangeEnd)) return false;
    } else {
      if (!scheduled.isBefore(rangeEnd)) return false;
    }
    return true;
  }

  static RecurrenceRule _buildRule(
    RecurrenceRuleSpec spec,
    int? remainingCount,
  ) {
    final DateTime? civilUntil;
    if (remainingCount != null || spec.endDate == null) {
      civilUntil = null;
    } else {
      civilUntil = _toCivilTuple(_asLocalWallTime(spec.endDate!));
    }

    final byWeekDays = spec.frequency.toUpperCase() == 'WEEKLY'
        ? _weeklyWeekdays(spec).map(ByWeekDayEntry.new).toList()
        : const <ByWeekDayEntry>[];

    return RecurrenceRule(
      frequency: _mapFrequency(spec.frequency),
      interval: spec.interval < 1 ? 1 : spec.interval,
      until: civilUntil,
      count: remainingCount,
      byWeekDays: byWeekDays,
    );
  }

  /// Weekday numbers selected by a `WEEKLY` rule.
  ///
  /// An empty `BYDAY` list means "the weekday of `startDate`", which RRULE
  /// would otherwise infer from the `start` argument. It is spelled out here so
  /// a fast-forwarded iteration anchor (a Monday) cannot shift an implicit
  /// weekday away from `startDate`'s.
  static List<int> _weeklyWeekdays(RecurrenceRuleSpec spec) {
    final explicit = spec.weekdays.where((d) => d >= 1 && d <= 7).toSet();
    if (explicit.isNotEmpty) {
      return explicit.toList()..sort();
    }
    final localStart = _asLocalWallTime(spec.startDate);
    return [_toCivilTuple(localStart).weekday];
  }

  static Frequency _mapFrequency(String freq) {
    switch (freq.toUpperCase()) {
      case 'DAILY':
        return Frequency.daily;
      case 'WEEKLY':
        return Frequency.weekly;
      case 'MONTHLY':
        return Frequency.monthly;
      case 'YEARLY':
        return Frequency.yearly;
      default:
        return Frequency.monthly;
    }
  }
}
