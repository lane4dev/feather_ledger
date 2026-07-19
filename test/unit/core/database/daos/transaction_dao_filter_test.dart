import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';

import '../../../../support/event_sourcing/ledger_service_harness.dart';

/// The filtered read (spec 004, US3 / T046).
///
/// Two properties here are not obvious from the call site and would fail
/// silently if broken: reversed rows stay hidden, and an account filter
/// returns *whole* transactions — both legs of a transfer, not one.
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
  late String foodId;
  late String salaryId;

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
    await harness.categoryService.createCategory(
      commandId: 'cmd_food',
      name: 'Groceries',
      iconKey: '1',
      colorInt: 0xFF000000,
      type: CategoryType.expense,
    );
    await harness.categoryService.createCategory(
      commandId: 'cmd_salary',
      name: 'Salary',
      iconKey: '2',
      colorInt: 0xFF000000,
      type: CategoryType.income,
    );
    final accounts = await harness.db.accountDao.getAllAccounts();
    cashId = accounts.firstWhere((a) => a.name == 'Cash').id;
    bankId = accounts.firstWhere((a) => a.name == 'Bank').id;
    final categories = await harness.db.categoriesDao.getAllCategories();
    foodId = categories.firstWhere((c) => c.name == 'Groceries').id;
    salaryId = categories.firstWhere((c) => c.name == 'Salary').id;
  }

  Future<String> addExpense({
    required int amountMinor,
    required DateTime date,
    String? note,
    String commandId = 'cmd',
  }) async {
    final result = await harness.ledgerService.addTransaction(
      commandId: '$commandId-${date.millisecondsSinceEpoch}-$amountMinor',
      amountMinor: amountMinor,
      type: TransactionKind.expense,
      date: date,
      categoryId: foodId,
      accountId: cashId,
      note: note,
    );
    expect(result, isA<Success<void>>());
    return _lastTransactionId(harness);
  }

  /// Reads rows through the DAO directly, which is the layer under test.
  Future<List<String>> idsMatching({
    String? query,
    TransactionKind? kind,
    String? accountId,
    String? categoryId,
    DateTime? from,
    DateTime? to,
  }) async {
    final rows = await harness.db.transactionsDao
        .watchTransactionsFiltered(
          query: query,
          kind: kind,
          accountId: accountId,
          categoryId: categoryId,
          from: from,
          to: to,
        )
        .first;
    return rows.map((r) => r.transaction.transactionId).toSet().toList();
  }

  test('a reversed transaction is excluded', () async {
    // Reversed rows are hidden by the *query* layer for the monthly list, so
    // a DAO caller that does not know that gets them. This one filters in
    // SQL on purpose.
    await seed();
    final kept = await addExpense(
        amountMinor: 1000, date: DateTime(2026, 1, 5), commandId: 'keep');
    final deleted = await addExpense(
        amountMinor: 2000, date: DateTime(2026, 1, 6), commandId: 'del');
    await harness.ledgerService.deleteTransaction(deleted,
        commandId: 'cmd_delete');

    final ids = await idsMatching();

    expect(ids, contains(kept));
    expect(ids, isNot(contains(deleted)));
  });

  test('the keyword matches the note, the category snapshot and the account',
      () async {
    await seed();
    final byNote = await addExpense(
        amountMinor: 1000,
        date: DateTime(2026, 1, 5),
        note: 'weekly market run',
        commandId: 'note');
    final byCategory = await addExpense(
        amountMinor: 2000, date: DateTime(2026, 1, 6), commandId: 'cat');
    final byAccount = await addExpense(
        amountMinor: 3000, date: DateTime(2026, 1, 7), commandId: 'acc');

    expect(await idsMatching(query: 'market'), [byNote]);
    expect(await idsMatching(query: 'Groceries'), contains(byCategory));
    // Case-insensitive: SQLite's LIKE is, for ASCII, which is what a search
    // box wants.
    expect(await idsMatching(query: 'cash'), contains(byAccount));
  });

  test('a percent sign is a literal, not a wildcard', () async {
    await seed();
    await addExpense(
        amountMinor: 1000,
        date: DateTime(2026, 1, 5),
        note: '50% off',
        commandId: 'pct');
    await addExpense(
        amountMinor: 2000, date: DateTime(2026, 1, 6), commandId: 'plain');

    final ids = await idsMatching(query: '50% off');

    expect(ids, hasLength(1),
        reason: 'an unescaped % would match every row in the ledger');
  });

  test('filters by kind', () async {
    await seed();
    final expense = await addExpense(
        amountMinor: 1000, date: DateTime(2026, 1, 5), commandId: 'exp');
    await harness.ledgerService.addTransaction(
      commandId: 'income',
      amountMinor: 5000,
      type: TransactionKind.income,
      date: DateTime(2026, 1, 6),
      categoryId: salaryId,
      accountId: cashId,
    );

    expect(await idsMatching(kind: TransactionKind.expense), [expense]);
  });

  test('the date range includes both endpoints, by day', () async {
    await seed();
    final before = await addExpense(
        amountMinor: 1000, date: DateTime(2026, 1, 4), commandId: 'before');
    final firstDay = await addExpense(
        amountMinor: 2000, date: DateTime(2026, 1, 5), commandId: 'first');
    // Late in the day: a range ending "on" this date must still include it.
    final lastDay = await addExpense(
        amountMinor: 3000,
        date: DateTime(2026, 1, 10, 23, 30),
        commandId: 'last');
    final after = await addExpense(
        amountMinor: 4000, date: DateTime(2026, 1, 11), commandId: 'after');

    final ids = await idsMatching(
      from: DateTime(2026, 1, 5),
      to: DateTime(2026, 1, 10),
    );

    expect(ids, containsAll([firstDay, lastDay]));
    expect(ids, isNot(contains(before)));
    expect(ids, isNot(contains(after)));
  });

  test('an account filter returns a whole transfer, both legs', () async {
    // The subtle one. A transfer has two posting rows; filtering the join
    // would return one of them, and the repository's grouping would then
    // throw looking for the missing leg.
    await seed();
    await harness.ledgerService.addTransfer(
      commandId: 'transfer',
      amountMinor: 25000,
      fromAccountId: cashId,
      toAccountId: bankId,
      date: DateTime(2026, 1, 8),
    );
    final expense = await addExpense(
        amountMinor: 1000, date: DateTime(2026, 1, 5), commandId: 'exp');

    // Filtering by the *destination* account must still find the transfer.
    final ids = await idsMatching(accountId: bankId);
    expect(ids, hasLength(1), reason: 'the transfer, exactly once');

    final rows = await harness.db.transactionsDao
        .watchTransactionsFiltered(accountId: bankId)
        .first;
    expect(rows, hasLength(2),
        reason: 'both postings come back so the entity can be reassembled');
    expect(
      rows.map((r) => r.posting.accountId).toSet(),
      {cashId, bankId},
    );

    // And the filter is exclusive.
    expect(await idsMatching(accountId: cashId), containsAll([expense, ids.single]));
  });

  test('filters by category', () async {
    await seed();
    final food = await addExpense(
        amountMinor: 1000, date: DateTime(2026, 1, 5), commandId: 'food');
    final income = await harness.ledgerService.addTransaction(
      commandId: 'income',
      amountMinor: 5000,
      type: TransactionKind.income,
      date: DateTime(2026, 1, 6),
      categoryId: salaryId,
      accountId: cashId,
    );
    expect(income, isA<Success<void>>());

    expect(await idsMatching(categoryId: foodId), [food]);
  });

  test('combines conditions with AND', () async {
    await seed();
    final wanted = await addExpense(
        amountMinor: 1000,
        date: DateTime(2026, 1, 5),
        note: 'market',
        commandId: 'wanted');
    await addExpense(
        amountMinor: 2000,
        date: DateTime(2026, 6, 5),
        note: 'market',
        commandId: 'wrong-month');
    await addExpense(
        amountMinor: 3000,
        date: DateTime(2026, 1, 6),
        note: 'other',
        commandId: 'wrong-note');

    final ids = await idsMatching(
      query: 'market',
      kind: TransactionKind.expense,
      accountId: cashId,
      categoryId: foodId,
      from: DateTime(2026, 1, 1),
      to: DateTime(2026, 1, 31),
    );

    expect(ids, [wanted]);
  });

  test('an empty filter returns everything live, newest first', () async {
    await seed();
    await addExpense(
        amountMinor: 1000, date: DateTime(2026, 1, 5), commandId: 'older');
    await addExpense(
        amountMinor: 2000, date: DateTime(2026, 3, 5), commandId: 'newer');

    final rows = await harness.db.transactionsDao
        .watchTransactionsFiltered()
        .first;

    // The two expenses, plus the correction that opened Cash with its
    // 1000.00 — a starting balance is a transaction like any other, and it
    // is the newest row here.
    expect(rows, hasLength(3));
    expect(
      rows.first.transaction.occurredAt.isAfter(
          rows.last.transaction.occurredAt),
      isTrue,
      reason: 'newest first',
    );
  });
}

/// The id of the transaction the last recorded event created.
Future<String> _lastTransactionId(LedgerServiceHarness harness) async {
  final events = (await harness.eventStore.readAll()).events;
  return TransactionRecorded.fromJson(events.last.payloadJson).transactionId;
}
