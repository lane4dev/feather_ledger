import 'package:flutter_test/flutter_test.dart';

import 'package:drift/drift.dart' show Value;

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';

import '../../../../../support/event_sourcing/ledger_service_harness.dart';
import '../../../../../support/mocks/mock_shared_preferences.dart';

/// The recurring-bill loop (spec 004, US2 / T036).
///
/// `recurring_series` and `scheduled_transactions_view` are the ledger's one
/// deliberately non-event-sourced pair; posting an instance is the single
/// action that crosses into the event store. Everything here goes through
/// [RecurringService] — the same seam the screens use.
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

  /// Rebuilds the harness with the ticket-28 safety gate opened or closed.
  /// The production default (closed) must keep auto-posting disabled; tests
  /// that exercise the posting path itself opt in here.
  Future<void> restartHarness(
      {bool autoPostEnabled = false,
      PreferencesRepository? preferences}) async {
    await harness.close();
    harness = LedgerServiceHarness(
        autoPostEnabled: autoPostEnabled, preferences: preferences);
    await harness.seedSystemCategories();
  }

  /// A preferences repository whose 订阅 auto-post switch is ON (ticket 31:
  /// the switch must be on for a due subscription to post itself), with its
  /// eligibility boundary anchored *before* the fixture's due date.
  Future<PreferencesRepository> prefsWithSubscriptionOn() async {
    final prefs = PreferencesRepositoryImpl(MockSharedPreferences());
    await prefs.setAutoPostEnabled(RecurringSeriesMode.subscription, true);
    // `setAutoPostEnabled` anchors the boundary to now; move it back so a
    // bill due ten days ago is genuinely eligible rather than "already due
    // when the switch turned on".
    await prefs.setAutoPostEnabledSince(RecurringSeriesMode.subscription,
        DateTime.now().subtract(const Duration(days: 30)));
    return prefs;
  }

  late String accountId;
  late String expenseCategoryId;
  late String incomeCategoryId;

  Future<void> seed() async {
    await harness.accountService.createAccount(
      commandId: 'cmd_acc',
      name: 'Cash',
      type: AccountType.cash,
      initialBalanceMinor: 100000,
      currencyCode: 'USD',
    );
    await harness.categoryService.createCategory(
      commandId: 'cmd_cat_expense',
      name: 'Rent',
      iconKey: '1',
      colorInt: 0xFF000000,
      type: CategoryType.expense,
    );
    await harness.categoryService.createCategory(
      commandId: 'cmd_cat_income',
      name: 'Salary',
      iconKey: '2',
      colorInt: 0xFF000000,
      type: CategoryType.income,
    );
    final accounts = await harness.db.accountDao.getAllAccounts();
    accountId = accounts.single.id;
    final categories = await harness.db.categoriesDao.getAllCategories();
    expenseCategoryId = categories.firstWhere((c) => c.name == 'Rent').id;
    incomeCategoryId = categories.firstWhere((c) => c.name == 'Salary').id;
  }

  /// A monthly series starting well in the past, so it has due instances.
  Future<Result<void>> createMonthly({
    int amountMinor = 50000,
    RecurringSeriesKind type = RecurringSeriesKind.expense,
    CategoryType categoryType = CategoryType.expense,
    DateTime? endDate,
    bool autoPost = false,
  }) {
    return harness.recurringService.createSeries(
      type: type,
      amountMinor: amountMinor,
      accountId: accountId,
      categoryId: categoryType == CategoryType.expense
          ? expenseCategoryId
          : incomeCategoryId,
      description: 'Rent',
      frequency: 'MONTHLY',
      interval: 1,
      startDate: DateTime(2026, 1, 1),
      endDate: endDate,
      autoPost: autoPost,
    );
  }

  /// A monthly series starting well in the future, so none of its bills are
  /// due yet (and none were "already due at creation").
  Future<Result<void>> createFutureMonthly({int amountMinor = 50000}) {
    return harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: amountMinor,
      accountId: accountId,
      categoryId: expenseCategoryId,
      description: 'Rent',
      frequency: 'MONTHLY',
      interval: 1,
      startDate: DateTime.now().add(const Duration(days: 30)),
    );
  }

  /// Re-arms [id]'s auto-post eligibility in the CRUD-exempt table.
  /// Used to simulate a series that existed before its bill came due (spec
  /// 006, US32 latches such bills at creation).
  Future<void> rearmEligible(String id) async {
    final row = await harness.db.recurringDao.getScheduled(id);
    await harness.db.recurringDao.insertOrUpdateScheduled(
      ScheduledTransactionsViewCompanion(
        id: Value(row!.id),
        seriesId: Value(row.seriesId),
        date: Value(row.date),
        amountMinor: Value(row.amountMinor),
        status: Value(row.status),
        transactionId: Value(row.transactionId),
        autoPostEligible: const Value(true),
      ),
    );
  }

  Future<List<ScheduledTransactionEntity>> scheduled() =>
      harness.recurringService.watchScheduled().first;

  Future<Set<String>> scheduledIds() async =>
      (await harness.db.recurringDao.watchAllScheduled().first)
          .map((row) => row.id)
          .toSet();

  Future<ScheduledTransactionEntity> firstScheduled() async =>
      (await scheduled())
          .firstWhere((s) => s.status == ScheduledTransactionStatus.scheduled);

  Future<int> accountBalance() async =>
      (await harness.db.accountDao.getAccountById(accountId))!.balanceMinor;

  /// The series row, read straight from the CRUD-exempt table.
  Future<RecurringSeriesRow> seriesRow() async =>
      (await harness.db.recurringDao.getAllSeries()).single;

  test('creating a series stores it and materializes its instances', () async {
    await seed();

    final result = await createMonthly();
    expect(result, isA<Success<void>>());

    // Stored with the values that were asked for.
    final row = await seriesRow();
    expect(row.frequency, 'MONTHLY');
    expect(row.interval, 1);
    expect(row.amountMinor, 50000);
    expect(row.accountId, accountId);
    expect(row.categoryId, expenseCategoryId);
    expect(row.endDate, isNull);
    expect(row.type, RecurringSeriesKind.expense);

    // And immediately visible as pending instances, not only after a restart.
    final instances = await scheduled();
    expect(instances, isNotEmpty);
    expect(
      instances.every((i) => i.status == ScheduledTransactionStatus.scheduled),
      isTrue,
    );
    expect(instances.every((i) => i.amountMinor == 50000), isTrue);
    expect(
        instances.every((i) => i.recurringTransactionSeries != null), isTrue);
  });

  test('a series persists its creation mode (计划/订阅/重复)', () async {
    await seed();

    // 计划: one-shot, startDate == endDate.
    await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 100,
      accountId: accountId,
      categoryId: expenseCategoryId,
      description: 'Plan',
      frequency: 'MONTHLY',
      interval: 1,
      startDate: DateTime(2027, 1, 1),
      endDate: DateTime(2027, 1, 1),
      mode: RecurringSeriesMode.planned,
    );
    // 重复: recurring, manual confirm.
    await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 200,
      accountId: accountId,
      categoryId: expenseCategoryId,
      description: 'Repeat',
      frequency: 'MONTHLY',
      interval: 1,
      startDate: DateTime(2026, 1, 1),
      mode: RecurringSeriesMode.repeating,
    );
    // 订阅: recurring, auto-post.
    await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 300,
      accountId: accountId,
      categoryId: expenseCategoryId,
      description: 'Subscribe',
      frequency: 'MONTHLY',
      interval: 1,
      startDate: DateTime(2026, 1, 1),
      autoPost: true,
      mode: RecurringSeriesMode.subscription,
    );

    final rows = await harness.db.recurringDao.getAllSeries();
    final byDescription = {for (final r in rows) r.description: r};
    expect(byDescription['Plan']!.mode, RecurringSeriesMode.planned);
    expect(byDescription['Repeat']!.mode, RecurringSeriesMode.repeating);
    expect(byDescription['Subscribe']!.mode, RecurringSeriesMode.subscription);
  });

  test('watchScheduled scopes to one currency', () async {
    await seed();
    await harness.accountService.createAccount(
      commandId: 'cmd_yuan',
      name: 'Yuan',
      type: AccountType.cash,
      initialBalanceMinor: 0,
      currencyCode: 'CNY',
    );
    final accounts = await harness.db.accountDao.getAllAccounts();
    final cnyId = accounts.firstWhere((a) => a.name == 'Yuan').id;

    // A USD series (via createMonthly) and a CNY series side by side.
    await createMonthly();
    await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 30000,
      accountId: cnyId,
      categoryId: expenseCategoryId,
      description: 'Yuan bill',
      frequency: 'MONTHLY',
      interval: 1,
      startDate: DateTime(2026, 1, 1),
      endDate: null,
      autoPost: false,
    );

    final usd =
        await harness.recurringService.watchScheduled(currencyCode: 'USD').first;
    expect(usd, isNotEmpty);
    expect(usd.every((s) => s.account?.currencyCode == 'USD'), isTrue);

    final cny =
        await harness.recurringService.watchScheduled(currencyCode: 'CNY').first;
    expect(cny, isNotEmpty);
    expect(cny.every((s) => s.account?.currencyCode == 'CNY'), isTrue);
  });

  test('creating a series writes no event', () async {
    await seed();
    final before = (await harness.eventStore.readAll()).events.length;

    await createMonthly();

    expect((await harness.eventStore.readAll()).events.length, before,
        reason: 'the recurring tables are CRUD-exempt by design');
  });

  test('materializing stays bounded in time', () async {
    // Guards the `before:` bound passed to getInstances. It is a lazy
    // generator that only stops at `before`, `until`, `count` or year 9999,
    // so filtering its output with a `.where` instead walks ~95,600 monthly
    // steps to find the ~20 inside the horizon — measured at ~37 seconds per
    // series. This command now runs on every app launch, where that is an
    // app that never opens.
    //
    // The bound is deliberately loose: the fixed path is well under a second,
    // so this only fires on a real regression, never on a slow machine.
    await seed();

    final stopwatch = Stopwatch()..start();
    await createMonthly();
    stopwatch.stop();

    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 10)));
  });

  test('materializing twice produces the identical instance set', () async {
    // SC-004. The derived id '${seriesId}_${date.millisecondsSinceEpoch}' is
    // the ONLY thing making materialization idempotent: change the series id
    // or the date normalization and every instance duplicates, silently
    // doubling every future bill.
    await seed();
    await createMonthly();

    final first = await scheduledIds();
    await harness.recurringService.materialize();
    await harness.recurringService.materialize();
    final second = await scheduledIds();

    expect(second, first);
    expect(second.length, first.length, reason: 'no duplicates');
  });

  test('even a far-future series gets its floor of instances', () async {
    // Every valid series now has at least one instance, because the floor
    // reaches past the window. That is why nothing needs to list series
    // separately to keep an instance-less one visible.
    await seed();
    final result = await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 100,
      accountId: accountId,
      categoryId: expenseCategoryId,
      description: 'Far future',
      frequency: 'MONTHLY',
      interval: 1,
      startDate: DateTime(2099, 1, 1),
    );
    expect(result, isA<Success<void>>());

    expect(await scheduledIds(), hasLength(3));
  });

  test('a category of the wrong kind is refused at creation', () async {
    await seed();

    final result = await harness.recurringService.createSeries(
      type: RecurringSeriesKind.income,
      amountMinor: 50000,
      accountId: accountId,
      categoryId: expenseCategoryId, // an expense category
      description: 'Salary',
      frequency: 'MONTHLY',
      interval: 1,
      startDate: DateTime(2026, 1, 1),
    );

    expect(
      result,
      isA<Failure<void>>()
          .having((f) => f.code, 'code', LedgerErrorCode.categoryTypeMismatch),
    );
    expect(await harness.db.recurringDao.getAllSeries(), isEmpty);
  });

  test('an end date before the start is refused', () async {
    await seed();

    final result = await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 100,
      accountId: accountId,
      categoryId: expenseCategoryId,
      description: 'Nonsense',
      frequency: 'MONTHLY',
      interval: 1,
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2025, 12, 31),
    );

    expect(result, isA<Failure<void>>());
    expect(await harness.db.recurringDao.getAllSeries(), isEmpty);
  });

  test('a one-shot series (计划) materializes exactly one instance', () async {
    await seed();

    // startDate == endDate is the 计划 shape: UNTIL is inclusive, so the rule
    // yields its own start date and nothing else — the far-future date is no
    // obstacle, the floor anchors at the series' own start.
    final result = await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 100,
      accountId: accountId,
      categoryId: expenseCategoryId,
      description: 'Planned bill',
      frequency: 'MONTHLY',
      interval: 1,
      startDate: DateTime(2027, 1, 1),
      endDate: DateTime(2027, 1, 1),
    );

    expect(result, isA<Success<void>>());
    final instances = await scheduled();
    expect(instances, hasLength(1));
    final only = instances.single;
    expect(only.status, ScheduledTransactionStatus.scheduled);
    expect(only.date, DateTime(2027, 1, 1));

    // A second run adds nothing: the derived id is the whole idempotency.
    await harness.recurringService.materialize();
    expect(await scheduledIds(), {only.id});
  });

  test('posting an instance records one transaction and flips its status',
      () async {
    await seed();
    await createMonthly();
    final instance = await firstScheduled();
    final eventsBefore = (await harness.eventStore.readAll()).events.length;

    final result = await harness.recurringService.postInstance(instance.id);
    expect(result, isA<Success<void>>());

    // One event, and it is the ledger's own TransactionRecorded.
    final events = (await harness.eventStore.readAll()).events;
    expect(events.length, eventsBefore + 1);
    expect(events.last.eventType, 'TransactionRecorded');
    final recorded = TransactionRecorded.fromJson(events.last.payloadJson);
    expect(recorded.kind, TransactionKind.expense);
    expect(recorded.postings.single.amountMinor, 50000);

    // The status flip rode the same append.
    final row = await harness.db.recurringDao.getScheduled(instance.id);
    expect(row!.status, 'posted');
    expect(row.transactionId, recorded.transactionId);

    // And the balance actually moved.
    expect(await accountBalance(), 100000 - 50000);
  });

  test('posting an already-posted instance is refused with its own code',
      () async {
    await seed();
    await createMonthly();
    final instance = await firstScheduled();
    await harness.recurringService.postInstance(instance.id);

    final result = await harness.recurringService.postInstance(instance.id);

    expect(
      result,
      isA<Failure<void>>().having(
          (f) => f.code, 'code', LedgerErrorCode.scheduledAlreadyPosted),
      reason: 'this used to report transactionAlreadyReversed, which told the '
          'user their transaction had been reversed',
    );
  });

  test('concurrent post and skip cannot both succeed', () async {
    await seed();
    await createMonthly();
    final instance = await firstScheduled();
    final before = (await harness.eventStore.readAll()).events.length;
    final results = await Future.wait([
      harness.recurringService.postInstance(instance.id),
      harness.recurringService
          .deleteBill(instance.id, scope: RecurringScope.thisOnly),
    ]);
    expect(results.whereType<Success<void>>(), hasLength(1));
    final row = (await harness.db.recurringDao.getScheduled(instance.id))!;
    final added = (await harness.eventStore.readAll()).events.length - before;
    expect(
        row.status == 'posted'
            ? added == 1
            : row.status == 'skipped' && added == 0,
        isTrue);
  });

  test('a skipped instance cannot be posted or resurrected', () async {
    await seed();
    await createMonthly();
    final instance = await firstScheduled();
    final skipped = await harness.recurringService
        .deleteBill(instance.id, scope: RecurringScope.thisOnly);
    expect(skipped, isA<Success<void>>());
    final eventsBefore = (await harness.eventStore.readAll()).events.length;
    final posted = await harness.recurringService.postInstance(instance.id);
    expect(posted, isA<Failure<void>>());
    expect((await harness.db.recurringDao.getScheduled(instance.id))!.status,
        'skipped');
    expect((await harness.eventStore.readAll()).events.length, eventsBefore);
  });

  test('deleting one bill writes no event and moves no money', () async {
    await seed();
    await createMonthly();
    final instance = await firstScheduled();
    final eventsBefore = (await harness.eventStore.readAll()).events.length;
    final balanceBefore = await accountBalance();

    final result = await harness.recurringService
        .deleteBill(instance.id, scope: RecurringScope.thisOnly);

    expect(result, isA<Success<void>>());
    // The row stays, marked `skipped`: that status is the tombstone
    // materialization refuses to re-create, and a bill that came back would
    // be worse than one that never left.
    expect((await harness.db.recurringDao.getScheduled(instance.id))!.status,
        'skipped');
    expect((await harness.eventStore.readAll()).events.length, eventsBefore);
    expect(await accountBalance(), balanceBefore);
  });

  test('deleting one bill neither returns nor takes its neighbours', () async {
    await seed();
    await createMonthly();
    final before = await scheduledIds();
    final instance = await firstScheduled();

    await harness.recurringService
        .deleteBill(instance.id, scope: RecurringScope.thisOnly);
    await harness.recurringService.materialize();

    expect(await scheduledIds(), before,
        reason: 'nothing resurrected, nothing else removed');
    expect((await seriesRow()).endDate, isNull,
        reason: 'the rule carries on producing the other bills');
  });

  test('deleting an already-recorded instance is refused', () async {
    await seed();
    await createMonthly();
    final instance = await firstScheduled();
    await harness.recurringService.postInstance(instance.id);

    final result = await harness.recurringService
        .deleteBill(instance.id, scope: RecurringScope.thisOnly);

    expect(
      result,
      isA<Failure<void>>().having(
          (f) => f.code, 'code', LedgerErrorCode.scheduledAlreadyPosted),
    );
  });

  test('acting on an unknown instance is refused', () async {
    await seed();

    expect(
      await harness.recurringService.postInstance('nope'),
      isA<Failure<void>>()
          .having((f) => f.code, 'code', LedgerErrorCode.transactionNotFound),
    );
    expect(
      await harness.recurringService
          .deleteBill('nope', scope: RecurringScope.thisOnly),
      isA<Failure<void>>()
          .having((f) => f.code, 'code', LedgerErrorCode.transactionNotFound),
    );
  });

  test('deleting this and following ends the series there', () async {
    await seed();
    await createMonthly();
    final pending = (await scheduled())
        .where((s) => s.status == ScheduledTransactionStatus.scheduled)
        .toList();
    expect(pending.length, greaterThan(3), reason: 'fixture precondition');
    final cut = pending[2];

    final result = await harness.recurringService
        .deleteBill(cut.id, scope: RecurringScope.thisAndFollowing);

    expect(result, isA<Success<void>>());
    // A day earlier, because `until` is inclusive — ending on the bill's own
    // date would let the next run materialize it straight back.
    expect((await seriesRow()).endDate,
        DateTime(cut.date.year, cut.date.month, cut.date.day - 1));

    final survivors = (await scheduled()).map((s) => s.id).toSet();
    for (final earlier in pending.sublist(0, 2)) {
      expect(survivors, contains(earlier.id),
          reason: 'bills before the cut are untouched');
    }
    for (final fromHere in pending.sublist(2)) {
      expect(survivors, isNot(contains(fromHere.id)),
          reason: 'the bill deleted and every later one are gone');
    }
  });

  test('a series ended by a delete materializes nothing further', () async {
    await seed();
    await createMonthly();
    final cut = (await scheduled())
        .firstWhere((s) => s.status == ScheduledTransactionStatus.scheduled);

    await harness.recurringService
        .deleteBill(cut.id, scope: RecurringScope.thisAndFollowing);

    final afterDelete = await scheduledIds();
    await harness.recurringService.materialize();

    expect(await scheduledIds(), afterDelete,
        reason: 'the rule is ended, so the window rolls forward in place');
  });

  test('deleting this and following keeps bills already recorded', () async {
    await seed();
    await createMonthly();
    final pending = (await scheduled())
        .where((s) => s.status == ScheduledTransactionStatus.scheduled)
        .toList();
    // Record a later bill first: money that moved outlives the schedule.
    final recorded = pending.last;
    await harness.recurringService.postInstance(recorded.id);
    final balanceAfterPost = await accountBalance();

    await harness.recurringService
        .deleteBill(pending.first.id, scope: RecurringScope.thisAndFollowing);

    expect(await accountBalance(), balanceAfterPost,
        reason: 'a recorded bill is not a pending bill');
    expect((await harness.db.recurringDao.getScheduled(recorded.id))!.status,
        'posted');
  });

  test('deleting all removes the series and its schedule, keeping the ledger',
      () async {
    await seed();
    await createMonthly();
    final pending = (await scheduled())
        .where((s) => s.status == ScheduledTransactionStatus.scheduled)
        .toList();
    await harness.recurringService.postInstance(pending.last.id);
    final balanceAfterPost = await accountBalance();
    final eventsAfterPost = (await harness.eventStore.readAll()).events.length;
    final cut = pending.first;

    final result = await harness.recurringService
        .deleteBill(cut.id, scope: RecurringScope.all);

    expect(result, isA<Success<void>>());
    expect(await harness.db.recurringDao.getAllSeries(), isEmpty);
    expect(await harness.db.recurringDao.watchAllScheduled().first, isEmpty,
        reason: 'every instance row goes with the series');
    // The bill that was recorded is untouched: it is a TransactionRecorded
    // event, not a row in the schedule.
    expect(await accountBalance(), balanceAfterPost);
    expect((await harness.eventStore.readAll()).events.length, eventsAfterPost);
  });

  test('deleting this and following leaves the rest of the rule intact',
      () async {
    await seed();
    await createMonthly();
    final cut = (await scheduled())
        .firstWhere((s) => s.status == ScheduledTransactionStatus.scheduled);

    await harness.recurringService
        .deleteBill(cut.id, scope: RecurringScope.thisAndFollowing);

    final series = await seriesRow();

    expect(series.frequency, 'MONTHLY');
    expect(series.interval, 1);
    expect(series.amountMinor, 50000);
    expect(series.accountId, accountId);
    expect(series.categoryId, expenseCategoryId);
  });

  // — editing (spec 004, US2) ————————————————————————————————————————————

  /// Edits [instance] at [scope]. The series-scoped fields default to the
  /// series' own values, which is what the form sends for `thisOnly` (a single
  /// row has nowhere to keep a category or an account).
  Future<Result<void>> editBill(
    ScheduledTransactionEntity instance, {
    required RecurringScope scope,
    int? amountMinor,
    DateTime? date,
    String description = 'Rent',
  }) =>
      harness.recurringService.updateBill(
        instance.id,
        scope: scope,
        amountMinor: amountMinor ?? instance.amountMinor,
        date: date ?? instance.date,
        categoryId: expenseCategoryId,
        accountId: accountId,
        description: description,
      );

  test('editing one bill changes its amount and nothing else', () async {
    await seed();
    await createMonthly();
    final instance = await firstScheduled();
    final before = await scheduledIds();
    final events = (await harness.eventStore.readAll()).events.length;

    final result = await editBill(instance,
        scope: RecurringScope.thisOnly, amountMinor: 60000);

    expect(result, isA<Success<void>>());
    final edited = (await scheduled()).firstWhere((s) => s.id == instance.id);
    expect(edited.amountMinor, 60000);
    expect(await scheduledIds(), before, reason: 'no row added or removed');
    expect((await seriesRow()).amountMinor, 50000,
        reason: 'the rule is untouched, so the other bills keep 50000');
    expect((await harness.eventStore.readAll()).events.length, events,
        reason: 'editing a forecast moves no money');
  });

  test('moving one bill leaves a tombstone the window cannot refill', () async {
    await seed();
    await createMonthly();
    final instance = await firstScheduled();
    final moved = DateTime(2026, 2, 15);

    final result =
        await editBill(instance, scope: RecurringScope.thisOnly, date: moved);
    expect(result, isA<Success<void>>());

    // The rule still produces the original date; a skipped row is what stops
    // materialization from putting the bill back where it was.
    final original = await harness.db.recurringDao.getScheduled(instance.id);
    expect(original!.status, 'skipped');

    await harness.recurringService.materialize();
    final onNewDate = (await scheduled()).where((s) =>
        s.date.year == moved.year &&
        s.date.month == moved.month &&
        s.date.day == moved.day);
    expect(onNewDate, hasLength(1), reason: 'the bill exists on its new day');
    expect(onNewDate.single.amountMinor, instance.amountMinor);

    // And the original day is not billed again — this is the failure that
    // would show the user a bill they had just moved, twice.
    final backOnOldDate = (await scheduled()).where((s) =>
        s.status == ScheduledTransactionStatus.scheduled &&
        s.date.year == instance.date.year &&
        s.date.month == instance.date.month &&
        s.date.day == instance.date.day);
    expect(backOnOldDate, isEmpty);
  });

  test('moving a bill onto a day that already has one is refused', () async {
    await seed();
    await createMonthly();
    final all = await scheduled();
    final first = all.first;
    final second = all[1];

    // Same series, a date the rule already bills: allowing it would put two
    // bills on one day, one of them invisible to materialization.
    final result = await editBill(first,
        scope: RecurringScope.thisOnly, date: second.date);

    expect(
      result,
      isA<Failure<void>>()
          .having((f) => f.code, 'code', LedgerErrorCode.scheduledDateTaken),
    );
  });

  test('editing this and following splits the rule in two', () async {
    await seed();
    await createMonthly();
    final all = await scheduled();
    final cut = all[2];

    final result = await editBill(cut,
        scope: RecurringScope.thisAndFollowing,
        amountMinor: 60000,
        date: DateTime(2026, 3, 15),
        description: 'Rent, raised');

    expect(result, isA<Success<void>>());

    // The old rule stops the day before the bill it lost, so it cannot bill
    // that date again.
    final series = await harness.db.recurringDao.getAllSeries();
    expect(series, hasLength(2));
    final old = series.firstWhere((s) => s.id == cut.seriesId);
    // Relative to the cut, not a literal date: which day the cut lands on is
    // the rule's business, and the contract is only "the day before it".
    expect(
        old.endDate, DateTime(cut.date.year, cut.date.month, cut.date.day - 1),
        reason: 'the old rule ends the day before the bill it lost');

    final fresh = series.firstWhere((s) => s.id != cut.seriesId);
    expect(fresh.amountMinor, 60000);
    expect(fresh.description, 'Rent, raised');
    expect(fresh.startDate, DateTime(2026, 3, 15));

    // Bills before the cut belong to the old rule and are untouched; bills
    // from the cut on are the new rule's, at the new amount.
    final after = await scheduled();
    final kept = after.where((s) => s.id == all[0].id || s.id == all[1].id);
    expect(kept, hasLength(2));
    expect(kept.every((s) => s.amountMinor == 50000), isTrue);
    final raised = after.where((s) => s.seriesId == fresh.id);
    expect(raised, isNotEmpty);
    expect(raised.every((s) => s.amountMinor == 60000), isTrue);
  });

  test('a split does not bill again for one already recorded', () async {
    await seed();
    await createMonthly();
    final all = await scheduled();
    // Record a later bill, then split from an earlier one: the new rule must
    // not produce a second bill for the day that money already moved.
    final recorded = all.last;
    await harness.recurringService.postInstance(recorded.id);
    final balance = await accountBalance();

    await editBill(all.first,
        scope: RecurringScope.thisAndFollowing, amountMinor: 60000);

    final clash = (await scheduled()).where((s) =>
        s.seriesId != all.first.seriesId &&
        s.date.year == recorded.date.year &&
        s.date.month == recorded.date.month &&
        s.date.day == recorded.date.day);
    expect(clash, hasLength(1));
    expect(clash.single.status, ScheduledTransactionStatus.skipped,
        reason: 'a tombstone, not a bill');
    expect(await accountBalance(), balance,
        reason: 'the recorded movement is untouched');
  });

  test('a split keeps a manual bill in the range manual', () async {
    await seed();
    await createMonthly();
    final bills = (await scheduled()).toList();
    final cut = bills[1];
    final later = bills[2];
    await harness.db.recurringDao.markAutoPostIneligible(later.id);

    await editBill(cut,
        scope: RecurringScope.thisAndFollowing,
        amountMinor: 60000,
        date: DateTime(2026, 2, 3));

    // The Apr 1 manual bill rides into the new series at its shifted date,
    // still manual — the split must not re-derive its eligibility fresh.
    final moved = (await scheduled())
        .where((s) =>
            s.date.year == 2026 && s.date.month == 4 && s.date.day == 3)
        .toList();
    expect(moved, hasLength(1));
    expect(moved.single.autoPostEligible, isFalse,
        reason: 'the manual latch survives the split');
    expect(moved.single.amountMinor, 60000,
        reason: 'the edited amount applies to the range');
  });

  test('editing all rewrites the rule and rebuilds the pending bills',
      () async {
    await seed();
    await createMonthly();
    final instance = await firstScheduled();

    final result =
        await editBill(instance, scope: RecurringScope.all, amountMinor: 60000);

    expect(result, isA<Success<void>>());
    final series = await seriesRow();
    expect(series.amountMinor, 60000);
    expect(series.startDate, DateTime(2026, 1, 1), reason: 'date unchanged');

    final pending = (await scheduled())
        .where((s) => s.status == ScheduledTransactionStatus.scheduled);
    expect(pending, isNotEmpty);
    expect(pending.every((s) => s.amountMinor == 60000), isTrue,
        reason: 'every pending bill picked up the new amount');
  });

  test('editing all moves the whole schedule when the date moves', () async {
    await seed();
    await createMonthly();
    final instance = await firstScheduled();

    // The rent came on the 1st; it now comes on the 4th — every month.
    final result = await editBill(instance,
        scope: RecurringScope.all, date: DateTime(2026, 1, 4));

    expect(result, isA<Success<void>>());
    expect((await seriesRow()).startDate, DateTime(2026, 1, 4));

    final pending = (await scheduled())
        .where((s) => s.status == ScheduledTransactionStatus.scheduled)
        .toList();
    expect(pending, isNotEmpty);
    expect(pending.every((s) => s.date.day == 4), isTrue,
        reason: 'the day of the month moved for every bill');
  });

  test('editing all leaves recorded bills alone', () async {
    await seed();
    await createMonthly();
    final instance = await firstScheduled();
    final other = (await scheduled())[1];
    await harness.recurringService.postInstance(other.id);
    final balance = await accountBalance();
    final events = (await harness.eventStore.readAll()).events.length;

    await editBill(instance, scope: RecurringScope.all, amountMinor: 60000);

    expect(await accountBalance(), balance);
    expect((await harness.eventStore.readAll()).events.length, events);
    expect((await harness.db.recurringDao.getScheduled(other.id))!.status,
        'posted');
    expect((await harness.db.recurringDao.getScheduled(other.id))!.amountMinor,
        50000,
        reason: 'what was recorded stays what was recorded');
  });

  test(
      'editing all keeps manual bills manual and tombstones recorded bills '
      'when the date moves', () async {
    await seed();
    await createMonthly();
    final bills = (await scheduled())
        .where((s) => s.status == ScheduledTransactionStatus.scheduled)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final january = bills.first; // Jan 1
    final february = bills.firstWhere((s) => s.date.month == 2); // Feb 1
    final april = bills.firstWhere((s) => s.date.month == 4); // Apr 1

    // Jan 1 moved its money; Feb 1 and Apr 1 are latched manual (create-time
    // latch already did it, but be explicit — the test is about the shift).
    await harness.recurringService.postInstance(january.id);
    await harness.db.recurringDao.markAutoPostIneligible(february.id);
    await harness.db.recurringDao.markAutoPostIneligible(april.id);
    final events = (await harness.eventStore.readAll()).events.length;

    // Move Feb 1 → Feb 3; the whole schedule follows by +2 days.
    final result = await editBill(february,
        scope: RecurringScope.all, date: DateTime(2026, 2, 3));
    expect(result, isA<Success<void>>());

    final series = await seriesRow();
    final jan3 = await harness.db.recurringDao
        .getScheduled(scheduledInstanceId(series.id, DateTime(2026, 1, 3)));
    final feb3 = await harness.db.recurringDao
        .getScheduled(scheduledInstanceId(series.id, DateTime(2026, 2, 3)));
    final apr3 = await harness.db.recurringDao
        .getScheduled(scheduledInstanceId(series.id, DateTime(2026, 4, 3)));

    // The recorded Jan 1 transaction stays put; the shifted rule must not
    // bill Jan 3, because that occurrence already moved its money.
    expect((await harness.db.recurringDao.getScheduled(january.id))!.status,
        'posted');
    expect(jan3, isNotNull);
    expect(jan3!.status, 'skipped');

    // The manual bills moved with their occurrences and stayed manual.
    expect(feb3, isNotNull);
    expect(feb3!.autoPostEligible, isFalse);
    expect(apr3, isNotNull);
    expect(apr3!.autoPostEligible, isFalse);

    // Nothing new was posted by the edit.
    expect((await harness.eventStore.readAll()).events.length, events);
  });

  test('editing an already-recorded bill is refused', () async {
    await seed();
    await createMonthly();
    final instance = await firstScheduled();
    await harness.recurringService.postInstance(instance.id);

    final result = await editBill(instance,
        scope: RecurringScope.thisOnly, amountMinor: 60000);

    expect(
      result,
      isA<Failure<void>>().having(
          (f) => f.code, 'code', LedgerErrorCode.scheduledAlreadyPosted),
    );
  });

  test('an income series posts a credit', () async {
    await seed();
    await createMonthly(
      amountMinor: 300000,
      type: RecurringSeriesKind.income,
      categoryType: CategoryType.income,
    );
    final instance = await firstScheduled();

    await harness.recurringService.postInstance(instance.id);

    final recorded = TransactionRecorded.fromJson(
        (await harness.eventStore.readAll()).events.last.payloadJson);
    expect(recorded.kind, TransactionKind.income);
    expect(await accountBalance(), 100000 + 300000);
  });

  // — 订阅 auto-post ——————————————————————————————————————————————————————

  /// An auto-posting monthly series started ten days ago: one due instance
  /// (its start) and several ahead, which is the catch-up's whole question.
  Future<Result<void>> createAutoPostingSeries({int amountMinor = 20000}) {
    return harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: amountMinor,
      accountId: accountId,
      categoryId: expenseCategoryId,
      description: 'Subscription',
      frequency: 'MONTHLY',
      interval: 1,
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      autoPost: true,
      mode: RecurringSeriesMode.subscription,
    );
  }

  test('the safety gate keeps catch-up closed by default', () async {
    await seed();
    expect(await createAutoPostingSeries(), isA<Success<void>>());
    final eventsBefore = (await harness.eventStore.readAll()).events.length;

    await harness.recurringService.catchUpAutoPosted();

    // Ticket 28: before the eligibility rules and the restore barrier land,
    // auto-posting is disabled by default. A due 订阅 must wait; only the
    // user's manual 记入 may post it.
    expect(
        (await scheduled())
            .every((i) => i.status == ScheduledTransactionStatus.scheduled),
        isTrue,
        reason: 'the closed gate must not post anything');
    expect((await harness.eventStore.readAll()).events.length, eventsBefore,
        reason: 'no TransactionRecorded while the gate is closed');
  });

  test('catch-up posts the due instances of an auto-posting series, once',
      () async {
    // Ticket 28: open the safety gate under a controlled test configuration —
    // the production default is closed. Ticket 31: the 订阅 switch must also
    // be on for the series to be eligible.
    await restartHarness(
        autoPostEnabled: true, preferences: await prefsWithSubscriptionOn());
    await seed();
    expect(await createAutoPostingSeries(), isA<Success<void>>());

    // Spec 006, US32: a series created after its first bill came due is
    // "created already due", so those bills are latched manual at creation.
    // This test exercises the posting path itself, so re-arm the due
    // instances as if the series had existed before they fell due.
    for (final row in await harness.db.recurringDao.watchAllScheduled().first) {
      if (row.date.isAfter(DateTime.now())) continue;
      await rearmEligible(row.id);
    }

    final eventsBefore = (await harness.eventStore.readAll()).events.length;
    await harness.recurringService.catchUpAutoPosted();

    final instances = await scheduled();
    final due = instances.where((i) => !i.date.isAfter(DateTime.now()));
    expect(due, isNotEmpty, reason: 'fixture precondition');
    expect(
        due.every((i) => i.status == ScheduledTransactionStatus.posted), isTrue,
        reason: 'the due instances posted themselves');
    expect(
        instances
            .where((i) => i.status == ScheduledTransactionStatus.scheduled)
            .isNotEmpty,
        isTrue,
        reason: 'future instances wait for their date');
    expect((await harness.eventStore.readAll()).events.length,
        eventsBefore + due.length,
        reason: 'one TransactionRecorded per due instance');
    expect(await accountBalance(), 100000 - 20000 * due.length);

    // The second run changes nothing — the status flip and the deterministic
    // commandId both refuse to post the same instance twice.
    await harness.recurringService.catchUpAutoPosted();
    expect((await harness.eventStore.readAll()).events.length,
        eventsBefore + due.length,
        reason: 'no double posting');
    expect(await accountBalance(), 100000 - 20000 * due.length);
  });

  test('catch-up leaves a manual series pending', () async {
    await seed();
    final result = await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 20000,
      accountId: accountId,
      categoryId: expenseCategoryId,
      description: 'Rent',
      frequency: 'MONTHLY',
      interval: 1,
      startDate: DateTime.now().subtract(const Duration(days: 10)),
    );
    expect(result, isA<Success<void>>());
    final events = (await harness.eventStore.readAll()).events.length;

    await harness.recurringService.catchUpAutoPosted();

    expect(
        (await scheduled())
            .every((i) => i.status == ScheduledTransactionStatus.scheduled),
        isTrue,
        reason: '重复 bills wait for the user 记入, not the launch');
    expect((await harness.eventStore.readAll()).events.length, events);
  });

  test('an edit split keeps the series auto-posting', () async {
    await seed();
    expect(await createMonthly(autoPost: true), isA<Success<void>>());
    final cut = (await scheduled())[2];

    final result = await editBill(cut,
        scope: RecurringScope.thisAndFollowing, amountMinor: 60000);

    expect(result, isA<Success<void>>());
    final series = await harness.db.recurringDao.getAllSeries();
    expect(series, hasLength(2));
    expect(series.every((s) => s.autoPost), isTrue,
        reason: 'the split is an edit of the same subscription, not a new '
            'series — a rewrite that dropped the flag would silently turn a '
            '订阅 back into a 重复');
  });

  test('rewriting the whole rule keeps the series auto-posting', () async {
    await seed();
    expect(await createMonthly(autoPost: true), isA<Success<void>>());
    final instance = await firstScheduled();

    final result =
        await editBill(instance, scope: RecurringScope.all, amountMinor: 60000);

    expect(result, isA<Success<void>>());
    expect((await seriesRow()).autoPost, isTrue);
  });

  // — 自动入账资格（ticket 31）———————————————————————————————————————

  test('a due bill that fell due before its switch turned on is latched '
      'manual and never retro-posts', () async {
    // Subscription switch OFF (the default) while the bill is already due.
    await restartHarness(
        autoPostEnabled: true,
        preferences: PreferencesRepositoryImpl(MockSharedPreferences()));
    await seed();
    expect(await createAutoPostingSeries(), isA<Success<void>>());
    final dueIds = (await scheduled())
        .where((i) => !i.date.isAfter(DateTime.now()))
        .map((i) => i.id)
        .toSet();
    expect(dueIds, isNotEmpty, reason: 'fixture precondition');

    await harness.recurringService.catchUpAutoPosted();

    // Still scheduled, but latched permanently manual.
    expect(
        (await scheduled())
            .where((i) => dueIds.contains(i.id))
            .every((i) =>
                i.status == ScheduledTransactionStatus.scheduled &&
                !i.autoPostEligible),
        isTrue,
        reason: 'due while the switch was off = manual, and the latch sticks');

    // Turn the 订阅 switch ON — the boundary is now — and try again.
    await (harness.preferences!).setAutoPostEnabled(
        RecurringSeriesMode.subscription, true);
    final eventsBefore = (await harness.eventStore.readAll()).events.length;
    await harness.recurringService.catchUpAutoPosted();

    expect(
        (await scheduled())
            .where((i) => dueIds.contains(i.id))
            .every((i) => i.status == ScheduledTransactionStatus.scheduled),
        isTrue,
        reason: 're-enabling must not retro-post a bill that was already due');
    expect((await harness.eventStore.readAll()).events.length, eventsBefore);
  });

  test('a bill due the same millisecond its switch turned on is manual',
      () async {
    final prefs = PreferencesRepositoryImpl(MockSharedPreferences());
    await prefs.setAutoPostEnabled(RecurringSeriesMode.subscription, true);
    final boundary = prefs.getAutoPostEnabledSince(
        RecurringSeriesMode.subscription)!;

    await restartHarness(autoPostEnabled: true, preferences: prefs);
    await seed();
    // The series starts exactly at the boundary millisecond.
    expect(
        await harness.recurringService.createSeries(
          type: RecurringSeriesKind.expense,
          amountMinor: 20000,
          accountId: accountId,
          categoryId: expenseCategoryId,
          description: 'Subscription',
          frequency: 'MONTHLY',
          interval: 1,
          startDate: boundary,
          autoPost: true,
          mode: RecurringSeriesMode.subscription,
        ),
        isA<Success<void>>());

    await harness.recurringService.catchUpAutoPosted();

    final due = (await scheduled())
        .where((i) => !i.date.isAfter(DateTime.now()));
    expect(due, isNotEmpty, reason: 'fixture precondition');
    expect(
        due.every((i) =>
            i.status == ScheduledTransactionStatus.scheduled &&
            !i.autoPostEligible),
        isTrue,
        reason: 'due exactly when the switch turned on counts as already-due');
  });

  test('a due bill whose currency was not yet current is manual', () async {
    final prefs = PreferencesRepositoryImpl(MockSharedPreferences());
    await prefs.setAutoPostEnabled(RecurringSeriesMode.subscription, true);
    // The bill's currency only became current a day after the bill was due.
    final due = DateTime.now().subtract(const Duration(days: 10));
    await prefs.setCurrencyActiveSince(
        'USD', due.add(const Duration(days: 1)));

    await restartHarness(autoPostEnabled: true, preferences: prefs);
    await seed();
    expect(
        await harness.recurringService.createSeries(
          type: RecurringSeriesKind.expense,
          amountMinor: 20000,
          accountId: accountId,
          categoryId: expenseCategoryId,
          description: 'Subscription',
          frequency: 'MONTHLY',
          interval: 1,
          startDate: due,
          autoPost: true,
          mode: RecurringSeriesMode.subscription,
        ),
        isA<Success<void>>());

    await harness.recurringService.catchUpAutoPosted();

    final instances = await scheduled();
    expect(
        instances
            .where((i) => !i.date.isAfter(DateTime.now()))
            .every((i) =>
                i.status == ScheduledTransactionStatus.scheduled &&
                !i.autoPostEligible),
        isTrue,
        reason: 'due before its currency became current = manual');
  });

  // — 自动入账资格（ticket 32：创建与编辑）——————————————————————————

  test('a series created already past its first due date latches those bills '
      'manual', () async {
    await seed();
    await createMonthly();

    final instances = await scheduled();
    final past = instances.where((i) => !i.date.isAfter(DateTime.now()));
    final future = instances.where((i) => i.date.isAfter(DateTime.now()));
    expect(past, isNotEmpty, reason: 'fixture precondition');
    expect(future, isNotEmpty, reason: 'fixture precondition');

    expect(past.every((i) => !i.autoPostEligible), isTrue,
        reason: 'already due at creation = manual, and it must never retro-post');
    expect(future.every((i) => i.autoPostEligible), isTrue,
        reason: 'a bill that was not yet due at creation keeps its eligibility');
  });

  test('editing a still-future bill keeps its auto-post eligibility', () async {
    await seed();
    await createFutureMonthly();
    final instance = await firstScheduled();

    await editBill(instance, scope: RecurringScope.thisOnly, amountMinor: 60000);

    final row = await harness.db.recurringDao.getScheduled(instance.id);
    expect(row!.autoPostEligible, isTrue,
        reason: 'editing before it is due must not turn it manual');
  });

  test('editing an already-due bill turns it manual', () async {
    await seed();
    await createMonthly();
    final due = (await scheduled())
        .firstWhere((i) => !i.date.isAfter(DateTime.now()));
    await rearmEligible(due.id);

    await editBill(due, scope: RecurringScope.thisOnly, amountMinor: 60000);

    final row = await harness.db.recurringDao.getScheduled(due.id);
    expect(row!.autoPostEligible, isFalse,
        reason: 'a real edit of an already-due bill must never auto-post');
  });

  test('a no-op save does not flip eligibility', () async {
    await seed();
    await createMonthly();
    final due = (await scheduled())
        .firstWhere((i) => !i.date.isAfter(DateTime.now()));
    await rearmEligible(due.id);

    await editBill(due,
        scope: RecurringScope.thisOnly,
        amountMinor: due.amountMinor,
        date: due.date);

    final row = await harness.db.recurringDao.getScheduled(due.id);
    expect(row!.autoPostEligible, isTrue,
        reason: 'a save that changes nothing must not flip eligibility');
  });

  test('moving a bill into the past turns the new row manual', () async {
    await seed();
    await createFutureMonthly();
    final instance = await firstScheduled();

    await editBill(instance,
        scope: RecurringScope.thisOnly,
        date: DateTime.now().subtract(const Duration(days: 1)));

    final rows = await harness.db.recurringDao.watchAllScheduled().first;
    final moved = rows.firstWhere((r) =>
        decodeScheduledStatus(r.status) == ScheduledTransactionStatus.scheduled &&
        !r.date.isAfter(DateTime.now()));
    expect(moved.autoPostEligible, isFalse,
        reason: 'a bill moved into the past must never auto-post');
  });

  test('a detected clock rollback turns the edited bill manual', () async {
    final prefs = PreferencesRepositoryImpl(MockSharedPreferences());
    // The wall clock was last seen a day in the future — the next decision
    // reads *earlier*, which is evidence of a rollback.
    await prefs.setLastSeenWallClock(DateTime.now().add(const Duration(days: 1)));

    await restartHarness(preferences: prefs);
    await seed();
    await createFutureMonthly();
    final instance = await firstScheduled();

    await editBill(instance, scope: RecurringScope.thisOnly, amountMinor: 60000);

    final row = await harness.db.recurringDao.getScheduled(instance.id);
    expect(row!.autoPostEligible, isFalse,
        reason: 'unreliable due/not-due ordering makes the touched bill manual');
  });
}
