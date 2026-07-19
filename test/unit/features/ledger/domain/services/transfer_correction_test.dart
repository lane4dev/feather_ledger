import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';

import '../../../../../support/event_sourcing/ledger_service_harness.dart';

/// Transfer correction (spec 004, US1 / FR-003 / FR-004).
///
/// A transfer edit is the same reversal + replacement pair an income/expense
/// edit uses, but the *original's kind* decides which command is legal. The
/// replaced guard tested only the incoming `type`, so correcting a transfer as
/// income used to pass and mirrored the two accounts instead of correcting
/// them.
void main() {
  // The comparison test below runs two harnesses at once to compare a
  // corrected ledger against a fresh one. They are separate in-memory
  // databases, so drift's shared-executor warning does not apply here.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late LedgerServiceHarness harness;

  // The correction path files under the seeded system categories; a
  // harness ledger starts empty, so it asks for them the way bootstrap
  // does.
  setUp(() async {
    harness = LedgerServiceHarness();
    await harness.seedSystemCategories();
  });
  tearDown(() => harness.close());

  test('a transfer edit reverses the original and records the replacement',
      () async {
    final accounts = await _seedTwoAccounts(harness);
    final original = await _recordTransfer(
      harness,
      from: accounts.cash,
      to: accounts.bank,
      amountMinor: 10000,
      commandId: 'cmd_transfer',
    );

    final result = await harness.ledgerService.updateTransfer(
      commandId: 'cmd_correct_transfer',
      id: original,
      amountMinor: 15000,
      fromAccountId: accounts.cash,
      toAccountId: accounts.bank,
      date: DateTime(2026, 1, 10),
      note: 'wrong amount',
    );
    expect(result, isA<Success<void>>());

    // Audit chain on the original's stream.
    final chain = await harness.eventStore.readStream(original);
    expect(chain.map((e) => e.eventType).toList(),
        ['TransactionRecorded', 'TransactionReversed']);
    expect(
      TransactionReversed.fromJson(chain.last.payloadJson).reason,
      ReversalReason.correction,
    );

    // The correction PAIR — the reversal and its replacement — carries one
    // commandId, because together they are one user action. The original's
    // own Recorded event keeps the id of the command that created it.
    final all = (await harness.eventStore.readAll()).events;
    expect(all[all.length - 2].eventType, 'TransactionReversed');
    expect(all[all.length - 2].commandId, 'cmd_correct_transfer');
    expect(all.last.commandId, 'cmd_correct_transfer');
    expect(chain.first.commandId, 'cmd_transfer',
        reason: 'creating and correcting are separate commands');

    // The replacement is a two-leg transfer at the new amount.
    final recorded = TransactionRecorded.fromJson(all.last.payloadJson);
    expect(recorded.transactionId, isNot(original));
    expect(recorded.postings, hasLength(2));
    expect(
      recorded.postings.map((p) => p.amountMinor),
      everyElement(15000),
    );
    expect(
      recorded.postings.map((p) => p.direction).toSet(),
      {PostingDirection.debit, PostingDirection.credit},
      reason: 'a transfer keeps one leg in each direction',
    );

    // Read model: the original is hidden, exactly one transfer remains.
    final originalRow =
        await harness.db.transactionsDao.getTransactionRow(original);
    expect(originalRow!.isReversed, isTrue);
    final list = await harness.ledgerService
        .watchTransactions(DateTime(2026, 1))
        .first;
    expect(list, hasLength(1));
    expect(list.single.id, recorded.transactionId);
    expect(list.single.type, TransactionKind.transfer);
  });

  test('a corrected transfer leaves the balances a fresh recording would',
      () async {
    // SC-002 / the double-count guard: correcting must be indistinguishable
    // from having recorded the target state in the first place. If the
    // reversal and the replacement ever land in two separate appends, or the
    // replacement loses a leg, these diverge.
    //
    // Account A starts at 1000.00 so a mirrored (one-legged) result is
    // visibly wrong rather than accidentally matching.
    final corrected = LedgerServiceHarness();
    addTearDown(corrected.close);
    final correctedAccounts = await _seedTwoAccounts(corrected);
    final original = await _recordTransfer(
      corrected,
      from: correctedAccounts.cash,
      to: correctedAccounts.bank,
      amountMinor: 10000,
      commandId: 'cmd_record_then_correct',
    );
    await corrected.ledgerService.updateTransfer(
      commandId: 'cmd_correct',
      id: original,
      amountMinor: 15000,
      // Also swap the direction, so the assertion covers both legs moving.
      fromAccountId: correctedAccounts.bank,
      toAccountId: correctedAccounts.cash,
      date: DateTime(2026, 1, 10),
    );

    final fresh = LedgerServiceHarness();
    addTearDown(fresh.close);
    final freshAccounts = await _seedTwoAccounts(fresh);
    await _recordTransfer(
      fresh,
      from: freshAccounts.bank,
      to: freshAccounts.cash,
      amountMinor: 15000,
      commandId: 'cmd_record_fresh',
    );

    expect(
      await _balanceOf(corrected, correctedAccounts.cash),
      await _balanceOf(fresh, freshAccounts.cash),
      reason: 'cash must match a fresh recording of the corrected transfer',
    );
    expect(
      await _balanceOf(corrected, correctedAccounts.bank),
      await _balanceOf(fresh, freshAccounts.bank),
      reason: 'bank must match a fresh recording of the corrected transfer',
    );
  });

  test('correcting a transfer as income is rejected and changes nothing',
      () async {
    final accounts = await _seedTwoAccounts(harness);
    await _seedCategory(harness, name: 'Food', type: CategoryType.expense);
    final categoryId = await _onlyCategoryId(harness);
    final original = await _recordTransfer(
      harness,
      from: accounts.cash,
      to: accounts.bank,
      amountMinor: 10000,
      commandId: 'cmd_transfer',
    );
    final eventsBefore = (await harness.eventStore.readAll()).events.length;

    final result = await harness.ledgerService.updateTransaction(
      commandId: 'cmd_correct_as_income',
      id: original,
      amountMinor: 10000,
      type: TransactionKind.income,
      date: DateTime(2026, 1, 10),
      categoryId: categoryId,
      accountId: accounts.bank,
    );

    expect(
      result,
      isA<Failure<void>>().having(
          (f) => f.code, 'code', LedgerErrorCode.invalidTransfer),
    );
    expect((await harness.eventStore.readAll()).events.length, eventsBefore,
        reason: 'a rejected correction writes nothing');
  });

  test('correcting an income as a transfer is rejected', () async {
    final accounts = await _seedTwoAccounts(harness);
    // An income needs an income category — the posting context rejects a
    // kind mismatch, which is not what this test is about.
    await _seedCategory(harness, name: 'Salary', type: CategoryType.income);
    final categoryId = await _onlyCategoryId(harness);

    final recorded = await harness.ledgerService.addTransaction(
      commandId: 'cmd_income',
      amountMinor: 20000,
      type: TransactionKind.income,
      date: DateTime(2026, 1, 10),
      categoryId: categoryId,
      accountId: accounts.cash,
    );
    expect(recorded, isA<Success<void>>());
    final events = (await harness.eventStore.readAll()).events;
    final incomeId =
        TransactionRecorded.fromJson(events.last.payloadJson).transactionId;

    final result = await harness.ledgerService.updateTransfer(
      commandId: 'cmd_correct_income_as_transfer',
      id: incomeId,
      amountMinor: 20000,
      fromAccountId: accounts.cash,
      toAccountId: accounts.bank,
      date: DateTime(2026, 1, 10),
    );

    expect(
      result,
      isA<Failure<void>>().having(
          (f) => f.code, 'code', LedgerErrorCode.invalidTransfer),
    );
  });

  test('correcting an already-reversed transfer is rejected', () async {
    final accounts = await _seedTwoAccounts(harness);
    final original = await _recordTransfer(
      harness,
      from: accounts.cash,
      to: accounts.bank,
      amountMinor: 10000,
      commandId: 'cmd_transfer',
    );
    await harness.ledgerService.deleteTransaction(original,
        commandId: 'cmd_delete');

    final result = await harness.ledgerService.updateTransfer(
      commandId: 'cmd_correct_after_delete',
      id: original,
      amountMinor: 15000,
      fromAccountId: accounts.cash,
      toAccountId: accounts.bank,
      date: DateTime(2026, 1, 10),
    );

    expect(
      result,
      isA<Failure<void>>().having((f) => f.code, 'code',
          LedgerErrorCode.transactionAlreadyReversed),
    );
    expect(await harness.eventStore.readStream(original), hasLength(2),
        reason: 'the deletion is not undone');
  });
}

/// Seeds Cash (1000.00 opening) and Bank (0) — both USD, so transfers between
/// them are legal.
///
/// A funded account is a correction transaction, so this brings the system
/// categories the shared `setUp` seeds — two tests here build their own
/// harness rather than use that one.
Future<({String cash, String bank})> _seedTwoAccounts(
    LedgerServiceHarness harness) async {
  await harness.seedSystemCategories();
  await harness.accountService.createAccount(
    commandId: 'cmd_seed_cash',
    name: 'Cash',
    type: AccountType.cash,
    initialBalanceMinor: 100000,
    currencyCode: 'USD',
  );
  await harness.accountService.createAccount(
    commandId: 'cmd_seed_bank',
    name: 'Bank',
    type: AccountType.bank,
    initialBalanceMinor: 0,
    currencyCode: 'USD',
  );
  final all = await harness.db.accountDao.getAllAccounts();
  return (
    cash: all.firstWhere((a) => a.name == 'Cash').id,
    bank: all.firstWhere((a) => a.name == 'Bank').id,
  );
}

Future<void> _seedCategory(
  LedgerServiceHarness harness, {
  required String name,
  required CategoryType type,
}) =>
    harness.categoryService.createCategory(
      commandId: 'cmd_seed_${name.toLowerCase()}',
      name: name,
      iconKey: '1',
      colorInt: 0xFF000000,
      type: type,
    );

/// The seeded category's id (there is exactly one in these fixtures).
Future<String> _onlyCategoryId(LedgerServiceHarness harness) async =>
    await harness.userCategoryId();

Future<String> _recordTransfer(
  LedgerServiceHarness harness, {
  required String from,
  required String to,
  required int amountMinor,
  required String commandId,
}) async {
  final result = await harness.ledgerService.addTransfer(
    commandId: commandId,
    amountMinor: amountMinor,
    fromAccountId: from,
    toAccountId: to,
    date: DateTime(2026, 1, 10),
  );
  expect(result, isA<Success<void>>());
  final events = (await harness.eventStore.readAll()).events;
  return TransactionRecorded.fromJson(events.last.payloadJson).transactionId;
}

Future<int> _balanceOf(LedgerServiceHarness harness, String accountId) async =>
    (await harness.db.accountDao.getAccountById(accountId))!.balanceMinor;
