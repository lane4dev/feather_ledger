import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/money/money.dart';

void main() {
  group('Money', () {
    test('equals combines amount and currency', () {
      expect(const Money(1050, 'USD'), const Money(1050, 'USD'));
      expect(const Money(1050, 'USD'), isNot(const Money(1050, 'CNY')));
      expect(const Money(1050, 'USD'), isNot(const Money(1049, 'USD')));
    });

    test('adds same-currency amounts in minor units', () {
      expect(
        const Money(1050, 'USD') + const Money(950, 'USD'),
        const Money(2000, 'USD'),
      );
      expect(
        const Money(500, 'CNY') - const Money(1250, 'CNY'),
        const Money(-750, 'CNY'),
      );
    });

    test('adding different currencies throws CurrencyMismatchError', () {
      expect(
        () => const Money(100, 'USD') + const Money(100, 'CNY'),
        throwsA(isA<CurrencyMismatchError>()),
      );
      expect(
        () => const Money(100, 'USD') - const Money(100, 'EUR'),
        throwsA(isA<CurrencyMismatchError>()),
      );
    });

    test('fromDouble bridges exact minor-unit doubles only', () {
      expect(Money.fromDouble(10.50, 'USD'), const Money(1050, 'USD'));
      expect(Money.fromDouble(-0.01, 'USD'), const Money(-1, 'USD'));
      expect(Money.fromDouble(0, 'USD'), const Money(0, 'USD'));
    });

    test('fromDouble rejects inexact or non-finite doubles', () {
      expect(
        () => Money.fromDouble(10.505, 'USD'),
        throwsA(isA<InexactAmountError>()),
      );
      expect(
        () => Money.fromDouble(double.nan, 'USD'),
        throwsA(isA<InexactAmountError>()),
      );
      expect(
        () => Money.fromDouble(double.infinity, 'USD'),
        throwsA(isA<InexactAmountError>()),
      );
    });

    test('negation keeps currency', () {
      expect(-const Money(1050, 'USD'), const Money(-1050, 'USD'));
    });
  });
}
