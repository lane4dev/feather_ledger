import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/mocks/mock_shared_preferences.dart';

void main() {
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
}
