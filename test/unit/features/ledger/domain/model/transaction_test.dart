import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/domain/model/transaction.dart';

/// The aggregate's own interface: no database, no projector, no service.
///
/// ADR-0001 puts `validate()` on the write path, so these rules are
/// testable through the aggregate itself — which is the point of the move.
/// Replay still validates what it rehydrates, so the same checks are also
/// exercised end-to-end by `record_transaction_test`'s rollback case.
void main() {
  group('validate — shape contract', () {
    const expenseLeg = Posting(
      accountId: 'acc-1',
      direction: PostingDirection.debit,
      amountMinor: 1050,
      currencyCode: 'USD',
    );

    Posting leg(String accountId, PostingDirection direction,
            {int amountMinor = 10000, String currencyCode = 'USD'}) =>
        Posting(
          accountId: accountId,
          direction: direction,
          amountMinor: amountMinor,
          currencyCode: currencyCode,
        );

    Transaction of(List<Posting> postings, TransactionKind kind) =>
        Transaction.rehydrate(
          transactionId: 'txn-1',
          occurredAt: DateTime(2026, 1, 15),
          description: 'x',
          kind: kind,
          postings: postings,
        );

    test('valid single-leg expense', () {
      expect(of([expenseLeg], TransactionKind.expense).validate(), isNull);
    });

    test('income must be a single credit posting', () {
      expect(
        of([expenseLeg], TransactionKind.income).validate(),
        TransactionViolation.postingDirection,
      );
      expect(
        of([expenseLeg, expenseLeg], TransactionKind.income).validate(),
        TransactionViolation.postingCount,
      );
    });

    test('empty postings and non-positive amounts are rejected', () {
      expect(
        of(const [], TransactionKind.expense).validate(),
        TransactionViolation.postingsEmpty,
      );
      expect(
        of([leg('a', PostingDirection.debit, amountMinor: 0)],
                TransactionKind.expense)
            .validate(),
        TransactionViolation.amountNotPositive,
      );
    });

    test('transfer requires opposite, equal, distinct, same-currency legs',
        () {
      expect(
        of([
          leg('a', PostingDirection.debit),
          leg('b', PostingDirection.credit),
        ], TransactionKind.transfer).validate(),
        isNull,
      );
      expect(
        of([
          leg('a', PostingDirection.debit),
          leg('a', PostingDirection.credit),
        ], TransactionKind.transfer).validate(),
        TransactionViolation.transferSameAccount,
      );
      expect(
        of([
          leg('a', PostingDirection.debit),
          leg('b', PostingDirection.credit, amountMinor: 9999),
        ], TransactionKind.transfer).validate(),
        TransactionViolation.transferAmounts,
      );
      expect(
        of([
          leg('a', PostingDirection.debit),
          leg('b', PostingDirection.debit),
        ], TransactionKind.transfer).validate(),
        TransactionViolation.transferDirections,
      );
      expect(
        of([
          leg('a', PostingDirection.debit),
          leg('b', PostingDirection.credit, currencyCode: 'CNY'),
        ], TransactionKind.transfer).validate(),
        TransactionViolation.transferCurrency,
      );
      expect(
        of([leg('a', PostingDirection.debit)], TransactionKind.transfer)
            .validate(),
        TransactionViolation.postingCount,
      );
    });

    test('signedImpact derives sign from direction only', () {
      expect(expenseLeg.signedImpact, -1050);
      expect(leg('a', PostingDirection.credit, amountMinor: 1050).signedImpact,
          1050);
    });
  });

  group('intent constructors', () {
    test('expense is one debit posting of the account currency', () {
      final txn = Transaction.expense(
        transactionId: 'txn-1',
        occurredAt: DateTime(2026, 1, 15),
        amountMinor: 1050,
        accountId: 'cash',
        currencyCode: 'CNY',
        categoryId: 'food',
      );

      expect(txn.kind, TransactionKind.expense);
      expect(txn.postings, hasLength(1));
      expect(txn.postings.single.direction, PostingDirection.debit);
      expect(txn.postings.single.currencyCode, 'CNY');
      expect(txn.postings.single.categoryId, 'food');
      expect(txn.validate(), isNull);
    });

    test('income is one credit posting', () {
      final txn = Transaction.income(
        transactionId: 'txn-1',
        occurredAt: DateTime(2026, 1, 15),
        amountMinor: 1050,
        accountId: 'cash',
        currencyCode: 'USD',
        categoryId: 'salary',
      );

      expect(txn.postings.single.direction, PostingDirection.credit);
      expect(txn.validate(), isNull);
    });

    test('transfer is two equal, opposite legs with no category', () {
      final txn = Transaction.transfer(
        transactionId: 'txn-1',
        occurredAt: DateTime(2026, 1, 15),
        amountMinor: 10000,
        fromAccountId: 'savings',
        fromCurrencyCode: 'USD',
        toAccountId: 'card',
        toCurrencyCode: 'USD',
      );

      expect(txn.kind, TransactionKind.transfer);
      expect(txn.postings, hasLength(2));
      expect(txn.postings.map((p) => p.categoryId), everyElement(isNull));
      expect(txn.postings.fold(0, (sum, p) => sum + p.signedImpact), 0);
      expect(txn.validate(), isNull);
    });

    test('a cross-currency transfer is constructible but not valid', () {
      final txn = Transaction.transfer(
        transactionId: 'txn-1',
        occurredAt: DateTime(2026, 1, 15),
        amountMinor: 10000,
        fromAccountId: 'savings',
        fromCurrencyCode: 'USD',
        toAccountId: 'card',
        toCurrencyCode: 'CNY',
      );

      expect(txn.validate(), TransactionViolation.transferCurrency);
    });

    test('a non-positive amount is constructible but not valid', () {
      final txn = Transaction.expense(
        transactionId: 'txn-1',
        occurredAt: DateTime(2026, 1, 15),
        amountMinor: 0,
        accountId: 'cash',
        currencyCode: 'USD',
        categoryId: 'food',
      );

      expect(txn.validate(), TransactionViolation.amountNotPositive);
    });
  });

  group('violation → user-facing code', () {
    test('every violation has a code, and the set is exhaustive', () {
      const expected = {
        TransactionViolation.amountNotPositive: LedgerErrorCode.invalidAmount,
        TransactionViolation.transferSameAccount:
            LedgerErrorCode.sameAccountTransfer,
        TransactionViolation.transferCurrency: LedgerErrorCode.currencyMismatch,
        TransactionViolation.transferDirections: LedgerErrorCode.invalidTransfer,
        TransactionViolation.transferAmounts: LedgerErrorCode.invalidTransfer,
        TransactionViolation.postingsEmpty:
            LedgerErrorCode.invalidTransactionShape,
        TransactionViolation.postingCount:
            LedgerErrorCode.invalidTransactionShape,
        TransactionViolation.postingDirection:
            LedgerErrorCode.invalidTransactionShape,
      };

      for (final violation in TransactionViolation.values) {
        expect(violation.errorCode, expected[violation],
            reason: '${violation.name} has no mapped code');
      }
      expect(expected.keys, hasLength(TransactionViolation.values.length));
    });

    test('shape failures do not collapse into the transfer codes', () {
      expect(TransactionViolation.postingCount.errorCode,
          isNot(LedgerErrorCode.invalidTransfer));
      expect(TransactionViolation.postingsEmpty.errorCode,
          isNot(LedgerErrorCode.invalidAmount));
    });
  });

  group('validateOrThrow', () {
    test('rejects with the mapped code, not a bare exception', () {
      final txn = Transaction.transfer(
        transactionId: 'txn-1',
        occurredAt: DateTime(2026, 1, 15),
        amountMinor: 10000,
        fromAccountId: 'same',
        fromCurrencyCode: 'USD',
        toAccountId: 'same',
        toCurrencyCode: 'USD',
      );

      expect(
        txn.validateOrThrow,
        throwsA(isA<CommandRejected>().having(
            (e) => e.code, 'code', LedgerErrorCode.sameAccountTransfer)),
      );
    });

    test('says nothing when the shape is legal', () {
      final txn = Transaction.income(
        transactionId: 'txn-1',
        occurredAt: DateTime(2026, 1, 15),
        amountMinor: 1050,
        accountId: 'cash',
        currencyCode: 'USD',
        categoryId: 'salary',
      );

      expect(txn.validateOrThrow, returnsNormally);
    });
  });
}
