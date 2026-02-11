import 'package:flutter/material.dart';

abstract class PreferencesRepository {
  /// Gets the current theme mode.
  ThemeMode getThemeMode();

  /// Sets the theme mode.
  Future<void> setThemeMode(ThemeMode mode);

  /// Gets the current locale.
  Locale? getLocale();

  /// Sets the current locale.
  Future<void> setLocale(Locale? locale);

  /// Gets the current currency symbol.
  String getCurrency();

  /// Sets the current currency symbol.
  Future<void> setCurrency(String symbol);

  /// Gets whether to show the total balance.
  bool getShowBalance();

  /// Sets whether to show the total balance.
  Future<void> setShowBalance(bool show);
}
