import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';
import 'package:feather_ledger/features/ledger/domain/commands/project_recurring_events_command.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';

import '../../../../../support/event_sourcing/ledger_service_harness.dart';

/// Calendar-month-aligned physical materialization policy
/// (`endOfMonth(nowYm + 2)`, no `maxKeep = 3` cap, 120-item safety valve,
/// `minKeep = 1` sparse floor, local civil dates, and shared `BudgetService`
/// integration).
void main() {
  setUpAll(tzdata.initializeTimeZones);

  late LedgerServiceHarness harness;
  late DateTime fixedNow;

  setUp(() async {
    // Anchor at Nov 26, 2026 10:00 so `endOfMonth(nowYm + 2)` is Jan 31, 2027
    // (full Nov 2026 + full Dec 2026 + full Jan 2027).
    fixedNow = DateTime(2026, 11, 26, 10, 0);
    harness = LedgerServiceHarness(clock: FixedClock(fixedNow));
    await harness.seedSystemCategories();
  });
  tearDown(() => harness.close());

  DateTime fromNow(int days) =>
      DateTime(fixedNow.year, fixedNow.month, fixedNow.day)
          .add(Duration(days: days));

  Future<void> seedAccountAndCategory(
    CategoryType type, {
    String currencyCode = 'USD',
  }) async {
    await harness.accountService.createAccount(
      commandId: 'cmd_acc',
      name: 'Cash',
      type: AccountType.cash,
      initialBalanceMinor: 100000,
      currencyCode: currencyCode,
    );
    await harness.categoryService.createCategory(
      commandId: 'cmd_cat',
      name: type == CategoryType.income ? 'Salary' : 'Rent',
      iconKey: '1',
      colorInt: 0xFF000000,
      type: type,
    );
  }

  Future<List<ScheduledTransactionEntity>> pending() async =>
      (await harness.recurringService.watchScheduled().first)
          .where((i) => i.status == ScheduledTransactionStatus.scheduled)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  Future<int> createSeries({
    required String frequency,
    required DateTime startDate,
    CategoryType categoryType = CategoryType.expense,
    RecurringSeriesKind kind = RecurringSeriesKind.expense,
    bool materialize = false,
  }) async {
    await seedAccountAndCategory(categoryType);
    final accountId = (await harness.db.accountDao.getAllAccounts()).single.id;
    final categoryId = await harness.userCategoryId();

    final result = await harness.recurringService.createSeries(
      type: kind,
      amountMinor: 50000,
      accountId: accountId,
      categoryId: categoryId,
      description: 'Rent',
      frequency: frequency,
      interval: 1,
      startDate: startDate,
    );
    expect(result, isA<Success<void>>());

    if (materialize) await harness.recurringService.materialize();
    return (await harness.db.recurringDao.watchAllScheduled().first).length;
  }

  for (final kind in ['planned', 'subscription', 'repeating']) {
    test('$kind preserves its scheduled time through posting', () async {
      await seedAccountAndCategory(CategoryType.expense);
      final account = (await harness.db.accountDao.getAllAccounts()).single;
      final day = fromNow(1);
      final start = DateTime(day.year, day.month, day.day, 14, 35);
      final result = await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 100,
        accountId: account.id,
        categoryId: await harness.userCategoryId(),
        description: 'Time check',
        frequency: 'DAILY',
        interval: 1,
        startDate: start,
        endDate: kind == 'planned' ? start : null,
        mode: kind == 'planned'
            ? RecurringSeriesMode.planned
            : RecurringSeriesMode.repeating,
        autoPost: kind == 'subscription',
      );
      expect(result, isA<Success<void>>());
      final bills = await pending();
      expect(bills.first.date, start);
      expect(await harness.recurringService.postInstance(bills.first.id),
          isA<Success<void>>());
      final events = (await harness.eventStore.readAll()).events;
      final recorded = TransactionRecorded.fromJson(events
          .lastWhere((e) => e.eventType == 'TransactionRecorded')
          .payloadJson);
      expect(recorded.occurredAt.toLocal(), start);
    });
  }

  group('Calendar-month-aligned horizon & high-frequency materialization', () {
    test(
        'fixed clock Nov 26: DAILY, WEEKLY, MONTHLY cover full endOfMonth(nowYm + 2) = Jan 31 with no maxKeep=3 cap; YEARLY keeps floor 1; idempotent',
        () async {
      await seedAccountAndCategory(CategoryType.expense);
      final account = (await harness.db.accountDao.getAllAccounts()).single;
      final categoryId = await harness.userCategoryId();

      // DAILY starting Nov 27 -> Nov 27..30 (4) + Dec (31) + Jan (31) = 66 bills.
      final dailyRes = await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 500,
        accountId: account.id,
        categoryId: categoryId,
        description: 'Daily commute',
        frequency: 'DAILY',
        interval: 1,
        startDate: DateTime(2026, 11, 27, 8, 0),
      );
      final dailySeriesId = (dailyRes as Success<String>).value;

      // WEEKLY starting Nov 27 (Fri): 10 Fridays through Jan 29, 2027.
      final weeklyRes = await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 2000,
        accountId: account.id,
        categoryId: categoryId,
        description: 'Weekly groceries',
        frequency: 'WEEKLY',
        interval: 1,
        startDate: DateTime(2026, 11, 27, 9, 0),
      );
      final weeklySeriesId = (weeklyRes as Success<String>).value;

      // MONTHLY starting Nov 28 -> Nov 28, Dec 28, Jan 28 (3 bills).
      final monthlyRes = await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 30000,
        accountId: account.id,
        categoryId: categoryId,
        description: 'Monthly rent',
        frequency: 'MONTHLY',
        interval: 1,
        startDate: DateTime(2026, 11, 28, 9, 0),
      );
      final monthlySeriesId = (monthlyRes as Success<String>).value;

      // YEARLY starting June 1, 2027 (past horizon) -> floor minKeep = 1.
      final yearlyRes = await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 120000,
        accountId: account.id,
        categoryId: categoryId,
        description: 'Annual insurance',
        frequency: 'YEARLY',
        interval: 1,
        startDate: DateTime(2027, 6, 1, 9, 0),
      );
      final yearlySeriesId = (yearlyRes as Success<String>).value;

      final all = await pending();
      final daily = all.where((b) => b.seriesId == dailySeriesId).toList();
      final weekly = all.where((b) => b.seriesId == weeklySeriesId).toList();
      final monthly = all.where((b) => b.seriesId == monthlySeriesId).toList();
      final yearly = all.where((b) => b.seriesId == yearlySeriesId).toList();

      expect(daily, hasLength(66));
      expect(daily.first.occurrenceKey, '2026-11-27');
      expect(daily.last.occurrenceKey, '2027-01-31');

      expect(weekly, hasLength(10));
      expect(weekly.first.occurrenceKey, '2026-11-27');
      expect(weekly.last.occurrenceKey, '2027-01-29');

      expect(monthly.map((b) => b.occurrenceKey).toList(), [
        '2026-11-28',
        '2026-12-28',
        '2027-01-28',
      ]);

      expect(yearly.map((b) => b.occurrenceKey).toList(), ['2027-06-01']);

      // Re-running materialize() is completely idempotent.
      final idsBefore = all.map((b) => b.id).toSet();
      expect(await harness.recurringService.materialize(), 0);
      expect(await harness.recurringService.materialize(), 0);
      final idsAfter = (await pending()).map((b) => b.id).toSet();
      expect(idsAfter, idsBefore);
    });

    test(
        'fixed clock Dec 26 covers through Feb 28 (and Feb 29 in leap year 2028)',
        () async {
      for (final entry in [
        (year: 2026, expectedLast: '2027-02-28', expectedDailyCount: 64),
        (year: 2027, expectedLast: '2028-02-29', expectedDailyCount: 65),
      ]) {
        final h = LedgerServiceHarness(
          clock: FixedClock(DateTime(entry.year, 12, 26, 10, 0)),
        );
        addTearDown(h.close);
        await h.accountService.createAccount(
          commandId: 'acc',
          name: 'Cash',
          type: AccountType.cash,
          initialBalanceMinor: 100000,
          currencyCode: 'USD',
        );
        await h.categoryService.createCategory(
          commandId: 'cat',
          name: 'Coffee',
          iconKey: '1',
          colorInt: 0xFF000000,
          type: CategoryType.expense,
        );
        final accId = (await h.db.accountDao.getAllAccounts()).single.id;
        final catId = (await h.db.categoriesDao.getAllCategories()).single.id;

        await h.recurringService.createSeries(
          type: RecurringSeriesKind.expense,
          amountMinor: 500,
          accountId: accId,
          categoryId: catId,
          description: 'Coffee',
          frequency: 'DAILY',
          interval: 1,
          startDate: DateTime(entry.year, 12, 27, 8, 0),
        );

        final bills = (await h.recurringService.watchScheduled().first)
          ..sort((a, b) => a.date.compareTo(b.date));
        expect(bills, hasLength(entry.expectedDailyCount));
        expect(bills.last.occurrenceKey, entry.expectedLast);
      }
    });

    test('a series starting beyond the window still gets its minKeep=1 floor',
        () async {
      // Two years out: past endOfMonth(nowYm + 2); gets the 1-occurrence floor.
      expect(
        await createSeries(
          frequency: 'MONTHLY',
          startDate: DateTime(2028, 11, 26, 9, 0),
        ),
        1,
      );
    });

    test('respects the 120 upcoming-row safety valve when horizon exceeds 120',
        () async {
      await seedAccountAndCategory(CategoryType.expense);
      final account = (await harness.db.accountDao.getAllAccounts()).single;
      final categoryId = await harness.userCategoryId();

      // Insert directly without running default materialize first.
      await harness.db.recurringDao.saveSeries(
        RecurringSeriesCompanion.insert(
          id: 'safety-daily',
          rrule: 'FREQ=DAILY',
          startDate: DateTime(2026, 11, 27, 9, 0),
          frequency: 'DAILY',
          interval: const Value(1),
          amountMinor: 100,
          description: 'Daily',
          categoryId: categoryId,
          accountId: account.id,
          type: RecurringSeriesKind.expense,
          mode: const Value(RecurringSeriesMode.repeating),
        ),
      );

      // With monthsAhead = 5 (Nov..Apr ~155 days), safety valve caps at 120.
      await ProjectRecurringEventsCommand(
        harness.recurringRepository,
        clock: FixedClock(fixedNow),
        monthsAhead: 5,
      ).execute();

      final rows = await harness.db.recurringDao.scheduledForSeries('safety-daily');
      expect(rows, hasLength(ProjectRecurringEventsCommand.maxUpcomingSafetyValve));
      expect(rows, hasLength(120));
    });
  });

  group('Rules, counts, overrides, and lifecycle', () {
    test('a finite weekly rule generates all selected weekdays in horizon and honors count',
        () async {
      await seedAccountAndCategory(CategoryType.expense);
      final account = (await harness.db.accountDao.getAllAccounts()).single;
      final categoryId = await harness.userCategoryId();
      final start = DateTime(2026, 11, 27, 9, 0); // Friday
      final result = await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 100,
        accountId: account.id,
        categoryId: categoryId,
        description: 'Test',
        frequency: 'WEEKLY',
        interval: 2,
        startDate: start,
        countLimit: 16,
        weekdays: const [DateTime.friday, DateTime.saturday],
      );
      expect(result, isA<Success<void>>());
      final bills = await pending();
      // Every 2 weeks on Fri/Sat from Nov 27 through Jan 31:
      // Nov 27,28; Dec 11,12; Dec 25,26; Jan 8,9; Jan 22,23 = 10 bills.
      expect(bills, hasLength(10));
      expect(
        bills.every((b) =>
            b.date.weekday == DateTime.friday ||
            b.date.weekday == DateTime.saturday),
        isTrue,
      );
      expect(await harness.recurringService.materialize(), 0);
      expect(await pending(), hasLength(10));
    });

    test('a count-limited series does not replenish a skipped occurrence',
        () async {
      await seedAccountAndCategory(CategoryType.expense);
      final account = (await harness.db.accountDao.getAllAccounts()).single;
      final categoryId = await harness.userCategoryId();
      final start = fromNow(1);
      final result = await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 100,
        accountId: account.id,
        categoryId: categoryId,
        description: 'Test',
        frequency: 'DAILY',
        interval: 1,
        startDate: start,
        countLimit: 3,
      );
      expect(result, isA<Success<void>>());
      final before = await pending();
      expect(before, hasLength(3));

      final middle = before[1];
      await harness.recurringService.deleteBill(
        middle.id,
        scope: RecurringScope.thisOnly,
      );
      await harness.recurringService.materialize();

      final after = await pending();
      expect(after, hasLength(2));
      expect(after.map((b) => b.date).toList(), [before[0].date, before[2].date]);
      expect((await harness.db.recurringDao.getScheduled(middle.id))!.status,
          'skipped');
    });

    test('posted, manual, and skipped bills each consume countLimit slots',
        () async {
      await seedAccountAndCategory(CategoryType.expense);
      final account = (await harness.db.accountDao.getAllAccounts()).single;
      final categoryId = await harness.userCategoryId();
      final result = await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 100,
        accountId: account.id,
        categoryId: categoryId,
        description: 'Test',
        frequency: 'DAILY',
        interval: 1,
        startDate: fromNow(1),
        countLimit: 3,
      );
      expect(result, isA<Success<void>>());
      final before = await pending();

      await harness.recurringService.postInstance(before[0].id);
      await harness.db.recurringDao.markManualOnly(before[1].id);
      await harness.recurringService.deleteBill(
        before[2].id,
        scope: RecurringScope.thisOnly,
      );
      await harness.recurringService.materialize();

      final after = await pending();
      expect(after.map((b) => b.date).toList(), [before[1].date]);
      expect((await harness.db.recurringDao.getScheduled(before[0].id))!.status,
          'posted');
      expect((await harness.db.recurringDao.getScheduled(before[2].id))!.status,
          'skipped');
    });

    test('updating a count-limited rule retains its full horizon occurrences',
        () async {
      await seedAccountAndCategory(CategoryType.expense);
      final account = (await harness.db.accountDao.getAllAccounts()).single;
      final categoryId = await harness.userCategoryId();
      final result = await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 100,
        accountId: account.id,
        categoryId: categoryId,
        description: 'Test',
        frequency: 'DAILY',
        interval: 1,
        startDate: DateTime(2026, 11, 27, 9, 0),
        countLimit: 16,
      );
      expect(result, isA<Success<void>>());
      final before = await pending();
      expect(before, hasLength(16));

      final second = before[1];
      final edited = await harness.recurringService.updateBill(
        second.id,
        scope: RecurringScope.updateRule,
        amountMinor: 200,
        date: second.date,
        categoryId: categoryId,
        accountId: account.id,
        description: 'Changed',
      );
      expect(edited, isA<Success<void>>());
      final after = await pending();
      expect(after, hasLength(16));
      expect(after.where((item) => item.amountMinor == 200), hasLength(16));
      final series = (await harness.db.recurringDao.getAllSeries()).single;
      expect(series.countLimit, 16);
      await harness.recurringService.materialize();
      expect(await pending(), hasLength(16));
    });

    test('a date-limited rule materializes all occurrences through inclusive endDate immediately',
        () async {
      await seedAccountAndCategory(CategoryType.expense);
      final account = (await harness.db.accountDao.getAllAccounts()).single;
      final start = DateTime(2026, 11, 27, 14, 0);
      final endDate = DateTime(2026, 12, 1, 9, 0); // earlier time on Dec 1
      final result = await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 100,
        accountId: account.id,
        categoryId: await harness.userCategoryId(),
        description: 'Test',
        frequency: 'DAILY',
        interval: 1,
        startDate: start,
        endDate: endDate,
      );
      expect(result, isA<Success<void>>());
      final bills = await pending();
      expect(
        bills.map((b) => b.occurrenceKey).toList(),
        ['2026-11-27', '2026-11-28', '2026-11-29', '2026-11-30', '2026-12-01'],
      );
    });

    test('materializeFrom skips earlier occurrences while keeping startDate as countLimit anchor',
        () async {
      await seedAccountAndCategory(CategoryType.expense);
      final account = (await harness.db.accountDao.getAllAccounts()).single;
      final categoryId = await harness.userCategoryId();

      // Started 6 months ago (May 1, 2026), countLimit = 8 (May..Dec 2026),
      // materializeFrom = Nov 1, 2026 -> only Nov 1 and Dec 1 materialize.
      final res = await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 10000,
        accountId: account.id,
        categoryId: categoryId,
        description: 'Installment',
        frequency: 'MONTHLY',
        interval: 1,
        startDate: DateTime(2026, 5, 1, 9, 0),
        materializeFrom: DateTime(2026, 11, 1, 0, 0),
        countLimit: 8,
      );
      expect(res, isA<Success<String>>());

      final bills = await pending();
      expect(
        bills.map((b) => b.occurrenceKey).toList(),
        ['2026-11-01', '2026-12-01'],
      );
    });

    test('completedCountOffset reduces materialized count accordingly', () async {
      await seedAccountAndCategory(CategoryType.expense);
      final account = (await harness.db.accountDao.getAllAccounts()).single;
      final categoryId = await harness.userCategoryId();

      await harness.db.recurringDao.saveSeries(
        RecurringSeriesCompanion.insert(
          id: 'offset-series',
          rrule: 'FREQ=MONTHLY;COUNT=5',
          startDate: DateTime(2026, 11, 28, 9, 0),
          materializeFrom: Value(DateTime(2026, 11, 28, 9, 0)),
          countLimit: const Value(5),
          completedCountOffset: const Value(3),
          frequency: 'MONTHLY',
          interval: const Value(1),
          amountMinor: 5000,
          description: 'Offset test',
          categoryId: categoryId,
          accountId: account.id,
          type: RecurringSeriesKind.expense,
          mode: const Value(RecurringSeriesMode.repeating),
        ),
      );

      await harness.recurringService.materialize();
      final bills = await pending();
      expect(
        bills.map((b) => b.occurrenceKey).toList(),
        ['2026-11-28', '2026-12-28'],
      );
    });

    test('reminder setting survives materialization and updating a series',
        () async {
      await seedAccountAndCategory(CategoryType.expense);
      final account = (await harness.db.accountDao.getAllAccounts()).single;
      final category = await harness.userCategoryId();
      final result = await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 100,
        accountId: account.id,
        categoryId: category,
        description: 'Rent',
        frequency: 'DAILY',
        interval: 1,
        startDate: fromNow(1),
        countLimit: 4,
        reminderMinutes: 15,
      );
      expect(result, isA<Success<void>>());
      final bills = await pending();
      expect(
          bills.every((b) => b.recurringTransactionSeries?.reminderMinutes == 15),
          isTrue);
      final edited = await harness.recurringService.updateBill(
        bills[1].id,
        scope: RecurringScope.updateRule,
        amountMinor: 200,
        date: bills[1].date,
        categoryId: category,
        accountId: account.id,
        description: 'Changed',
        reminderMinutes: 15,
      );
      expect(edited, isA<Success<void>>());
      expect(
        (await pending())
            .every((b) => b.recurringTransactionSeries?.reminderMinutes == 15),
        isTrue,
      );
    });

    test('a bill deleted on its own is neither resurrected nor counted',
        () async {
      await createSeries(
        frequency: 'MONTHLY',
        startDate: DateTime(2026, 11, 28, 9, 0),
      );
      final first = (await pending()).first;

      await harness.recurringService
          .deleteBill(first.id, scope: RecurringScope.thisOnly);
      await harness.recurringService.materialize();

      final rows = await harness.db.recurringDao.watchAllScheduled().first;
      final deleted = rows.where((r) => r.id == first.id).toList();
      expect(deleted, hasLength(1));
      expect(deleted.single.status, 'skipped');
    });

    test('an income series materializes across the full 3-month window',
        () async {
      final count = await createSeries(
        frequency: 'MONTHLY',
        startDate: DateTime(2026, 11, 28, 9, 0),
        categoryType: CategoryType.income,
        kind: RecurringSeriesKind.income,
      );
      expect(count, 3);
    });

    test('materializing stays bounded in time', () async {
      await seedAccountAndCategory(CategoryType.expense);
      final accountId = (await harness.db.accountDao.getAllAccounts()).single.id;
      final categoryId = await harness.userCategoryId();
      await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 50000,
        accountId: accountId,
        categoryId: categoryId,
        description: 'Rent',
        frequency: 'DAILY',
        interval: 1,
        startDate: fromNow(1),
      );

      final stopwatch = Stopwatch()..start();
      await harness.recurringService.materialize();
      stopwatch.stop();

      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 10)));
    });

    test('a series deleted via updateRule gains no new instances', () async {
      await createSeries(
        frequency: 'MONTHLY',
        startDate: DateTime(2026, 11, 28, 9, 0),
      );
      final cut = (await pending()).first;

      await harness.recurringService
          .deleteBill(cut.id, scope: RecurringScope.updateRule);
      final afterDelete =
          (await harness.db.recurringDao.watchAllScheduled().first)
              .map((r) => r.id)
              .toSet();

      await harness.recurringService.materialize();

      final afterRoll = (await harness.db.recurringDao.watchAllScheduled().first)
          .map((r) => r.id)
          .toSet();
      expect(afterRoll, afterDelete);
    });

    test('joined repository reads resolve kind, category, account, and support pending/range filters',
        () async {
      await createSeries(
        frequency: 'MONTHLY',
        startDate: DateTime(2026, 11, 28, 9, 0),
      );

      final all = await harness.recurringRepository.watchAllScheduled().first;
      expect(all, hasLength(3));
      final first = all.first;
      expect(first.kind, TransactionKind.expense);
      expect(first.category?.name, 'Rent');
      expect(first.account?.name, 'Cash');
      expect(first.recurringTransactionSeries?.description, 'Rent');

      // Single-row joined fetch populates all metadata too.
      final single =
          await harness.recurringRepository.getScheduledEntity(first.id);
      expect(single, isNotNull);
      expect(single!.category?.name, 'Rent');
      expect(single.account?.name, 'Cash');

      // Range filter for December 2026 returns only the December occurrence.
      final decOnly = await harness.recurringRepository
          .watchScheduledInRange(
            startInclusive: DateTime(2026, 12, 1),
            endExclusive: DateTime(2027, 1, 1),
            currencyCode: 'USD',
            pendingOnly: true,
          )
          .first;
      expect(decOnly.map((b) => b.occurrenceKey).toList(), ['2026-12-28']);

      // Pending-only filter excludes posted rows.
      await harness.recurringService.postInstance(first.id);
      final pendingOnly = await harness.recurringRepository
          .watchPendingScheduled(currencyCode: 'USD')
          .first;
      expect(pendingOnly, hasLength(2));
      expect(pendingOnly.map((b) => b.id), isNot(contains(first.id)));
    });
  });

  group('Overdue backfill, local civil 00:30, and cross-timezone idempotency',
      () {
    test(
        'a dormant daily series materializes missing historical overdue bills',
        () async {
      await seedAccountAndCategory(CategoryType.expense);
      final account = (await harness.db.accountDao.getAllAccounts()).single;
      final start = fromNow(-40);
      final result = await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 100,
        accountId: account.id,
        categoryId: await harness.userCategoryId(),
        description: 'Daily',
        frequency: 'DAILY',
        interval: 1,
        startDate: start,
      );
      expect(result, isA<Success<void>>());

      final bills = await pending();
      final overdue = bills.where((i) => !i.date.isAfter(fixedNow)).toList();

      expect(overdue, hasLength(41));
      expect(overdue.first.date, start);
      expect(overdue.last.date, fromNow(0));
      expect(await harness.recurringService.materialize(), 0);
    });

    test(
        'materialize returns newlyMaterializedOverdueCount only for manual/non-auto-post overdue rows and stays idempotent',
        () async {
      await seedAccountAndCategory(CategoryType.expense);
      final account = (await harness.db.accountDao.getAllAccounts()).single;
      final categoryId = await harness.userCategoryId();

      await harness.db.recurringDao.saveSeries(
        RecurringSeriesCompanion.insert(
          id: 'dormant-manual-series',
          type: RecurringSeriesKind.expense,
          mode: const Value(RecurringSeriesMode.repeating),
          amountMinor: 100,
          accountId: account.id,
          categoryId: categoryId,
          description: 'Daily manual',
          rrule: 'FREQ=DAILY',
          frequency: 'DAILY',
          startDate: fromNow(-40),
          autoPost: const Value(false),
        ),
      );
      await harness.db.recurringDao.saveSeries(
        RecurringSeriesCompanion.insert(
          id: 'dormant-auto-series',
          type: RecurringSeriesKind.expense,
          mode: const Value(RecurringSeriesMode.repeating),
          amountMinor: 100,
          accountId: account.id,
          categoryId: categoryId,
          description: 'Daily auto',
          rrule: 'FREQ=DAILY',
          frequency: 'DAILY',
          startDate: fromNow(-10),
          autoPost: const Value(true),
        ),
      );

      final firstCount = await harness.recurringService.materialize();
      expect(firstCount, 41);
      final secondCount = await harness.recurringService.materialize();
      expect(secondCount, 0);
    });

    test(
        'local 1st at 00:30 (previous month in UTC) produces local 1st occurrenceKeys and cross-timezone re-runs create zero duplicates',
        () async {
      final shanghai = tz.getLocation('Asia/Shanghai');
      final newYork = tz.getLocation('America/New_York');
      final london = tz.getLocation('Europe/London');

      await seedAccountAndCategory(CategoryType.expense);
      final account = (await harness.db.accountDao.getAllAccounts()).single;
      final categoryId = await harness.userCategoryId();

      // Monthly rule at local 2026-11-01 00:30 (in Asia/Shanghai, UTC is Oct 31 16:30).
      final startLocal = DateTime(2026, 11, 1, 0, 30);
      await harness.db.recurringDao.saveSeries(
        RecurringSeriesCompanion.insert(
          id: 'midnight-monthly',
          type: RecurringSeriesKind.expense,
          mode: const Value(RecurringSeriesMode.repeating),
          amountMinor: 5000,
          accountId: account.id,
          categoryId: categoryId,
          description: 'First of month',
          rrule: 'FREQ=MONTHLY',
          frequency: 'MONTHLY',
          interval: const Value(1),
          startDate: startLocal,
        ),
      );

      await ProjectRecurringEventsCommand(
        harness.recurringRepository,
        clock: FixedClock(fixedNow),
        buildDateTime: (y, m, d, h, min, s) =>
            tz.TZDateTime(shanghai, y, m, d, h, min, s),
      ).execute();

      final initial = (await harness.db.recurringDao
          .scheduledForSeries('midnight-monthly'))
        ..sort((a, b) => a.occurrenceKey.compareTo(b.occurrenceKey));

      expect(
        initial.map((r) => r.occurrenceKey).toList(),
        ['2026-11-01', '2026-12-01', '2027-01-01'],
        reason: 'local civil 1st must never shift to UTC Oct 31 / Nov 30',
      );
      final idsBefore = initial.map((r) => r.id).toSet();

      // Re-running under different target zones keeps the same civil keys
      // and inserts zero duplicates.
      await ProjectRecurringEventsCommand(
        harness.recurringRepository,
        clock: FixedClock(fixedNow),
        buildDateTime: (y, m, d, h, min, s) =>
            tz.TZDateTime(newYork, y, m, d, h, min, s),
      ).execute();
      await ProjectRecurringEventsCommand(
        harness.recurringRepository,
        clock: FixedClock(fixedNow),
        buildDateTime: (y, m, d, h, min, s) =>
            tz.TZDateTime(london, y, m, d, h, min, s),
      ).execute();

      final idsAfter =
          (await harness.db.recurringDao.scheduledForSeries('midnight-monthly'))
              .map((r) => r.id)
              .toSet();
      expect(idsAfter, idsBefore);
    });
  });

  group('LedgerServiceHarness + BudgetService end-to-end seam', () {
    test(
        'high-frequency daily expense bills materialized through end of month flow into BudgetService pendingMinor without maxKeep=3 truncation',
        () async {
      final nov10 = DateTime(2026, 11, 10, 9, 0);
      final h = LedgerServiceHarness(clock: FixedClock(nov10));
      addTearDown(h.close);

      await h.accountService.createAccount(
        commandId: 'acc-cny',
        name: 'Cash',
        type: AccountType.cash,
        initialBalanceMinor: 500000,
        currencyCode: 'CNY',
      );
      await h.categoryService.createCategory(
        commandId: 'cat-lunch',
        name: 'Lunch',
        iconKey: 'utensils',
        colorInt: 0xFFE65100,
        type: CategoryType.expense,
      );
      final accId = (await h.db.accountDao.getAllAccounts()).single.id;
      final catId = (await h.db.categoriesDao.getAllCategories()).single.id;

      await h.budgetService.setCategoryBudget(
        currencyCode: 'CNY',
        categoryId: catId,
        month: const YearMonth(2026, 11),
        amountMinor: 50000,
        scope: BudgetEditScope.thisAndFollowing,
      );

      // Daily lunch starting Nov 11 through Nov 30 = 20 remaining days in Nov.
      final res = await h.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 1000,
        accountId: accId,
        categoryId: catId,
        description: 'Lunch',
        frequency: 'DAILY',
        interval: 1,
        startDate: DateTime(2026, 11, 11, 12, 0),
      );
      expect(res, isA<Success<String>>());

      final novBudget = await h.budgetService
          .watchMonthBudget(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 11),
          )
          .first;
      expect(novBudget.budgetedPendingMinor, 20000,
          reason: 'all 20 remaining daily bills in Nov must be counted, not 3');
      expect(novBudget.projectedRemainingMinor, 30000);
    });
  });
}
