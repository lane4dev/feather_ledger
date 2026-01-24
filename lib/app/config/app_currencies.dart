import 'dart:ui';

import 'package:feather_ledger/app/l10n/app_localizations.dart';

// Defines the Currency class for encapsulating currency information.
class Currency {
  final String code; // Unique currency code, e.g. 'USD', 'CNY'
  final String symbol; // Display symbol, e.g. '$', '¥'
  final Locale? locale; // Optional locale for currency-specific localization
  final String Function(AppLocalizations l10n)
      getName; // Returns the localized display name

  const Currency({
    required this.code,
    required this.symbol,
    required this.locale,
    required this.getName,
  });
}

class AppCurrencies {
  // List of all supported currencies.
  static final List<Currency> _allCurrencies = [
    Currency(
      code: 'USD',
      symbol: '\$',
      locale: const Locale('en', 'US'),
      getName: (l10n) => l10n.dollarCurrency,
    ),
    Currency(
      code: 'CNY',
      symbol: '¥',
      locale: const Locale('zh', 'CN'),
      getName: (l10n) => l10n.yuanCurrency,
    ),
    Currency(
      code: 'JPY',
      symbol: '¥',
      locale: const Locale('ja', 'JP'),
      getName: (l10n) => l10n.yenCurrency,
    ),
    Currency(
      code: 'EUR',
      symbol: '€',
      locale: const Locale('de', 'DE'),
      getName: (l10n) => l10n.euroCurrency,
    ),
    Currency(
      code: 'GBP',
      symbol: '£',
      locale: const Locale('en', 'GB'),
      getName: (l10n) => l10n.poundCurrency,
    ),
  ];

  /// Returns a list of all supported currency codes.
  static List<String> get supportedCurrencyCodes =>
      _allCurrencies.map((c) => c.code).toList();

  /// Returns the default currency (currently 'USD').
  static Currency get defaultCurrency => _allCurrencies.first;

  /// Returns a [Currency] by currency code.
  static Currency? getCurrencyByCode(String code) {
    for (var currency in _allCurrencies) {
      if (currency.code == code) {
        return currency;
      }
    }
    return null;
  }

  /// Returns the display symbol for the given currency code.
  static String getSymbol(String code) {
    return getCurrencyByCode(code)?.symbol ??
        code; // Fall back to the code if not found.
  }

  /// Returns the localized display name for the given currency code.
  static String getName(String code, AppLocalizations l10n) {
    return getCurrencyByCode(code)?.getName(l10n) ??
        code; // Fall back to the code if not found.
  }

  /// return currency based on locale
  static Currency? getCurrencyByLocale(Locale locale) {
    // Try exact match first (e.g., "zh_CN")
    for (var currency in _allCurrencies) {
      if (currency.locale == locale) {
        return currency;
      }
    }

    // If no exact match, try matching by language code (e.g., "zh")
    final languageCode = locale.languageCode;
    for (var currency in _allCurrencies) {
      if (currency.locale != null &&
          currency.locale!.languageCode == languageCode) {
        return currency;
      }
    }

    return null;
  }
}
