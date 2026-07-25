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
      );

  List<LedgerDayGroup> group(List<TransactionTileUiModel> tiles) =>
      LedgerDayGroup.group(tiles, currencySymbol: r'$');

  test('writes each day out and totals it', () {
    final days = group([
      tile(amount: 250000, type: TransactionKind.income, date: DateTime(2026, 11, 1)),
      tile(amount: 50000, type: TransactionKind.expense, date: DateTime(2026, 11, 1)),
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
      tile(amount: 300000, type: TransactionKind.transfer, date: DateTime(2026, 11, 2)),
    ]);

    expect(days.single.displayIncome, isNull);
    expect(days.single.displayExpense, isNull);
  });

  test('a kind the day has none of is left out, not shown as zero', () {
    final days = group([
      tile(amount: 1000, type: TransactionKind.expense, date: DateTime(2026, 11, 3)),
    ]);

    expect(days.single.displayExpense, r'$10.00');
    expect(days.single.displayIncome, isNull,
        reason: 'a zero is not worth a line');
  });

  test('days keep the order they arrived in', () {
    final days = group([
      tile(amount: 100, type: TransactionKind.expense, date: DateTime(2026, 11, 5)),
      tile(amount: 100, type: TransactionKind.expense, date: DateTime(2026, 11, 1)),
    ]);

    expect(days.map((d) => d.date.day), [5, 1]);
  });

  test('the same day is one group however its rows are timestamped', () {
    final days = group([
      tile(amount: 100, type: TransactionKind.expense, date: DateTime(2026, 11, 4, 9)),
      tile(amount: 100, type: TransactionKind.expense, date: DateTime(2026, 11, 4, 21)),
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
      tile(amount: 50000, type: TransactionKind.expense, date: DateTime(2026, 11, 2)),
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
