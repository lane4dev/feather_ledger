import 'package:flutter_test/flutter_test.dart';

import 'package:drift/drift.dart' show Value;

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/domain/entities/automatic_posting_batch.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

import '../../../../../support/event_sourcing/ledger_service_harness.dart';
import '../../../../../support/mocks/mock_shared_preferences.dart';

/// The automatic-posting batch loop (spec 006, US37/39/46–54).
///
/// Catch-up runs after the first frame, settles eligible due bills in a
/// bounded batch with a fixed cutoff, and persists per-member results so an
/// interruption or a retry never double-posts. Everything here goes through
/// [RecurringService] and [RecurringRepository] — the same seams bootstrap
/// uses.
void main() {
  late LedgerServiceHarness harness;

  setUp(() async {
    harness = LedgerServiceHarness();
    await harness.seedSystemCategories();
  });
  tearDown(() => harness.close());

  /// Rebuilds the harness with the ticket-28 gate open and the 订阅 switch
  /// on (ticket 31: the switch must be on for a due subscription to post).
  Future<void> restartHarness() async {
    await harness.close();
    final prefs = PreferencesRepositoryImpl(MockSharedPreferences());
    await prefs.setAutoPostEnabled(RecurringSeriesMode.subscription, true);
    await prefs.setAutoPostEnabledSince(RecurringSeriesMode.subscription,
        DateTime.now().subtract(const Duration(days: 30)));
    harness = LedgerServiceHarness(autoPostEnabled: true, preferences: prefs);
    await harness.seedSystemCategories();
  }

  late String accountId;
  late String expenseCategoryId;

  Future<void> seed() async {
    await harness.accountService.createAccount(
      commandId: 'cmd_acc',
      name: 'Cash',
      type: AccountType.cash,
      initialBalanceMinor: 100000,
      currencyCode: 'USD',
    );
    await harness.categoryService.createCategory(
      commandId: 'cmd_cat',
      name: 'Rent',
      iconKey: '1',
      colorInt: 0xFF000000,
      type: CategoryType.expense,
    );
    accountId = (await harness.db.accountDao.getAllAccounts()).single.id;
    final categories = await harness.db.categoriesDao.getAllCategories();
    expenseCategoryId = categories.firstWhere((c) => c.name == 'Rent').id;
  }

  /// A subscription series whose single bill is already due. Its due bill is
  /// latched manual at creation (US32), so re-arm it before catch-up.
  Future<ScheduledTransactionEntity> createDueBill() async {
    await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 20000,
      accountId: accountId,
      categoryId: expenseCategoryId,
      description: 'Rent',
      frequency: 'MONTHLY',
      interval: 1,
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      autoPost: true,
      mode: RecurringSeriesMode.subscription,
    );
    final now = DateTime.now();
    final instances = await harness.recurringService.watchScheduled().first;
    final due = instances.singleWhere((i) => !i.date.isAfter(now));
    final row = await harness.db.recurringDao.getScheduled(due.id);
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
    return due;
  }

  Future<int> accountBalance() async =>
      (await harness.db.accountDao.getAccountById(accountId))!.balanceMinor;

  test('a catch-up creates a fixed-cutoff batch and posts its due bills',
      () async {
    await restartHarness();
    await seed();
    final due = await createDueBill();

    await harness.recurringService.catchUpAutoPosted();

    // The bill was actually posted, exactly once.
    final row = await harness.db.recurringDao.getScheduled(due.id);
    expect(row!.status, 'posted');
    expect(await accountBalance(), 100000 - 20000);

    // A batch was persisted with a cutoff that never reaches into the future.
    final batch =
        await harness.recurringRepository.latestAutomaticPostingBatch();
    expect(batch, isNotNull);
    expect(batch!.cutoff.isAfter(DateTime.now()), isFalse);

    // And its member result records the outcome.
    final members =
        await harness.recurringRepository.automaticPostingMembers(batch.id);
    expect(members, hasLength(1));
    expect(members.single.result, AutomaticPostingMemberResult.succeeded);
  });

  test('a pending member from an interrupted run resumes without double posting',
      () async {
    await restartHarness();
    await seed();
    final due = await createDueBill();

    // Simulate a crash right after the batch claimed the bill but before the
    // post landed: a pending member row with no transaction yet.
    final oldBatchId = await harness.recurringRepository
        .createAutomaticPostingBatch(DateTime.now());
    await harness.recurringRepository.setAutomaticPostingMemberResult(
        oldBatchId, due.id, AutomaticPostingMemberResult.pending);

    await harness.recurringService.catchUpAutoPosted();

    // The interrupted member settled to succeeded in its ORIGINAL batch.
    final oldMembers = await harness.recurringRepository
        .automaticPostingMembers(oldBatchId);
    expect(oldMembers.single.result, AutomaticPostingMemberResult.succeeded);

    // The bill posted exactly once — resume never double-posts.
    final row = await harness.db.recurringDao.getScheduled(due.id);
    expect(row!.status, 'posted');
    expect(await accountBalance(), 100000 - 20000);
  });

  test('a failed member retries and updates its original batch result',
      () async {
    await restartHarness();
    await seed();
    final due = await createDueBill();

    // Simulate a previous run whose post failed: the member is marked failed
    // and the bill is still scheduled.
    final oldBatchId = await harness.recurringRepository
        .createAutomaticPostingBatch(DateTime.now());
    await harness.recurringRepository.setAutomaticPostingMemberResult(
        oldBatchId, due.id, AutomaticPostingMemberResult.failed);

    await harness.recurringService.catchUpAutoPosted();

    // The retry succeeded and replaced the failed result in place.
    final oldMembers = await harness.recurringRepository
        .automaticPostingMembers(oldBatchId);
    expect(oldMembers.single.result, AutomaticPostingMemberResult.succeeded);

    final row = await harness.db.recurringDao.getScheduled(due.id);
    expect(row!.status, 'posted');
    expect(await accountBalance(), 100000 - 20000);
  });

  test('a bill the user already posted is recorded as user-handled', () async {
    await restartHarness();
    await seed();
    final due = await createDueBill();

    // The user posts it themselves before catch-up runs.
    await harness.recurringService.postInstance(due.id);

    await harness.recurringService.catchUpAutoPosted();

    // No double post: the balance moved once and the member says user-handled.
    expect(await accountBalance(), 100000 - 20000);
    final batch =
        await harness.recurringRepository.latestAutomaticPostingBatch();
    final members = await harness.recurringRepository
        .automaticPostingMembers(batch!.id);
    expect(members, hasLength(1));
    expect(members.single.result, AutomaticPostingMemberResult.userHandled);
  });
}
