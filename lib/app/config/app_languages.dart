import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class AppLanguages {
  static const en = Locale('en');
  static const zhHans = Locale.fromSubtags(
      languageCode: 'zh', scriptCode: 'Hans'); // 'zh_Hans' 简体
  static const zhHant = Locale.fromSubtags(
      languageCode: 'zh', scriptCode: 'Hant'); // 'zh_Hant' 繁体

  /// List of all supported locales in the app.
  /// Update this list when adding new languages.
  static const List<Locale> supportedLocales = [
    en,
    zhHans,
    zhHant,
  ];

  /// Returns the display name of the locale.
  static String getName(Locale locale, AppLocalizations l10n) {
    if (locale.languageCode == 'zh') {
      switch (locale.scriptCode) {
        case 'Hans':
          return l10n.simplifiedChinese;
        case 'Hant':
          return l10n.traditionalChinese;
        default:
          return l10n.chinese;
      }
    } else if (locale.languageCode == 'en') {
      return l10n.english;
    }
    return l10n.english; // Default fallback
  }
}
