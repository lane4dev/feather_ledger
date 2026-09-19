import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';

import '../../../../../support/event_sourcing/ledger_service_harness.dart';

/// Monthly account balance snapshot service tests (spec 003, US7/T055):
/// opening/closing chains, empty-month materialization, transfer columns,
/// historical correction cascades and the eventSequenceFrom/To bracket.
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
    foodId = await harness.userCategoryId();
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

    // The creation month opens at zero and the starting balance lands as a
    // visible, category-free opening-balance transaction dated today. It
    // changes the balance but not this month's income.
    var row =
        await harness.db.monthlySnapshotDao.getForAccount(bankId, m0.$1, m0.$2);
    expect(row, isNotNull);
    expect(row!.openingBalanceMinor, 0);
    expect(row.incomeMinor, 0);
    expect(row.netChangeMinor, 100000);
    expect(row.closingBalanceMinor, 100000);
    expect(row.isClosed, false);

    await harness.categoryService.createCategory(
      commandId: 'cmd_food_bank',
      name: 'Food',
      iconKey: '1',
      colorInt: 0xFF000000,
      type: CategoryType.expense,
    );
    final foodBankId = await harness.userCategoryId();
    await harness.ledgerService.addTransaction(
      commandId: 'cmd_expense_m0',
      amountMinor: 3000,
      type: TransactionKind.expense,
      date: DateTime(m0.$1, m0.$2, 15),
      categoryId: foodBankId,
      accountId: bankId,
    );

    row =
        await harness.db.monthlySnapshotDao.getForAccount(bankId, m0.$1, m0.$2);
    expect(row!.openingBalanceMinor, 0);
    expect(row.netChangeMinor, 97000);
    expect(row.expenseMinor, -3000);
    expect(row.closingBalanceMinor, 97000);
    expect(row.transactionCount, 2,
        reason: 'the opening balance and the expense');

    // Next month: opening = previous closing.
    await harness.ledgerService.addTransaction(
      commandId: 'cmd_expense_m1',
      amountMinor: 5000,
      type: TransactionKind.expense,
      date: DateTime(m1.$1, m1.$2, 10),
      categoryId: foodBankId,
      accountId: bankId,
    );
    row =
        await harness.db.monthlySnapshotDao.getForAccount(bankId, m1.$1, m1.$2);
    expect(row!.openingBalanceMinor, 97000);
    expect(row.closingBalanceMinor, 92000);

    // The header's three figures: income and expense are this month's, the
    // balance is the live accounts total — the same 92000 the account row
    // holds, read whatever month is on screen.
    final totals = await harness.ledgerService
        .watchMonthlySnapshot(DateTime(m1.$1, m1.$2), currencyCode: 'USD')
        .first;
    expect(totals.expenseMinor, -5000);
    expect(totals.incomeMinor, 0);
    expect(totals.balanceMinor, 92000,
        reason: 'current balance includes the future-dated posting');

    final previous = await harness.ledgerService
        .watchMonthlySnapshot(DateTime(m0.$1, m0.$2), currencyCode: 'USD')
        .first;
    expect(previous.balanceMinor, 92000,
        reason: 'the balance is not a month figure — it does not move with '
            'the month, while the month\'s own closing balance does (97000)');
  });

  test('empty months materialize with zero net between events', () async {
    await seedCashAndFood();
    await recordExpense(3000,
        commandId: 'cmd_jan', date: DateTime(2026, 1, 10));

    final jan =
        await harness.db.monthlySnapshotDao.getForAccount(cashId, 2026, 1);
    expect(jan!.openingBalanceMinor, 0,
        reason: 'Cash carries no starting balance → anchor opening is 0');
    expect(jan.closingBalanceMinor, -3000);
    expect(jan.transactionCount, 1);

    // February has no events: net zero, opening = January's closing.
    final feb =
        await harness.db.monthlySnapshotDao.getForAccount(cashId, 2026, 2);
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

    final savings =
        await harness.db.monthlySnapshotDao.getForAccount(savingsId, 2026, 1);
    expect(savings!.transferOutMinor, -50000);
    expect(savings.transferInMinor, 0);
    expect(savings.incomeMinor, 0);
    expect(savings.expenseMinor, 0);
    expect(savings.netChangeMinor, -50000);

    final cash =
        await harness.db.monthlySnapshotDao.getForAccount(cashId, 2026, 1);
    expect(cash!.transferInMinor, 50000);
    expect(cash.transferOutMinor, 0);
    expect(cash.incomeMinor, 0);
    expect(cash.expenseMinor, 0);
    expect(cash.netChangeMinor, 50000);

    final totals = await harness.ledgerService
        .watchMonthlySnapshot(DateTime(2026, 1), currencyCode: 'USD')
        .first;
    expect(totals.incomeMinor, 0);
    expect(totals.expenseMinor, 0,
        reason: 'transfers never pollute income/expense statistics');
  });

  test('correction and deletion cascade through following months', () async {
    await seedCashAndFood();
    await recordExpense(5000,
        commandId: 'cmd_original', date: DateTime(2026, 1, 10));
    final originalId =
        (await harness.ledgerService.watchTransactions(DateTime(2026, 1)).first)
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
    var jan =
        await harness.db.monthlySnapshotDao.getForAccount(cashId, 2026, 1);
    expect(jan!.expenseMinor, -8000);
    expect(jan.closingBalanceMinor, -8000);
    var feb =
        await harness.db.monthlySnapshotDao.getForAccount(cashId, 2026, 2);
    expect(feb!.openingBalanceMinor, -8000,
        reason: 'cascade: the month after the edit re-anchors');

    // Deletion: the original month nets zero and the chain follows.
    final correctedId =
        (await harness.ledgerService.watchTransactions(DateTime(2026, 1)).first)
            .single
            .id;
    final deleted = await harness.ledgerService
        .deleteTransaction(correctedId, commandId: 'cmd_delete');
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
    await recordExpense(3000,
        commandId: 'cmd_first', date: DateTime(2026, 1, 10));

    final events = (await harness.eventStore.readAll()).events;
    final anchorGsn = events
        .firstWhere(
            (e) => e.eventType == 'AccountCreated' && e.streamId == cashId)
        .globalSequenceNumber!;

    var jan =
        await harness.db.monthlySnapshotDao.getForAccount(cashId, 2026, 1);
    expect(jan!.eventSequenceFrom, anchorGsn);
    expect(jan.eventSequenceTo, events.last.globalSequenceNumber);

    // A second transaction advances only `to`.
    await recordExpense(4000,
        commandId: 'cmd_second', date: DateTime(2026, 1, 20));
    final eventsAfter = (await harness.eventStore.readAll()).events;
    jan = await harness.db.monthlySnapshotDao.getForAccount(cashId, 2026, 1);
    expect(jan!.eventSequenceFrom, anchorGsn);
    expect(jan.eventSequenceTo, eventsAfter.last.globalSequenceNumber);
  });

  test('the month owns income and expense; the balance is the ledger\'s',
      () async {
    // Two screens, one projection, three figures — but only two of them are
    // the month's. The header's big number is labelled 总余额 and is what the
    // accounts hold now; the reports screen shows the month's own closing
    // balance under a label that says month-end. Reading the header's number
    // off the month's snapshots made a future month read 0 while the accounts
    // held money.
    await seedCashAndFood();
    await harness.accountService.createAccount(
      commandId: 'cmd_open',
      name: 'Bank',
      type: AccountType.bank,
      initialBalanceMinor: 100000,
      currencyCode: 'USD',
    );

    await recordExpense(30000,
        commandId: 'cmd_jan', date: DateTime(2026, 1, 10));
    await recordExpense(20000,
        commandId: 'cmd_feb', date: DateTime(2026, 2, 10));

    final headerBalances = <int>[];
    final reportBalances = <int>[];
    for (final month in [DateTime(2026, 1), DateTime(2026, 2)]) {
      final header = await harness.ledgerService
          .watchMonthlySnapshot(month, currencyCode: 'USD')
          .first;
      final reports = await harness.db.reportsDao
          .watchMonthlyTotals(month, currencyCode: 'USD')
          .first;

      expect(header.incomeMinor, reports.incomeMinor,
          reason: 'both read the month off the same projection');
      expect(header.expenseMinor, reports.expenseMinor);

      headerBalances.add(header.balanceMinor);
      reportBalances.add(reports.balanceMinor);
    }

    expect(headerBalances.first, headerBalances.last,
        reason: 'the ledger\'s total is the same whichever month is on '
            'screen — that is what makes it the ledger\'s');
    expect(reportBalances.first, isNot(reportBalances.last),
        reason: 'a closing balance is the month\'s, so it moves with it');

    // The case that made this a bug report: a month the projection has not
    // reached holds no rows, so a closing balance read off them is 0 — while
    // the ledger is holding money. Its total does not care.
    final now = DateTime.now();
    final beyond = DateTime(now.year, now.month + 2);
    expect(
      await harness.db.monthlySnapshotDao
          .getAllForMonth(beyond.year, beyond.month),
      isEmpty,
      reason: 'no events land there, so the chain was never walked',
    );
    final future = await harness.ledgerService
        .watchMonthlySnapshot(beyond, currencyCode: 'USD')
        .first;
    expect(future.incomeMinor, 0);
    expect(future.expenseMinor, 0);
    expect(future.balanceMinor, headerBalances.last,
        reason: 'nothing has happened since, and the ledger still holds it');
  });

  test('an account out of the totals leaves every one of the three figures',
      () async {
    // The header's figures are the ledger totals (CONTEXT.md), and an
    // excluded account is out of all of them — the balance and the month's
    // income and expense alike. Nothing about the account itself changes:
    // its own balance and its own snapshot rows stay exactly as they were.
    //
    // Opening balances land on today's date, so this is the current month.
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);

    Future<String> openAccount(String commandId, String name, int opening,
        {bool includeInTotals = true}) async {
      await harness.accountService.createAccount(
        commandId: commandId,
        name: name,
        type: AccountType.bank,
        initialBalanceMinor: opening,
        currencyCode: 'USD',
        includeInTotals: includeInTotals,
      );
      return (await harness.db.accountDao.getAllAccounts())
          .firstWhere((a) => a.name == name)
          .id;
    }

    await seedCashAndFood();
    await openAccount('cmd_bank_in', 'Kept', 100000);
    final excludedId = await openAccount('cmd_bank_out', 'Held', 250000,
        includeInTotals: false);

    final header = await harness.ledgerService
        .watchMonthlySnapshot(month, currencyCode: 'USD')
        .first;
    expect(header.balanceMinor, 100000,
        reason: 'the excluded account holds 250000 and none of it counts');
    expect(header.incomeMinor, 0,
        reason: 'opening balances are not monthly income');

    // Its own balance is untouched — the exclusion is about the sums, not
    // about the account.
    final own = await harness.db.accountDao.getAccountById(excludedId);
    expect(own!.balanceMinor, 250000);
    final ownRow = await harness.db.monthlySnapshotDao
        .getForAccount(excludedId, month.year, month.month);
    expect(ownRow!.incomeMinor, 0,
        reason: 'the opening balance changes only the account balance');
  });

  test('totals are scoped to one currency and never mix', () async {
    // Two currencies in the same month, even the same day, must never be
    // summed together. The header and the reports both ask for one
    // currency, and each answer excludes the other currency's accounts and
    // rows entirely.
    await seedCashAndFood();
    await harness.accountService.createAccount(
      commandId: 'cmd_seed_cny',
      name: 'CNY Wallet',
      type: AccountType.cash,
      initialBalanceMinor: 0,
      currencyCode: 'CNY',
    );
    final cnyId = (await harness.db.accountDao.getAllAccounts())
        .firstWhere((a) => a.name == 'CNY Wallet')
        .id;

    await recordExpense(30000,
        commandId: 'cmd_usd', date: DateTime(2026, 1, 10));
    await harness.ledgerService.addTransaction(
      commandId: 'cmd_cny',
      amountMinor: 50000,
      type: TransactionKind.expense,
      date: DateTime(2026, 1, 10),
      categoryId: foodId,
      accountId: cnyId,
    );

    final usd = await harness.ledgerService
        .watchMonthlySnapshot(DateTime(2026, 1), currencyCode: 'USD')
        .first;
    final cny = await harness.ledgerService
        .watchMonthlySnapshot(DateTime(2026, 1), currencyCode: 'CNY')
        .first;

    expect(usd.expenseMinor, -30000,
        reason: 'expense is signed negative');
    expect(cny.expenseMinor, -50000);
    expect(usd.incomeMinor, 0);
    expect(cny.incomeMinor, 0);

    // The balance is scoped the same way: each currency totals its own
    // accounts, never the other's.
    expect(usd.balanceMinor, -30000);
    expect(cny.balanceMinor, -50000);
  });

  test('an account without transactions still shows its balance', () async {
    // Story 13: a currency that has an account but no transactions must
    // distinguish 'no transactions' from 'no balance' — the balance is the
    // account's, and the flows are zero.
    await seedCashAndFood();
    await harness.accountService.createAccount(
      commandId: 'cmd_cny',
      name: 'CNY Wallet',
      type: AccountType.cash,
      initialBalanceMinor: 88800,
      currencyCode: 'CNY',
    );

    final cny = await harness.ledgerService
        .watchMonthlySnapshot(DateTime(2026, 1), currencyCode: 'CNY')
        .first;
    expect(cny.balanceMinor, 88800);
    expect(cny.incomeMinor, 0);
    expect(cny.expenseMinor, 0);
  });
}
