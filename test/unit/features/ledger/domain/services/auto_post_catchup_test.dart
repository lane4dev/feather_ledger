import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/domain/commands/convert_scheduled_to_posted_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/create_recurring_series_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/delete_recurring_bill_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/project_recurring_events_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/restore_skipped_bill_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/update_recurring_bill_command.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import 'package:feather_ledger/features/ledger/domain/queries/get_scheduled_transaction_query.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_scheduled_transactions_query.dart';
import 'package:feather_ledger/features/ledger/domain/services/posting_context.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';

import '../../../../../support/event_sourcing/ledger_service_harness.dart';
import '../../../../../support/mocks/mock_shared_preferences.dart';

class _CountingMaterializeCommand extends ProjectRecurringEventsCommand {
  int executeCount = 0;

  _CountingMaterializeCommand(
    super.recurringRepository, {
    super.clock,
  });

  @override
  Future<MaterializationSummary> execute() {
    executeCount++;
    return super.execute();
  }
}

/// The auto-post catch-up seams (spec 006, US46/US49/US58).
///
/// Auto-posting only ever fires for a series that is active, enabled, not
/// latched manual-only, still `scheduled`, in the current currency and not
/// yet due — and the launch catch-up must neither block the queue on a bad
/// bill nor double-post. These are the predicates behind that.
void main() {
  late LedgerServiceHarness harness;
  late PreferencesRepositoryImpl preferences;

  // A fixed current currency so `catchUpAutoPosted` filters by it.
  setUp(() async {
    preferences = PreferencesRepositoryImpl(MockSharedPreferences());
    await preferences.setCurrency('USD');
    harness = LedgerServiceHarness(preferences: preferences);
    await harness.seedSystemCategories();
  });
  tearDown(() => harness.close());

  late String usdAccountId;
  late String jpyAccountId;
  late String expenseCategoryId;

  Future<void> seedAccounts() async {
    await harness.accountService.createAccount(
      commandId: 'cmd_acc_usd',
      name: 'Cash',
      type: AccountType.cash,
      initialBalanceMinor: 100000,
      currencyCode: 'USD',
    );
    await harness.accountService.createAccount(
      commandId: 'cmd_acc_jpy',
      name: 'Cash JPY',
      type: AccountType.cash,
      initialBalanceMinor: 100000,
      currencyCode: 'JPY',
    );
    await harness.categoryService.createCategory(
      commandId: 'cmd_cat_expense',
      name: 'Rent',
      iconKey: '1',
      colorInt: 0xFF000000,
      type: CategoryType.expense,
    );
    final accounts = await harness.db.accountDao.getAllAccounts();
    usdAccountId = accounts.firstWhere((a) => a.currencyCode == 'USD').id;
    jpyAccountId = accounts.firstWhere((a) => a.currencyCode == 'JPY').id;
    expenseCategoryId = (await harness.db.categoriesDao.getAllCategories())
        .firstWhere((c) => c.name == 'Rent')
        .id;
  }

  Future<Result<void>> createAutoSeries(
    String accountId, {
    String description = 'Rent',
    RecurringSeriesMode mode = RecurringSeriesMode.repeating,
    DateTime? startDate,
  }) {
    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 10));
    return harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 20000,
      accountId: accountId,
      categoryId: expenseCategoryId,
      description: description,
      frequency: 'MONTHLY',
      interval: 1,
      startDate: start,
      endDate: mode == RecurringSeriesMode.planned ? start : null,
      autoPost: true,
      mode: mode,
    );
  }

  Future<List<ScheduledTransactionEntity>> scheduled() =>
      harness.recurringService.watchScheduled().first;

  Future<List<ScheduledTransactionEntity>> due() async =>
      (await scheduled())
          .where((i) => !i.effectiveDate.isAfter(DateTime.now()))
          .toList();

  test('markPreRestoreManualOnly latches due bills in every currency', () async {
    await seedAccounts();
    // Create both series while another currency is active so due bills remain
    // pending (manualOnly = false) across both USD and JPY before restore.
    await preferences.setCurrency('EUR');
    await createAutoSeries(usdAccountId, description: 'USD rent');
    await createAutoSeries(jpyAccountId, description: 'JPY rent');
    await preferences.setCurrency('USD');

    final changed = await harness.recurringService.markPreRestoreManualOnly(
        DateTime.now());
    expect(changed, greaterThan(0), reason: 'due bills exist in both currencies');

    final instances = await scheduled();
    final dueBills = instances.where((i) => !i.date.isAfter(DateTime.now()));
    final futureBills = instances.where((i) => i.date.isAfter(DateTime.now()));

    expect(dueBills, isNotEmpty);
    expect(futureBills, isNotEmpty);
    expect(dueBills.every((i) => i.manualOnly), isTrue,
        reason: 'the watermark is currency-blind: every due bill is latched');
    expect(futureBills.every((i) => !i.manualOnly), isTrue,
        reason: 'future bills stay eligible');
    expect(
        dueBills.map((i) => i.account!.currencyCode).toSet(),
        containsAll({'USD', 'JPY'}),
        reason: 'fixture exercises both currencies');
  });

  test('catchUpAutoPosted only posts the current currency', () async {
    await seedAccounts();
    await preferences.setCurrency('EUR');
    await createAutoSeries(usdAccountId, description: 'USD rent');
    await createAutoSeries(jpyAccountId, description: 'JPY rent');
    await preferences.setCurrency('USD');

    final posted = await harness.recurringService.catchUpAutoPosted();
    expect(posted, greaterThan(0));

    for (final instance in await scheduled()) {
      if (instance.account!.currencyCode == 'USD' &&
          !instance.date.isAfter(DateTime.now())) {
        expect(instance.status, ScheduledTransactionStatus.posted,
            reason: 'the active currency settles itself');
      } else if (instance.account!.currencyCode == 'JPY' &&
          !instance.date.isAfter(DateTime.now())) {
        expect(instance.status, ScheduledTransactionStatus.scheduled,
            reason: 'another currency\'s backlog is left untouched');
      }
    }
  });

  test('getCurrencyBacklog only sees autoPost due bills of that currency',
      () async {
    await seedAccounts();
    await preferences.setCurrency('EUR');
    await createAutoSeries(usdAccountId, description: 'USD rent');
    await createAutoSeries(jpyAccountId, description: 'JPY rent');
    // A manual repeating series in the same currency must not appear.
    await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 30000,
      accountId: usdAccountId,
      categoryId: expenseCategoryId,
      description: 'Manual',
      frequency: 'MONTHLY',
      interval: 1,
      startDate: DateTime.now().subtract(const Duration(days: 40)),
    );
    await preferences.setCurrency('USD');

    final backlog =
        await harness.recurringService.getCurrencyBacklog('USD');

    expect(backlog, isNotEmpty);
    expect(backlog.every((i) => i.account!.currencyCode == 'USD'), isTrue);
    expect(backlog.every((i) => i.recurringTransactionSeries!.autoPost), isTrue,
        reason: 'manual bills are never a backlog');
    expect(backlog.every((i) => !i.date.isAfter(DateTime.now())), isTrue);
    expect(backlog.every((i) => !i.manualOnly), isTrue);
  });

  test('settleCurrencyBacklog posts all or freezes them, on the choice',
      () async {
    await seedAccounts();
    await preferences.setCurrency('EUR');
    await createAutoSeries(usdAccountId, description: 'USD rent');
    await createAutoSeries(jpyAccountId, description: 'JPY rent');
    await preferences.setCurrency('USD');

    // postAll: true settles the USD backlog immediately.
    final posted = await harness.recurringService
        .settleCurrencyBacklog('USD', postAll: true);
    expect(posted, greaterThan(0));

    // The JPY backlog is untouched and still frozen into manual bills by the
    // keep-pending arm.
    final frozen = await harness.recurringService
        .settleCurrencyBacklog('JPY', postAll: false);
    expect(frozen, 0);

    for (final instance in await scheduled()) {
      if (instance.account!.currencyCode == 'USD' &&
          !instance.date.isAfter(DateTime.now())) {
        expect(instance.status, ScheduledTransactionStatus.posted);
      } else if (instance.account!.currencyCode == 'JPY' &&
          !instance.date.isAfter(DateTime.now())) {
        expect(instance.manualOnly, isTrue,
            reason: 'keeping pending latches the bill for manual review');
        expect(instance.status, ScheduledTransactionStatus.scheduled);
      }
    }
  });

  test('a failing bill is marked failed and does not block the queue',
      () async {
    await seedAccounts();
    await preferences.setCurrency('EUR');
    await createAutoSeries(usdAccountId, description: 'USD rent');
    await preferences.setCurrency('USD');

    // Remove the category the series files under: posting now fails inside
    // the context resolver, after the catch-up predicate already admitted it.
    await harness.categoryService.archiveCategory(
      commandId: 'cmd_archive',
      categoryId: expenseCategoryId,
    );

    final posted = await harness.recurringService.catchUpAutoPosted();
    expect(posted, 0, reason: 'nothing could be posted');

    final dueBills = await due();
    expect(dueBills, isNotEmpty);
    expect(
        dueBills
            .every((i) => i.status == ScheduledTransactionStatus.failed),
        isTrue,
        reason: 'the failure is captured on the bill, not thrown into launch');
  });

  test('auto-posting planned bill in another currency enters currency backlog',
      () async {
    await seedAccounts();
    await preferences.setCurrency('EUR');
    await createAutoSeries(
      usdAccountId,
      description: 'Past planned',
      mode: RecurringSeriesMode.planned,
      startDate: DateTime.now().subtract(const Duration(days: 2)),
    );
    await preferences.setCurrency('USD');

    final backlog = await harness.recurringService.getCurrencyBacklog('USD');
    expect(backlog, hasLength(1));
    expect(backlog.single.recurringTransactionSeries?.mode,
        RecurringSeriesMode.planned);

    final posted = await harness.recurringService
        .settleCurrencyBacklog('USD', postAll: true);
    expect(posted, 1);
  });

  group('Two-stage auto-post circuit breaker & batch materialization', () {
    final fixedNow = DateTime(2026, 11, 26, 10, 0);

    Future<({LedgerServiceHarness h, String accId, String catId})>
        seedFixedHarness() async {
      final prefs = PreferencesRepositoryImpl(MockSharedPreferences());
      await prefs.setCurrency('USD');
      final h = LedgerServiceHarness(
        preferences: prefs,
        clock: FixedClock(fixedNow),
      );
      addTearDown(h.close);
      await h.seedSystemCategories();
      await h.accountService.createAccount(
        commandId: 'cmd_acc',
        name: 'Cash',
        type: AccountType.cash,
        initialBalanceMinor: 500000,
        currencyCode: 'USD',
      );
      await h.categoryService.createCategory(
        commandId: 'cmd_cat',
        name: 'Subscription',
        iconKey: '1',
        colorInt: 0xFF000000,
        type: CategoryType.expense,
      );
      final accId = (await h.db.accountDao.getAllAccounts()).single.id;
      final catId = await h.userCategoryId();
      return (h: h, accId: accId, catId: catId);
    }

    test(
        'Stage 1: due auto-post bills strictly older than 30 days are latched manualOnly without posting while recent eligible bills still post',
        () async {
      final env = await seedFixedHarness();

      // Monthly auto-post starting 2026-09-20 09:00:
      // 2026-09-20 and 2026-10-20 are > 30 days before 2026-11-26 10:00 (stale);
      // 2026-11-20 is 6 days old (eligible).
      await env.h.db.recurringDao.saveSeries(
        RecurringSeriesCompanion.insert(
          id: 'stale-and-recent',
          type: RecurringSeriesKind.expense,
          mode: const Value(RecurringSeriesMode.repeating),
          amountMinor: 10000,
          accountId: env.accId,
          categoryId: env.catId,
          description: 'Monthly sub',
          rrule: 'FREQ=MONTHLY',
          frequency: 'MONTHLY',
          startDate: DateTime(2026, 9, 20, 9, 0),
          autoPost: const Value(true),
        ),
      );
      await env.h.recurringService.materialize();

      final result =
          await env.h.recurringService.catchUpAutoPostedWithSummary();
      expect(result.staleLatchedCount, 2);
      expect(result.bulkLatchedCount, 0);
      expect(result.postedCount, 1);
      expect(result.circuitBreakerTripped, isTrue);
      expect(result.circuitBreakerLatchedCount, 2);

      final rows = (await env.h.db.recurringDao
          .scheduledForSeries('stale-and-recent'))
        ..sort((a, b) => a.occurrenceKey.compareTo(b.occurrenceKey));
      final sept = rows.firstWhere((r) => r.occurrenceKey == '2026-09-20');
      final oct = rows.firstWhere((r) => r.occurrenceKey == '2026-10-20');
      final nov = rows.firstWhere((r) => r.occurrenceKey == '2026-11-20');

      expect(sept.status, 'scheduled');
      expect(sept.manualOnly, isTrue);
      expect(oct.status, 'scheduled');
      expect(oct.manualOnly, isTrue);
      expect(nov.status, 'posted');

      final balance = await env.h.ledgerService.accountBalance(env.accId);
      expect(balance.balance, 500000 - 10000);

      final recordedEvents = (await env.h.eventStore.readAll())
          .events
          .where((e) => e.eventType == 'TransactionRecorded')
          .map((e) => TransactionRecorded.fromJson(e.payloadJson))
          .where((e) => e.sourceScheduledBillId != null)
          .toList();
      expect(recordedEvents, hasLength(1));
      expect(recordedEvents.single.sourceScheduledBillId, nov.id);
    });

    test(
        'Stage 2: more than 10 due auto-post bills within 30 days trips the bulk circuit breaker, latches all manualOnly, and leaves balance untouched',
        () async {
      final env = await seedFixedHarness();

      // 15 daily bills: Nov 12 .. Nov 26 (all within 30 days).
      await env.h.db.recurringDao.saveSeries(
        RecurringSeriesCompanion.insert(
          id: 'bulk-15-daily',
          type: RecurringSeriesKind.expense,
          mode: const Value(RecurringSeriesMode.repeating),
          amountMinor: 1000,
          accountId: env.accId,
          categoryId: env.catId,
          description: 'Daily coffee',
          rrule: 'FREQ=DAILY',
          frequency: 'DAILY',
          startDate: DateTime(2026, 11, 12, 9, 0),
          autoPost: const Value(true),
        ),
      );
      await env.h.recurringService.materialize();

      final result =
          await env.h.recurringService.catchUpAutoPostedWithSummary();
      expect(result.postedCount, 0);
      expect(result.staleLatchedCount, 0);
      expect(result.bulkLatchedCount, 15);
      expect(result.circuitBreakerTripped, isTrue);
      expect(result.circuitBreakerLatchedCount, 15);

      final dueRows = (await env.h.db.recurringDao
              .scheduledForSeries('bulk-15-daily'))
          .where((r) => !r.scheduledDate.isAfter(fixedNow))
          .toList();
      expect(dueRows, hasLength(15));
      expect(dueRows.every((r) => r.status == 'scheduled'), isTrue);
      expect(dueRows.every((r) => r.manualOnly), isTrue);

      final balance = await env.h.ledgerService.accountBalance(env.accId);
      expect(balance.balance, 500000);

      // Re-running is a clean no-op once latched.
      final rerun =
          await env.h.recurringService.catchUpAutoPostedWithSummary();
      expect(rerun, AutoPostCatchUpResult.empty);
    });

    test(
        'normal catch-up: 5 compliant due auto-post bills within 30 days post cleanly with sourceScheduledBillId and boundary 10 does not trip',
        () async {
      final env = await seedFixedHarness();

      // 5 daily bills: Nov 22 .. Nov 26.
      await env.h.db.recurringDao.saveSeries(
        RecurringSeriesCompanion.insert(
          id: 'five-daily',
          type: RecurringSeriesKind.expense,
          mode: const Value(RecurringSeriesMode.repeating),
          amountMinor: 1500,
          accountId: env.accId,
          categoryId: env.catId,
          description: 'Bus pass',
          rrule: 'FREQ=DAILY',
          frequency: 'DAILY',
          startDate: DateTime(2026, 11, 22, 9, 0),
          autoPost: const Value(true),
        ),
      );
      await env.h.recurringService.materialize();

      final result =
          await env.h.recurringService.catchUpAutoPostedWithSummary();
      expect(result.postedCount, 5);
      expect(result.circuitBreakerTripped, isFalse);

      final balance = await env.h.ledgerService.accountBalance(env.accId);
      expect(balance.balance, 500000 - 5 * 1500);

      final dueIds = (await env.h.db.recurringDao
              .scheduledForSeries('five-daily'))
          .where((r) => !r.scheduledDate.isAfter(fixedNow))
          .map((r) => r.id)
          .toSet();
      expect(dueIds, hasLength(5));

      final recordedSourceIds = (await env.h.eventStore.readAll())
          .events
          .where((e) => e.eventType == 'TransactionRecorded')
          .map((e) => TransactionRecorded.fromJson(e.payloadJson))
          .where((e) => e.sourceScheduledBillId != null)
          .map((e) => e.sourceScheduledBillId!)
          .toSet();
      expect(recordedSourceIds, dueIds);

      // Exact boundary of 10 bills must NOT trip the bulk circuit breaker.
      await env.h.db.recurringDao.saveSeries(
        RecurringSeriesCompanion.insert(
          id: 'ten-daily',
          type: RecurringSeriesKind.expense,
          mode: const Value(RecurringSeriesMode.repeating),
          amountMinor: 1000,
          accountId: env.accId,
          categoryId: env.catId,
          description: 'Ten boundary',
          rrule: 'FREQ=DAILY',
          frequency: 'DAILY',
          startDate: DateTime(2026, 11, 17, 9, 0),
          autoPost: const Value(true),
        ),
      );
      await env.h.recurringService.materialize();

      final boundaryResult =
          await env.h.recurringService.catchUpAutoPostedWithSummary();
      expect(boundaryResult.postedCount, 10);
      expect(boundaryResult.circuitBreakerTripped, isFalse);
    });

    test(
        'batch auto-posting (catchUpAutoPosted and settleCurrencyBacklog) materializes once after the full batch rather than once per posted bill',
        () async {
      final env = await seedFixedHarness();
      final contextResolver = PostingContextResolver(
        env.h.accountRepository,
        env.h.categoryRepository,
      );
      final countingMaterialize = _CountingMaterializeCommand(
        env.h.recurringRepository,
        clock: FixedClock(fixedNow),
      );
      final service = RecurringService(
        CreateRecurringSeriesCommand(env.h.recurringRepository, contextResolver),
        DeleteRecurringBillCommand(env.h.recurringRepository),
        UpdateRecurringBillCommand(
          env.h.recurringRepository,
          contextResolver,
          clock: FixedClock(fixedNow),
        ),
        ConvertScheduledToPostedCommand(
          env.h.eventStore,
          env.h.projector,
          env.h.recurringRepository,
          contextResolver,
        ),
        countingMaterialize,
        WatchScheduledTransactionsQuery(env.h.recurringRepository),
        GetScheduledTransactionQuery(env.h.recurringRepository),
        env.h.recurringRepository,
        restoreSkipped: RestoreSkippedBillCommand(
          env.h.recurringRepository,
          clock: FixedClock(fixedNow),
        ),
        preferences: env.h.preferences,
        clock: FixedClock(fixedNow),
      );

      // Seed 5 due bills in USD for catchUpAutoPosted.
      await env.h.db.recurringDao.saveSeries(
        RecurringSeriesCompanion.insert(
          id: 'batch-catchup',
          type: RecurringSeriesKind.expense,
          mode: const Value(RecurringSeriesMode.repeating),
          amountMinor: 500,
          accountId: env.accId,
          categoryId: env.catId,
          description: 'Batch catchup',
          rrule: 'FREQ=DAILY',
          frequency: 'DAILY',
          startDate: DateTime(2026, 11, 22, 9, 0),
          autoPost: const Value(true),
        ),
      );
      await service.materialize();
      countingMaterialize.executeCount = 0;

      final catchUpPosted = await service.catchUpAutoPosted();
      expect(catchUpPosted, 5);
      expect(countingMaterialize.executeCount, 1,
          reason: 'catchUpAutoPosted must materialize once after the batch');

      // Seed 5 due bills in EUR for settleCurrencyBacklog(postAll: true).
      await env.h.accountService.createAccount(
        commandId: 'cmd_acc_eur',
        name: 'Euro Cash',
        type: AccountType.cash,
        initialBalanceMinor: 500000,
        currencyCode: 'EUR',
      );
      final eurAccId = (await env.h.db.accountDao.getAllAccounts())
          .firstWhere((a) => a.currencyCode == 'EUR')
          .id;
      await env.h.db.recurringDao.saveSeries(
        RecurringSeriesCompanion.insert(
          id: 'batch-backlog',
          type: RecurringSeriesKind.expense,
          mode: const Value(RecurringSeriesMode.repeating),
          amountMinor: 500,
          accountId: eurAccId,
          categoryId: env.catId,
          description: 'Batch backlog',
          rrule: 'FREQ=DAILY',
          frequency: 'DAILY',
          startDate: DateTime(2026, 11, 22, 9, 0),
          autoPost: const Value(true),
        ),
      );
      await service.materialize();
      countingMaterialize.executeCount = 0;

      final backlogPosted =
          await service.settleCurrencyBacklog('EUR', postAll: true);
      expect(backlogPosted, 5);
      expect(countingMaterialize.executeCount, 1,
          reason:
              'settleCurrencyBacklog(postAll: true) must materialize once after the batch');
    });
  });
}
