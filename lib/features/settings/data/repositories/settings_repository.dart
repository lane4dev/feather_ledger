import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_repository.g.dart';

class SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  static const _keyTheme = 'app_theme_mode';
  static const _keyLocale = 'app_locale';
  static const _keyCurrency = 'currency_symbol';

  ThemeMode getThemeMode() {
    final val = _prefs.getString(_keyTheme);
    if (val == 'light') return ThemeMode.light;
    if (val == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) {
    String val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    return _prefs.setString(_keyTheme, val);
  }

  Locale getLocale() {
    final val = _prefs.getString(_keyLocale);
    if (val == 'zh') return const Locale('zh');
    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) {
    return _prefs.setString(_keyLocale, locale.languageCode);
  }

  String getCurrency() {
    return _prefs.getString(_keyCurrency) ?? '\$';
  }

  Future<void> setCurrency(String symbol) {
    return _prefs.setString(_keyCurrency, symbol);
  }
}

@riverpod
Future<SettingsRepository> settingsRepository(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return SettingsRepository(prefs);
}
