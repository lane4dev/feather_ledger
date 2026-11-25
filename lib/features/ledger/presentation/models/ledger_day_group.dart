import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/shared/presentation/money_format.dart';

import 'transaction_tile_ui_model.dart';

/// One day of the ledger, ready to render.
///
/// The day's income and expense arrive already summed and already written out.
/// A widget that added them up would have to know what an amount *is*: that a
/// transfer is neither (both legs are the same money moving, so counting them
/// would report a card payment as income and spending), and how to turn minor
/// units into the two decimals a person reads. Both are the business of
/// whoever builds these rows, which is also the only side that knows the
/// currency.
class LedgerDayGroup {
  final DateTime date;
  final List<TransactionTileUiModel> transactions;

  /// Include the currency symbol. Null when the day has none of that kind —
  /// a zero is not worth a line.
  final String? displayIncome;
  final String? displayExpense;

  const LedgerDayGroup({
    required this.date,
    required this.transactions,
    this.displayIncome,
    this.displayExpense,
  });

  bool get isEmpty => transactions.isEmpty;

  /// Only show the card's footer divider and subtotal when the day has at
  /// least two visible rows and at least one countable posted income/expense.
  bool get hasSubtotal =>
      transactions.length >= 2 &&
      (displayIncome != null || displayExpense != null);

  /// Sorts all rows newest first and groups them by calendar day, totalling
  /// each day's posted income and expense as it goes. Pending bills keep
  /// their place by date but do not contribute to the totals.
  ///
  /// Transfers are counted as neither. Their two legs are one movement
  /// between the user's own accounts, so a day that only moved money around
  /// reads as a day with no income and no expense, which is the truth.
  ///
  /// A row on an account that is out of the **ledger totals** (CONTEXT.md)
  /// still gets its day, and still appears in it — but it adds nothing to
  /// that day's figures. The day's subtotal is a cross-account total like any
  /// other, and the rule is one rule; the cost is that such a row is on
  /// screen without being in the arithmetic beside it. That is the same
  /// bargain the header makes one level up.
  static List<LedgerDayGroup> group(
    List<TransactionTileUiModel> transactions, {
    required String currencySymbol,
  }) {
    final order = <DateTime>[];
    final byDay = <DateTime, List<TransactionTileUiModel>>{};
    final income = <DateTime, int>{};
    final expense = <DateTime, int>{};
    final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));

    for (final tx in sorted) {
      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (!byDay.containsKey(day)) {
        order.add(day);
        byDay[day] = [];
        income[day] = 0;
        expense[day] = 0;
      }
      byDay[day]!.add(tx);

      if (tx.isPending || !tx.account.includeInTotals) continue;

      // Tile amounts are unsigned — the kind is what says which way the money
      // went, so the kind is what decides which column this lands in.
      switch (tx.type) {
        case TransactionKind.income:
          income[day] = income[day]! + tx.amount;
        case TransactionKind.expense:
          expense[day] = expense[day]! + tx.amount;
        case TransactionKind.transfer:
        case TransactionKind.openingBalance:
        case TransactionKind.balanceAdjustment:
          break;
      }
    }

    return [
      for (final day in order)
        LedgerDayGroup(
          date: day,
          transactions: byDay[day]!,
          displayIncome: income[day]! == 0
              ? null
              : '$currencySymbol${formatMinor(income[day]!)}',
          displayExpense: expense[day]! == 0
              ? null
              : '$currencySymbol${formatMinor(expense[day]!)}',
        ),
    ];
  }
}
