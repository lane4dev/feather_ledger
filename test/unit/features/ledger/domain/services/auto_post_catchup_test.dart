import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

import '../../../../../support/event_sourcing/ledger_service_harness.dart';
import '../../../../../support/mocks/mock_shared_preferences.dart';

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
        startDate ?? DateTime.now().subtract(const Duration(days: 40));
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
}
