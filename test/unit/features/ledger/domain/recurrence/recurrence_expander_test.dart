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

    test('horizonEndForMonth aligns strictly to end of (nowYm + 2)', () {
      // Nov 26, 2026 -> Jan 31, 2027 (Nov, Dec, Jan = 3 full months)
      final nov = RecurrenceExpander.horizonEndForMonth(
        DateTime(2026, 11, 26, 10, 0),
      );
      expect(nov.year, 2027);
      expect(nov.month, 1);
      expect(nov.day, 31);

      // Dec 26, 2026 -> Feb 28, 2027 (non-leap)
      final dec = RecurrenceExpander.horizonEndForMonth(
        DateTime(2026, 12, 26, 10, 0),
      );
      expect(dec.year, 2027);
      expect(dec.month, 2);
      expect(dec.day, 28);

      // Dec 26, 2027 -> Feb 29, 2028 (leap year)
      final leapDec = RecurrenceExpander.horizonEndForMonth(
        DateTime(2027, 12, 26, 10, 0),
      );
      expect(leapDec.year, 2028);
      expect(leapDec.month, 2);
      expect(leapDec.day, 29);
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
}
