import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import 'package:feather_ledger/features/ledger/domain/value_objects/transaction_filter.dart';

import '../../../../support/event_sourcing/ledger_service_harness.dart';

/// The filtered read, at the entity level (spec 004, US3 / T047).
///
/// The DAO test proves the rows come back correct; this proves they are
/// assembled into whole transactions — a filtered transfer is still one
/// entity with both sides, not a half-built one.
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
  late String bankId;

  Future<void> seed() async {
    await harness.accountService.createAccount(
      commandId: 'cmd_cash',
      name: 'Cash',
      type: AccountType.cash,
      initialBalanceMinor: 100000,
      currencyCode: 'USD',
    );
    await harness.accountService.createAccount(
      commandId: 'cmd_bank',
      name: 'Bank',
      type: AccountType.bank,
      initialBalanceMinor: 0,
      currencyCode: 'USD',
    );
    final accounts = await harness.db.accountDao.getAllAccounts();
    cashId = accounts.firstWhere((a) => a.name == 'Cash').id;
    bankId = accounts.firstWhere((a) => a.name == 'Bank').id;
  }

  test('a filtered transfer is one entity with both accounts', () async {
    await seed();
    await harness.ledgerService.addTransfer(
      commandId: 'transfer',
      amountMinor: 25000,
      fromAccountId: cashId,
      toAccountId: bankId,
      date: DateTime(2026, 1, 8),
    );

    // Filtering by the destination account — the leg that is NOT the
    // entity's primary `account`.
    final results = await harness.ledgerRepository
        .watchTransactionsFiltered(
            const TransactionFilter(accountId: 'CHANGED'))
        .first;
    expect(results, isEmpty, reason: 'sanity: an unknown account matches none');

    final matching = await harness.ledgerRepository
        .watchTransactionsFiltered(TransactionFilter(accountId: bankId))
        .first;

    expect(matching, hasLength(1),
        reason: 'the two legs collapse into one transaction');
    final transfer = matching.single;
    expect(transfer.type, TransactionKind.transfer);
    expect(transfer.amount, 25000);
    expect(transfer.account.id, cashId, reason: 'the debit side is primary');
    expect(transfer.toAccount?.id, bankId,
        reason: 'the credit side must survive the filter');
  });

  test('a transfer excluded by kind does not appear', () async {
    await seed();
    await harness.ledgerService.addTransfer(
      commandId: 'transfer',
      amountMinor: 25000,
      fromAccountId: cashId,
      toAccountId: bankId,
      date: DateTime(2026, 1, 8),
    );

    final expenses = await harness.ledgerRepository
        .watchTransactionsFiltered(
            const TransactionFilter(kind: TransactionKind.expense))
        .first;

    expect(expenses, isEmpty);
  });

  test('an empty filter returns the whole live ledger', () async {
    await seed();
    await harness.accountService.createAccount(
      commandId: 'cmd_third',
      name: 'Third',
      type: AccountType.other,
      initialBalanceMinor: 0,
      currencyCode: 'USD',
    );
    await harness.categoryService.createCategory(
      commandId: 'cmd_food',
      name: 'Food',
      iconKey: '1',
      colorInt: 0xFF000000,
      type: CategoryType.expense,
    );
    final categoryId =
        await harness.userCategoryId();

    await harness.ledgerService.addTransfer(
      commandId: 'transfer',
      amountMinor: 25000,
      fromAccountId: cashId,
      toAccountId: bankId,
      date: DateTime(2026, 1, 8),
    );
    await harness.ledgerService.addTransaction(
      commandId: 'expense',
      amountMinor: 1000,
      type: TransactionKind.expense,
      date: DateTime(2026, 1, 5),
      categoryId: categoryId,
      accountId: cashId,
    );

    final all = await harness.ledgerRepository
        .watchTransactionsFiltered(TransactionFilter.empty)
        .first;

    // The transfer, the expense, and the correction that opened Cash with
    // its 1000.00.
    expect(all, hasLength(3));
  });

  test('the filter value object survives the round trip', () async {
    await seed();
    final recorded = await harness.ledgerService.addTransfer(
      commandId: 'transfer',
      amountMinor: 25000,
      fromAccountId: cashId,
      toAccountId: bankId,
      date: DateTime(2026, 1, 8),
    );
    expect(recorded, isA<Success<void>>());
    final events = (await harness.eventStore.readAll()).events;
    final transferId =
        TransactionRecorded.fromJson(events.last.payloadJson).transactionId;

    const filter = TransactionFilter(
      kind: TransactionKind.transfer,
      query: 'unmatchable',
    );
    final none = await harness.ledgerRepository
        .watchTransactionsFiltered(filter)
        .first;
    expect(none, isEmpty);

    final byKindOnly = await harness.ledgerRepository
        .watchTransactionsFiltered(
            const TransactionFilter(kind: TransactionKind.transfer))
        .first;
    expect(byKindOnly.single.id, transferId);
  });

  test('a filtered search is scoped to one currency', () async {
    // Two accounts in different currencies, both with the same note. The
    // search text matches both, so only the currency argument separates them.
    await harness.accountService.createAccount(
      commandId: 'cmd_dollar',
      name: 'Dollar',
      type: AccountType.cash,
      initialBalanceMinor: 0,
      currencyCode: 'USD',
    );
    await harness.accountService.createAccount(
      commandId: 'cmd_yuan',
      name: 'Yuan',
      type: AccountType.cash,
      initialBalanceMinor: 0,
      currencyCode: 'CNY',
    );
    await harness.categoryService.createCategory(
      commandId: 'cmd_food',
      name: 'Food',
      iconKey: '1',
      colorInt: 0xFF000000,
      type: CategoryType.expense,
    );
    final categoryId = await harness.userCategoryId();
    final accounts = await harness.db.accountDao.getAllAccounts();
    final usdId = accounts.firstWhere((a) => a.name == 'Dollar').id;
    final cnyId = accounts.firstWhere((a) => a.name == 'Yuan').id;

    await harness.ledgerService.addTransaction(
      commandId: 'usd_rent',
      amountMinor: 1000,
      type: TransactionKind.expense,
      date: DateTime(2026, 1, 5),
      categoryId: categoryId,
      accountId: usdId,
      note: 'rent',
    );
    await harness.ledgerService.addTransaction(
      commandId: 'cny_rent',
      amountMinor: 2000,
      type: TransactionKind.expense,
      date: DateTime(2026, 1, 6),
      categoryId: categoryId,
      accountId: cnyId,
      note: 'rent',
    );

    const filter = TransactionFilter(query: 'rent');
    final usd = await harness.ledgerRepository
        .watchTransactionsFiltered(filter, currencyCode: 'USD')
        .first;
    expect(usd, hasLength(1));
    expect(usd.single.account.currencyCode, 'USD');
    expect(usd.single.amount, -1000);

    final cny = await harness.ledgerRepository
        .watchTransactionsFiltered(filter, currencyCode: 'CNY')
        .first;
    expect(cny, hasLength(1));
    expect(cny.single.account.currencyCode, 'CNY');
    expect(cny.single.amount, -2000);
  });

  test('a monthly read is scoped to one currency', () async {
    // Two accounts in different currencies, two expenses in the same month.
    await harness.accountService.createAccount(
      commandId: 'cmd_dollar',
      name: 'Dollar',
      type: AccountType.cash,
      initialBalanceMinor: 0,
      currencyCode: 'USD',
    );
    await harness.accountService.createAccount(
      commandId: 'cmd_yuan',
      name: 'Yuan',
      type: AccountType.cash,
      initialBalanceMinor: 0,
      currencyCode: 'CNY',
    );
    await harness.categoryService.createCategory(
      commandId: 'cmd_food',
      name: 'Food',
      iconKey: '1',
      colorInt: 0xFF000000,
      type: CategoryType.expense,
    );
    final categoryId = await harness.userCategoryId();
    final accounts = await harness.db.accountDao.getAllAccounts();
    final usdId = accounts.firstWhere((a) => a.name == 'Dollar').id;
    final cnyId = accounts.firstWhere((a) => a.name == 'Yuan').id;

    await harness.ledgerService.addTransaction(
      commandId: 'usd_expense',
      amountMinor: 1000,
      type: TransactionKind.expense,
      date: DateTime(2026, 1, 5),
      categoryId: categoryId,
      accountId: usdId,
    );
    await harness.ledgerService.addTransaction(
      commandId: 'cny_expense',
      amountMinor: 2000,
      type: TransactionKind.expense,
      date: DateTime(2026, 1, 6),
      categoryId: categoryId,
      accountId: cnyId,
    );

    final usd = await harness.ledgerRepository
        .watchTransactions(DateTime(2026, 1), currencyCode: 'USD')
        .first;
    expect(usd, hasLength(1));
    expect(usd.single.account.currencyCode, 'USD');
    expect(usd.single.amount, -1000, reason: 'an expense is a negative amount');

    final cny = await harness.ledgerRepository
        .watchTransactions(DateTime(2026, 1), currencyCode: 'CNY')
        .first;
    expect(cny, hasLength(1));
    expect(cny.single.account.currencyCode, 'CNY');
    expect(cny.single.amount, -2000);
  });
}
