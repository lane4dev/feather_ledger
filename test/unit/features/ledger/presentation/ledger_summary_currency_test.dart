import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_monthly_snapshot_query.dart';
import 'package:feather_ledger/features/ledger/domain/services/ledger_service.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/features/settings/domain/services/account_service.dart';

import '../../../../support/event_sourcing/ledger_service_harness.dart';

/// The header's figures follow the setting's currency, not the accounts.
///
/// The setting is the single source of truth for the ledger, search and
/// reports (spec 006). An account created in another currency does not move
/// the ledger; the ledger shows the currency the user asked to see, and a
/// setting with no accounts in it is the empty state, not an error.
void main() {
  test('the setting, not the accounts, decides the summary', () async {
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
    container.listen(ledgerMonthlySummaryProvider(month), (_, __) {});

    // A unit test cannot read the disk preference, so the setting is the
    // built-in default.
    expect(container.read(ledgerCurrencyProvider), 'USD');

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

    // The account does not move the ledger's currency: the setting is the
    // scope, and USD has no accounts in it, so the header is zero rather
    // than the other currency's money relabelled.
    expect(container.read(ledgerCurrencyProvider), 'USD');
    final summary = container.read(ledgerMonthlySummaryProvider(month)).value;
    expect(summary?.displayBalance, r'$0.00',
        reason: 'USD is the setting; the CNY account is out of its scope');
  });

  test('a late old-currency emission does not overwrite the new result',
      () async {
    final service = _FakeLedgerService();
    final currency = _MutableCurrency('USD');
    final container = ProviderContainer(overrides: [
      currencyControllerProvider.overrideWith(() => currency),
      ledgerServiceProvider.overrideWithValue(service),
    ]);
    addTearDown(container.dispose);

    final month = DateTime(2026, 1);
    container.listen(ledgerMonthlySummaryProvider(month), (_, __) {});

    await container.read(currencyControllerProvider.future);
    expect(container.read(ledgerCurrencyProvider), 'USD');

    service.emit(
      'USD',
      const MonthlySnapshotTotals(
        currencyCode: 'USD',
        incomeMinor: 0,
        expenseMinor: 0,
        balanceMinor: 10000,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(container.read(ledgerMonthlySummaryProvider(month)).value
        ?.displayBalance, r'$100.00');

    // Switch: the provider re-subscribes to the new currency's stream.
    await currency.setCurrency('JPY');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(container.read(ledgerCurrencyProvider), 'JPY');

    service.emit(
      'JPY',
      const MonthlySnapshotTotals(
        currencyCode: 'JPY',
        incomeMinor: 0,
        expenseMinor: 0,
        balanceMinor: 20000,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(container.read(ledgerMonthlySummaryProvider(month)).value
        ?.displayBalance, '¥200.00');

    // The old currency's stream emits late; the subscription that would have
    // received it was cancelled on switch, so it must be discarded.
    service.emit(
      'USD',
      const MonthlySnapshotTotals(
        currencyCode: 'USD',
        incomeMinor: 0,
        expenseMinor: 0,
        balanceMinor: 99999,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(
      container.read(ledgerMonthlySummaryProvider(month)).value
          ?.displayBalance,
      '¥200.00',
      reason: 'a late emission from the previous subscription is dropped',
    );
  });
}

/// A service whose snapshot stream is test-controlled per currency, so a test
/// can hand back an old currency's result after the switch has happened.
class _FakeLedgerService implements LedgerService {
  final _snapshot = <String, StreamController<MonthlySnapshotTotals>>{};

  @override
  Stream<MonthlySnapshotTotals> watchMonthlySnapshot(
    DateTime month, {
    required String currencyCode,
  }) {
    return _snapshot
        .putIfAbsent(
            currencyCode, () => StreamController<MonthlySnapshotTotals>.broadcast())
        .stream;
  }

  void emit(String currencyCode, MonthlySnapshotTotals totals) {
    _snapshot[currencyCode]!.add(totals);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _MutableCurrency extends CurrencyController {
  _MutableCurrency(this.code);

  String code;

  @override
  Future<String> build() async => code;

  @override
  Future<void> setCurrency(String currencyCode) async {
    code = currencyCode;
    state = AsyncData(currencyCode);
  }
}
