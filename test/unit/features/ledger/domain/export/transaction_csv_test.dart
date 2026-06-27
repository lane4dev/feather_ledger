import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/export/transaction_csv.dart';

/// The CSV export (spec 004, US3 / T049).
///
/// The escaping and the byte-order mark are the only real logic here, and
/// both are the kind of thing that looks fine until someone opens the file.
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
  const bank = AccountEntity(
    id: 'acc_bank',
    name: 'Bank',
    type: AccountType.bank,
    currencyCode: 'USD',
    balanceMinor: 0,
    archived: false,
    lastUpdatedEventId: 0,
  );
  const emptyCategory = CategoryEntity(
    id: '',
    name: '',
    iconKey: '',
    colorInt: 0,
    type: CategoryType.expense,
  );
  const food = CategoryEntity(
    id: 'cat_food',
    name: 'Food',
    iconKey: '1',
    colorInt: 0xFF000000,
    type: CategoryType.expense,
  );

  TransactionEntity row({
    required TransactionKind type,
    required int amount,
    String? note,
    CategoryEntity category = food,
    AccountEntity? toAccount,
    DateTime? date,
  }) =>
      TransactionEntity(
        id: 'tx',
        amount: amount,
        type: type,
        date: date ?? DateTime(2026, 1, 5),
        note: note,
        category: type == TransactionKind.transfer ? emptyCategory : category,
        account: cash,
        toAccount: toAccount,
        eventId: 1,
      );

  /// Data lines, with the byte-order mark stripped off the first one.
  List<String> lines(String csv) => csv
      .replaceFirst('﻿', '')
      .split('\n')
      .where((l) => l.trim().isNotEmpty)
      .toList();

  test('starts with a UTF-8 BOM', () {
    final csv = transactionsToCsv([row(type: TransactionKind.expense, amount: -500)]);

    expect(csv.codeUnitAt(0), 0xFEFF,
        reason: 'without it, Excel on Windows renders CJK notes as mojibake');
  });

  test('writes the header', () {
    final csv = transactionsToCsv([]);

    expect(lines(csv).single,
        'date,kind,amount,currency,account,toAccount,category,note');
  });

  test('writes an expense with its sign and its category', () {
    final csv = transactionsToCsv([
      row(type: TransactionKind.expense, amount: -1234, note: 'lunch'),
    ]);

    expect(lines(csv).last, '2026-01-05,expense,-12.34,USD,Cash,,Food,lunch');
  });

  test('writes income with a positive sign', () {
    final csv = transactionsToCsv([
      row(type: TransactionKind.income, amount: 500000, note: 'salary'),
    ]);

    expect(lines(csv).last,
        '2026-01-05,income,5000.00,USD,Cash,,Food,salary');
  });

  test('writes a transfer unsigned, with both accounts and no category', () {
    final csv = transactionsToCsv([
      row(
        type: TransactionKind.transfer,
        amount: 25000,
        toAccount: bank,
        note: 'repayment',
      ),
    ]);

    expect(lines(csv).last, '2026-01-05,transfer,250.00,USD,Cash,Bank,,repayment');
  });

  test('quotes fields containing a comma', () {
    final csv = transactionsToCsv([
      row(type: TransactionKind.expense, amount: -100, note: 'lunch, coffee'),
    ]);

    expect(lines(csv).last.endsWith('"lunch, coffee"'), isTrue);
  });

  test('doubles quotes inside a quoted field', () {
    final csv = transactionsToCsv([
      row(type: TransactionKind.expense, amount: -100, note: 'the "good" one'),
    ]);

    expect(lines(csv).last.endsWith('"the ""good"" one"'), isTrue);
  });

  test('quotes fields containing a line break', () {
    final csv = transactionsToCsv([
      row(type: TransactionKind.expense, amount: -100, note: 'line one\nline two'),
    ]);

    // Asserted against the whole document: a quoted newline is *inside* a
    // field, so splitting on '\n' would break the record in two.
    expect(csv.contains('"line one\nline two"'), isTrue);
  });

  test('keeps a plain field unquoted', () {
    final csv = transactionsToCsv([
      row(type: TransactionKind.expense, amount: -100, note: 'plain'),
    ]);

    expect(lines(csv).last.endsWith(',plain'), isTrue);
    expect(lines(csv).last.contains('"'), isFalse);
  });

  test('a CJK note survives the round trip through the bytes', () {
    // The point of the BOM: these characters must come out as themselves.
    final csv = transactionsToCsv([
      row(type: TransactionKind.expense, amount: -100, note: '房租'),
    ]);

    expect(csv.contains('房租'), isTrue);
  });

  test('an empty ledger produces only the header', () {
    expect(lines(transactionsToCsv([])), hasLength(1));
  });
}
