import 'package:flutter_test/flutter_test.dart';

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

  setUp(() => harness = LedgerServiceHarness());
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
    expenseCategoryId =
        categories.firstWhere((c) => c.name == 'Rent').id;
    incomeCategoryId =
        categories.firstWhere((c) => c.name == 'Salary').id;
  }

  /// A monthly series starting well in the past, so it has due instances.
  Future<Result<void>> createMonthly({
    int amountMinor = 50000,
    RecurringSeriesKind type = RecurringSeriesKind.expense,
    CategoryType categoryType = CategoryType.expense,
    DateTime? endDate,
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
    expect(instances.every((i) => i.recurringTransactionSeries != null), isTrue);
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

  test('a series with no materialized instances is still listed', () async {
    // The reason watchAllSeries exists. Starting beyond the projection
    // horizon means zero scheduled rows, and a view built only from
    // instances would show the user nothing at all — including immediately
    // after they created it.
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

    expect(await scheduledIds(), isEmpty);
    expect((await harness.recurringService.watchSeries().first), hasLength(1));
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
      isA<Failure<void>>().having((f) => f.code, 'code',
          LedgerErrorCode.categoryTypeMismatch),
    );
    expect(await harness.db.recurringDao.getAllSeries(), isEmpty);
  });

  test('an end date at or before the start is refused', () async {
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
      endDate: DateTime(2026, 1, 1),
    );

    expect(result, isA<Failure<void>>());
    expect(await harness.db.recurringDao.getAllSeries(), isEmpty);
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
      isA<Failure<void>>().having((f) => f.code, 'code',
          LedgerErrorCode.scheduledAlreadyPosted),
      reason: 'this used to report transactionAlreadyReversed, which told the '
          'user their transaction had been reversed',
    );
  });

  test('skipping writes no event and moves no money', () async {
    await seed();
    await createMonthly();
    final instance = await firstScheduled();
    final eventsBefore = (await harness.eventStore.readAll()).events.length;
    final balanceBefore = await accountBalance();

    final result = await harness.recurringService.skipInstance(instance.id);

    expect(result, isA<Success<void>>());
    expect((await harness.db.recurringDao.getScheduled(instance.id))!.status,
        'skipped');
    expect((await harness.eventStore.readAll()).events.length, eventsBefore);
    expect(await accountBalance(), balanceBefore);
  });

  test('skipping an already-posted instance is refused', () async {
    await seed();
    await createMonthly();
    final instance = await firstScheduled();
    await harness.recurringService.postInstance(instance.id);

    final result = await harness.recurringService.skipInstance(instance.id);

    expect(
      result,
      isA<Failure<void>>().having((f) => f.code, 'code',
          LedgerErrorCode.scheduledAlreadyPosted),
    );
  });

  test('acting on an unknown instance is refused', () async {
    await seed();

    expect(
      await harness.recurringService.postInstance('nope'),
      isA<Failure<void>>().having(
          (f) => f.code, 'code', LedgerErrorCode.transactionNotFound),
    );
    expect(
      await harness.recurringService.skipInstance('nope'),
      isA<Failure<void>>().having(
          (f) => f.code, 'code', LedgerErrorCode.transactionNotFound),
    );
  });

  test('deactivating keeps existing instances and adds no more', () async {
    await seed();
    await createMonthly();
    final before = await scheduledIds();
    expect(before, isNotEmpty, reason: 'fixture precondition');

    final result = await harness.recurringService
        .deactivateSeries((await seriesRow()).id,
            endDate: DateTime(2026, 3, 1));
    expect(result, isA<Success<void>>());

    // endDate is what materialization filters on.
    expect((await seriesRow()).endDate, DateTime(2026, 3, 1));

    // Existing instances are kept — past ones are history, pending ones stay
    // visible so the user can post or skip each deliberately.
    await harness.recurringService.materialize();
    final after = await scheduledIds();
    expect(after.difference(before), isEmpty,
        reason: 'deactivation must not create instances');
    expect(before.difference(after), isEmpty,
        reason: 'deactivation must not delete existing instances');
  });

  test('a deactivated series survives a round-trip through the projection',
      () async {
    await seed();
    await createMonthly();
    await harness.recurringService
        .deactivateSeries((await seriesRow()).id, endDate: DateTime(2026, 3, 1));

    final series = await harness.recurringService.watchSeries().first;

    expect(series, hasLength(1));
    expect(series.single.endDate, DateTime(2026, 3, 1));
    expect(series.single.frequency, 'MONTHLY');
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
}
