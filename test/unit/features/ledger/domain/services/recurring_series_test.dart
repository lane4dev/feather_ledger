import 'package:flutter_test/flutter_test.dart';

import 'package:drift/drift.dart' show Value;

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';

import '../../../../../support/event_sourcing/ledger_service_harness.dart';

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

  /// Re-arms [id]'s auto-post eligibility in the CRUD-exempt table by
  /// clearing `manualOnly`.
  Future<void> rearmEligible(String id) async {
    final row = await harness.db.recurringDao.getScheduled(id);
    await harness.db.recurringDao.insertOrUpdateScheduled(
      ScheduledTransactionsViewCompanion(
        id: Value(row!.id),
        seriesId: Value(row.seriesId),
        occurrenceKey: Value(row.occurrenceKey),
        scheduledDate: Value(row.scheduledDate),
        amountOverrideMinor: Value(row.amountOverrideMinor),
        dateOverride: Value(row.dateOverride),
        memoOverride: Value(row.memoOverride),
        status: Value(row.status),
        transactionId: Value(row.transactionId),
        manualOnly: const Value(false),
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

  test('a series persists its creation mode (计划/重复)', () async {
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
    // 重复 (autoPost): recurring, auto-post enabled.
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
      mode: RecurringSeriesMode.repeating,
    );

    final rows = await harness.db.recurringDao.getAllSeries();
    final byDescription = {for (final r in rows) r.description: r};
    expect(byDescription['Plan']!.mode, RecurringSeriesMode.planned);
    expect(byDescription['Repeat']!.mode, RecurringSeriesMode.repeating);
    expect(byDescription['Repeat']!.autoPost, isFalse);
    expect(byDescription['Subscribe']!.mode, RecurringSeriesMode.repeating);
    expect(byDescription['Subscribe']!.autoPost, isTrue);
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

    final usd = await harness.recurringService
        .watchScheduled(currencyCode: 'USD')
        .first;
    expect(usd, isNotEmpty);
    expect(usd.every((s) => s.account?.currencyCode == 'USD'), isTrue);

    final cny = await harness.recurringService
        .watchScheduled(currencyCode: 'CNY')
        .first;
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

    expect(await scheduledIds(), hasLength(1));
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

  test('deleting with updateRule deactivates the series and removes pending',
      () async {
    await seed();
    await createMonthly();
    final pending = (await scheduled())
        .where((s) => s.status == ScheduledTransactionStatus.scheduled)
        .toList();
    expect(pending.length, greaterThanOrEqualTo(3),
        reason: 'fixture precondition');
    final cut = pending[1];

    final result = await harness.recurringService
        .deleteBill(cut.id, scope: RecurringScope.updateRule);

    expect(result, isA<Success<void>>());
    expect((await seriesRow()).isActive, isFalse);
    expect(
      (await scheduled())
          .where((s) => s.status == ScheduledTransactionStatus.scheduled),
      isEmpty,
    );
  });

  test('a series deactivated by updateRule materializes nothing further',
      () async {
    await seed();
    await createMonthly();
    final cut = (await scheduled())
        .firstWhere((s) => s.status == ScheduledTransactionStatus.scheduled);

    await harness.recurringService
        .deleteBill(cut.id, scope: RecurringScope.updateRule);

    final afterDelete = await scheduledIds();
    await harness.recurringService.materialize();

    expect(await scheduledIds(), afterDelete,
        reason: 'the rule is inactive, so materialization adds nothing');
  });

  test('deleting with updateRule keeps bills already recorded', () async {
    await seed();
    await createMonthly();
    final pending = (await scheduled())
        .where((s) => s.status == ScheduledTransactionStatus.scheduled)
        .toList();
    // Record a later bill first: money that moved outlives the schedule.
    final recorded = pending.last;
    await harness.recurringService.postInstance(recorded.id);
    final balanceAfterPost = await accountBalance();
    final eventsAfterPost = (await harness.eventStore.readAll()).events.length;

    await harness.recurringService
        .deleteBill(pending.first.id, scope: RecurringScope.updateRule);

    expect(await accountBalance(), balanceAfterPost,
        reason: 'a recorded bill is not a pending bill');
    expect((await harness.eventStore.readAll()).events.length, eventsAfterPost);
    expect((await harness.db.recurringDao.getScheduled(recorded.id))!.status,
        'posted');
  });

  test('deleting a planned series with updateRule removes the series',
      () async {
    await seed();
    final start = DateTime(2027, 2, 10, 9);
    await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 50000,
      accountId: accountId,
      categoryId: expenseCategoryId,
      description: 'Plan',
      frequency: 'MONTHLY',
      interval: 1,
      startDate: start,
      endDate: start,
      mode: RecurringSeriesMode.planned,
    );
    final cut = await firstScheduled();

    final result = await harness.recurringService
        .deleteBill(cut.id, scope: RecurringScope.updateRule);

    expect(result, isA<Success<void>>());
    expect(await harness.db.recurringDao.getAllSeries(), isEmpty);
    expect(await harness.db.recurringDao.watchAllScheduled().first, isEmpty);
  });

  test('deleting with updateRule leaves the rest of the rule intact',
      () async {
    await seed();
    await createMonthly();
    final cut = (await scheduled())
        .firstWhere((s) => s.status == ScheduledTransactionStatus.scheduled);

    await harness.recurringService
        .deleteBill(cut.id, scope: RecurringScope.updateRule);

    final series = await seriesRow();

    expect(series.isActive, isFalse);
    expect(series.frequency, 'MONTHLY');
    expect(series.interval, 1);
    expect(series.amountMinor, 50000);
    expect(series.accountId, accountId);
    expect(series.categoryId, expenseCategoryId);
  });

  // — editing (spec 004, US2) ————————————————————————————————————————————

  /// Edits [instance] at [scope]. The series-scoped fields default to the
  /// series' own values, which is what the form sends for `thisOnly` (a single
  /// row has sparse override columns for amount, date, and memo).
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

  test('moving one bill updates dateOverride in place without tombstones',
      () async {
    await seed();
    await createMonthly();
    final instance = await firstScheduled();
    final moved = DateTime(2026, 2, 15);

    final result =
        await editBill(instance, scope: RecurringScope.thisOnly, date: moved);
    expect(result, isA<Success<void>>());

    // The row keeps its UUID and occurrenceKey; dateOverride records the move.
    final updated = await harness.db.recurringDao.getScheduled(instance.id);
    expect(updated!.status, 'scheduled');
    expect(updated.occurrenceKey, instance.occurrenceKey);
    expect(updated.dateOverride, moved);

    await harness.recurringService.materialize();
    final onNewDate = (await scheduled()).where((s) =>
        s.date.year == moved.year &&
        s.date.month == moved.month &&
        s.date.day == moved.day);
    expect(onNewDate, hasLength(1), reason: 'the bill exists on its new day');
    expect(onNewDate.single.id, instance.id);
    expect(onNewDate.single.amountMinor, instance.amountMinor);

    // And the original day is not billed again — occurrenceKey prevents
    // materialization from re-creating it.
    final backOnOldDate = (await scheduled()).where((s) =>
        s.status == ScheduledTransactionStatus.scheduled &&
        s.date.year == instance.date.year &&
        s.date.month == instance.date.month &&
        s.date.day == instance.date.day);
    expect(backOnOldDate, isEmpty);
  });

  test('changing one bill time survives materialization', () async {
    await seed();
    await createMonthly();
    final original = await firstScheduled();
    final moved = original.date.add(const Duration(hours: 1));
    final result =
        await editBill(original, scope: RecurringScope.thisOnly, date: moved);
    expect(result, isA<Success<void>>());
    await harness.recurringService.materialize();
    final rows = await scheduled();
    expect(
        rows.where((row) =>
            row.id == original.id &&
            row.date == moved &&
            row.status == ScheduledTransactionStatus.scheduled),
        hasLength(1));
    expect(
        rows.where((row) =>
            row.id != original.id &&
            row.occurrenceKey == original.occurrenceKey),
        isEmpty);
  });

  test('editing a series reminder keeps its mode', () async {
    await seed();
    await createMonthly();
    final instance = await firstScheduled();
    final result = await harness.recurringService.updateBill(
      instance.id,
      scope: RecurringScope.updateRule,
      amountMinor: instance.amountMinor,
      date: instance.date,
      categoryId: expenseCategoryId,
      accountId: accountId,
      description: 'Rent',
      reminderMinutes: 30,
    );
    expect(result, isA<Success<void>>());
    final updated = await seriesRow();
    expect(updated.reminderMinutes, 30);
    expect(updated.mode, RecurringSeriesMode.repeating);
  });

  test('changing a series time moves its pending bills without duplicates',
      () async {
    await seed();
    await createMonthly();
    final original = await firstScheduled();
    final moved = original.date.add(const Duration(hours: 1));
    final result =
        await editBill(original, scope: RecurringScope.updateRule, date: moved);
    expect(result, isA<Success<void>>());
    await harness.recurringService.materialize();
    final pending = (await scheduled())
        .where((row) => row.status == ScheduledTransactionStatus.scheduled)
        .toList();
    expect(pending.where((row) => row.date == original.date), isEmpty);
    expect(pending.where((row) => row.date == moved), hasLength(1));
    expect(pending.every((row) => row.date.hour == moved.hour), isTrue);
  });

  test('editing a one-shot plan moves its rule and its only pending bill',
      () async {
    await seed();
    final start = DateTime(2027, 2, 10, 9);
    final moved = DateTime(2027, 4, 15, 14, 30);
    await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 50000,
      accountId: accountId,
      categoryId: expenseCategoryId,
      description: 'Rent',
      frequency: 'MONTHLY',
      interval: 1,
      startDate: start,
      endDate: start,
      mode: RecurringSeriesMode.planned,
    );
    final bill = await firstScheduled();
    final result = await harness.recurringService.updateBill(bill.id,
        scope: RecurringScope.updateRule,
        amountMinor: 60000,
        date: moved,
        categoryId: expenseCategoryId,
        accountId: accountId,
        description: 'Updated',
        reminderMinutes: 30);
    expect(result, isA<Success<void>>());
    await harness.recurringService.materialize();
    final series = await seriesRow();
    expect(series.startDate, moved);
    expect(series.endDate, moved);
    expect(series.reminderMinutes, 30);
    final pending = (await scheduled())
        .where((row) => row.status == ScheduledTransactionStatus.scheduled)
        .toList();
    expect(pending, hasLength(1));
    expect(pending.single.id, bill.id);
    expect(pending.single.date, moved);
    expect(pending.single.amountMinor, 60000);
  });

  test('thisOnly supports sparse memo override including explicit empty memo',
      () async {
    await seed();
    await createMonthly();
    final instance = await firstScheduled();

    final explicitEmpty = await harness.recurringService.updateBill(
      instance.id,
      scope: RecurringScope.thisOnly,
      amountMinor: instance.amountMinor,
      date: instance.date,
      categoryId: expenseCategoryId,
      accountId: accountId,
      description: '',
    );
    expect(explicitEmpty, isA<Success<void>>());
    final emptyRow = await harness.db.recurringDao.getScheduled(instance.id);
    expect(emptyRow!.memoOverride, '');
    final emptyEntity =
        (await scheduled()).firstWhere((s) => s.id == instance.id);
    expect(emptyEntity.effectiveMemo, '');

    final inherited = await harness.recurringService.updateBill(
      instance.id,
      scope: RecurringScope.thisOnly,
      amountMinor: instance.amountMinor,
      date: instance.date,
      categoryId: expenseCategoryId,
      accountId: accountId,
      description: 'Rent',
    );
    expect(inherited, isA<Success<void>>());
    final inheritedRow = await harness.db.recurringDao.getScheduled(instance.id);
    expect(inheritedRow!.memoOverride, isNull);
    final inheritedEntity =
        (await scheduled()).firstWhere((s) => s.id == instance.id);
    expect(inheritedEntity.effectiveMemo, 'Rent');
  });

  test('thisOnly allows moving an occurrence onto an already occupied date',
      () async {
    await seed();
    await createMonthly();
    final pending = (await scheduled())
        .where((s) => s.status == ScheduledTransactionStatus.scheduled)
        .toList();
    final first = pending[0];
    final second = pending[1];

    final result = await editBill(
      first,
      scope: RecurringScope.thisOnly,
      date: second.date,
    );
    expect(result, isA<Success<void>>());

    final after = (await scheduled())
        .where((s) => s.date == second.date)
        .toList();
    expect(after.map((s) => s.id), containsAll([first.id, second.id]));
  });

  test('updateRule enforces countLimit >= K + 1 where K = posted + skipped',
      () async {
    await seed();
    final start = DateTime.now().add(const Duration(days: 1));
    await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 50000,
      accountId: accountId,
      categoryId: expenseCategoryId,
      description: 'Installment',
      frequency: 'DAILY',
      interval: 1,
      startDate: start,
      countLimit: 5,
    );
    final items = await scheduled()
      ..sort((a, b) => a.date.compareTo(b.date));
    await harness.recurringService.postInstance(items[0].id);
    await harness.recurringService
        .deleteBill(items[1].id, scope: RecurringScope.thisOnly);

    final tooSmall = await harness.recurringService.updateBill(
      items[2].id,
      scope: RecurringScope.updateRule,
      amountMinor: 50000,
      date: items[2].date,
      categoryId: expenseCategoryId,
      accountId: accountId,
      description: 'Installment',
      frequency: 'DAILY',
      interval: 1,
      countLimit: 2,
    );
    expect(
      tooSmall,
      isA<Failure<void>>()
          .having((f) => f.code, 'code', LedgerErrorCode.countLimitTooSmall),
    );

    final valid = await harness.recurringService.updateBill(
      items[2].id,
      scope: RecurringScope.updateRule,
      amountMinor: 50000,
      date: items[2].date,
      categoryId: expenseCategoryId,
      accountId: accountId,
      description: 'Installment',
      frequency: 'DAILY',
      interval: 1,
      countLimit: 3,
    );
    expect(valid, isA<Success<void>>());
  });

  test('updateRule without schedule change preserves existing thisOnly overrides',
      () async {
    await seed();
    await createMonthly();
    final items = await scheduled()
      ..sort((a, b) => a.date.compareTo(b.date));
    final first = items[0];
    final second = items[1];

    await harness.recurringService.updateBill(
      first.id,
      scope: RecurringScope.thisOnly,
      amountMinor: 77777,
      date: first.date,
      categoryId: expenseCategoryId,
      accountId: accountId,
      description: 'Custom memo',
    );

    final result = await harness.recurringService.updateBill(
      second.id,
      scope: RecurringScope.updateRule,
      amountMinor: 60000,
      date: second.date,
      categoryId: expenseCategoryId,
      accountId: accountId,
      description: 'Updated Rent',
    );
    expect(result, isA<Success<void>>());

    final afterFirst =
        (await scheduled()).firstWhere((s) => s.id == first.id);
    final afterSecond =
        (await scheduled()).firstWhere((s) => s.id == second.id);
    expect(afterFirst.amountMinor, 77777);
    expect(afterFirst.effectiveMemo, 'Custom memo');
    expect(afterSecond.amountMinor, 60000);
    expect(afterSecond.effectiveMemo, 'Updated Rent');
  });

  test('editing rule-only fields under thisOnly is refused', () async {
    await seed();
    await createMonthly();
    final instance = await firstScheduled();

    final result = await harness.recurringService.updateBill(
      instance.id,
      scope: RecurringScope.thisOnly,
      amountMinor: instance.amountMinor,
      date: instance.date,
      categoryId: expenseCategoryId,
      accountId: accountId,
      description: 'Rent',
      autoPost: true,
    );

    expect(
      result,
      isA<Failure<void>>()
          .having((f) => f.code, 'code', LedgerErrorCode.invalidTransactionShape),
    );
  });

  test('editing updateRule rewrites the rule and updates pending bills',
      () async {
    await seed();
    await createMonthly();
    final instance = await firstScheduled();

    final result = await editBill(instance,
        scope: RecurringScope.updateRule, amountMinor: 60000);

    expect(result, isA<Success<void>>());
    final series = await seriesRow();
    expect(series.amountMinor, 60000);
    expect(series.startDate, DateTime(2026, 1, 1), reason: 'date unchanged');

    final pending = (await scheduled())
        .where((s) => s.status == ScheduledTransactionStatus.scheduled);
    expect(pending, isNotEmpty);
    expect(pending.every((s) => s.amountMinor == 60000), isTrue,
        reason: 'every pending bill without an override picked up 60000');
  });

  test('editing updateRule moves the whole schedule when the date moves',
      () async {
    await seed();
    await createMonthly();
    final instance = await firstScheduled();

    // The rent came on the 1st; it now comes on the 4th — every month.
    final result = await editBill(instance,
        scope: RecurringScope.updateRule, date: DateTime(2026, 1, 4));

    expect(result, isA<Success<void>>());
    expect((await seriesRow()).startDate, DateTime(2026, 1, 4));

    final pending = (await scheduled())
        .where((s) => s.status == ScheduledTransactionStatus.scheduled)
        .toList();
    expect(pending, isNotEmpty);
    expect(pending.every((s) => s.date.day == 4), isTrue,
        reason: 'the day of the month moved for every bill');
  });

  test('editing updateRule leaves recorded bills alone', () async {
    await seed();
    await createMonthly();
    final instance = await firstScheduled();
    final other = (await scheduled())[1];
    await harness.recurringService.postInstance(other.id);
    final balance = await accountBalance();
    final events = (await harness.eventStore.readAll()).events.length;

    await editBill(instance,
        scope: RecurringScope.updateRule, amountMinor: 60000);

    expect(await accountBalance(), balance);
    expect((await harness.eventStore.readAll()).events.length, events);
    expect((await harness.db.recurringDao.getScheduled(other.id))!.status,
        'posted');
    expect(
      (await scheduled()).firstWhere((s) => s.id == other.id).amountMinor,
      60000,
      reason: 'posted row remains linked to its transaction in ledger',
    );
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

  // — 重复 (autoPost) —————————————————————————————————————————————————————

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
      mode: RecurringSeriesMode.repeating,
    );
  }

  test('thisOnly clears manualOnly when moving a past autoPost bill to future',
      () async {
    await seed();
    await createAutoPostingSeries();
    final due = (await scheduled()).firstWhere(
      (s) => !s.date.isAfter(DateTime.now()),
    );
    expect(due.manualOnly, isTrue);

    final future = DateTime.now().add(const Duration(days: 30));
    final result = await harness.recurringService.updateBill(
      due.id,
      scope: RecurringScope.thisOnly,
      amountMinor: due.amountMinor,
      date: future,
      categoryId: expenseCategoryId,
      accountId: accountId,
      description: 'Subscription',
    );
    expect(result, isA<Success<void>>());

    final updated = await harness.db.recurringDao.getScheduled(due.id);
    expect(updated!.manualOnly, isFalse);
  });

  test('thisOnly resets a failed bill back to scheduled', () async {
    await seed();
    await createAutoPostingSeries();
    final instance = await firstScheduled();
    await harness.db.recurringDao.insertOrUpdateScheduled(
      ScheduledTransactionsViewCompanion(
        id: Value(instance.id),
        seriesId: Value(instance.seriesId),
        occurrenceKey: Value(instance.occurrenceKey),
        scheduledDate: Value(instance.scheduledDate),
        amountOverrideMinor: Value(instance.amountOverrideMinor),
        dateOverride: Value(instance.dateOverride),
        memoOverride: Value(instance.memoOverride),
        status: const Value('failed'),
        manualOnly: Value(instance.manualOnly),
        transactionId: Value(instance.transactionId),
      ),
    );

    final result = await harness.recurringService.updateBill(
      instance.id,
      scope: RecurringScope.thisOnly,
      amountMinor: 25000,
      date: instance.date,
      categoryId: expenseCategoryId,
      accountId: accountId,
      description: 'Subscription',
    );
    expect(result, isA<Success<void>>());

    final updated = await harness.db.recurringDao.getScheduled(instance.id);
    expect(updated!.status, 'scheduled');
  });

  test('catch-up posts the due instances of an auto-posting series, once',
      () async {
    await seed();
    expect(await createAutoPostingSeries(), isA<Success<void>>());

    // A series created already past its first due date latches due rows
    // manualOnly at creation. Re-arm them to exercise the catch-up path.
    for (final row in await harness.db.recurringDao.watchAllScheduled().first) {
      final effective = row.dateOverride ?? row.scheduledDate;
      if (effective.isAfter(DateTime.now())) continue;
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

  test('rewriting the rule with updateRule keeps the series auto-posting',
      () async {
    await seed();
    expect(await createMonthly(autoPost: true), isA<Success<void>>());
    final instance = await firstScheduled();

    final result = await editBill(instance,
        scope: RecurringScope.updateRule, amountMinor: 60000);

    expect(result, isA<Success<void>>());
    expect((await seriesRow()).autoPost, isTrue);
  });

  // — 自动入账资格（创建与更新）———————————————————————————————————————————

  test(
      'an auto-post series created already past its first due date latches '
      'those bills manualOnly', () async {
    await seed();
    await createMonthly(autoPost: true);

    final instances = await scheduled();
    final past = instances.where((i) => !i.date.isAfter(DateTime.now()));
    final future = instances.where((i) => i.date.isAfter(DateTime.now()));
    expect(past, isNotEmpty, reason: 'fixture precondition');
    expect(future, isNotEmpty, reason: 'fixture precondition');

    expect(past.every((i) => i.manualOnly), isTrue,
        reason:
            'already due at creation = manualOnly, and it must never retro-post');
    expect(future.every((i) => !i.manualOnly), isTrue,
        reason:
            'a bill that was not yet due at creation keeps auto-post enabled');
  });

  test('editing a still-future bill keeps manualOnly false', () async {
    await seed();
    await createFutureMonthly();
    final instance = await firstScheduled();

    await editBill(instance,
        scope: RecurringScope.thisOnly, amountMinor: 60000);

    final row = await harness.db.recurringDao.getScheduled(instance.id);
    expect(row!.manualOnly, isFalse,
        reason: 'editing before it is due must not turn it manual');
  });

  test(
      'an auto-post series starting today latches today\'s bill manualOnly '
      'while keeping future bills automatic', () async {
    await seed();
    final now = DateTime.now();
    await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 50000,
      accountId: accountId,
      categoryId: expenseCategoryId,
      description: 'Rent',
      frequency: 'MONTHLY',
      interval: 1,
      startDate: now,
      autoPost: true,
      mode: RecurringSeriesMode.repeating,
    );

    final instances = await scheduled();
    final dueNow = instances.where((i) => !i.effectiveDate.isAfter(now));
    final future = instances.where((i) => i.effectiveDate.isAfter(now));
    expect(dueNow, hasLength(1));
    expect(dueNow.single.manualOnly, isTrue);
    expect(future, isNotEmpty);
    expect(future.every((i) => !i.manualOnly), isTrue);
  });

  test('creating a planned series ignores autoPost: true and stores false',
      () async {
    await seed();
    final result = await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 50000,
      accountId: accountId,
      categoryId: expenseCategoryId,
      description: 'Trip',
      frequency: 'MONTHLY',
      interval: 1,
      startDate: DateTime.now().add(const Duration(days: 5)),
      endDate: DateTime.now().add(const Duration(days: 5)),
      autoPost: true,
      mode: RecurringSeriesMode.planned,
    );

    expect(result, isA<Success<void>>());
    expect((await seriesRow()).mode, RecurringSeriesMode.planned);
    expect((await seriesRow()).autoPost, isFalse);
  });
}
