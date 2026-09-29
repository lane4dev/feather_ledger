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

  /// Whether the user's last created one-shot planned bill enabled auto-post.
  /// Local-only: default false, never carried by the backup.
  bool getLastPlannedAutoPost();

  /// Persists the user's last choice for the planned auto-post switch.
  Future<void> setLastPlannedAutoPost(bool enabled);

  /// Whether the user's last created repeating rule enabled auto-post.
  /// Local-only: default false, never carried by the backup.
  bool getLastRepeatingAutoPost();

  /// Persists the user's last choice for the repeating auto-post switch.
  Future<void> setLastRepeatingAutoPost(bool enabled);

  /// The last account explicitly chosen on a transaction form, local to this device.
  String? getLastTransactionAccount();

  Future<void> setLastTransactionAccount(String id);

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
