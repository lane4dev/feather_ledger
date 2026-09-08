import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';

import '../../../../support/event_sourcing/ledger_service_harness.dart';

/// Transfer service tests (spec 003, US5/T043): one Transaction+Postings
/// model — debit/credit pair, net zero, excluded from income/expense
/// statistics, with same-account and cross-currency rejection.
void main() {
  late LedgerServiceHarness harness;

  setUp(() => harness = LedgerServiceHarness());
  tearDown(() => harness.close());

  Future<(String, String)> seedTwoAccounts({
    String fromCurrency = 'USD',
    String toCurrency = 'USD',
    AccountType toType = AccountType.bank,
  }) async {
    await harness.accountService.createAccount(
      commandId: 'cmd_seed_from',
      name: 'Savings',
      type: AccountType.bank,
      initialBalanceMinor: 100000,
      currencyCode: fromCurrency,
    );
    await harness.accountService.createAccount(
      commandId: 'cmd_seed_to',
      name: 'Credit Card',
      type: toType,
      initialBalanceMinor: 0,
      currencyCode: toCurrency,
    );
    final accounts = await harness.db.accountDao.getAllAccounts();
    return (
      accounts.firstWhere((a) => a.name == 'Savings').id,
      accounts.firstWhere((a) => a.name == 'Credit Card').id,
    );
  }

  Future<(String, String)> seedAccountAndCategory() async {
    await harness.accountService.createAccount(
      commandId: 'cmd_seed_account',
      name: 'Cash',
      type: AccountType.cash,
      initialBalanceMinor: 0,
      currencyCode: 'USD',
    );
    await harness.categoryService.createCategory(
      commandId: 'cmd_seed_category',
      name: 'Food',
      iconKey: '1',
      colorInt: 0xFF000000,
      type: CategoryType.expense,
    );
    final account = (await harness.db.accountDao.getAllAccounts())
        .firstWhere((a) => a.name == 'Cash');
    final category = (await harness.db.categoriesDao.getAllCategories()).single;
    return (account.id, category.id);
  }

  group('transfer', () {
    test('A→B 100 writes equal debit/credit and moves both balances',
        () async {
      final (fromId, toId) = await seedTwoAccounts();

      final result = await harness.ledgerService.addTransfer(
        commandId: 'cmd_transfer_100',
        amountMinor: 10000,
        fromAccountId: fromId,
        toAccountId: toId,
        date: DateTime(2026, 1, 15),
        note: 'Repayment',
      );

      expect(result, isA<Success<void>>());

      final events = (await harness.eventStore.readAll()).events;
      final recorded = TransactionRecorded.fromJson(
          events.last.payloadJson);
      expect(recorded.kind, TransactionKind.transfer);
      expect(recorded.postings, hasLength(2));

      final debit = recorded.postings
          .firstWhere((p) => p.direction == PostingDirection.debit);
      final credit = recorded.postings
          .firstWhere((p) => p.direction == PostingDirection.credit);
      expect(debit.accountId, fromId);
      expect(debit.amountMinor, 10000);
      expect(credit.accountId, toId);
      expect(credit.amountMinor, 10000);

      final from = await harness.db.accountDao.getAccountById(fromId);
      final to = await harness.db.accountDao.getAccountById(toId);
      expect(from!.balanceMinor, 90000);
      expect(to!.balanceMinor, 10000);

      // Two posting rows share one transaction row.
      final txRows = await harness.db.select(harness.db.transactionsView).get();
      expect(txRows.where((t) => t.kind == TransactionKind.transfer),
          hasLength(1));
      final postings =
          await harness.db.select(harness.db.transactionPostingsView).get();
      expect(postings.where((p) => p.transactionId == recorded.transactionId),
          hasLength(2));
    });

    test('transfer aggregates to a single list row with both sides',
        () async {
      final (fromId, toId) = await seedTwoAccounts();

      await harness.ledgerService.addTransfer(
        commandId: 'cmd_transfer_agg',
        amountMinor: 5000,
        fromAccountId: fromId,
        toAccountId: toId,
        date: DateTime(2026, 1, 15),
      );

      final list = await harness.ledgerService
          .watchTransactions(DateTime(2026, 1))
          .first;
      expect(list, hasLength(1));
      expect(list.single.type, TransactionKind.transfer);
      expect(list.single.account.name, 'Savings');
      expect(list.single.toAccount?.name, 'Credit Card');
      expect(list.single.amount, 5000);
    });

    test('transfer is excluded from income/expense monthly totals', () async {
      final (fromId, toId) = await seedTwoAccounts();
      final (accountId, categoryId) = await seedAccountAndCategory();

      // One expense for reference, then a transfer.
      await harness.ledgerService.addTransaction(
        commandId: 'cmd_expense',
        amountMinor: 3000,
        type: TransactionKind.expense,
        date: DateTime(2026, 1, 10),
        categoryId: categoryId,
        accountId: accountId,
      );
      await harness.ledgerService.addTransfer(
        commandId: 'cmd_transfer_excl',
        amountMinor: 50000,
        fromAccountId: fromId,
        toAccountId: toId,
        date: DateTime(2026, 1, 15),
      );

      final summary = await harness.ledgerService
          .watchMonthlySnapshot(DateTime(2026, 1))
          .first;
      expect(summary.expenseMinor, -3000,
          reason: 'kind == transfer is the single exclusion criterion');
      expect(summary.incomeMinor, 0);
    });

    test('same-account transfer is rejected', () async {
      final (fromId, _) = await seedTwoAccounts();

      final result = await harness.ledgerService.addTransfer(
        commandId: 'cmd_same_account',
        amountMinor: 1000,
        fromAccountId: fromId,
        toAccountId: fromId,
        date: DateTime.now(),
      );

      expect(
        result,
        isA<Failure<void>>()
            .having((f) => f.code, 'code', LedgerErrorCode.sameAccountTransfer),
      );
    });

    test('cross-currency transfer is rejected', () async {
      final (fromId, toId) = await seedTwoAccounts(toCurrency: 'EUR');

      final result = await harness.ledgerService.addTransfer(
        commandId: 'cmd_cross_currency',
        amountMinor: 1000,
        fromAccountId: fromId,
        toAccountId: toId,
        date: DateTime.now(),
      );

      expect(
        result,
        isA<Failure<void>>()
            .having((f) => f.code, 'code', LedgerErrorCode.currencyMismatch),
      );
      // Nothing appended, no balances moved.
      final events = (await harness.eventStore.readAll()).events;
      expect(events.where((e) => e.eventType == 'TransactionRecorded'),
          isEmpty);
      final from = await harness.db.accountDao.getAccountById(fromId);
      expect(from!.balanceMinor, 100000);
    });

    test('savings→credit repayment is a transfer, not an expense', () async {
      final (savingsId, creditId) = await seedTwoAccounts(
          toType: AccountType.credit);

      final result = await harness.ledgerService.addTransfer(
        commandId: 'cmd_repayment',
        amountMinor: 25000,
        fromAccountId: savingsId,
        toAccountId: creditId,
        date: DateTime(2026, 1, 15),
        note: 'Repayment',
      );

      expect(result, isA<Success<void>>());
      final summary = await harness.ledgerService
          .watchMonthlySnapshot(DateTime(2026, 1))
          .first;
      expect(summary.expenseMinor, 0,
          reason: '还款不重复计支出（风险 #4）');
      expect(summary.incomeMinor, 0);

      final credit = await harness.db.accountDao.getAccountById(creditId);
      expect(credit!.balanceMinor, 25000,
          reason: 'credit balance positive = debt repaid');
    });

    test('credit-card purchase is a plain expense on the credit account',
        () async {
      final (_, creditId) = await seedTwoAccounts(toType: AccountType.credit);
      final (_, categoryId) = await seedAccountAndCategory();

      final result = await harness.ledgerService.addTransaction(
        commandId: 'cmd_credit_purchase',
        amountMinor: 8000,
        type: TransactionKind.expense,
        date: DateTime(2026, 1, 15),
        categoryId: categoryId,
        accountId: creditId,
      );

      expect(result, isA<Success<void>>());
      final credit = await harness.db.accountDao.getAccountById(creditId);
      expect(credit!.balanceMinor, -8000,
          reason: '信用卡消费挂信用卡账户，负余额=欠款');
    });
  });
}
