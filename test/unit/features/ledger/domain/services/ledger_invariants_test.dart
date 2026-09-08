import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';

import '../../../../../support/event_sourcing/ledger_service_harness.dart';

/// Ledger invariants (spec 003, US8/T061): any event stream must satisfy
/// - Σ live posting increments per account == that account's balance
///   (minus its opening amount),
/// - every transfer nets to zero,
/// - reversed transactions never contribute to monthly statistics,
/// - every month's opening equals the previous month's closing.
void main() {
  late LedgerServiceHarness harness;

  setUp(() => harness = LedgerServiceHarness());
  tearDown(() => harness.close());

  late String cashId;
  late String bankId;
  late String foodId;
  late String salaryId;

  /// Builds a stream that exercises every write path: opening balance,
  /// expense, income, transfer, correction, deletion.
  Future<void> runScriptedHistory() async {
    await harness.accountService.createAccount(
      commandId: 'inv_seed_cash',
      name: 'Cash',
      type: AccountType.cash,
      initialBalanceMinor: 0,
      currencyCode: 'USD',
    );
    await harness.accountService.createAccount(
      commandId: 'inv_seed_bank',
      name: 'Bank',
      type: AccountType.bank,
      initialBalanceMinor: 100000,
      currencyCode: 'USD',
    );
    await harness.categoryService.createCategory(
      commandId: 'inv_seed_food',
      name: 'Food',
      iconKey: '1',
      colorInt: 0xFF000000,
      type: CategoryType.expense,
    );
    await harness.categoryService.createCategory(
      commandId: 'inv_seed_salary',
      name: 'Salary',
      iconKey: '2',
      colorInt: 0xFF00FF00,
      type: CategoryType.income,
    );
    final accounts = await harness.db.accountDao.getAllAccounts();
    cashId = accounts.firstWhere((a) => a.name == 'Cash').id;
    bankId = accounts.firstWhere((a) => a.name == 'Bank').id;
    final categories = await harness.db.categoriesDao.getAllCategories();
    foodId = categories.firstWhere((c) => c.name == 'Food').id;
    salaryId = categories.firstWhere((c) => c.name == 'Salary').id;

    await harness.ledgerService.addTransaction(
      commandId: 'inv_expense',
      amountMinor: 5000,
      type: TransactionKind.expense,
      date: DateTime(2026, 1, 10),
      categoryId: foodId,
      accountId: cashId,
    );
    await harness.ledgerService.addTransaction(
      commandId: 'inv_income',
      amountMinor: 20000,
      type: TransactionKind.income,
      date: DateTime(2026, 1, 12),
      categoryId: salaryId,
      accountId: bankId,
    );
    await harness.ledgerService.addTransfer(
      commandId: 'inv_transfer',
      amountMinor: 3000,
      fromAccountId: bankId,
      toAccountId: cashId,
      date: DateTime(2026, 1, 15),
    );
    final originalId = (await harness.ledgerService
            .watchTransactions(DateTime(2026, 1))
            .first)
        .firstWhere((t) => t.type == TransactionKind.expense)
        .id;
    await harness.ledgerService.updateTransaction(
      commandId: 'inv_correct',
      id: originalId,
      amountMinor: 8000,
      type: TransactionKind.expense,
      date: DateTime(2026, 1, 10),
      categoryId: foodId,
      accountId: cashId,
    );
    final correctedId = (await harness.ledgerService
            .watchTransactions(DateTime(2026, 1))
            .first)
        .firstWhere((t) => t.amount == -8000)
        .id;
    await harness.ledgerService.deleteTransaction(correctedId,
        commandId: 'inv_delete');
  }

  Future<(Set<String> reversedIds, List<TransactionRecorded> live)> liveRecords() async {
    final events = (await harness.eventStore.readAll()).events;
    final reversed = <String>{};
    for (final e in events) {
      if (e.eventType == 'TransactionReversed') {
        reversed.add(
            TransactionReversed.fromJson(e.payloadJson).originalTransactionId);
      }
    }
    final live = [
      for (final e in events)
        if (e.eventType == 'TransactionRecorded' &&
            !reversed.contains(
                TransactionRecorded.fromJson(e.payloadJson).transactionId))
          TransactionRecorded.fromJson(e.payloadJson),
    ];
    return (reversed, live);
  }

  test('posting increments equal balance changes per account', () async {
    await runScriptedHistory();
    final (_, live) = await liveRecords();

    final impacts = <String, int>{};
    for (final record in live) {
      for (final posting in record.postings) {
        impacts[posting.accountId] =
            (impacts[posting.accountId] ?? 0) + posting.signedImpact;
      }
    }

    // Opening amounts from OpeningBalanceSet events.
    final openings = <String, int>{};
    for (final e in (await harness.eventStore.readAll()).events) {
      if (e.eventType == 'OpeningBalanceSet') {
        final p = OpeningBalanceSet.fromJson(e.payloadJson);
        openings[p.accountId] =
            (openings[p.accountId] ?? 0) + p.amountMinor.abs();
      }
    }

    final accounts = await harness.db.accountDao.getAllAccounts();
    for (final account in accounts) {
      expect(
        account.balanceMinor,
        (openings[account.id] ?? 0) + (impacts[account.id] ?? 0),
        reason: 'balance of ${account.name} = opening + live postings',
      );
    }
  });

  test('every transfer nets to zero', () async {
    await runScriptedHistory();
    final (_, live) = await liveRecords();

    for (final record in live.where((r) => r.kind == TransactionKind.transfer)) {
      final net = record.postings
          .fold<int>(0, (sum, p) => sum + p.signedImpact);
      expect(net, 0, reason: 'transfer ${record.transactionId} must net zero');
    }
  });

  test('reversed transactions never contribute to monthly statistics',
      () async {
    await runScriptedHistory();
    final (_, live) = await liveRecords();

    // Expected January income/expense per account from the live events.
    final expectedExpense = <String, int>{};
    final expectedIncome = <String, int>{};
    for (final record in live.where(
        (r) => r.occurredAt.year == 2026 && r.occurredAt.month == 1)) {
      for (final posting in record.postings) {
        final key = posting.accountId;
        if (record.kind == TransactionKind.expense) {
          expectedExpense[key] =
              (expectedExpense[key] ?? 0) + posting.signedImpact;
        } else if (record.kind == TransactionKind.income) {
          expectedIncome[key] =
              (expectedIncome[key] ?? 0) + posting.signedImpact;
        }
      }
    }

    for (final account in await harness.db.accountDao.getAllAccounts()) {
      final row = await harness.db.monthlySnapshotDao
          .getForAccount(account.id, 2026, 1);
      if (row == null) continue; // account with no January history
      expect(row.expenseMinor, expectedExpense[account.id] ?? 0,
          reason: 'reversed amounts must not appear in statistics');
      expect(row.incomeMinor, expectedIncome[account.id] ?? 0);
    }
  });

  test('every month opening equals the previous month closing', () async {
    await runScriptedHistory();

    for (final account in await harness.db.accountDao.getAllAccounts()) {
      final rows = (await (harness.db.select(
              harness.db.monthlyAccountBalanceSnapshots)
            ..where((t) => t.accountId.equals(account.id)))
              .get())
        ..sort((a, b) {
          final byYear = a.year.compareTo(b.year);
          return byYear != 0 ? byYear : a.month.compareTo(b.month);
        });

      expect(rows, isNotEmpty, reason: '${account.name} has snapshots');
      for (var i = 1; i < rows.length; i++) {
        expect(
          rows[i].openingBalanceMinor,
          rows[i - 1].closingBalanceMinor,
          reason: '${account.name} ${rows[i].year}-${rows[i].month} opening '
              'chains from the previous closing',
        );
      }
    }
  });
}
