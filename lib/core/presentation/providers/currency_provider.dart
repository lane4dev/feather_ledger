import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';

import '../../data/repositories/preferences_repository.dart';

part 'currency_provider.g.dart';

@riverpod
class CurrencyController extends _$CurrencyController {
  @override
  Future<String> build() async {
    final repo = await ref.watch(preferencesRepositoryProvider.future);
    String? storedCurrency = repo.getCurrency();

    if (storedCurrency != AppCurrencies.defaultCurrency.code) {
      return storedCurrency;
    }

    // If no currency is stored or it's the default '$', try to determine it from the system locale
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;

    final localeCurrency = AppCurrencies.getCurrencyByLocale(systemLocale);

    String currencyCodeToSet;
    if (localeCurrency != null) {
      currencyCodeToSet = localeCurrency.code;
    } else {
      currencyCodeToSet = AppCurrencies.defaultCurrency
          .code; // Fallback to default currency if no match found
    }

    await repo.setCurrency(currencyCodeToSet);
    return currencyCodeToSet;
  }

  Future<void> setCurrency(String currencyCode) async {
    final repo = await ref.read(preferencesRepositoryProvider.future);
    await repo.setCurrency(currencyCode);
    state = AsyncData(currencyCode);
  }
}
