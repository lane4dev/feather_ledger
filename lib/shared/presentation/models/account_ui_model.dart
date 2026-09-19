import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/shared/presentation/money_format.dart';

/// An account as a screen shows it: the entity, plus its balance written out.
///
/// Every place that lists accounts — the ledger's picker and the management
/// screen — was turning minor units into text itself, which is two answers to
/// one question and the way two answers drift apart.
class AccountUiModel {
  final AccountEntity account;

  /// Ready to print, currency symbol included. A credit card's balance is
  /// negative, and reads `- $12.34`.
  final String displayBalance;

  /// [displayBalance] with the ISO code appended (`¥5000.00 JPY`), for a
  /// mixed-currency list where the symbol alone is ambiguous.
  final String displayBalanceWithCode;

  const AccountUiModel({
    required this.account,
    required this.displayBalance,
    required this.displayBalanceWithCode,
  });

  /// The balance is in **the account's own currency**, not the display
  /// preference: a wallet holding yen shows yen, and a screen listing several
  /// accounts at once could not use one symbol for all of them anyway.
  factory AccountUiModel.of(AccountEntity account) {
    final symbol = AppCurrencies.getSymbol(account.currencyCode);
    return AccountUiModel(
      account: account,
      displayBalance: formatMinorWithSymbol(account.balanceMinor, symbol),
      displayBalanceWithCode: formatMinorWithSymbolAndCode(
          account.balanceMinor, symbol, account.currencyCode),
    );
  }
}
