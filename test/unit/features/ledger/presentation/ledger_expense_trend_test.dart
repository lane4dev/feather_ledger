import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/presentation/models/ledger_day_group.dart';
import 'package:feather_ledger/features/ledger/presentation/models/ledger_expense_trend.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';

/// The sparkline reads the month the list already shows. What matters is that
/// it reads *spending* — not pending bills, not transfers, not money on an
/// account outside the ledger totals — and that a month with nothing to draw
/// says so instead of inventing a shape.
void main() {
  final account = AccountEntity(
    id: 'acc',
    name: 'Cash',
    type: AccountType.cash,
    currencyCode: 'CNY',
    balanceMinor: 0,
    archived: false,
    lastUpdatedEventId: 1,
  );
  final excluded = AccountEntity(
    id: 'hidden',
    name: 'Vault',
    type: AccountType.cash,
    currencyCode: 'CNY',
    balanceMinor: 0,
    archived: false,
    includeInTotals: false,
    lastUpdatedEventId: 2,
  );

  TransactionTileUiModel row({
    required int amount,
    required DateTime date,
    TransactionKind type = TransactionKind.expense,
    bool pending = false,
    AccountEntity? on,
  }) =>
      TransactionTileUiModel(
        id: 'tx-$amount-${date.day}',
        amount: amount,
        type: type,
        date: date,
        note: null,
        account: on ?? account,
        displayAmount: '10.00',
        displaySign: '-',
        isPending: pending,
      );

  LedgerDayGroup day(DateTime date, List<TransactionTileUiModel> rows) =>
      LedgerDayGroup(date: date, transactions: rows);

  test('no rows means no line to draw', () {
    final trend = LedgerExpenseTrend.fromDays(const []);

    expect(trend.points, isEmpty);
    expect(trend.isDrawable, isFalse);
  });

  test('a single day of spending is not a trend', () {
    final trend = LedgerExpenseTrend.fromDays([
      day(DateTime(2026, 11, 20), [row(amount: 500, date: DateTime(2026, 11, 20))]),
    ]);

    expect(trend.points, [500.0]);
    expect(
      trend.isDrawable,
      isFalse,
      reason: 'one point cannot be a line; the card draws a baseline instead',
    );
  });

  test('a month of zeros has no shape', () {
    final trend = LedgerExpenseTrend.fromDays([
      for (var d = 12; d >= 10; d--)
        day(DateTime(2026, 11, d), [
          row(
            amount: 100,
            date: DateTime(2026, 11, d),
            type: TransactionKind.income,
          ),
        ]),
    ]);

    expect(trend.points, [0.0, 0.0, 0.0]);
    expect(trend.isDrawable, isFalse);
  });

  test('pending bills and transfers are not spending', () {
    final trend = LedgerExpenseTrend.fromDays([
      day(DateTime(2026, 11, 12), [
        row(amount: 900, date: DateTime(2026, 11, 12), pending: true),
        row(
          amount: 700,
          date: DateTime(2026, 11, 12),
          type: TransactionKind.transfer,
        ),
        row(amount: 200, date: DateTime(2026, 11, 12)),
      ]),
      day(DateTime(2026, 11, 11), [
        row(amount: 50, date: DateTime(2026, 11, 11)),
      ]),
    ]);

    expect(trend.points, [50.0, 200.0]);
  });

  test('an account outside the ledger totals does not spend', () {
    final trend = LedgerExpenseTrend.fromDays([
      day(DateTime(2026, 11, 12), [
        row(amount: 900, date: DateTime(2026, 11, 12), on: excluded),
      ]),
      day(DateTime(2026, 11, 11), [
        row(amount: 50, date: DateTime(2026, 11, 11)),
      ]),
    ]);

    expect(trend.points, [50.0, 0.0]);
  });

  test('days without rows are zero, not missing', () {
    final trend = LedgerExpenseTrend.fromDays([
      day(DateTime(2026, 11, 15), [row(amount: 300, date: DateTime(2026, 11, 15))]),
      day(DateTime(2026, 11, 12), [row(amount: 100, date: DateTime(2026, 11, 12))]),
    ]);

    expect(trend.points, [100.0, 0.0, 0.0, 300.0]);
    expect(trend.peak, 300.0);
  });

  test('the window never exceeds the point budget', () {
    final days = [
      for (var d = 30; d >= 1; d--)
        day(DateTime(2026, 11, d), [row(amount: d * 10, date: DateTime(2026, 11, d))]),
    ];

    final trend = LedgerExpenseTrend.fromDays(days, maxPoints: 7);

    expect(trend.points.length, 7);
    expect(
      trend.points,
      [240.0, 250.0, 260.0, 270.0, 280.0, 290.0, 300.0],
      reason: 'the newest days are kept, oldest first',
    );
  });

  test('a short window is not padded', () {
    final trend = LedgerExpenseTrend.fromDays([
      day(DateTime(2026, 11, 7), [row(amount: 100, date: DateTime(2026, 11, 7))]),
      day(DateTime(2026, 11, 6), [row(amount: 200, date: DateTime(2026, 11, 6))]),
    ]);

    expect(trend.points, [200.0, 100.0]);
  });
}
