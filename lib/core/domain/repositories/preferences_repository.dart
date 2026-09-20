import 'package:flutter/material.dart';

import 'package:feather_ledger/core/domain/enums.dart';

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

  /// Gets whether bills of [mode] post themselves at launch (spec 006, US30).
  /// Local-only: default false, never carried by the backup.
  bool getAutoPostEnabled(RecurringSeriesMode mode);

  /// Sets whether bills of [mode] post themselves at launch.
  Future<void> setAutoPostEnabled(RecurringSeriesMode mode, bool enabled);

  /// The last time the auto-post switch for [mode] was turned ON, or null if
  /// it has never been enabled. A bill that fell due at or before this moment
  /// is permanently manual (spec 006, US31) — re-enabling never retro-posts.
  /// Local-only: never carried by the backup.
  DateTime? getAutoPostEnabledSince(RecurringSeriesMode mode);

  /// Records the moment the auto-post switch for [mode] was turned on.
  Future<void> setAutoPostEnabledSince(
      RecurringSeriesMode mode, DateTime moment);

  /// The last time [currencyCode] became the current currency, or null if it
  /// has never been current. A bill in that currency that fell due at or
  /// before this moment is permanently manual (spec 006, US31).
  /// Local-only: never carried by the backup.
  DateTime? getCurrencyActiveSince(String currencyCode);

  /// Records the moment [currencyCode] became the current currency.
  Future<void> setCurrencyActiveSince(String currencyCode, DateTime moment);

  /// The last wall-clock moment an eligibility decision observed, or null if
  /// none has run yet. A later decision whose clock reads *earlier* than this
  /// is evidence of a clock rollback, which makes due/not-due ordering
  /// unreliable (spec 006, US32). Local-only: never carried by the backup.
  DateTime? getLastSeenWallClock();

  /// Records the latest wall-clock moment an eligibility decision observed.
  Future<void> setLastSeenWallClock(DateTime moment);

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
