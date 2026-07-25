import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/features/settings/domain/services/account_service.dart';

import '../../../../support/event_sourcing/ledger_service_harness.dart';

/// The header's figures follow the ledger's currency, including while that
/// currency is still changing.
///
/// The ledger's currency is derived from the accounts, so while they are
/// loading it answers with the display preference — and before that, with the
/// built-in default. A summary bound to that first answer went on filtering by
/// it after the first account landed in another currency: a fresh install on a
/// zh locale captured USD on the first frame, then opened its first account in
/// CNY, and the header read `$0.00` over a ledger holding ¥1000. Income and
/// expense were wrong the same way, off the same code.
///
/// The workaround was to swipe a month away and back, because changing the
/// month was the only thing that re-read it. See
/// [ledgerMonthlySummaryProvider] — the currency is a `ref.watch` there now,
/// so Riverpod re-subscribes on its own.
void main() {
  test('a summary built before the first account lands still finds it',
      () async {
    final harness = LedgerServiceHarness();
    addTearDown(harness.close);
    await harness.seedSystemCategories();

    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(harness.db)],
    );
    addTearDown(container.dispose);
    container.listen(accountListProvider, (_, __) {});

    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    // Subscribed *before* the account exists — that is the whole point.
    container.listen(ledgerMonthlySummaryProvider(month), (_, __) {});

    expect(container.read(ledgerCurrencyProvider), 'USD',
        reason: 'no accounts and no preference read yet: the built-in default');

    final result = await container.read(accountServiceProvider).createAccount(
          commandId: 'cmd_opening',
          name: 'Cash',
          type: AccountType.cash,
          initialBalanceMinor: 100000,
          currencyCode: 'CNY',
          initialBalanceNote: 'difference',
        );
    expect(result, isA<Success<void>>());

    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(container.read(ledgerCurrencyProvider), 'CNY');
    final summary = container.read(ledgerMonthlySummaryProvider(month)).value;
    expect(summary?.displayBalance, '¥1000.00',
        reason: "the header totals the accounts in the ledger's own currency");
    expect(summary?.displayIncome, '¥0.00',
        reason: 'an opening balance is not this month\'s income');
  });
}
