import 'package:feather_ledger/shared/presentation/money_format.dart';

/// A month's three headline figures, written out and unsigned.
///
/// Takes plain minor units rather than either slice's totals type: the ledger
/// header and the reports screen read the same numbers through different
/// repositories, and both would otherwise convert them themselves.
class MonthlySummaryUiModel {
  /// Signed on purpose, and written as `-$12.34` rather than `$-12.34`. A
  /// balance can genuinely be below zero — an overdrawn account is a fact
  /// about the money, not a convention about which way it moved — so unlike
  /// income and expense this one keeps its minus.
  final String displayBalance;

  /// Magnitudes. Which way the money went is what the label beside them says,
  /// so a minus here would be the label repeated in arithmetic.
  final String displayIncome;
  final String displayExpense;

  const MonthlySummaryUiModel({
    required this.displayBalance,
    required this.displayIncome,
    required this.displayExpense,
  });

  factory MonthlySummaryUiModel.of({
    required int balanceMinor,
    required int incomeMinor,
    required int expenseMinor,
    required String currencySymbol,
  }) =>
      MonthlySummaryUiModel(
        displayBalance:
            formatMinorWithSymbol(balanceMinor, currencySymbol),
        displayIncome: '$currencySymbol${formatMinor(incomeMinor.abs())}',
        displayExpense: '$currencySymbol${formatMinor(expenseMinor.abs())}',
      );
}
