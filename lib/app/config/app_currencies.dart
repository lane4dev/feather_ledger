import 'package:feather_ledger/app/l10n/app_localizations.dart';

class AppCurrencies {
  static const dollar = '\$';
  static const yuan = 'CNY'; // Using internal keys to distinguish same symbols
  static const yen = 'JPY';
  static const euro = '€';
  static const pound = '£';

  /// List of all supported currency internal keys in the app.
  static const List<String> supportedCurrencies = [
    dollar,
    yuan,
    yen,
    euro,
    pound,
  ];

  /// Returns the symbol to display.
  static String getSymbol(String key) {
    switch (key) {
      case yuan:
      case yen:
        return '¥';
      default:
        return key;
    }
  }

  /// Returns the display name of the currency.
  static String getName(String key, AppLocalizations l10n) {
    switch (key) {
      case dollar:
        return l10n.dollarCurrency;
      case yuan:
        return l10n.yuanCurrency;
      case yen:
        return l10n.yenCurrency;
      case euro:
        return l10n.euroCurrency;
      case pound:
        return l10n.poundCurrency;
      default:
        return key;
    }
  }
}