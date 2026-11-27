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

  ScheduledTransactionEntity pending(int amountMinor,
          {TransactionKind? kind}) =>
      ScheduledTransactionEntity(
        id: 'sched_1',
        seriesId: 'series_1',
        occurrenceKey: '2026-11-01',
        scheduledDate: DateTime(2026, 11, 1),
        amountOverrideMinor: amountMinor,
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
      expect(tile.formattedAmount('¥'), '-¥500.00');
    });

    test('renders one sign, not two', () {
      final tile = mapper.toPendingTile(
        pending(-50000),
        category: rent,
        account: cash,
      );

      final painted = tile.formattedAmount('¥');
      expect(painted, '-¥500.00');
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
      expect(tile.formattedAmount('¥'), '+¥300.00');
    });
  });

  group('posted transactions', () {
    TransactionEntity posted({
      required TransactionKind type,
      required int amount,
      String? sourceScheduledBillId,
    }) =>
        TransactionEntity(
          id: 'tx_1',
          amount: amount,
          type: type,
          date: DateTime(2026, 11, 1),
          account: cash,
          category: type == TransactionKind.transfer ? null : rent,
          toAccount: type == TransactionKind.transfer ? cash : null,
          eventId: 1,
          sourceScheduledBillId: sourceScheduledBillId,
        );

    test('formats compact signed and unsigned amounts without extra spaces',
        () {
      expect(
        mapper
            .toTile(posted(type: TransactionKind.expense, amount: -1000))
            .formattedAmount('¥'),
        '-¥10.00',
      );
      expect(
        mapper
            .toTile(posted(type: TransactionKind.income, amount: 1000))
            .formattedAmount('¥'),
        '+¥10.00',
      );
      final transfer =
          mapper.toTile(posted(type: TransactionKind.transfer, amount: 2000));
      expect(transfer.formattedAmount('¥'), '¥20.00');
      expect(transfer.formattedAmount('¥').startsWith(' '), isFalse);
    });

    test('carries the scheduled bill it was posted from', () {
      final tile = mapper.toTile(
        posted(
          type: TransactionKind.expense,
          amount: -1000,
          sourceScheduledBillId: 'sched_42',
        ),
      );

      expect(tile.sourceScheduledBillId, 'sched_42');
      expect(
        mapper
            .toTile(posted(type: TransactionKind.expense, amount: -1000))
            .sourceScheduledBillId,
        isNull,
      );
    });
  });
}
