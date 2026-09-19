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

  /// Maps a device language to the currency a first-use install should start
  /// with. The mapping is by *language code* only, never by region: an
  /// `en-GB` device still starts in USD (not GBP), and French shares the euro
  /// with German. Languages without an entry fall back to the default currency.
  static const Map<String, String> _languageToCurrencyCode = {
    'zh': 'CNY',
    'ja': 'JPY',
    'en': 'USD',
    'de': 'EUR',
    'fr': 'EUR',
  };

  /// Returns the currency for a device locale, or null for unmapped languages
  /// (callers fall back to [defaultCurrency]).
  static Currency? getCurrencyByLocale(Locale locale) {
    final code = _languageToCurrencyCode[locale.languageCode];
    return code == null ? null : getCurrencyByCode(code);
  }
}
