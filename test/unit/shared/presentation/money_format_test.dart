import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/shared/presentation/models/account_ui_model.dart';
import 'package:feather_ledger/shared/presentation/models/monthly_summary_ui_model.dart';
import 'package:feather_ledger/shared/presentation/money_format.dart';

import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/enums.dart';

/// How a signed amount is written.
///
/// The rule is one character wide and easy to undo one call site at a time:
/// the minus goes **outside** the symbol. `$-12.34` reads as a currency sign
/// followed by a negative number, which is not what a negative amount is.
void main() {
  group('formatMinorWithSymbol', () {
    test('puts a negative amount’s sign before the symbol', () {
      expect(formatMinorWithSymbol(-1234, r'$'), r'- $12.34');
      expect(formatMinorWithSymbol(-1234, '¥'), '- ¥12.34');
    });

    test('leaves a positive amount alone', () {
      expect(formatMinorWithSymbol(1234, r'$'), r'$12.34');
      expect(formatMinorWithSymbol(0, r'$'), r'$0.00');
    });

    test('never writes a sign between the symbol and the digits', () {
      for (final minor in [-1, -100, -123456, 0, 999, 123456]) {
        expect(formatMinorWithSymbol(minor, r'$').contains(r'$-'), isFalse,
            reason: '$minor must not render as \$-…');
      }
    });
  });

  group('formatMinorWithSymbolAndCode', () {
    test('appends the code after the amount', () {
      expect(formatMinorWithSymbolAndCode(500000, '¥', 'JPY'), '¥5000.00 JPY');
      expect(formatMinorWithSymbolAndCode(123456, r'$', 'USD'), r'$1234.56 USD');
    });

    test('keeps a negative sign outside the symbol', () {
      expect(formatMinorWithSymbolAndCode(-1234, r'$', 'USD'), r'- $12.34 USD');
    });
  });

  group('the models that can be negative', () {
    AccountEntity account(int balanceMinor) => AccountEntity(
          id: 'acc_1',
          name: 'Card',
          type: AccountType.credit,
          currencyCode: 'USD',
          balanceMinor: balanceMinor,
          archived: false,
          lastUpdatedEventId: 0,
        );

    test('an overdrawn account balance reads - \$12.34', () {
      expect(AccountUiModel.of(account(-1234)).displayBalance, r'- $12.34');
    });

    test('a month that ended below zero reads the same way', () {
      final summary = MonthlySummaryUiModel.of(
        balanceMinor: -5000,
        incomeMinor: 10000,
        expenseMinor: -15000,
        currencySymbol: r'$',
      );

      expect(summary.displayBalance, r'- $50.00');
      // Income and expense are magnitudes: the label beside them is what says
      // which way the money went, so a minus there would say it twice.
      expect(summary.displayIncome, r'$100.00');
      expect(summary.displayExpense, r'$150.00');
    });
  });
}
