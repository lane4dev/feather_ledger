import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';

import '../../../../../support/event_sourcing/ledger_service_harness.dart';

/// Reversal and correction service tests (spec 003, US6/T049): delete
/// appends `TransactionReversed(userDeleted)`, edit appends the paired
/// `TransactionReversed(correction)` + `TransactionRecorded` in one
/// transaction; reversed transactions cannot be touched again; replay of
/// the event stream cancels original against reversal.
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

  Future<String> recordExpense(
    int amountMinor, {
    required String commandId,
    DateTime? date,
  }) async {
    final result = await harness.ledgerService.addTransaction(
      commandId: commandId,
      amountMinor: amountMinor,
      type: TransactionKind.expense,
      date: date ?? DateTime(2026, 1, 10),
      categoryId: foodId,
      accountId: cashId,
    );
    expect(result, isA<Success<void>>());
    final events = (await harness.eventStore.readAll()).events;
    return TransactionRecorded.fromJson(events.last.payloadJson).transactionId;
  }

  test('delete hides the row, undoes the balance and keeps the audit chain',
      () async {
    await seedCashAndFood();
    final txId = await recordExpense(5000, commandId: 'cmd_expense');

    final result = await harness.ledgerService.deleteTransaction(txId,
        commandId: 'cmd_delete');
    expect(result, isA<Success<void>>());

    // Audit chain: Recorded then Reversed(userDeleted) on the same stream.
    final chain = await harness.eventStore.readStream(txId);
    expect(chain.map((e) => e.eventType).toList(),
        ['TransactionRecorded', 'TransactionReversed']);
    expect(
        TransactionReversed.fromJson(chain.last.payloadJson).reason,
        ReversalReason.userDeleted);

    // Projection: row reversed, balance restored, list hides the row.
    final row = await harness.db.transactionsDao.getTransactionRow(txId);
    expect(row!.isReversed, isTrue);
    final cash = await harness.db.accountDao.getAccountById(cashId);
    expect(cash!.balanceMinor, 0);
    final list = await harness.ledgerService
        .watchTransactions(DateTime(2026, 1))
        .first;
    expect(list, isEmpty);
  });

  test('deleting an unknown transaction is rejected', () async {
    await seedCashAndFood();
    final before = (await harness.eventStore.readAll()).events.length;

    final result = await harness.ledgerService.deleteTransaction('nope',
        commandId: 'cmd_delete_unknown');

    expect(
      result,
      isA<Failure<void>>()
          .having((f) => f.code, 'code', LedgerErrorCode.transactionNotFound),
    );
    expect((await harness.eventStore.readAll()).events.length, before);
  });

  test('deleting an already-reversed transaction is rejected', () async {
    await seedCashAndFood();
    final txId = await recordExpense(5000, commandId: 'cmd_expense');
    await harness.ledgerService.deleteTransaction(txId,
        commandId: 'cmd_delete');

    final result = await harness.ledgerService.deleteTransaction(txId,
        commandId: 'cmd_delete_again');

    expect(
      result,
      isA<Failure<void>>().having((f) => f.code, 'code',
          LedgerErrorCode.transactionAlreadyReversed),
    );
    expect(await harness.eventStore.readStream(txId), hasLength(2));
  });

  test('correction appends the paired events and swaps the projection',
      () async {
    await seedCashAndFood();
    final txId = await recordExpense(5000, commandId: 'cmd_expense');

    final result = await harness.ledgerService.updateTransaction(
      commandId: 'cmd_correct',
      id: txId,
      amountMinor: 12000,
      type: TransactionKind.expense,
      date: DateTime(2026, 1, 10),
      categoryId: foodId,
      accountId: cashId,
    );
    expect(result, isA<Success<void>>());

    // One command, two events: reversal on the original's stream, a fresh
    // Recorded on its own stream.
    final originalChain = await harness.eventStore.readStream(txId);
    expect(originalChain.map((e) => e.eventType).toList(),
        ['TransactionRecorded', 'TransactionReversed']);
    expect(
        TransactionReversed.fromJson(originalChain.last.payloadJson).reason,
        ReversalReason.correction);

    final all = (await harness.eventStore.readAll()).events;
    final recorded = TransactionRecorded.fromJson(
        all.last.payloadJson);
    expect(recorded.transactionId, isNot(txId));
    expect(recorded.postings.single.amountMinor, 12000);

    // Projection: original reversed + its impact undone; only the
    // replacement (12000) remains visible and in the balance.
    final originalRow =
        await harness.db.transactionsDao.getTransactionRow(txId);
    expect(originalRow!.isReversed, isTrue);
    final list = await harness.ledgerService
        .watchTransactions(DateTime(2026, 1))
        .first;
    expect(list, hasLength(1));
    expect(list.single.id, recorded.transactionId);
    expect(list.single.amount, -12000,
        reason: 'entity amount is the signed posting impact');
    final cash = await harness.db.accountDao.getAccountById(cashId);
    expect(cash!.balanceMinor, -12000,
        reason: 'reversal cancels the original, not the replacement');
  });

  test('correction onto another account restores the original account',
      () async {
    await seedCashAndFood();
    await harness.accountService.createAccount(
      commandId: 'cmd_seed_bank',
      name: 'Bank',
      type: AccountType.bank,
      initialBalanceMinor: 0,
      currencyCode: 'USD',
    );
    final bankId = (await harness.db.accountDao.getAllAccounts())
        .firstWhere((a) => a.name == 'Bank')
        .id;
    final txId = await recordExpense(5000, commandId: 'cmd_expense');

    await harness.ledgerService.updateTransaction(
      commandId: 'cmd_correct_account',
      id: txId,
      amountMinor: 2000,
      type: TransactionKind.expense,
      date: DateTime(2026, 1, 10),
      categoryId: foodId,
      accountId: bankId,
    );

    final cash = await harness.db.accountDao.getAccountById(cashId);
    final bank = await harness.db.accountDao.getAccountById(bankId);
    expect(cash!.balanceMinor, 0);
    expect(bank!.balanceMinor, -2000);
  });

  test('correcting a deleted transaction is rejected', () async {
    await seedCashAndFood();
    final txId = await recordExpense(5000, commandId: 'cmd_expense');
    await harness.ledgerService.deleteTransaction(txId,
        commandId: 'cmd_delete');

    final result = await harness.ledgerService.updateTransaction(
      commandId: 'cmd_correct_deleted',
      id: txId,
      amountMinor: 1000,
      type: TransactionKind.expense,
      date: DateTime(2026, 1, 10),
      categoryId: foodId,
      accountId: cashId,
    );

    expect(
      result,
      isA<Failure<void>>().having((f) => f.code, 'code',
          LedgerErrorCode.transactionAlreadyReversed),
    );
    final cash = await harness.db.accountDao.getAccountById(cashId);
    expect(cash!.balanceMinor, 0, reason: 'deletion is not undone');
  });

  test('replaying the stream cancels original against reversal (invariant)',
      () async {
    await seedCashAndFood();
    // A chain with both reversals: an expense corrected, then deleted.
    final txId = await recordExpense(5000, commandId: 'cmd_expense');
    await harness.ledgerService.updateTransaction(
      commandId: 'cmd_correct',
      id: txId,
      amountMinor: 8000,
      type: TransactionKind.expense,
      date: DateTime(2026, 1, 10),
      categoryId: foodId,
      accountId: cashId,
    );
    final corrected = (await harness.ledgerService
            .watchTransactions(DateTime(2026, 1))
            .first)
        .single
        .id;
    await harness.ledgerService.deleteTransaction(corrected,
        commandId: 'cmd_delete');

    // Incremental state.
    final balanceBefore = (await harness.db.accountDao.getAccountById(cashId))!
        .balanceMinor;
    final rowsBefore = await harness.db.select(harness.db.transactionsView).get();
    final postingsBefore =
        await harness.db.select(harness.db.transactionPostingsView).get();
    final visibleBefore = await harness.ledgerService
        .watchTransactions(DateTime(2026, 1))
        .first;

    // Wipe the projections and replay the full event stream.
    await harness.projector.clear();
    final events = (await harness.eventStore.readAll()).events;
    await harness.projector.applyAll(events);

    final balanceAfter = (await harness.db.accountDao.getAccountById(cashId))!
        .balanceMinor;
    final rowsAfter = await harness.db.select(harness.db.transactionsView).get();
    final postingsAfter =
        await harness.db.select(harness.db.transactionPostingsView).get();
    final visibleAfter = await harness.ledgerService
        .watchTransactions(DateTime(2026, 1))
        .first;

    expect(balanceAfter, balanceBefore,
        reason: 'replay must reproduce the cancellation exactly');
    expect(
        rowsAfter
            .map((r) => (r.transactionId, r.isReversed, r.kind))
            .toSet(),
        rowsBefore
            .map((r) => (r.transactionId, r.isReversed, r.kind))
            .toSet());
    expect(postingsAfter.length, postingsBefore.length);
    expect(visibleAfter.map((t) => t.id).toSet(),
        visibleBefore.map((t) => t.id).toSet());
  });
}
