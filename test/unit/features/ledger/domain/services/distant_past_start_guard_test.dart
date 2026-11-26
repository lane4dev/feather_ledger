import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import 'package:feather_ledger/features/ledger/domain/recurrence/distant_past_guard.dart';

import '../../../../../support/event_sourcing/ledger_service_harness.dart';
import '../../../../../support/mocks/mock_shared_preferences.dart';

void main() {
  group('DistantPastStartGuard', () {
    test('checks strict 2-calendar-month threshold with short-month clamping',
        () {
      final now = DateTime(2026, 11, 26, 10, 0);
      expect(
        DistantPastStartGuard.isDistantPast(DateTime(2026, 9, 25, 23, 59),
            now: now),
        isTrue,
      );
      expect(
        DistantPastStartGuard.isDistantPast(DateTime(2026, 9, 26, 0, 0),
            now: now),
        isFalse,
      );
      expect(
        DistantPastStartGuard.isDistantPast(DateTime(2026, 9, 26, 9, 0),
            now: now),
        isFalse,
      );
      expect(
        DistantPastStartGuard.isDistantPast(DateTime(2026, 10, 26, 9, 0),
            now: now),
        isFalse,
      );

      // April 30 minus 2 calendar months clamps to Feb 28 (non-leap) or Feb 29 (leap).
      final nonLeapApr30 = DateTime(2026, 4, 30, 15, 0);
      expect(
        DistantPastStartGuard.isDistantPast(DateTime(2026, 2, 27, 23, 59),
            now: nonLeapApr30),
        isTrue,
      );
      expect(
        DistantPastStartGuard.isDistantPast(DateTime(2026, 2, 28, 0, 0),
            now: nonLeapApr30),
        isFalse,
      );

      final leapApr30 = DateTime(2024, 4, 30, 15, 0);
      expect(
        DistantPastStartGuard.isDistantPast(DateTime(2024, 2, 28, 23, 59),
            now: leapApr30),
        isTrue,
      );
      expect(
        DistantPastStartGuard.isDistantPast(DateTime(2024, 2, 29, 0, 0),
            now: leapApr30),
        isFalse,
      );

      // Aug 31 minus 2 calendar months clamps to June 30.
      final aug31 = DateTime(2026, 8, 31, 8, 0);
      expect(
        DistantPastStartGuard.isDistantPast(DateTime(2026, 6, 29, 23, 59),
            now: aug31),
        isTrue,
      );
      expect(
        DistantPastStartGuard.isDistantPast(DateTime(2026, 6, 30, 0, 0),
            now: aug31),
        isFalse,
      );

      // Year rollover: Jan 15 minus 2 calendar months -> Nov 15 previous year.
      final jan15 = DateTime(2026, 1, 15, 8, 0);
      expect(
        DistantPastStartGuard.isDistantPast(DateTime(2025, 11, 14, 23, 59),
            now: jan15),
        isTrue,
      );
      expect(
        DistantPastStartGuard.isDistantPast(DateTime(2025, 11, 15, 0, 0),
            now: jan15),
        isFalse,
      );
    });

    test('computes fromToday and clamped backfillDays materializeFrom bounds',
        () {
      final now = DateTime(2026, 11, 26, 10, 30);
      expect(
        DistantPastStartGuard.fromTodayMaterializeFrom(now: now),
        DateTime(2026, 11, 26),
      );

      // 45 days before Nov 26 is Oct 12 00:00 (after 2-year-old startDate).
      expect(
        DistantPastStartGuard.backfillDaysMaterializeFrom(
          startDate: DateTime(2024, 11, 26, 9, 0),
          now: now,
          days: 45,
        ),
        DateTime(2026, 10, 12),
      );

      // When now - N days is earlier than startDate, clamp to startDate.
      final start = DateTime(2026, 9, 1, 9, 0);
      expect(
        DistantPastStartGuard.backfillDaysMaterializeFrom(
          startDate: start,
          now: now,
          days: 100,
        ),
        start,
      );
    });
  });

  group('Distant-past & near-past recurring start guard (LedgerServiceHarness)',
      () {
    final fixedNow = DateTime(2026, 11, 26, 10, 0);
    final startOfToday = DateTime(2026, 11, 26);

    late LedgerServiceHarness harness;
    late String accountId;
    late String categoryId;

    setUp(() async {
      final prefs = PreferencesRepositoryImpl(MockSharedPreferences());
      await prefs.setCurrency('USD');
      harness = LedgerServiceHarness(
        preferences: prefs,
        clock: FixedClock(fixedNow),
      );
      await harness.seedSystemCategories();
      await harness.accountService.createAccount(
        commandId: 'cmd_acc',
        name: 'Checking',
        type: AccountType.bank,
        initialBalanceMinor: 1000000,
        currencyCode: 'USD',
      );
      await harness.categoryService.createCategory(
        commandId: 'cmd_cat',
        name: 'Installment',
        iconKey: 'credit_card',
        colorInt: 0xFF1565C0,
        type: CategoryType.expense,
      );
      accountId = (await harness.db.accountDao.getAllAccounts()).single.id;
      categoryId = await harness.userCategoryId();
    });

    tearDown(() => harness.close());

    Future<List<TransactionRecorded>> recordedWithSourceBill() async {
      final events = (await harness.eventStore.readAll()).events;
      return events
          .where((e) => e.eventType == 'TransactionRecorded')
          .map((e) => TransactionRecorded.fromJson(e.payloadJson))
          .where((e) => e.sourceScheduledBillId != null)
          .toList();
    }

    test(
        '2-year-old 36-period installment choosing "from today" skips 24 past '
        'periods, shows 12 remaining periods accurately in BudgetService Plan, '
        'and returns 0 on the 13th month', () async {
      final start = DateTime(2024, 11, 26, 9, 0);
      final materializeFrom =
          DistantPastStartGuard.fromTodayMaterializeFrom(now: fixedNow);

      final created = await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 10000,
        accountId: accountId,
        categoryId: categoryId,
        description: 'Laptop 36m',
        frequency: 'MONTHLY',
        interval: 1,
        startDate: start,
        materializeFrom: materializeFrom,
        countLimit: 36,
        autoPost: true,
        mode: RecurringSeriesMode.repeating,
      );
      expect(created, isA<Success<String>>());
      final seriesId = (created as Success<String>).value;

      // Series keeps original startDate as schedule & countLimit anchor while
      // persisting materializeFrom = startOfDay(now).
      final series = await harness.db.recurringDao.getSeries(seriesId);
      expect(series!.startDate, start);
      expect(series.materializeFrom, startOfToday);
      expect(series.countLimit, 36);

      // No historical occurrences strictly before today were materialized.
      final physical = await harness.db.recurringDao.scheduledForSeries(seriesId);
      expect(
        physical.where((r) => r.scheduledDate.isBefore(startOfToday)),
        isEmpty,
        reason: '24 historical periods (2024-11..2026-10) must not materialize',
      );

      // Period 25 (2026-11-26 09:00 <= 10:00) auto-posted today with sourceScheduledBillId.
      final todayRow =
          physical.singleWhere((r) => r.occurrenceKey == '2026-11-26');
      expect(todayRow.status, 'posted');
      expect(todayRow.manualOnly, isFalse);
      final recorded = await recordedWithSourceBill();
      expect(recorded, hasLength(1));
      expect(recorded.single.sourceScheduledBillId, todayRow.id);
      expect(
        (await harness.ledgerService.accountBalance(accountId)).balance,
        1000000 - 10000,
      );

      // Remaining 12 periods (2026-11 actual + 2026-12..2027-10 Plan pending):
      final novSummary = await harness.budgetService
          .watchMonthBudget(
            currencyCode: 'USD',
            month: const YearMonth(2026, 11),
          )
          .first;
      expect(novSummary.allExpenseActualMinor, 10000);
      expect(novSummary.allExpensePendingMinor, 0);

      for (var offset = 1; offset <= 11; offset++) {
        final target = YearMonth.fromDate(DateTime(2026, 11 + offset, 1));
        final plan = await harness.budgetService
            .watchMonthBudget(currencyCode: 'USD', month: target)
            .first;
        expect(
          plan.allExpensePendingMinor,
          10000,
          reason: 'Period ${25 + offset} in ${target.ym} must show 10000 in Plan',
        );
      }

      // 13th month from today (period 37: 2027-11) must be 0.
      final afterEnd = await harness.budgetService
          .watchMonthBudget(
            currencyCode: 'USD',
            month: const YearMonth(2027, 11),
          )
          .first;
      expect(afterEnd.allExpensePendingMinor, 0);
      expect(afterEnd.allExpenseActualMinor, 0);
    });

    test(
        '2-year-old series choosing "backfill last 45 days" only materializes '
        'within 45 days and marks all strictly-before-today rows manualOnly '
        'even when autoPost is true', () async {
      final start = DateTime(2024, 11, 20, 9, 0);
      final materializeFrom = DistantPastStartGuard.backfillDaysMaterializeFrom(
        startDate: start,
        now: fixedNow,
        days: 45,
      );
      // 45 days before 2026-11-26 is 2026-10-12 00:00 -> covers 2026-10-20 and 2026-11-20.
      expect(materializeFrom, DateTime(2026, 10, 12));

      final created = await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 15000,
        accountId: accountId,
        categoryId: categoryId,
        description: 'Old Gym',
        frequency: 'MONTHLY',
        interval: 1,
        startDate: start,
        materializeFrom: materializeFrom,
        autoPost: true,
        mode: RecurringSeriesMode.repeating,
      );
      expect(created, isA<Success<String>>());
      final seriesId = (created as Success<String>).value;

      final rows = (await harness.db.recurringDao.scheduledForSeries(seriesId))
        ..sort((a, b) => a.occurrenceKey.compareTo(b.occurrenceKey));

      final pastRows =
          rows.where((r) => r.scheduledDate.isBefore(startOfToday)).toList();
      expect(
        pastRows.map((r) => r.occurrenceKey).toList(),
        ['2026-10-20', '2026-11-20'],
      );
      expect(
        pastRows.every((r) => r.status == 'scheduled' && r.manualOnly),
        isTrue,
        reason: 'backfilled bills strictly before today must be manualOnly',
      );

      // Account balance untouched — zero silent debits for past occurrences.
      expect(
        (await harness.ledgerService.accountBalance(accountId)).balance,
        1000000,
      );
      expect(await recordedWithSourceBill(), isEmpty);

      // Upcoming rows remain eligible for future auto-posting.
      final futureRows =
          rows.where((r) => !r.scheduledDate.isBefore(startOfToday)).toList();
      expect(futureRows, isNotEmpty);
      expect(futureRows.every((r) => !r.manualOnly), isTrue);

      // Subsequent catchUpAutoPosted respects manualOnly and still posts nothing.
      expect(await harness.recurringService.catchUpAutoPosted(), 0);
    });

    test(
        'backfill is still bounded by the 100-item per-series cap and latches '
        'all strictly-before-today rows manualOnly', () async {
      final start = DateTime(2024, 1, 1, 9, 0);
      final materializeFrom = DistantPastStartGuard.backfillDaysMaterializeFrom(
        startDate: start,
        now: fixedNow,
        days: 200,
      );

      final created = await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 500,
        accountId: accountId,
        categoryId: categoryId,
        description: 'Daily commute',
        frequency: 'DAILY',
        interval: 1,
        startDate: start,
        materializeFrom: materializeFrom,
        autoPost: true,
        mode: RecurringSeriesMode.repeating,
      );
      expect(created, isA<Success<String>>());
      final seriesId = (created as Success<String>).value;

      final rows = await harness.db.recurringDao.scheduledForSeries(seriesId);
      final dueRows =
          rows.where((r) => !r.scheduledDate.isAfter(fixedNow)).toList();
      // Capped at 100 historical-through-now rows: 99 strictly before today + 1 today.
      expect(dueRows, hasLength(100));

      final strictlyBeforeToday =
          dueRows.where((r) => r.scheduledDate.isBefore(startOfToday)).toList();
      expect(strictlyBeforeToday, hasLength(99));
      expect(
        strictlyBeforeToday
            .every((r) => r.status == 'scheduled' && r.manualOnly),
        isTrue,
      );

      final todayRow =
          dueRows.singleWhere((r) => r.occurrenceKey == '2026-11-26');
      expect(todayRow.status, 'posted');
      expect(todayRow.manualOnly, isFalse);
      expect(
        (await harness.ledgerService.accountBalance(accountId)).balance,
        1000000 - 500,
      );
    });

    test(
        'within-2-months past start defaults materializeFrom to startDate, '
        'latches strictly-before-today rows manualOnly, and still auto-posts '
        'same-day due occurrences (including midnight startOfDay(now)) with '
        'sourceScheduledBillId', () async {
      // Exact midnight 1 month ago -> occurrences on 2026-10-26 00:00 (past)
      // and 2026-11-26 00:00 (exact startOfDay(now), same-day due!).
      final start = DateTime(2026, 10, 26, 0, 0);

      final created = await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 8000,
        accountId: accountId,
        categoryId: categoryId,
        description: 'Near past sub',
        frequency: 'MONTHLY',
        interval: 1,
        startDate: start,
        autoPost: true,
        mode: RecurringSeriesMode.repeating,
      );
      expect(created, isA<Success<String>>());
      final seriesId = (created as Success<String>).value;

      final series = await harness.db.recurringDao.getSeries(seriesId);
      expect(series!.materializeFrom, start);

      final rows = await harness.db.recurringDao.scheduledForSeries(seriesId);
      final oct = rows.singleWhere((r) => r.occurrenceKey == '2026-10-26');
      final nov = rows.singleWhere((r) => r.occurrenceKey == '2026-11-26');

      expect(oct.status, 'scheduled');
      expect(oct.manualOnly, isTrue);

      expect(nov.status, 'posted');
      expect(nov.manualOnly, isFalse);

      final recorded = await recordedWithSourceBill();
      expect(recorded, hasLength(1));
      expect(recorded.single.sourceScheduledBillId, nov.id);
      expect(
        (await harness.ledgerService.accountBalance(accountId)).balance,
        1000000 - 8000,
      );
      expect(harness.recurringService.takeLastAutoPostedCount(), 1);
    });

    test(
        'updateBill(updateRule) changing base schedule persists materializeFrom, '
        'keeps startDate as countLimit anchor, latches strictly-before-today '
        'rows manualOnly, and auto-posts same-day due occurrence', () async {
      // Create an active future monthly series first.
      final created = await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 12000,
        accountId: accountId,
        categoryId: categoryId,
        description: 'Loan',
        frequency: 'MONTHLY',
        interval: 1,
        startDate: DateTime(2026, 12, 26, 9, 0),
        autoPost: true,
        mode: RecurringSeriesMode.repeating,
      );
      final seriesId = (created as Success<String>).value;
      final bill =
          (await harness.db.recurringDao.scheduledForSeries(seriesId)).first;

      // Move start date to 2 years ago with countLimit = 36 and backfill 45 days.
      final distantStart = DateTime(2024, 11, 26, 9, 0);
      final backfillFrom = DistantPastStartGuard.backfillDaysMaterializeFrom(
        startDate: distantStart,
        now: fixedNow,
        days: 45,
      );

      final updated = await harness.recurringService.updateBill(
        bill.id,
        scope: RecurringScope.updateRule,
        amountMinor: 12000,
        date: distantStart,
        categoryId: categoryId,
        accountId: accountId,
        description: 'Loan',
        frequency: 'MONTHLY',
        interval: 1,
        countLimit: 36,
        autoPost: true,
        materializeFrom: backfillFrom,
      );
      expect(updated, isA<Success<void>>());

      final series = await harness.db.recurringDao.getSeries(seriesId);
      expect(series!.startDate, distantStart);
      expect(series.materializeFrom, backfillFrom);
      expect(series.countLimit, 36);

      final rows = (await harness.db.recurringDao.scheduledForSeries(seriesId))
        ..sort((a, b) => a.occurrenceKey.compareTo(b.occurrenceKey));

      // Backfill 45 days from Nov 26 covers Oct 26 (manualOnly) and Nov 26 (posted today).
      final pastRows =
          rows.where((r) => r.scheduledDate.isBefore(startOfToday)).toList();
      expect(pastRows.map((r) => r.occurrenceKey).toList(), ['2026-10-26']);
      expect(pastRows.single.status, 'scheduled');
      expect(pastRows.single.manualOnly, isTrue);

      final todayRow =
          rows.singleWhere((r) => r.occurrenceKey == '2026-11-26');
      expect(todayRow.status, 'posted');
      expect(todayRow.manualOnly, isFalse);

      // 13th month from today (period 37: 2027-11) is 0 in BudgetService Plan.
      final afterEnd = await harness.budgetService
          .watchMonthBudget(
            currencyCode: 'USD',
            month: const YearMonth(2027, 11),
          )
          .first;
      expect(afterEnd.allExpensePendingMinor, 0);
    });
  });
}
