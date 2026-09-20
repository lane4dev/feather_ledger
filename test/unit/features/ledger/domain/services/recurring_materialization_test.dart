import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/domain/commands/project_recurring_events_command.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';

import '../../../../../support/event_sourcing/ledger_service_harness.dart';

/// The rolling materialization policy (spec 004, US2).
///
/// A 90-day window clamped to [3, 12] pending instances. The frequency table
/// below is the whole policy in one place; if a number here changes, the
/// user-visible number of upcoming bills changes with it.
void main() {
  late LedgerServiceHarness harness;

  // The correction path files under the seeded system categories; a
  // harness ledger starts empty, so it asks for them the way bootstrap
  // does.
  setUp(() async {
    harness = LedgerServiceHarness();
    await harness.seedSystemCategories();
  });
  tearDown(() => harness.close());

  /// A date roughly [days] from now, as a series start.
  DateTime fromNow(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: days));
  }

  Future<void> seedAccountAndCategory(CategoryType type) async {
    await harness.accountService.createAccount(
      commandId: 'cmd_acc',
      name: 'Cash',
      type: AccountType.cash,
      initialBalanceMinor: 100000,
      currencyCode: 'USD',
    );
    await harness.categoryService.createCategory(
      commandId: 'cmd_cat',
      name: type == CategoryType.income ? 'Salary' : 'Rent',
      iconKey: '1',
      colorInt: 0xFF000000,
      type: type,
    );
  }

  /// Creates a series and returns how many instances it now has.
  ///
  /// [materialize] re-runs the command, which is idempotent — useful for
  /// asserting that a second run changes nothing.
  Future<int> createSeries({
    required String frequency,
    required int startInDays,
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
      startDate: fromNow(startInDays),
    );
    expect(result, isA<Success<void>>());

    if (materialize) await harness.recurringService.materialize();
    return (await harness.db.recurringDao.watchAllScheduled().first).length;
  }

  Future<List<ScheduledTransactionEntity>> pending() async =>
      (await harness.recurringService.watchScheduled().first)
          .where((i) => i.status == ScheduledTransactionStatus.scheduled)
          .toList();

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
          autoPost: kind == 'subscription');
      expect(result, isA<Success<void>>());
      final bills = await pending()
        ..sort((a, b) => a.date.compareTo(b.date));
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

  test('a finite weekly rule generates all selected weekdays and honors count',
      () async {
    await seedAccountAndCategory(CategoryType.expense);
    final account = (await harness.db.accountDao.getAllAccounts()).single;
    final categoryId = await harness.userCategoryId();
    final start = fromNow(1);
    final weekday = start.weekday;
    final other = weekday == 7 ? 1 : weekday + 1;
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
        weekdays: [weekday, other]);
    expect(result, isA<Success<void>>());
    final bills = await pending();
    expect(bills, hasLength(16));
    expect(
        bills
            .every((b) => b.date.weekday == weekday || b.date.weekday == other),
        isTrue);
    await harness.recurringService.materialize();
    expect(await pending(), hasLength(16));
  });

  test('a count-limited series replenishes a deleted occurrence at the tail',
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
        countLimit: 3);
    expect(result, isA<Success<void>>());
    final before = await pending()
      ..sort((a, b) => a.date.compareTo(b.date));
    expect(before, hasLength(3));

    // Deleting the middle occurrence frees one slot; materialization must
    // grow exactly one new occurrence at the tail, without resurrecting the
    // deleted one (spec 006, US37).
    final middle = before[1];
    await harness.recurringService.deleteBill(middle.id,
        scope: RecurringScope.thisOnly);
    await harness.recurringService.materialize();

    final after = await pending()
      ..sort((a, b) => a.date.compareTo(b.date));
    expect(after, hasLength(3),
        reason: 'the freed slot is refilled at the tail');
    expect(
        after.map((b) => b.date).toList(),
        [before[0].date, before[2].date,
         before[2].date.add(const Duration(days: 1))],
        reason: 'kept bills stay, and one new bill follows the last');
    expect((await harness.db.recurringDao.getScheduled(middle.id))!.status,
        'skipped',
        reason: 'the deleted occurrence is a tombstone, not a resurrection');
  });

  test('posted and manual bills still occupy their slot in a count-limited '
      'series', () async {
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
        countLimit: 3);
    expect(result, isA<Success<void>>());
    final before = await pending()
      ..sort((a, b) => a.date.compareTo(b.date));

    await harness.recurringService.postInstance(before[0].id);
    await harness.db.recurringDao.markAutoPostIneligible(before[1].id);
    await harness.recurringService.deleteBill(before[2].id,
        scope: RecurringScope.thisOnly);
    await harness.recurringService.materialize();

    // The posted and manual bills keep two of the three slots; only the
    // deletion frees one, so exactly one new bill appears at the tail.
    final after = await pending()
      ..sort((a, b) => a.date.compareTo(b.date));
    expect(after.map((b) => b.date).toList(),
        [before[1].date, before[2].date.add(const Duration(days: 1))],
        reason: 'manual bill stays, and one slot is refilled at the tail');
    expect((await harness.db.recurringDao.getScheduled(before[0].id))!.status,
        'posted');
    expect((await harness.db.recurringDao.getScheduled(before[2].id))!.status,
        'skipped');
  });

  test('splitting a count-limited rule retains only its remaining occurrences',
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
        countLimit: 16);
    expect(result, isA<Success<void>>());
    final before = await pending()
      ..sort((a, b) => a.date.compareTo(b.date));
    final fourth = before[3];
    final edited = await harness.recurringService.updateBill(fourth.id,
        scope: RecurringScope.thisAndFollowing,
        amountMinor: 200,
        date: fourth.date,
        categoryId: categoryId,
        accountId: account.id,
        description: 'Changed');
    expect(edited, isA<Success<void>>());
    final after = await pending();
    expect(after, hasLength(16));
    expect(after.where((item) => item.amountMinor == 200), hasLength(13));
    await harness.recurringService.materialize();
    expect(await pending(), hasLength(16));
  });

  test('a date-limited rule creates bills through its inclusive end date',
      () async {
    await seedAccountAndCategory(CategoryType.expense);
    final account = (await harness.db.accountDao.getAllAccounts()).single;
    final start = fromNow(1);
    final result = await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 100,
        accountId: account.id,
        categoryId: await harness.userCategoryId(),
        description: 'Test',
        frequency: 'DAILY',
        interval: 1,
        startDate: start,
        endDate: start.add(const Duration(days: 15)));
    expect(result, isA<Success<void>>());
    expect(await pending(), hasLength(16));
  });

  test('reminder setting survives materialization and splitting a series',
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
        reminderMinutes: 15);
    expect(result, isA<Success<void>>());
    final bills = await pending()
      ..sort((a, b) => a.date.compareTo(b.date));
    expect(
        bills.every((b) => b.recurringTransactionSeries?.reminderMinutes == 15),
        isTrue);
    final edited = await harness.recurringService.updateBill(bills[1].id,
        scope: RecurringScope.thisAndFollowing,
        amountMinor: 200,
        date: bills[1].date,
        categoryId: category,
        accountId: account.id,
        description: 'Changed');
    expect(edited, isA<Success<void>>());
    expect(
        (await pending())
            .every((b) => b.recurringTransactionSeries?.reminderMinutes == 15),
        isTrue);
  });

  test('a monthly series keeps three upcoming bills', () async {
    // 90 days holds exactly three monthly occurrences — which is where the
    // "initialise three" number comes from.
    expect(await createSeries(frequency: 'MONTHLY', startInDays: 20), 3);
  });

  test('a weekly series fills the window and stops at twelve', () async {
    // ~13 weekly occurrences fit in 90 days; the cap is 12.
    expect(await createSeries(frequency: 'WEEKLY', startInDays: 3), 12);
  });

  test('a daily series is capped at twelve', () async {
    // 90 daily occurrences would fit; the cap is 12.
    expect(await createSeries(frequency: 'DAILY', startInDays: 1), 12);
  });

  test('a yearly series reaches past the window to meet the floor', () async {
    // The sharp one: a yearly rule starting next year has *nothing* inside
    // the 90-day window, so the window alone would leave the user with zero
    // upcoming bills. The floor reaches forward.
    final count = await createSeries(frequency: 'YEARLY', startInDays: 300);

    expect(count, 3);

    final instances = await pending();
    final dates = instances.map((i) => i.date).toList()..sort();
    // Three consecutive years, not three arbitrary dates.
    expect(dates[1].year - dates[0].year, 1);
    expect(dates[2].year - dates[1].year, 1);
  });

  test('a series starting beyond the window still gets its floor', () async {
    // Two years out: past the window and past the window's extension anchor.
    expect(await createSeries(frequency: 'MONTHLY', startInDays: 730), 3);
  });

  test('materializing twice produces the identical instance set', () async {
    // The derived id '${seriesId}_${date}' is the ONLY thing making this
    // idempotent. Change it, or the date normalization, and every run
    // duplicates every future bill.
    await createSeries(frequency: 'WEEKLY', startInDays: 3);
    final before = (await harness.db.recurringDao.watchAllScheduled().first)
        .map((r) => r.id)
        .toSet();

    await harness.recurringService.materialize();
    await harness.recurringService.materialize();

    final after = (await harness.db.recurringDao.watchAllScheduled().first)
        .map((r) => r.id)
        .toSet();
    expect(after, before);
  });

  test('posting one immediately refills the floor', () async {
    // The rolling part: a bill the user acted on stops counting, so the next
    // run reaches one period further out.
    await createSeries(frequency: 'MONTHLY', startInDays: 5);
    expect(await pending(), hasLength(3));

    final first = (await pending()).first;
    await harness.recurringService.postInstance(first.id);
    expect(await pending(), hasLength(3), reason: 'the floor is restored');
  });

  test('posting a daily bill refills without exceeding twelve pending',
      () async {
    await createSeries(frequency: 'DAILY', startInDays: 1);
    final before = await pending();
    expect(before, hasLength(12));
    expect(await harness.recurringService.postInstance(before.first.id),
        isA<Success<void>>());
    final after = await pending();
    expect(after, hasLength(12));
    expect(after.map((bill) => bill.id).toSet().length, 12);
    expect(after.map((bill) => bill.id), isNot(contains(before.first.id)));
  });

  test('a bill deleted on its own is neither resurrected nor counted',
      () async {
    await createSeries(frequency: 'MONTHLY', startInDays: 5);
    final first = (await pending()).first;

    await harness.recurringService
        .deleteBill(first.id, scope: RecurringScope.thisOnly);
    await harness.recurringService.materialize();

    final rows = await harness.db.recurringDao.watchAllScheduled().first;
    final deleted = rows.where((r) => r.id == first.id).toList();
    expect(deleted, hasLength(1), reason: 'not duplicated');
    expect(deleted.single.status, 'skipped',
        reason: 'the user\'s decision stands; it is not pending again');
  });

  test('an income series materializes the same way', () async {
    final count = await createSeries(
      frequency: 'MONTHLY',
      startInDays: 10,
      categoryType: CategoryType.income,
      kind: RecurringSeriesKind.income,
    );

    expect(count, 3);
  });

  test('materializing stays bounded in time', () async {
    // Guards the `before:` bound passed to getInstances. It is a lazy
    // generator that only stops at `before`, `until`, `count` or year 9999,
    // so filtering its output with a `.where` instead walks ~95,600 monthly
    // steps — ~37 seconds per series, on a command that runs at startup.
    // The bound is loose: the fixed path is well under a second.
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

  test('a series deleted from here on gains no new instances', () async {
    await createSeries(frequency: 'MONTHLY', startInDays: 5);
    final cut = (await pending()).first;

    await harness.recurringService
        .deleteBill(cut.id, scope: RecurringScope.thisAndFollowing);
    final afterDelete =
        (await harness.db.recurringDao.watchAllScheduled().first)
            .map((r) => r.id)
            .toSet();

    await harness.recurringService.materialize();

    final afterRoll = (await harness.db.recurringDao.watchAllScheduled().first)
        .map((r) => r.id)
        .toSet();
    expect(afterRoll, afterDelete,
        reason: 'the rule is ended, so rolling the window adds nothing back');
  });

  test('the projected instances carry a resolved kind and category', () async {
    // The ledger list renders these as rows, so they need more than a date
    // and an amount.
    await createSeries(frequency: 'MONTHLY', startInDays: 5);

    final instance = (await harness.recurringService.watchScheduled().first)
        .firstWhere((i) => i.status == ScheduledTransactionStatus.scheduled);

    expect(instance.kind, TransactionKind.expense);
    expect(instance.category?.name, 'Rent');
    expect(instance.account?.name, 'Cash');
    expect(instance.recurringTransactionSeries?.description, 'Rent');
  });

  test('a dormant daily series materializes every overdue bill, not twelve',
      () async {
    // A series left dormant longer than the 12-upcoming cap still owes every
    // instance that has come due. The rolling window must not hide the debt:
    // every month a bill fell due in must findable in the ledger.
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

    final bills = await pending()
      ..sort((a, b) => a.date.compareTo(b.date));
    final overdue = bills.where((i) => !i.date.isAfter(DateTime.now())).toList();

    expect(overdue.length, greaterThan(12),
        reason: 'every overdue day is materialized, not just the first twelve');
    expect(overdue.first.date, start, reason: 'the debt starts on day one');
    for (var i = 1; i < overdue.length; i++) {
      expect(overdue[i].date.difference(overdue[i - 1].date),
          const Duration(days: 1),
          reason: 'no overdue day is skipped');
    }
  });

  test('re-materializing in another timezone never duplicates a bill',
      () async {
    tzdata.initializeTimeZones();
    final newYork = tz.getLocation('America/New_York');
    final london = tz.getLocation('Europe/London');

    await seedAccountAndCategory(CategoryType.expense);
    final account = (await harness.db.accountDao.getAllAccounts()).single;
    final result = await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 100,
      accountId: account.id,
      categoryId: await harness.userCategoryId(),
      description: 'Daily',
      frequency: 'DAILY',
      interval: 1,
      startDate: fromNow(-5),
    );
    expect(result, isA<Success<void>>());

    final before =
        (await harness.db.recurringDao.watchAllScheduled().first)
            .map((row) => row.id)
            .toSet();

    // Identity is the UTC instant (`seriesId + epoch ms`), not the wall time
    // a zone happens to render it as. Re-running under two different device
    // zones must add nothing — otherwise every trip across a timezone would
    // mint a second bill for the same logical occurrence.
    await ProjectRecurringEventsCommand(
      harness.recurringRepository,
      localize: (u) => tz.TZDateTime.from(u, newYork),
    ).execute();
    await ProjectRecurringEventsCommand(
      harness.recurringRepository,
      localize: (u) => tz.TZDateTime.from(u, london),
    ).execute();

    final after =
        (await harness.db.recurringDao.watchAllScheduled().first)
            .map((row) => row.id)
            .toSet();
    expect(after, before);
  });
}
