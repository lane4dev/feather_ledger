import 'package:feather_ledger/app/config/app_currencies.dart';
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
  String getCurrency() {
    return _prefs.getString(_keyCurrency) ?? AppCurrencies.defaultCurrency.code;
  }

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
}

@riverpod
Future<PreferencesRepository> preferencesRepository(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return PreferencesRepositoryImpl(prefs);
}
