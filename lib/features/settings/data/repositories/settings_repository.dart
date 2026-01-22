import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/settings_repository.dart';

export '../../domain/repositories/settings_repository.dart';

part 'settings_repository.g.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepositoryImpl(this._prefs);

  static const _keyTheme = 'app_theme_mode';
  static const _keyLocale = 'app_locale';
  static const _keyCurrency = 'currency_symbol';

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
    final val = _prefs.getString(_keyLocale);
    if (val == 'zh') return const Locale('zh');
    if (val == 'en') return const Locale('en');
    return null;
  }

  @override
  Future<void> setLocale(Locale? locale) {
    if (locale == null) {
      return _prefs.remove(_keyLocale);
    }
    return _prefs.setString(_keyLocale, locale.languageCode);
  }

  @override
  String getCurrency() {
    return _prefs.getString(_keyCurrency) ?? '\$';
  }

  @override
  Future<void> setCurrency(String symbol) {
    return _prefs.setString(_keyCurrency, symbol);
  }
}

@riverpod
Future<SettingsRepository> settingsRepository(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return SettingsRepositoryImpl(prefs);
}
