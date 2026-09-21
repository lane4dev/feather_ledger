import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/features/ledger/domain/services/ledger_service.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';

import '../../../../support/event_sourcing/ledger_service_harness.dart';

/// The month picker's marker derives from every pending bill's own month
/// (spec 006, US33), scoped to the setting's currency.
void main() {
  test('pendingBillMonths marks every month that still owes a bill',
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

    // A monthly series starting next month produces upcoming bills across
    // multiple future months within the 90-day lookahead, none of which
    // the picker may hide.
    final now = DateTime.now();
    final start = DateTime(now.year, now.month + 1, 1);
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
}

class _FixedCurrency extends CurrencyController {
  @override
  Future<String> build() async => 'USD';
}
