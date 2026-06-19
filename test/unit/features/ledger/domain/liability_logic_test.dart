import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';

import '../../../../support/event_sourcing/ledger_service_harness.dart';

/// Liability logic (spec 003, US4): a credit-card account carries a
/// negative balance for expenses — expense posting goes debit against the
/// credit account, payment (income) goes credit.
void main() {
  test('Liability logic: Expense increases debt (negative balance)', () async {
    final harness = LedgerServiceHarness();

    await harness.accountService.createAccount(
      commandId: 'cmd_create_credit',
      name: 'Credit Card',
      type: AccountType.credit,
      initialBalanceMinor: 0,
      currencyCode: 'USD',
    );
    final account = (await harness.db.accountDao.getAllAccounts()).single;
    await harness.categoryService.createCategory(
      commandId: 'cmd_create_cat',
      name: 'Shopping',
      iconKey: '1',
      colorInt: 0xFF000000,
      type: CategoryType.expense,
    );
    final category = (await harness.db.categoriesDao.getAllCategories()).single;

    // 1. Post Expense of 50.00
    final result = await harness.ledgerService.addTransaction(
      commandId: 'cmd_liability_expense',
      amountMinor: 5000,
      type: TransactionKind.expense,
      date: DateTime.now(),
      categoryId: category.id,
      accountId: account.id,
    );
    expect(result, isA<Success<void>>());

    final updated = await harness.db.accountDao.getAccountById(account.id);
    expect(updated!.balanceMinor, -5000, reason: 'debt grows with expenses');

    final events = (await harness.eventStore.readAll()).events;
    expect(events.where((e) => e.eventType == 'TransactionRecorded'),
        hasLength(1));

    await harness.close();
  });

  test('Liability logic: Payment (Income) decreases debt', () async {
    final harness = LedgerServiceHarness();

    await harness.accountService.createAccount(
      commandId: 'cmd_create_credit',
      name: 'Credit Card',
      type: AccountType.credit,
      initialBalanceMinor: 0,
      currencyCode: 'USD',
    );
    final account = (await harness.db.accountDao.getAllAccounts()).single;
    await harness.categoryService.createCategory(
      commandId: 'cmd_create_cat',
      name: 'Salary',
      iconKey: '1',
      colorInt: 0xFF000000,
      type: CategoryType.income,
    );
    final incomeCategory =
        (await harness.db.categoriesDao.getAllCategories()).single;
    await harness.categoryService.createCategory(
      commandId: 'cmd_create_expense_cat',
      name: 'Shopping',
      iconKey: '2',
      colorInt: 0xFF000000,
      type: CategoryType.expense,
    );
    final expenseCategory = (await harness.db.categoriesDao.getAllCategories())
        .firstWhere((c) => c.type == CategoryType.expense);

    // Expense first, then payment.
    await harness.ledgerService.addTransaction(
      commandId: 'cmd_liability_expense',
      amountMinor: 5000,
      type: TransactionKind.expense,
      date: DateTime.now(),
      categoryId: expenseCategory.id,
      accountId: account.id,
    );
    final result = await harness.ledgerService.addTransaction(
      commandId: 'cmd_liability_payment',
      amountMinor: 5000,
      type: TransactionKind.income,
      date: DateTime.now(),
      categoryId: incomeCategory.id,
      accountId: account.id,
    );
    expect(result, isA<Success<void>>());

    final updated = await harness.db.accountDao.getAccountById(account.id);
    expect(updated!.balanceMinor, 0, reason: 'payment clears the debt');

    await harness.close();
  });
}
