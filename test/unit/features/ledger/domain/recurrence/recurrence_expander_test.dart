import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/recurrence/recurrence_expander.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  const expander = RecurrenceExpander();

  group('RecurrenceExpander — frequencies, intervals, and BYDAY', () {
    test('expands DAILY, WEEKLY, MONTHLY, YEARLY with custom intervals', () {
      final daily = expander.expandInRange(
        RecurrenceRuleSpec(
          mode: RecurringSeriesMode.repeating,
          frequency: 'DAILY',
          interval: 2,
          startDate: DateTime(2026, 11, 1, 9, 15),
        ),
        rangeEnd: DateTime(2026, 11, 7, 23, 59, 59),
      );
      expect(
        daily.map((o) => o.occurrenceKey).toList(),
        ['2026-11-01', '2026-11-03', '2026-11-05', '2026-11-07'],
      );
      expect(
        daily.every((o) => o.scheduledDate.hour == 9 && o.scheduledDate.minute == 15),
        isTrue,
      );

      final weekly = expander.expandInRange(
        RecurrenceRuleSpec(
          mode: RecurringSeriesMode.repeating,
          frequency: 'WEEKLY',
          interval: 2,
          startDate: DateTime(2026, 11, 2, 8, 0), // Monday
          weekdays: const [DateTime.monday, DateTime.wednesday],
        ),
        rangeEnd: DateTime(2026, 11, 30, 23, 59, 59),
      );
      expect(
        weekly.map((o) => o.occurrenceKey).toList(),
        ['2026-11-02', '2026-11-04', '2026-11-16', '2026-11-18', '2026-11-30'],
      );

      final monthly = expander.expandInRange(
        RecurrenceRuleSpec(
          mode: RecurringSeriesMode.repeating,
          frequency: 'MONTHLY',
          interval: 2,
          startDate: DateTime(2026, 11, 15, 10, 0),
        ),
        rangeEnd: DateTime(2027, 4, 30, 23, 59, 59),
      );
      expect(
        monthly.map((o) => o.occurrenceKey).toList(),
        ['2026-11-15', '2027-01-15', '2027-03-15'],
      );

      final yearly = expander.expandInRange(
        RecurrenceRuleSpec(
          mode: RecurringSeriesMode.repeating,
          frequency: 'YEARLY',
          interval: 1,
          startDate: DateTime(2026, 6, 1, 12, 0),
        ),
        rangeEnd: DateTime(2028, 12, 31, 23, 59, 59),
      );
      expect(
        yearly.map((o) => o.occurrenceKey).toList(),
        ['2026-06-01', '2027-06-01', '2028-06-01'],
      );
    });

    test('interprets BYDAY directly as local weekdays without UTC shift', () {
      // 00:30 in Asia/Shanghai (UTC+8) on Monday 2026-11-02 is Sunday 16:30 UTC.
      // Local civil expansion must still emit Monday and Thursday in Shanghai.
      final shanghai = tz.getLocation('Asia/Shanghai');
      final start = tz.TZDateTime(shanghai, 2026, 11, 2, 0, 30); // Monday
      final shanghaiExpander = RecurrenceExpander(
        buildDateTime: (y, m, d, h, min, s) =>
            tz.TZDateTime(shanghai, y, m, d, h, min, s),
      );

      final results = shanghaiExpander.expandInRange(
        RecurrenceRuleSpec(
          mode: RecurringSeriesMode.repeating,
          frequency: 'WEEKLY',
          interval: 1,
          startDate: start,
          weekdays: const [DateTime.monday, DateTime.thursday],
        ),
        rangeEnd: tz.TZDateTime(shanghai, 2026, 11, 12, 23, 59, 59),
      );

      expect(
        results.map((o) => o.occurrenceKey).toList(),
        ['2026-11-02', '2026-11-05', '2026-11-09', '2026-11-12'],
      );
      expect(
        results.every((o) =>
            o.scheduledDate.weekday == DateTime.monday ||
            o.scheduledDate.weekday == DateTime.thursday),
        isTrue,
      );
      expect(
        results.every(
            (o) => o.scheduledDate.hour == 0 && o.scheduledDate.minute == 30),
        isTrue,
      );
    });
  });

  group('RecurrenceExpander — local civil date, UTC midnight, and DST', () {
    test(
        'local 1st at 00:30 in UTC+8 (previous month in UTC) stays on local 1st across all months including Feb',
        () {
      final shanghai = tz.getLocation('Asia/Shanghai');
      final start = tz.TZDateTime(shanghai, 2026, 11, 1, 0, 30);
      expect(start.toUtc().month, 10,
          reason: 'precondition: UTC instant falls in October');
      expect(start.toUtc().day, 31);

      final shanghaiExpander = RecurrenceExpander(
        buildDateTime: (y, m, d, h, min, s) =>
            tz.TZDateTime(shanghai, y, m, d, h, min, s),
      );

      final results = shanghaiExpander.expandInRange(
        RecurrenceRuleSpec(
          mode: RecurringSeriesMode.repeating,
          frequency: 'MONTHLY',
          interval: 1,
          startDate: start,
        ),
        rangeEnd: tz.TZDateTime(shanghai, 2027, 3, 31, 23, 59, 59),
      );

      expect(
        results.map((o) => o.occurrenceKey).toList(),
        [
          '2026-11-01',
          '2026-12-01',
          '2027-01-01',
          '2027-02-01',
          '2027-03-01',
        ],
      );
      for (final occ in results) {
        expect(occ.scheduledDate.day, 1);
        expect(occ.scheduledDate.hour, 0);
        expect(occ.scheduledDate.minute, 30);
      }
    });

    test('preserves local wall-clock time across DST fall-back and spring-forward',
        () {
      final newYork = tz.getLocation('America/New_York');
      final nyExpander = RecurrenceExpander(
        buildDateTime: (y, m, d, h, min, s) =>
            tz.TZDateTime(newYork, y, m, d, h, min, s),
      );

      // Fall-back on 2026-11-01 in America/New_York.
      final fallBack = nyExpander.expandInRange(
        RecurrenceRuleSpec(
          mode: RecurringSeriesMode.repeating,
          frequency: 'DAILY',
          interval: 1,
          startDate: tz.TZDateTime(newYork, 2026, 10, 31, 9, 0),
        ),
        rangeEnd: tz.TZDateTime(newYork, 2026, 11, 2, 23, 59, 59),
      );
      expect(
        fallBack.map((o) => o.occurrenceKey).toList(),
        ['2026-10-31', '2026-11-01', '2026-11-02'],
      );
      expect(fallBack.every((o) => o.scheduledDate.hour == 9), isTrue);

      // Spring-forward on 2026-03-08 in America/New_York.
      final springForward = nyExpander.expandInRange(
        RecurrenceRuleSpec(
          mode: RecurringSeriesMode.repeating,
          frequency: 'DAILY',
          interval: 1,
          startDate: tz.TZDateTime(newYork, 2026, 3, 7, 9, 0),
        ),
        rangeEnd: tz.TZDateTime(newYork, 2026, 3, 9, 23, 59, 59),
      );
      expect(
        springForward.map((o) => o.occurrenceKey).toList(),
        ['2026-03-07', '2026-03-08', '2026-03-09'],
      );
      expect(springForward.every((o) => o.scheduledDate.hour == 9), isTrue);
    });
  });

  group('RecurrenceExpander — bounds, counts, materializeFrom, and planned', () {
    test('endDate truncates inclusively by local civil date regardless of time',
        () {
      final results = expander.expandInRange(
        RecurrenceRuleSpec(
          mode: RecurringSeriesMode.repeating,
          frequency: 'DAILY',
          interval: 1,
          startDate: DateTime(2026, 11, 1, 18, 0),
          // Earlier time-of-day on Nov 3 must still include Nov 3.
          endDate: DateTime(2026, 11, 3, 0, 0),
        ),
        rangeEnd: DateTime(2026, 11, 10, 23, 59, 59),
      );

      expect(
        results.map((o) => o.occurrenceKey).toList(),
        ['2026-11-01', '2026-11-02', '2026-11-03'],
      );
    });

    test('countLimit subtracts completedCountOffset and stops at zero', () {
      final results = expander.expandInRange(
        RecurrenceRuleSpec(
          mode: RecurringSeriesMode.repeating,
          frequency: 'MONTHLY',
          interval: 1,
          startDate: DateTime(2026, 11, 1, 9, 0),
          countLimit: 5,
          completedCountOffset: 3,
        ),
        rangeEnd: DateTime(2027, 12, 31, 23, 59, 59),
      );

      expect(
        results.map((o) => o.occurrenceKey).toList(),
        ['2026-11-01', '2026-12-01'],
      );

      final exhausted = expander.expandInRange(
        RecurrenceRuleSpec(
          mode: RecurringSeriesMode.repeating,
          frequency: 'MONTHLY',
          interval: 1,
          startDate: DateTime(2026, 11, 1, 9, 0),
          countLimit: 3,
          completedCountOffset: 3,
        ),
        rangeEnd: DateTime(2027, 12, 31, 23, 59, 59),
      );
      expect(exhausted, isEmpty);
    });

    test(
        'materializeFrom skips earlier occurrences while preserving startDate as countLimit anchor',
        () {
      // 6 monthly bills starting Jan 2026 (Jan..Jun), materializeFrom Apr 1.
      // Jan, Feb, Mar consume 3 slots of countLimit without emitting; Apr..Jun emit.
      final results = expander.expandInRange(
        RecurrenceRuleSpec(
          mode: RecurringSeriesMode.repeating,
          frequency: 'MONTHLY',
          interval: 1,
          startDate: DateTime(2026, 1, 15, 9, 0),
          countLimit: 6,
          materializeFrom: DateTime(2026, 4, 1, 0, 0),
        ),
        rangeEnd: DateTime(2026, 12, 31, 23, 59, 59),
      );

      expect(
        results.map((o) => o.occurrenceKey).toList(),
        ['2026-04-15', '2026-05-15', '2026-06-15'],
      );
    });

    test('planned mode emits a single occurrence with key "single"', () {
      final start = DateTime(2026, 11, 20, 14, 30);
      final results = expander.expandInRange(
        RecurrenceRuleSpec(
          mode: RecurringSeriesMode.planned,
          frequency: 'DAILY',
          interval: 1,
          startDate: start,
          endDate: start,
        ),
        rangeEnd: DateTime(2026, 12, 31, 23, 59, 59),
      );

      expect(results, hasLength(1));
      expect(results.single.occurrenceKey, kPlannedOccurrenceKey);
      expect(results.single.scheduledDate, start);
    });

    test('expandForMonth and firstOccurrenceAfter support budget and floor queries',
        () {
      final spec = RecurrenceRuleSpec(
        mode: RecurringSeriesMode.repeating,
        frequency: 'WEEKLY',
        interval: 1,
        startDate: DateTime(2026, 11, 2, 18, 0),
      );

      final dec = expander.expandForMonth(spec, 2026, 12);
      expect(
        dec.map((o) => o.occurrenceKey).toList(),
        ['2026-12-07', '2026-12-14', '2026-12-21', '2026-12-28'],
      );

      // Same-day occurrence later in the day is still strictly after `after`.
      final sameDayLater = expander.firstOccurrenceAfter(
        spec,
        DateTime(2026, 11, 2, 10, 0),
      );
      expect(sameDayLater?.occurrenceKey, '2026-11-02');

      final nextWeek = expander.firstOccurrenceAfter(
        spec,
        DateTime(2026, 11, 2, 18, 0),
      );
      expect(nextWeek?.occurrenceKey, '2026-11-09');
    });

    test('horizonEndForMonth aligns strictly to end of (nowYm + 1)', () {
      // Nov 26, 2026 -> Dec 31, 2026 (Nov, Dec = 2 full months)
      final nov = RecurrenceExpander.horizonEndForMonth(
        DateTime(2026, 11, 26, 10, 0),
      );
      expect(nov.year, 2026);
      expect(nov.month, 12);
      expect(nov.day, 31);

      // Jan 26, 2027 -> Feb 28, 2027 (non-leap)
      final jan = RecurrenceExpander.horizonEndForMonth(
        DateTime(2027, 1, 26, 10, 0),
      );
      expect(jan.year, 2027);
      expect(jan.month, 2);
      expect(jan.day, 28);

      // Jan 26, 2028 -> Feb 29, 2028 (leap year)
      final leapJan = RecurrenceExpander.horizonEndForMonth(
        DateTime(2028, 1, 26, 10, 0),
      );
      expect(leapJan.year, 2028);
      expect(leapJan.month, 2);
      expect(leapJan.day, 29);
    });

    test('formatRrule uses local civil UNTIL and round-trips BYDAY cleanly', () {
      final shanghai = tz.getLocation('Asia/Shanghai');
      final localEnd = tz.TZDateTime(shanghai, 2026, 12, 1, 0, 30);
      final rrule = RecurrenceExpander.formatRrule(
        frequency: 'WEEKLY',
        interval: 2,
        endDate: localEnd,
        weekdays: const [DateTime.friday, DateTime.monday, DateTime.monday],
      );
      expect(rrule, 'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,FR;UNTIL=20261201');
      expect(
        RecurrenceExpander.parseWeekdaysFromRrule(rrule),
        [DateTime.monday, DateTime.friday],
      );
    });
  });

  group('RecurrenceExpander — fast-forward for unbounded DAILY/WEEKLY rules',
      () {
    final windowStart = DateTime(2026, 1, 1);
    final windowEnd = DateTime(2028, 12, 31, 23, 59, 59);

    test(
        'DAILY interval 1 from a startDate 25 years back matches linear stepping',
        () {
      final spec = RecurrenceRuleSpec(
        mode: RecurringSeriesMode.repeating,
        frequency: 'DAILY',
        startDate: DateTime(2001, 3, 7, 9, 15),
      );

      final expanded = expander.expandInRange(
        spec,
        rangeStart: windowStart,
        rangeEnd: windowEnd,
      );

      expect(
        expanded.map((o) => o.occurrenceKey).toList(),
        _linearStepKeys(spec, rangeStart: windowStart, rangeEnd: windowEnd),
      );
      expect(expanded.first.occurrenceKey, '2026-01-01');
      expect(
        expanded.every(
            (o) => o.scheduledDate.hour == 9 && o.scheduledDate.minute == 15),
        isTrue,
      );
    });

    test(
        'DAILY interval 3 from a startDate 25 years back matches linear stepping',
        () {
      final spec = RecurrenceRuleSpec(
        mode: RecurringSeriesMode.repeating,
        frequency: 'DAILY',
        interval: 3,
        startDate: DateTime(2001, 3, 7, 9, 15),
      );

      final expanded = expander.expandInRange(
        spec,
        rangeStart: windowStart,
        rangeEnd: windowEnd,
      );

      expect(
        expanded.map((o) => o.occurrenceKey).toList(),
        _linearStepKeys(spec, rangeStart: windowStart, rangeEnd: windowEnd),
      );
      // 2026-01-01 is 9084 days after start, divisible by the 3-day interval.
      expect(expanded.first.occurrenceKey, '2026-01-01');
    });

    test(
        'WEEKLY interval 1 with multiple BYDAY over a century matches linear stepping',
        () {
      final spec = RecurrenceRuleSpec(
        mode: RecurringSeriesMode.repeating,
        frequency: 'WEEKLY',
        startDate: DateTime(1926, 6, 2, 18, 0), // Wednesday
        weekdays: const [DateTime.tuesday, DateTime.friday],
      );

      final expanded = expander.expandInRange(
        spec,
        rangeStart: windowStart,
        rangeEnd: DateTime(2026, 3, 31, 23, 59, 59),
      );

      expect(
        expanded.map((o) => o.occurrenceKey).toList(),
        _linearStepKeys(
          spec,
          rangeStart: windowStart,
          rangeEnd: DateTime(2026, 3, 31, 23, 59, 59),
        ),
      );
      expect(expanded.first.occurrenceKey, '2026-01-02');
      expect(
        expanded.every((o) =>
            o.scheduledDate.weekday == DateTime.tuesday ||
            o.scheduledDate.weekday == DateTime.friday),
        isTrue,
      );
    });

    test('WEEKLY interval 2 with multiple BYDAY keeps startDate week phase',
        () {
      // Start on a Wednesday: the first included week still drops the Monday
      // before startDate, which fast-forwarding must not resurrect.
      final spec = RecurrenceRuleSpec(
        mode: RecurringSeriesMode.repeating,
        frequency: 'WEEKLY',
        interval: 2,
        startDate: DateTime(2003, 2, 5, 18, 0), // Wednesday
        weekdays: const [DateTime.monday, DateTime.wednesday],
      );

      final expanded = expander.expandInRange(
        spec,
        rangeStart: windowStart,
        rangeEnd: windowEnd,
      );

      expect(
        expanded.map((o) => o.occurrenceKey).toList(),
        _linearStepKeys(spec, rangeStart: windowStart, rangeEnd: windowEnd),
      );
      expect(expanded.first.occurrenceKey, '2026-01-05');
    });

    test(
        'WEEKLY interval 2 without BYDAY keeps startDate weekday after fast-forward',
        () {
      final spec = RecurrenceRuleSpec(
        mode: RecurringSeriesMode.repeating,
        frequency: 'WEEKLY',
        interval: 2,
        startDate: DateTime(2003, 2, 5, 18, 0), // Wednesday
      );

      final expanded = expander.expandInRange(
        spec,
        rangeStart: windowStart,
        rangeEnd: windowEnd,
      );

      expect(
        expanded.map((o) => o.occurrenceKey).toList(),
        _linearStepKeys(spec, rangeStart: windowStart, rangeEnd: windowEnd),
      );
      expect(
        expanded.every((o) => o.scheduledDate.weekday == DateTime.wednesday),
        isTrue,
      );
    });

    test('materializeFrom today with interval > 1 keeps startDate phase', () {
      final dailySpec = RecurrenceRuleSpec(
        mode: RecurringSeriesMode.repeating,
        frequency: 'DAILY',
        interval: 3,
        startDate: DateTime(2001, 3, 7, 9, 0),
        materializeFrom: DateTime(2026, 11, 28),
      );
      final daily = expander.expandInRange(
        dailySpec,
        rangeStart: windowStart,
        rangeEnd: DateTime(2027, 3, 31, 23, 59, 59),
      );
      // 2026-11-27 would be phase-aligned but lies before materializeFrom, so
      // the next aligned day is 2026-11-30 — not materializeFrom + interval.
      expect(daily.first.occurrenceKey, '2026-11-30');
      expect(
        daily.map((o) => o.occurrenceKey).toList(),
        _linearStepKeys(
          dailySpec,
          rangeStart: windowStart,
          rangeEnd: DateTime(2027, 3, 31, 23, 59, 59),
        ),
      );

      final weeklySpec = RecurrenceRuleSpec(
        mode: RecurringSeriesMode.repeating,
        frequency: 'WEEKLY',
        interval: 3,
        startDate: DateTime(2003, 2, 5, 18, 0), // Wednesday
        weekdays: const [DateTime.monday, DateTime.wednesday],
        materializeFrom: DateTime(2026, 11, 27),
      );
      final weekly = expander.expandInRange(
        weeklySpec,
        rangeStart: windowStart,
        rangeEnd: windowEnd,
      );
      // The included week starting 2026-11-23 has no occurrence on/after
      // materializeFrom, so the first emitted occurrence is the startDate-phase
      // week of 2026-12-14 (3 weeks later), never a materializeFrom-anchored one.
      expect(weekly.first.occurrenceKey, '2026-12-14');
      expect(
        weekly.map((o) => o.occurrenceKey).toList(),
        _linearStepKeys(weeklySpec,
            rangeStart: windowStart, rangeEnd: windowEnd),
      );
    });

    test('count-limited rules keep exact counting from startDate', () {
      // Every slot of these 10 daily bills was consumed long before 2026.
      final exhausted = RecurrenceRuleSpec(
        mode: RecurringSeriesMode.repeating,
        frequency: 'DAILY',
        startDate: DateTime(2000, 1, 1, 9, 0),
        countLimit: 10,
        materializeFrom: DateTime(2026, 1, 1),
      );
      expect(
        expander.expandInRange(
          exhausted,
          rangeStart: windowStart,
          rangeEnd: windowEnd,
        ),
        isEmpty,
      );

      // Counting still starts at startDate even when the window opens later.
      final midWindow = RecurrenceRuleSpec(
        mode: RecurringSeriesMode.repeating,
        frequency: 'DAILY',
        startDate: DateTime(2026, 1, 1, 9, 0),
        countLimit: 5,
      );
      expect(
        expander
            .expandInRange(
              midWindow,
              rangeStart: DateTime(2026, 1, 3),
              rangeEnd: windowEnd,
            )
            .map((o) => o.occurrenceKey)
            .toList(),
        ['2026-01-03', '2026-01-04', '2026-01-05'],
      );

      // A weekly count-limited rule with BYDAY keeps both count and phase.
      final weekly = RecurrenceRuleSpec(
        mode: RecurringSeriesMode.repeating,
        frequency: 'WEEKLY',
        interval: 2,
        startDate: DateTime(2026, 1, 5, 18, 0), // Monday
        weekdays: const [DateTime.monday, DateTime.thursday],
        countLimit: 6,
      );
      final weeklyStart = DateTime(2026, 1, 20);
      final weeklyOccurrences = expander.expandInRange(
        weekly,
        rangeStart: weeklyStart,
        rangeEnd: windowEnd,
      );
      expect(
        weeklyOccurrences.map((o) => o.occurrenceKey).toList(),
        ['2026-01-22', '2026-02-02', '2026-02-05'],
      );
      expect(
        weeklyOccurrences.map((o) => o.occurrenceKey).toList(),
        _linearStepKeys(weekly, rangeStart: weeklyStart, rangeEnd: windowEnd),
      );
    });

    test(
        'firstOccurrenceAfter and expandForMonth match linear stepping far ahead',
        () {
      final spec = RecurrenceRuleSpec(
        mode: RecurringSeriesMode.repeating,
        frequency: 'WEEKLY',
        interval: 2,
        startDate: DateTime(2003, 2, 5, 18, 0), // Wednesday
        weekdays: const [DateTime.monday, DateTime.wednesday],
      );

      final after = DateTime(2026, 1, 7, 12, 0);
      final sameDayKeys = _linearStepKeys(
        spec,
        rangeStart: DateTime(2026, 1, 7),
        rangeEnd: DateTime(2026, 12, 31, 23, 59, 59),
      );
      final expectedFirst = sameDayKeys.firstWhere((key) {
        final day = DateTime.parse(key);
        return DateTime(day.year, day.month, day.day, 18, 0).isAfter(after);
      });
      expect(
        expander.firstOccurrenceAfter(spec, after)?.occurrenceKey,
        expectedFirst,
      );

      final july2031 = expander.expandForMonth(spec, 2031, 7);
      expect(july2031, isNotEmpty);
      expect(
        july2031.map((o) => o.occurrenceKey).toList(),
        _linearStepKeys(
          spec,
          rangeStart: DateTime(2031, 7, 1),
          rangeEnd: DateTime(2031, 7, 31, 23, 59, 59),
        ),
      );
    });

    test('a 1000-year-old DAILY startDate expands without linear stepping', () {
      // Regression guard for the fast-forward itself: stepping every other day
      // from year 1000 to 2026 takes minutes (it exceeds the per-test timeout),
      // while a whole-period jump takes milliseconds.
      final spec = RecurrenceRuleSpec(
        mode: RecurringSeriesMode.repeating,
        frequency: 'DAILY',
        interval: 2,
        startDate: DateTime(1000, 1, 3, 9, 0),
      );
      final rangeEnd = DateTime(2027, 12, 31, 23, 59, 59);

      final stopwatch = Stopwatch()..start();
      final expanded = expander.expandInRange(
        spec,
        rangeStart: windowStart,
        rangeEnd: rangeEnd,
      );
      stopwatch.stop();

      expect(
        expanded.map((o) => o.occurrenceKey).toList(),
        _linearStepKeys(spec, rangeStart: windowStart, rangeEnd: rangeEnd),
      );
      expect(expanded.first.occurrenceKey, '2026-01-02');
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
    });
  });
}

/// Independent oracle for the fast-forward tests: linear day-by-day stepping
/// from `startDate` using the documented rule semantics (local civil dates,
/// `BYDAY` inside RRULE weeks anchored to Monday, `countLimit` counted from
/// `startDate`).
///
/// Deliberately naive and shared with no `RecurrenceExpander` code so the
/// fast-forwarded expansion has something real to be compared against.
List<String> _linearStepKeys(
  RecurrenceRuleSpec spec, {
  DateTime? rangeStart,
  required DateTime rangeEnd,
  bool respectMaterializeFrom = true,
}) {
  final frequency = spec.frequency.toUpperCase();
  if (frequency != 'DAILY' && frequency != 'WEEKLY') {
    throw UnsupportedError('linear oracle supports DAILY and WEEKLY only');
  }

  final startCivil = _civilDate(spec.startDate);
  final endCivil = _civilDate(rangeEnd);
  final endLimit = spec.endDate == null
      ? endCivil
      : _earliestCivil(_civilDate(spec.endDate!), endCivil);

  var lower = startCivil;
  if (rangeStart != null) {
    final rangeStartCivil = _civilDate(rangeStart);
    if (rangeStartCivil.isAfter(lower)) lower = rangeStartCivil;
  }
  if (respectMaterializeFrom) {
    final materializeCivil = _civilDate(spec.effectiveMaterializeFrom);
    if (materializeCivil.isAfter(lower)) lower = materializeCivil;
  }

  final interval = spec.interval < 1 ? 1 : spec.interval;
  final weekdays = spec.weekdays.isEmpty
      ? {startCivil.weekday}
      : spec.weekdays.where((d) => d >= 1 && d <= 7).toSet();
  final startWeekMonday = startCivil.subtract(
    Duration(days: startCivil.weekday - DateTime.monday),
  );

  var remaining = spec.remainingCountLimit;
  final keys = <String>[];
  for (var day = startCivil;
      !day.isAfter(endLimit);
      day = day.add(const Duration(days: 1))) {
    final bool matches;
    if (frequency == 'DAILY') {
      matches = day.difference(startCivil).inDays % interval == 0;
    } else {
      final weekIndex =
          day.difference(startWeekMonday).inDays ~/ DateTime.daysPerWeek;
      matches = weekIndex % interval == 0 && weekdays.contains(day.weekday);
    }
    if (!matches) continue;
    if (remaining != null) {
      if (remaining <= 0) break;
      remaining--;
    }
    if (day.isBefore(lower)) continue;
    keys.add(
      RecurrenceExpander.formatCivilDateKey(day.year, day.month, day.day),
    );
  }
  return keys;
}

DateTime _civilDate(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day);

DateTime _earliestCivil(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
