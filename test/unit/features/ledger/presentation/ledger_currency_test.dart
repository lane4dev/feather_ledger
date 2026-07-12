import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';

/// Which currency the ledger says it is in.
///
/// The header asks this to decide which accounts and snapshots to total. Get
/// it from the *preference* and the ledger can report nothing at all: accounts
/// are created in whatever the preference was at the time, the preference can
/// move on, and there is no FX conversion to bridge the two.
void main() {
  AccountEntity account(String currencyCode) => AccountEntity(
        id: 'acc_$currencyCode',
        name: 'Cash',
        type: AccountType.cash,
        currencyCode: currencyCode,
        balanceMinor: 100000,
        archived: false,
        lastUpdatedEventId: 0,
      );

  ProviderContainer container({
    required List<AccountEntity> accounts,
    required String preference,
  }) {
    final c = ProviderContainer(overrides: [
      accountListProvider.overrideWithValue(AsyncData(accounts)),
      currencyControllerProvider.overrideWith(() => _FixedCurrency(preference)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('the accounts decide, not the preference', () {
    // The bug: seeded USD accounts meeting a preference resolved to CNY from
    // the locale. Filtering by CNY matched no account and no snapshot, so the
    // header showed 0.00 while the ledger held money.
    final c = container(accounts: [account('USD')], preference: 'CNY');

    expect(c.read(ledgerCurrencyProvider), 'USD');
    expect(c.read(displayCurrencySymbolProvider), r'$',
        reason: 'the symbol follows the money, or it mislabels it');
  });

  test('agreement is the same answer from either side', () {
    final c = container(accounts: [account('CNY')], preference: 'CNY');

    expect(c.read(ledgerCurrencyProvider), 'CNY');
    expect(c.read(displayCurrencySymbolProvider), '¥');
  });

  test('a mixed ledger falls back to the preference', () {
    // No single answer without FX conversion, so it reports the part of
    // itself the user asked to see rather than inventing a total.
    final c = container(
      accounts: [account('USD'), account('CNY')],
      preference: 'USD',
    );

    expect(c.read(ledgerCurrencyProvider), 'USD');
  });

  test('no accounts yet is the preference', () async {
    final c = container(accounts: const [], preference: 'EUR');
    // The preference is read from disk, so it has to have arrived before it
    // can stand in — the app awaits it at bootstrap for the same reason.
    await c.read(currencyControllerProvider.future);

    expect(c.read(ledgerCurrencyProvider), 'EUR');
  });
}

class _FixedCurrency extends CurrencyController {
  _FixedCurrency(this.code);

  final String code;

  @override
  Future<String> build() async => code;
}
