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

  /// Ready to print, currency symbol included.
  final String displayBalance;

  const AccountUiModel({
    required this.account,
    required this.displayBalance,
  });

  /// The balance is in **the account's own currency**, not the display
  /// preference: a wallet holding yen shows yen, and a screen listing several
  /// accounts at once could not use one symbol for all of them anyway.
  factory AccountUiModel.of(AccountEntity account) => AccountUiModel(
        account: account,
        displayBalance: '${AppCurrencies.getSymbol(account.currencyCode)}'
            '${formatMinor(account.balanceMinor)}',
      );
}
