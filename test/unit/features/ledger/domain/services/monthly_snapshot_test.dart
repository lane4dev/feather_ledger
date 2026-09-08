import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';

import '../../../../../support/event_sourcing/ledger_service_harness.dart';

/// Monthly account balance snapshot service tests (spec 003, US7/T055):
/// opening/closing chains, empty-month materialization, transfer columns,
/// historical correction cascades and the eventSequenceFrom/To bracket.
void main() {
  late LedgerServiceHarness harness;

  setUp(() => harness = LedgerServiceHarness());
  tearDown(() => harness.close());

  late String cashId;
  late String foodId;

  Future<void> seedCashAndFood() async {
    await harness.accountService.createAccount(
      commandId: 'cmd_seed_cash',
      name: 'Cash',
      type: AccountType.cash,
      initialBalanceMinor: 0,
      currencyCode: 'USD',
    );
    await harness.categoryService.createCategory(
      commandId: 'cmd_seed_food',
      name: 'Food',
      iconKey: '1',
      colorInt: 0xFF000000,
      type: CategoryType.expense,
    );
    cashId = (await harness.db.accountDao.getAllAccounts())
        .firstWhere((a) => a.name == 'Cash')
        .id;
    foodId = (await harness.db.categoriesDao.getAllCategories()).single.id;
  }

  Future<void> recordExpense(
    int amountMinor, {
    required String commandId,
    required DateTime date,
  }) async {
    final result = await harness.ledgerService.addTransaction(
      commandId: commandId,
      amountMinor: amountMinor,
      type: TransactionKind.expense,
      date: date,
      categoryId: foodId,
      accountId: cashId,
    );
    expect(result, isA<Success<void>>());
  }

  test('opening balance anchors the first month and the chain carries on',
      () async {
    final now = DateTime.now();
    final m0 = (now.year, now.month);
    final m1 = m0.$2 == 12 ? (m0.$1 + 1, 1) : (m0.$1, m0.$2 + 1);

    final result = await harness.accountService.createAccount(
      commandId: 'cmd_bank',
      name: 'Bank',
      type: AccountType.bank,
      initialBalanceMinor: 100000,
      currencyCode: 'USD',
    );
    expect(result, isA<Success<void>>());
    final bankId = (await harness.db.accountDao.getAllAccounts())
        .firstWhere((a) => a.name == 'Bank')
        .id;

    // The creation month's row is anchored by OpeningBalanceSet.
    var row = await harness.db.monthlySnapshotDao
        .getForAccount(bankId, m0.$1, m0.$2);
    expect(row, isNotNull);
    expect(row!.openingBalanceMinor, 100000);
    expect(row.closingBalanceMinor, 100000);
    expect(row.netChangeMinor, 0);
    expect(row.isClosed, false);

    await harness.categoryService.createCategory(
      commandId: 'cmd_food_bank',
      name: 'Food',
      iconKey: '1',
      colorInt: 0xFF000000,
      type: CategoryType.expense,
    );
    final foodBankId =
        (await harness.db.categoriesDao.getAllCategories()).single.id;
    await harness.ledgerService.addTransaction(
      commandId: 'cmd_expense_m0',
      amountMinor: 3000,
      type: TransactionKind.expense,
      date: DateTime(m0.$1, m0.$2, 15),
      categoryId: foodBankId,
      accountId: bankId,
    );

    row = await harness.db.monthlySnapshotDao
        .getForAccount(bankId, m0.$1, m0.$2);
    expect(row!.openingBalanceMinor, 100000);
    expect(row.netChangeMinor, -3000);
    expect(row.expenseMinor, -3000);
    expect(row.closingBalanceMinor, 97000);
    expect(row.transactionCount, 1);

    // Next month: opening = previous closing.
    await harness.ledgerService.addTransaction(
      commandId: 'cmd_expense_m1',
      amountMinor: 5000,
      type: TransactionKind.expense,
      date: DateTime(m1.$1, m1.$2, 10),
      categoryId: foodBankId,
      accountId: bankId,
    );
    row = await harness.db.monthlySnapshotDao
        .getForAccount(bankId, m1.$1, m1.$2);
    expect(row!.openingBalanceMinor, 97000);
    expect(row.closingBalanceMinor, 92000);

    // The header totals read the same snapshot projection.
    final totals = await harness.ledgerService
        .watchMonthlySnapshot(DateTime(m1.$1, m1.$2))
        .first;
    expect(totals.expenseMinor, -5000);
    expect(totals.incomeMinor, 0);
    expect(totals.balanceMinor, 92000,
        reason: 'current balance includes the future-dated posting');
  });

  test('empty months materialize with zero net between events', () async {
    await seedCashAndFood();
    await recordExpense(3000, commandId: 'cmd_jan', date: DateTime(2026, 1, 10));

    final jan = await harness.db.monthlySnapshotDao
        .getForAccount(cashId, 2026, 1);
    expect(jan!.openingBalanceMinor, 0,
        reason: 'no OpeningBalanceSet → anchor opening is 0');
    expect(jan.closingBalanceMinor, -3000);
    expect(jan.transactionCount, 1);

    // February has no events: net zero, opening = January's closing.
    final feb = await harness.db.monthlySnapshotDao
        .getForAccount(cashId, 2026, 2);
    expect(feb, isNotNull, reason: 'empty months materialize (spec US7)');
    expect(feb!.openingBalanceMinor, -3000);
    expect(feb.closingBalanceMinor, -3000);
    expect(feb.netChangeMinor, 0);
    expect(feb.transactionCount, 0);
    expect(feb.incomeMinor, 0);
    expect(feb.expenseMinor, 0);
  });

  test('transfer legs land in transferIn/Out, never income/expense', () async {
    await seedCashAndFood();
    await harness.accountService.createAccount(
      commandId: 'cmd_seed_savings',
      name: 'Savings',
      type: AccountType.bank,
      initialBalanceMinor: 0,
      currencyCode: 'USD',
    );
    final savingsId = (await harness.db.accountDao.getAllAccounts())
        .firstWhere((a) => a.name == 'Savings')
        .id;

    final result = await harness.ledgerService.addTransfer(
      commandId: 'cmd_transfer',
      amountMinor: 50000,
      fromAccountId: savingsId,
      toAccountId: cashId,
      date: DateTime(2026, 1, 15),
    );
    expect(result, isA<Success<void>>());

    final savings = await harness.db.monthlySnapshotDao
        .getForAccount(savingsId, 2026, 1);
    expect(savings!.transferOutMinor, -50000);
    expect(savings.transferInMinor, 0);
    expect(savings.incomeMinor, 0);
    expect(savings.expenseMinor, 0);
    expect(savings.netChangeMinor, -50000);

    final cash = await harness.db.monthlySnapshotDao
        .getForAccount(cashId, 2026, 1);
    expect(cash!.transferInMinor, 50000);
    expect(cash.transferOutMinor, 0);
    expect(cash.incomeMinor, 0);
    expect(cash.expenseMinor, 0);
    expect(cash.netChangeMinor, 50000);

    final totals = await harness.ledgerService
        .watchMonthlySnapshot(DateTime(2026, 1))
        .first;
    expect(totals.incomeMinor, 0);
    expect(totals.expenseMinor, 0,
        reason: 'transfers never pollute income/expense statistics');
  });

  test('correction and deletion cascade through following months', () async {
    await seedCashAndFood();
    await recordExpense(5000, commandId: 'cmd_original', date: DateTime(2026, 1, 10));
    final originalId = (await harness.ledgerService
            .watchTransactions(DateTime(2026, 1))
            .first)
        .single
        .id;

    // Correction: the January row is rewritten to the new amount and
    // February's opening follows it.
    await harness.ledgerService.updateTransaction(
      commandId: 'cmd_correct',
      id: originalId,
      amountMinor: 8000,
      type: TransactionKind.expense,
      date: DateTime(2026, 1, 10),
      categoryId: foodId,
      accountId: cashId,
    );
    var jan = await harness.db.monthlySnapshotDao
        .getForAccount(cashId, 2026, 1);
    expect(jan!.expenseMinor, -8000);
    expect(jan.closingBalanceMinor, -8000);
    var feb = await harness.db.monthlySnapshotDao
        .getForAccount(cashId, 2026, 2);
    expect(feb!.openingBalanceMinor, -8000,
        reason: 'cascade: the month after the edit re-anchors');

    // Deletion: the original month nets zero and the chain follows.
    final correctedId = (await harness.ledgerService
            .watchTransactions(DateTime(2026, 1))
            .first)
        .single
        .id;
    final deleted = await harness.ledgerService.deleteTransaction(correctedId,
        commandId: 'cmd_delete');
    expect(deleted, isA<Success<void>>());
    jan = await harness.db.monthlySnapshotDao.getForAccount(cashId, 2026, 1);
    expect(jan!.netChangeMinor, 0);
    expect(jan.expenseMinor, 0);
    expect(jan.closingBalanceMinor, 0);
    feb = await harness.db.monthlySnapshotDao.getForAccount(cashId, 2026, 2);
    expect(feb!.openingBalanceMinor, 0);
  });

  test('eventSequenceFrom/To bracket the events behind the row', () async {
    await seedCashAndFood();
    await recordExpense(3000, commandId: 'cmd_first', date: DateTime(2026, 1, 10));

    final events = (await harness.eventStore.readAll()).events;
    final anchorGsn = events
        .firstWhere((e) => e.eventType == 'AccountCreated' && e.streamId == cashId)
        .globalSequenceNumber!;

    var jan = await harness.db.monthlySnapshotDao
        .getForAccount(cashId, 2026, 1);
    expect(jan!.eventSequenceFrom, anchorGsn);
    expect(jan.eventSequenceTo, events.last.globalSequenceNumber);

    // A second transaction advances only `to`.
    await recordExpense(4000, commandId: 'cmd_second', date: DateTime(2026, 1, 20));
    final eventsAfter = (await harness.eventStore.readAll()).events;
    jan = await harness.db.monthlySnapshotDao.getForAccount(cashId, 2026, 1);
    expect(jan!.eventSequenceFrom, anchorGsn);
    expect(jan.eventSequenceTo, eventsAfter.last.globalSequenceNumber);
  });
}
