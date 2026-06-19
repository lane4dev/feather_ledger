import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/data/database/daos/transaction_dao.dart';

import 'ledger_service_harness.dart';

/// Smoke test for the shared migration harness (T002): proves the wiring
/// drives both domain services against the in-memory Drift database and
/// that events + projections stay observable through it.
void main() {
  late LedgerServiceHarness harness;

  setUp(() => harness = LedgerServiceHarness());
  tearDown(() => harness.close());

  test('drives LedgerService and observes events + projections', () async {
    await harness.seedAccount(id: 'acc-1', name: 'Cash');
    await harness.seedCategory(id: 'cat-1', name: 'Food');

    final result = await harness.ledgerService.addTransaction(
      commandId: 'cmd_smoke_expense',
      amountMinor: 1050,
      type: TransactionKind.expense,
      date: DateTime(2026, 1, 15),
      categoryId: 'cat-1',
      accountId: 'acc-1',
      note: 'Lunch',
    );
    expect(result, isA<Success<void>>());

    final events = (await harness.eventStore.readAll()).events;
    expect(events.first.eventType, 'TransactionRecorded');

    final account = await harness.db.accountDao.getAccountById('acc-1');
    expect(account!.balanceMinor, -1050);

    final transactions =
        await harness.db.select(harness.db.transactionsView).get();
    expect(transactions, hasLength(1));
    expect(transactions.first.kind, TransactionKind.expense);
    final postings =
        await harness.db.select(harness.db.transactionPostingsView).get();
    expect(postings, hasLength(1));
    expect(postingSignedImpact(postings.first), -1050);
  });

  test('drives AccountService through the same seam', () async {
    final result = await harness.accountService.createAccount(
      commandId: 'cmd_smoke_create',
      name: 'Wallet',
      type: AccountType.cash,
      initialBalanceMinor: 0,
      currencyCode: 'USD',
    );
    expect(result, isA<Success<void>>());

    final accounts = await harness.db.accountDao.getAllAccounts();
    expect(accounts, hasLength(1));
    expect(accounts.first.name, 'Wallet');

    final events = (await harness.eventStore.readAll()).events;
    expect(events.map((e) => e.eventType), contains('AccountCreated'));
  });
}
