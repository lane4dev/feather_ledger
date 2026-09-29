import 'package:feather_ledger/app/config/app_languages.dart';
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

  // Local-only: remembers the user's last choice on the planned & repeating
  // forms' auto-post toggles independently; deliberately absent from
  // [_knownKeys] so backup never overwrites the target device's local preference.
  static const _keyLastPlannedAutoPost = 'last_planned_auto_post';
  static const _keyLastRepeatingAutoPost = 'last_repeating_auto_post';
  static const _keyLastTransactionAccount = 'last_transaction_account';

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
  bool getLastPlannedAutoPost() {
    return _prefs.getBool(_keyLastPlannedAutoPost) ?? false;
  }

  @override
  Future<void> setLastPlannedAutoPost(bool enabled) {
    return _prefs.setBool(_keyLastPlannedAutoPost, enabled);
  }

  @override
  bool getLastRepeatingAutoPost() {
    return _prefs.getBool(_keyLastRepeatingAutoPost) ?? false;
  }

  @override
  Future<void> setLastRepeatingAutoPost(bool enabled) {
    return _prefs.setBool(_keyLastRepeatingAutoPost, enabled);
  }

  @override
  String? getLastTransactionAccount() =>
      _prefs.getString(_keyLastTransactionAccount);

  @override
  Future<void> setLastTransactionAccount(String id) =>
      _prefs.setString(_keyLastTransactionAccount, id);

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
