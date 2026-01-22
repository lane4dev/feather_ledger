import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class AppLanguages {
  static const en = Locale('en');
  static const zh = Locale('zh');

  /// List of all supported locales in the app.
  /// Update this list when adding new languages.
  static const List<Locale> supportedLocales = [
    en,
    zh,
  ];

  /// Returns the display name of the locale.
  static String getName(Locale locale, AppLocalizations l10n) {
    switch (locale.languageCode) {
      case 'zh':
        return l10n.chinese;
      case 'en':
      default:
        return l10n.english;
    }
  }
}
