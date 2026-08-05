import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/presentation/models/ledger_day_group.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';

/// The timeline's rows (spec 004).
///
/// A day's totals are worked out where the currency is known and arrive at the
/// widget as text. If they were added up in the timeline instead, the timeline
/// would need to know that tile amounts are unsigned, that a transfer is
/// neither income nor expense, and how to write minor units — three things it
/// should not have an opinion about.
void main() {
  const cash = AccountEntity(
    id: 'acc_cash',
    name: 'Cash',
    type: AccountType.cash,
    currencyCode: 'USD',
    balanceMinor: 0,
    archived: false,
    lastUpdatedEventId: 0,
  );
  const rent = CategoryEntity(
    id: 'cat_rent',
    name: 'Rent',
    iconKey: '1',
    colorInt: 0xFF000000,
    type: CategoryType.expense,
  );

  TransactionTileUiModel tile({
    required int amount,
    required TransactionKind type,
    required DateTime date,
    bool isPending = false,
  }) =>
      TransactionTileUiModel(
        id: 'tx_$amount$type',
        amount: amount,
        type: type,
        date: date,
        note: null,
        category: rent,
        account: cash,
        displayAmount: '0.00',
        displaySign: type == TransactionKind.income ? '+' : '-',
        isPending: isPending,
      );

  List<LedgerDayGroup> group(List<TransactionTileUiModel> tiles) =>
      LedgerDayGroup.group(tiles, currencySymbol: r'$');

  test('writes each day out and totals it', () {
    final days = group([
      tile(
          amount: 250000,
          type: TransactionKind.income,
          date: DateTime(2026, 11, 1)),
      tile(
          amount: 50000,
          type: TransactionKind.expense,
          date: DateTime(2026, 11, 1)),
    ]);

    expect(days, hasLength(1));
    expect(days.single.displayIncome, r'$2500.00');
    expect(days.single.displayExpense, r'$500.00');
    expect(days.single.transactions, hasLength(2));
  });

  test('a transfer is neither income nor expense', () {
    // Both legs are the same money moving between the user's own accounts.
    // Counting them would report a card payment as income and as spending.
    final days = group([
      tile(
          amount: 300000,
          type: TransactionKind.transfer,
          date: DateTime(2026, 11, 2)),
    ]);

    expect(days.single.displayIncome, isNull);
    expect(days.single.displayExpense, isNull);
  });

  test('a kind the day has none of is left out, not shown as zero', () {
    final days = group([
      tile(
          amount: 1000,
          type: TransactionKind.expense,
          date: DateTime(2026, 11, 3)),
    ]);

    expect(days.single.displayExpense, r'$10.00');
    expect(days.single.displayIncome, isNull,
        reason: 'a zero is not worth a line');
  });

  test('posted and pending days are sorted newest first without changing input',
      () {
    final tiles = [
      tile(
          amount: 100,
          type: TransactionKind.expense,
          date: DateTime(2026, 11, 5)),
      tile(
          amount: 200,
          type: TransactionKind.expense,
          date: DateTime(2026, 11, 1)),
      tile(
          amount: 300,
          type: TransactionKind.expense,
          date: DateTime(2026, 11, 9),
          isPending: true),
      tile(
          amount: 400,
          type: TransactionKind.income,
          date: DateTime(2026, 11, 3),
          isPending: true),
    ];
    final days = group(List.unmodifiable(tiles));

    expect(days.map((d) => d.date.day), [9, 5, 3, 1]);
    expect(tiles.map((t) => t.date.day), [5, 1, 9, 3]);
  });

  test('rows within a day sort by time regardless of posting status', () {
    final morning = tile(
        amount: 100,
        type: TransactionKind.expense,
        date: DateTime(2026, 11, 5, 9));
    final evening = tile(
        amount: 200,
        type: TransactionKind.expense,
        date: DateTime(2026, 11, 5, 21));
    final afternoon = tile(
        amount: 300,
        type: TransactionKind.expense,
        date: DateTime(2026, 11, 5, 15),
        isPending: true);
    final midnight = tile(
        amount: 400,
        type: TransactionKind.expense,
        date: DateTime(2026, 11, 5),
        isPending: true);
    final days = group([morning, evening, midnight, afternoon]);

    expect(days.single.transactions, [evening, afternoon, morning, midnight]);
    expect(days.single.displayExpense, r'$3.00');
  });

  test(
      'pending income and expense stay visible without affecting posted totals',
      () {
    final days = group([
      tile(
          amount: 10000,
          type: TransactionKind.income,
          date: DateTime(2026, 11, 5)),
      tile(
          amount: 2000,
          type: TransactionKind.expense,
          date: DateTime(2026, 11, 5)),
      tile(
          amount: 30000,
          type: TransactionKind.income,
          date: DateTime(2026, 11, 5),
          isPending: true),
      tile(
          amount: 4000,
          type: TransactionKind.expense,
          date: DateTime(2026, 11, 5),
          isPending: true),
    ]);

    expect(days.single.transactions, hasLength(4));
    expect(days.single.displayIncome, r'$100.00');
    expect(days.single.displayExpense, r'$20.00');
  });

  test('a pending-only day has no income or expense subtotal', () {
    final days = group([
      tile(
          amount: 10000,
          type: TransactionKind.income,
          date: DateTime(2026, 11, 5),
          isPending: true),
      tile(
          amount: 2000,
          type: TransactionKind.expense,
          date: DateTime(2026, 11, 5),
          isPending: true),
    ]);

    expect(days.single.transactions, hasLength(2));
    expect(days.single.displayIncome, isNull);
    expect(days.single.displayExpense, isNull);
  });

  test('the same day is one group however its rows are timestamped', () {
    final days = group([
      tile(
          amount: 100,
          type: TransactionKind.expense,
          date: DateTime(2026, 11, 4, 9)),
      tile(
          amount: 100,
          type: TransactionKind.expense,
          date: DateTime(2026, 11, 4, 21)),
    ]);

    expect(days, hasLength(1));
    expect(days.single.displayExpense, r'$2.00');
  });

  test('a row on an excluded account keeps its day but not its total', () {
    // The day's subtotal is a cross-account total like any other, so the
    // same rule applies. The row stays on screen — the account is out of the
    // totals, not out of the ledger — which does mean a day can show rows
    // that its own subtotal does not account for. That is the deliberate
    // bargain; see CONTEXT.md on the two off-switches.
    const excluded = AccountEntity(
      id: 'acc_held',
      name: 'Held',
      type: AccountType.bank,
      currencyCode: 'USD',
      balanceMinor: 0,
      archived: false,
      includeInTotals: false,
      lastUpdatedEventId: 0,
    );

    final days = group([
      tile(
          amount: 50000,
          type: TransactionKind.expense,
          date: DateTime(2026, 11, 2)),
      TransactionTileUiModel(
        id: 'tx_excluded',
        amount: 90000,
        type: TransactionKind.expense,
        date: DateTime(2026, 11, 2),
        note: null,
        category: rent,
        account: excluded,
        displayAmount: '0.00',
        displaySign: '-',
      ),
    ]);

    expect(days.single.transactions, hasLength(2),
        reason: 'the excluded row is still a row');
    expect(days.single.displayExpense, r'$500.00',
        reason: 'and it is not in the number beside it');
  });
}
