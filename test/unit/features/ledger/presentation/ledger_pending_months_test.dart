import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_monthly_pending_bills_query.dart';
import 'package:feather_ledger/features/ledger/domain/services/ledger_service.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';

import '../../../../support/event_sourcing/ledger_service_harness.dart';

/// The month picker's marker derives from every pending bill's own month
/// (spec 006, US33), scoped to the setting's currency.
void main() {
  test('pendingBillMonths marks every month that still owes a bill', () async {
    final harness = LedgerServiceHarness();
    addTearDown(harness.close);
    await harness.seedSystemCategories();
    await harness.accountService.createAccount(
      commandId: 'cmd_acc',
      name: 'Cash',
      type: AccountType.cash,
      initialBalanceMinor: 100000,
      currencyCode: 'USD',
    );
    final account = (await harness.db.accountDao.getAllAccounts()).single;
    await harness.categoryService.createCategory(
      commandId: 'cmd_cat',
      name: 'Rent',
      iconKey: '1',
      colorInt: 0xFF000000,
      type: CategoryType.expense,
    );

    // A monthly series starting this month produces bills in the current month
    // and the next, the full calendar-month lookahead the picker must mark.
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final result = await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 100,
      accountId: account.id,
      categoryId: await harness.userCategoryId(),
      description: 'Monthly',
      frequency: 'MONTHLY',
      interval: 1,
      startDate: start,
    );
    expect(result, isA<Success<void>>());

    final container = ProviderContainer(
      overrides: [
        currencyControllerProvider.overrideWith(_FixedCurrency.new),
        ledgerServiceProvider.overrideWithValue(harness.ledgerService),
        watchMonthlyPendingBillsQueryProvider.overrideWithValue(
          WatchMonthlyPendingBillsQuery(
              harness.recurringRepository, harness.clock),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currencyControllerProvider.future);
    container.listen(pendingBillMonthsProvider, (_, __) {});
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final months = container.read(pendingBillMonthsProvider).value;
    expect(months, isNotNull);
    expect(months, contains(DateTime(start.year, start.month)));
    expect(months, contains(DateTime(start.year, start.month + 1)));
  });

  test(
      'pendingBillMonths ignores skipped-only months while monthlyPendingTransactions includes skipped and failed',
      () async {
    final harness = LedgerServiceHarness();
    addTearDown(harness.close);
    await harness.seedSystemCategories();
    await harness.accountService.createAccount(
      commandId: 'cmd_acc',
      name: 'Cash',
      type: AccountType.cash,
      initialBalanceMinor: 100000,
      currencyCode: 'USD',
    );
    final account = (await harness.db.accountDao.getAllAccounts()).single;
    await harness.categoryService.createCategory(
      commandId: 'cmd_cat',
      name: 'Rent',
      iconKey: '1',
      colorInt: 0xFF000000,
      type: CategoryType.expense,
    );

    final now = DateTime.now();
    final month1 = DateTime(now.year, now.month, 5);
    final month2 = DateTime(now.year, now.month + 1, 5);
    await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 1000,
      accountId: account.id,
      categoryId: await harness.userCategoryId(),
      description: 'Monthly',
      frequency: 'MONTHLY',
      interval: 1,
      startDate: month1,
    );

    final bills = await harness.recurringService.watchScheduled().first;
    final m1Bill = bills.firstWhere(
        (b) => b.date.year == month1.year && b.date.month == month1.month);
    final m2Bill = bills.firstWhere(
        (b) => b.date.year == month2.year && b.date.month == month2.month);

    // Skip month1 bill and mark month2 bill failed.
    await harness.recurringService
        .deleteBill(m1Bill.id, scope: RecurringScope.thisOnly);
    await (harness.db.update(harness.db.scheduledTransactionsView)
          ..where((t) => t.id.equals(m2Bill.id)))
        .write(
            const ScheduledTransactionsViewCompanion(status: Value('failed')));

    final container = ProviderContainer(
      overrides: [
        currencyControllerProvider.overrideWith(_FixedCurrency.new),
        ledgerServiceProvider.overrideWithValue(harness.ledgerService),
        watchMonthlyPendingBillsQueryProvider.overrideWithValue(
          WatchMonthlyPendingBillsQuery(
              harness.recurringRepository, harness.clock),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currencyControllerProvider.future);
    container.listen(pendingBillMonthsProvider, (_, __) {});
    container.listen(monthlyPendingTransactionsProvider(month1), (_, __) {});
    container.listen(monthlyPendingTransactionsProvider(month2), (_, __) {});
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final months = container.read(pendingBillMonthsProvider).value;
    expect(months, isNotNull);
    expect(months, isNot(contains(DateTime(month1.year, month1.month))));
    expect(months, contains(DateTime(month2.year, month2.month)));

    final m1Pending =
        container.read(monthlyPendingTransactionsProvider(month1)).value;
    expect(m1Pending, hasLength(1));
    expect(m1Pending!.single.isSkipped, isTrue);

    final m2Pending =
        container.read(monthlyPendingTransactionsProvider(month2)).value;
    expect(m2Pending, hasLength(1));
    expect(m2Pending!.single.isFailed, isTrue);
  });

  test('pendingBillMonths stays physical while a far month is virtual',
      () async {
    final now = DateTime(2026, 5, 15, 10);
    final harness = LedgerServiceHarness(clock: FixedClock(now));
    addTearDown(harness.close);
    await harness.seedAccount(
      id: 'acc-cash',
      name: 'Cash',
      currencyCode: 'USD',
    );
    await harness.categoryService.createCategory(
      commandId: 'cmd_cat_far',
      categoryId: 'far-cat',
      name: 'Rent',
      iconKey: '1',
      colorInt: 0xFF000000,
      type: CategoryType.expense,
    );

    final farMonth = DateTime(2026, 11);
    await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 100,
      accountId: 'acc-cash',
      categoryId: 'far-cat',
      description: 'Daily lunch',
      frequency: 'DAILY',
      startDate: DateTime(2026, 5, 1, 12),
    );

    final container = ProviderContainer(
      overrides: [
        currencyControllerProvider.overrideWith(_FixedCurrency.new),
        ledgerServiceProvider.overrideWithValue(harness.ledgerService),
        watchMonthlyPendingBillsQueryProvider.overrideWithValue(
          WatchMonthlyPendingBillsQuery(
              harness.recurringRepository, harness.clock),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currencyControllerProvider.future);
    container.listen(pendingBillMonthsProvider, (_, __) {});
    container.listen(monthlyPendingTransactionsProvider(farMonth), (_, __) {});
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final months = container.read(pendingBillMonthsProvider).value;
    expect(months, isNotNull);
    expect(months, isNot(contains(farMonth)));

    final farPending =
        container.read(monthlyPendingTransactionsProvider(farMonth)).value;
    expect(farPending, hasLength(30));
    expect(farPending!.every((bill) => bill.isVirtual), isTrue);
  });
}

class _FixedCurrency extends CurrencyController {
  @override
  Future<String> build() async => 'USD';
}
