import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/shared/presentation/models/account_ui_model.dart';

/// An account as a row shows it.
///
/// Two screens list accounts — the ledger's picker and the settings management
/// screen — and both used to turn minor units into text themselves.
void main() {
  AccountEntity account({
    required String currencyCode,
    required int balanceMinor,
  }) =>
      AccountEntity(
        id: 'acc_1',
        name: 'Wallet',
        type: AccountType.cash,
        currencyCode: currencyCode,
        balanceMinor: balanceMinor,
        archived: false,
        lastUpdatedEventId: 0,
      );

  test('writes the balance out', () {
    expect(AccountUiModel.of(account(currencyCode: 'USD', balanceMinor: 123456))
        .displayBalance, r'$1234.56');
  });

  test('uses the account’s own currency, not a display preference', () {
    // A screen can list several accounts at once, and a wallet holding yen
    // shows yen however the ledger is configured.
    expect(AccountUiModel.of(account(currencyCode: 'JPY', balanceMinor: 500000))
        .displayBalance, '¥5000.00');
  });

  test('mixed view writes the balance with its currency code', () {
    expect(
        AccountUiModel.of(account(currencyCode: 'JPY', balanceMinor: 500000))
            .displayBalanceWithCode,
        '¥5000.00 JPY');
    expect(
        AccountUiModel.of(account(currencyCode: 'JPY', balanceMinor: -1234))
            .displayBalanceWithCode,
        '-¥12.34 JPY');
    expect(
        AccountUiModel.of(account(currencyCode: 'USD', balanceMinor: -123456))
            .displayBalanceWithCode,
        r'-$1234.56 USD');
  });

  test('keeps the entity for the screen to name and tap', () {
    final model =
        AccountUiModel.of(account(currencyCode: 'USD', balanceMinor: 1));

    expect(model.account.name, 'Wallet');
    expect(model.account.id, 'acc_1');
  });
}
