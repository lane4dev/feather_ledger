import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/shared/presentation/models/balance_display_parts.dart';

/// The overview card sets a balance in three sizes, which means it needs one
/// written-out amount taken apart. These tests pin the split — including the
/// cases where a naive `substring` would land in the wrong place: a currency
/// symbol that is not one character, a negative balance, an amount with no
/// decimals, and a mask that was never a number.
void main() {
  group('BalanceDisplayParts.parse', () {
    test('splits a single-character symbol, units, and decimals', () {
      final parts = BalanceDisplayParts.parse('¥1195.00');

      expect(parts.sign, '');
      expect(parts.symbol, '¥');
      expect(parts.whole, '1195');
      expect(parts.fraction, '.00');
      expect(parts.isNumeric, isTrue);
    });

    test('the minus stays outside the symbol', () {
      final parts = BalanceDisplayParts.parse('-¥12.34');

      expect(parts.sign, '-');
      expect(parts.symbol, '¥');
      expect(parts.whole, '12');
      expect(parts.fraction, '.34');
    });

    test('a multi-character or letter symbol is taken whole', () {
      final parts = BalanceDisplayParts.parse(r'$1,234.56');

      expect(parts.symbol, r'$');
      expect(parts.whole, '1,234');
      expect(parts.fraction, '.56');

      final letters = BalanceDisplayParts.parse('USD 99.50');
      expect(letters.symbol, 'USD ');
      expect(letters.whole, '99');
      expect(letters.fraction, '.50');
    });

    test('an amount written without decimals has no fraction to step down', () {
      final parts = BalanceDisplayParts.parse('¥630');

      expect(parts.whole, '630');
      expect(parts.fraction, '');
    });

    test('a mask or a dash is not numeric', () {
      for (final source in ['¥ ****', '******', '—']) {
        expect(
          BalanceDisplayParts.parse(source).isNumeric,
          isFalse,
          reason: '"$source" is not a number and cannot be set in three tiers',
        );
      }
    });

    test('an empty string survives', () {
      final parts = BalanceDisplayParts.parse('');

      expect(parts.isNumeric, isFalse);
      expect(parts.whole, '');
    });
  });
}
