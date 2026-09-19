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

  /// Gets the selected currency code, or null before one has been selected.
  String? getCurrency();

  /// Sets the selected currency code.
  Future<void> setCurrency(String code);

  /// Gets whether to show the total balance.
  bool getShowBalance();

  /// Sets whether to show the total balance.
  Future<void> setShowBalance(bool show);

  /// The known preference keys and their stored values, for the backup
  /// archive (spec 004, US4).
  ///
  /// Deliberately enumerates the known keys rather than whatever
  /// SharedPreferences happens to hold: a backup should carry this app's
  /// settings, not a snapshot of every key any package ever wrote.
  Map<String, Object?> exportAll();

  /// Re-applies previously exported preferences. Unknown keys are ignored so
  /// a backup from a future version stays loadable.
  Future<void> importAll(Map<String, Object?> values);
}
