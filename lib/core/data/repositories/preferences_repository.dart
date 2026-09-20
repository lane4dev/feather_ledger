import 'package:feather_ledger/app/config/app_languages.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/preferences_repository.dart';

export '../../domain/repositories/preferences_repository.dart';

part 'preferences_repository.g.dart';

class PreferencesRepositoryImpl implements PreferencesRepository {
  final SharedPreferences _prefs;

  PreferencesRepositoryImpl(this._prefs);

  static const _keyTheme = 'app_theme_mode';
  static const _keyLocale = 'app_locale';
  static const _keyCurrency = 'currency_code';
  static const _keyShowBalance = 'show_balance';

  // Local-only: the three auto-post switches are deliberately absent from
  // [_knownKeys], so the backup neither carries them nor overwrites the
  // target device's own choice (spec 006, US30).
  static const _keyAutoPostPlanned = 'autopost_planned';
  static const _keyAutoPostSubscription = 'autopost_subscription';
  static const _keyAutoPostRepeating = 'autopost_repeating';

  // Local-only eligibility boundaries (spec 006, US31): never in [_knownKeys].
  static const _keyAutoPostPlannedSince = 'autopost_planned_since';
  static const _keyAutoPostSubscriptionSince = 'autopost_subscription_since';
  static const _keyAutoPostRepeatingSince = 'autopost_repeating_since';
  static const _keyCurrencyActiveSincePrefix = 'currency_active_since_';

  // Local-only wall-clock anchor for clock-rollback detection (spec 006,
  // US32): never in [_knownKeys].
  static const _keyLastSeenWallClock = 'last_seen_wall_clock';

  @override
  ThemeMode getThemeMode() {
    final val = _prefs.getString(_keyTheme);
    if (val == 'light') return ThemeMode.light;
    if (val == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) {
    var val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    return _prefs.setString(_keyTheme, val);
  }

  @override
  Locale? getLocale() {
    final tag = _prefs.getString(_keyLocale);
    if (tag == null) return null;
    // Pre-tag installs stored a bare language code, where `zh` meant 简体.
    if (tag == 'zh') return AppLanguages.zhHans;
    // Unsupported tags fall through to the system locale rather than a
    // Locale the app cannot translate.
    return AppLanguages.supportedLocales
        .where((locale) => locale.toLanguageTag() == tag)
        .firstOrNull;
  }

  @override
  Future<void> setLocale(Locale? locale) {
    if (locale == null) {
      return _prefs.remove(_keyLocale);
    }
    // The script subtag distinguishes 简体 from 繁体 — languageCode alone
    // collapses both into `zh`.
    return _prefs.setString(_keyLocale, locale.toLanguageTag());
  }

  @override
  String? getCurrency() => _prefs.getString(_keyCurrency);

  @override
  Future<void> setCurrency(String code) {
    return _prefs.setString(_keyCurrency, code);
  }

  @override
  bool getShowBalance() {
    return _prefs.getBool(_keyShowBalance) ?? true;
  }

  @override
  Future<void> setShowBalance(bool show) {
    return _prefs.setBool(_keyShowBalance, show);
  }

  @override
  bool getAutoPostEnabled(RecurringSeriesMode mode) {
    return _prefs.getBool(_keyForMode(mode)) ?? false;
  }

  @override
  Future<void> setAutoPostEnabled(RecurringSeriesMode mode, bool enabled) async {
    await _prefs.setBool(_keyForMode(mode), enabled);
    // Turning the switch on is the eligibility boundary (spec 006, US31):
    // anything that fell due at or before this moment is already manual.
    // Turning it off leaves the boundary alone, so the next re-enable records
    // a fresh one.
    if (enabled) {
      await setAutoPostEnabledSince(mode, DateTime.now());
    }
  }

  String _keyForMode(RecurringSeriesMode mode) => switch (mode) {
        RecurringSeriesMode.planned => _keyAutoPostPlanned,
        RecurringSeriesMode.subscription => _keyAutoPostSubscription,
        RecurringSeriesMode.repeating => _keyAutoPostRepeating,
      };

  String _keyForModeSince(RecurringSeriesMode mode) => switch (mode) {
        RecurringSeriesMode.planned => _keyAutoPostPlannedSince,
        RecurringSeriesMode.subscription => _keyAutoPostSubscriptionSince,
        RecurringSeriesMode.repeating => _keyAutoPostRepeatingSince,
      };

  @override
  DateTime? getAutoPostEnabledSince(RecurringSeriesMode mode) {
    final millis = _prefs.getInt(_keyForModeSince(mode));
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  @override
  Future<void> setAutoPostEnabledSince(
      RecurringSeriesMode mode, DateTime moment) {
    return _prefs.setInt(
        _keyForModeSince(mode), moment.millisecondsSinceEpoch);
  }

  @override
  DateTime? getCurrencyActiveSince(String currencyCode) {
    final millis = _prefs.getInt('$_keyCurrencyActiveSincePrefix$currencyCode');
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  @override
  Future<void> setCurrencyActiveSince(
      String currencyCode, DateTime moment) {
    return _prefs.setInt('$_keyCurrencyActiveSincePrefix$currencyCode',
        moment.millisecondsSinceEpoch);
  }

  @override
  DateTime? getLastSeenWallClock() {
    final millis = _prefs.getInt(_keyLastSeenWallClock);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  @override
  Future<void> setLastSeenWallClock(DateTime moment) {
    return _prefs.setInt(_keyLastSeenWallClock, moment.millisecondsSinceEpoch);
  }

  /// The four known keys, in a stable order. Values are stored in their raw
  /// SharedPreferences form (String/Bool), so a backup round-trips without
  /// the archive having to know how each is parsed.
  @override
  Map<String, Object?> exportAll() => {
        for (final key in _knownKeys)
          if (_prefs.containsKey(key)) key: _prefs.get(key),
      };

  @override
  Future<void> importAll(Map<String, Object?> values) async {
    for (final key in _knownKeys) {
      if (!values.containsKey(key)) continue;
      final value = values[key];
      // A null (or wrong-typed) entry from a hand-edited archive is skipped
      // rather than throwing: a partly-restorable backup beats none.
      if (value is String) {
        await _prefs.setString(key, value);
      } else if (value is bool) {
        await _prefs.setBool(key, value);
      }
    }
  }

  static const _knownKeys = [
    _keyTheme,
    _keyLocale,
    _keyCurrency,
    _keyShowBalance,
  ];
}

@riverpod
Future<PreferencesRepository> preferencesRepository(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return PreferencesRepositoryImpl(prefs);
}
