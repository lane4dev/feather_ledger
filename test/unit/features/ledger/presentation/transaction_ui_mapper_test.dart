import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/presentation/mappers/transaction_ui_mapper.dart';

/// What the ledger's rows are handed (spec 004).
///
/// Two properties that are easy to lose one file at a time: the amount a row
/// carries is **unsigned**, and which sign it shows is decided by the kind,
/// not by the number. A signed amount plus a sign derived from the kind is how
/// you get "- $-500.00".
void main() {
  const mapper = TransactionUiMapper();
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

  ScheduledTransactionEntity pending(int amountMinor, {TransactionKind? kind}) =>
      ScheduledTransactionEntity(
        id: 'sched_1',
        seriesId: 'series_1',
        amountMinor: amountMinor,
        date: DateTime(2026, 11, 1),
        status: ScheduledTransactionStatus.scheduled,
        kind: kind ?? TransactionKind.expense,
      );

  group('a pending bill', () {
    test('carries its amount unsigned, with the sign in the kind', () {
      final tile = mapper.toPendingTile(
        pending(-50000),
        category: rent,
        account: cash,
      );

      expect(tile.amount, 50000,
          reason: 'a negative column value must not reach the row signed');
      expect(tile.displayAmount, '500.00');
      expect(tile.displaySign, '-',
          reason: 'the kind is the only thing deciding the sign');
    });

    test('renders one sign, not two', () {
      final tile = mapper.toPendingTile(
        pending(-50000),
        category: rent,
        account: cash,
      );

      // What the row actually paints.
      final painted = '${tile.displaySign} ${tile.displayAmount}';
      expect(painted, '- 500.00');
      expect(painted.contains('--'), isFalse);
    });

    test('an income bill reads the same magnitude with a plus', () {
      final tile = mapper.toPendingTile(
        pending(-30000, kind: TransactionKind.income),
        category: rent,
        account: cash,
      );

      expect(tile.amount, 30000);
      expect(tile.displaySign, '+');
      expect(tile.displayAmount, '300.00');
    });
  });
}
