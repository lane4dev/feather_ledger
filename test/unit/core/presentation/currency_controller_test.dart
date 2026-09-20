import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/mocks/mock_shared_preferences.dart';

void main() {
  group('first-use language to currency mapping', () {
    Currency? currencyFor(String languageCode, [String? countryCode]) =>
        AppCurrencies.getCurrencyByLocale(
          countryCode == null
              ? Locale(languageCode)
              : Locale(languageCode, countryCode),
        );

    test('maps Chinese to CNY', () {
      expect(currencyFor('zh', 'CN')?.code, 'CNY');
      expect(currencyFor('zh', 'TW')?.code, 'CNY');
    });

    test('maps Japanese to JPY', () {
      expect(currencyFor('ja')?.code, 'JPY');
    });

    test('maps English to USD regardless of region', () {
      expect(currencyFor('en')?.code, 'USD');
      expect(currencyFor('en', 'US')?.code, 'USD');
      expect(currencyFor('en', 'GB')?.code, 'USD',
          reason: 'en-GB first-use is USD, not GBP');
    });

    test('maps German to EUR', () {
      expect(currencyFor('de')?.code, 'EUR');
    });

    test('maps French to EUR', () {
      expect(currencyFor('fr')?.code, 'EUR');
    });

    test('falls back to null for languages with no mapping', () {
      expect(currencyFor('es'), isNull);
      expect(currencyFor('ko'), isNull);
    });
  });

  testWidgets('a British English device starts in USD on first use',
      (tester) async {
    tester.binding.platformDispatcher.localeTestValue =
        const Locale('en', 'GB');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    final preferences = PreferencesRepositoryImpl(MockSharedPreferences());

    final container = ProviderContainer(overrides: [
      preferencesRepositoryProvider
          .overrideWith((ref) async => preferences),
    ]);
    addTearDown(container.dispose);
    container.listen(currencyControllerProvider, (_, __) {});

    expect(await container.read(currencyControllerProvider.future), 'USD');
    expect(preferences.getCurrency(), 'USD');
  });

  testWidgets('a selected dollar currency survives restart on a Chinese device',
      (tester) async {
    tester.binding.platformDispatcher.localeTestValue =
        const Locale('zh', 'CN');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    final preferences = PreferencesRepositoryImpl(MockSharedPreferences());

    ProviderContainer createContainer() => ProviderContainer(overrides: [
          preferencesRepositoryProvider
              .overrideWith((ref) async => preferences),
        ]);

    final first = createContainer();
    final subscription = first.listen(currencyControllerProvider, (_, __) {});
    expect(await first.read(currencyControllerProvider.future), 'CNY');
    await first.read(currencyControllerProvider.notifier).setCurrency('USD');
    expect(first.read(currencyControllerProvider).value, 'USD');
    subscription.close();
    first.dispose();

    final restarted = createContainer();
    addTearDown(restarted.dispose);
    final restartedSubscription =
        restarted.listen(currencyControllerProvider, (_, __) {});
    addTearDown(restartedSubscription.close);
    expect(await restarted.read(currencyControllerProvider.future), 'USD');
    expect(preferences.getCurrency(), 'USD');
  });

  testWidgets('switching currency anchors the active-since boundary',
      (tester) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('en');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    final preferences = PreferencesRepositoryImpl(MockSharedPreferences());

    final container = ProviderContainer(overrides: [
      preferencesRepositoryProvider.overrideWith((ref) async => preferences),
    ]);
    addTearDown(container.dispose);
    container.listen(currencyControllerProvider, (_, __) {});

    expect(await container.read(currencyControllerProvider.future), 'USD');
    expect(preferences.getCurrencyActiveSince('USD'), isNotNull,
        reason: 'first use anchors the boundary so a bill that fell due '
            'before this currency ever existed is permanently manual');

    await container.read(currencyControllerProvider.notifier).setCurrency('JPY');
    expect(preferences.getCurrencyActiveSince('JPY'), isNotNull,
        reason: 'switching to a currency opens its eligibility window');
  });
}
