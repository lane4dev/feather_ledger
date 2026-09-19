import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';

/// Which currency the ledger is scoped to.
///
/// The multi-currency spec makes the *setting* the single source of truth for
/// the ledger, search and reports (spec 006). Accounts no longer decide:
/// accounts are created in whatever the preference was at the time, and the
/// preference can move on, so the account list can hold several currencies at
/// once. The ledger shows the part the user asked to see; a setting with no
/// accounts in it is the empty state, not an error.
void main() {
  AccountEntity account(String currencyCode, {bool includeInTotals = true}) =>
      AccountEntity(
        id: 'acc_$currencyCode',
        name: 'Cash',
        type: AccountType.cash,
        currencyCode: currencyCode,
        balanceMinor: 100000,
        archived: false,
        includeInTotals: includeInTotals,
        lastUpdatedEventId: 0,
      );

  Future<ProviderContainer> container({
    required List<AccountEntity> accounts,
    required String preference,
  }) async {
    final c = ProviderContainer(overrides: [
      accountListProvider.overrideWithValue(AsyncData(accounts)),
      currencyControllerProvider.overrideWith(() => _FixedCurrency(preference)),
    ]);
    addTearDown(c.dispose);
    // The preference is read from disk and awaited at bootstrap; without
    // waiting here the provider's `.value` is still null and the default
    // (USD) stands in.
    await c.read(currencyControllerProvider.future);
    return c;
  }

  test('the setting decides, not the accounts', () async {
    // Accounts can hold several currencies; the ledger shows the one the user
    // chose in settings, even while other-currency accounts exist.
    final c = await container(accounts: [account('USD')], preference: 'CNY');

    expect(c.read(ledgerCurrencyProvider), 'CNY');
    expect(c.read(displayCurrencySymbolProvider), '¥',
        reason: 'the symbol follows the setting, or it mislabels the money');
  });

  test('agreement is the same answer from either side', () async {
    final c = await container(accounts: [account('CNY')], preference: 'CNY');

    expect(c.read(ledgerCurrencyProvider), 'CNY');
    expect(c.read(displayCurrencySymbolProvider), '¥');
  });

  test('a mixed ledger still follows the setting', () async {
    final c = await container(
      accounts: [account('USD'), account('CNY')],
      preference: 'USD',
    );

    expect(c.read(ledgerCurrencyProvider), 'USD');
  });

  test('no accounts yet is the preference', () async {
    final c = await container(accounts: const [], preference: 'EUR');

    expect(c.read(ledgerCurrencyProvider), 'EUR');
  });

  test('an account out of the totals does not move the setting', () async {
    // The setting is the scope regardless of how individual accounts are
    // flagged; includeInTotals changes the sums, never the currency.
    final c = await container(
      accounts: [account('CNY', includeInTotals: false)],
      preference: 'USD',
    );

    expect(c.read(ledgerCurrencyProvider), 'USD');
    expect(c.read(displayCurrencySymbolProvider), r'$');
  });
}

class _FixedCurrency extends CurrencyController {
  _FixedCurrency(this.code);

  final String code;

  @override
  Future<String> build() async => code;
}
