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
    final storedCurrency = repo.getCurrency();

    if (storedCurrency != null) {
      return storedCurrency;
    }

    // Choose from the system locale only on first use. USD is a valid user
    // choice and must not be mistaken for an unset preference on restart.
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
