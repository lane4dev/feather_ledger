import 'package:flutter/material.dart';

abstract class PreferencesRepository {
  ThemeMode getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);
  Locale? getLocale();
  Future<void> setLocale(Locale? locale);
  String getCurrency();
  Future<void> setCurrency(String symbol);
}
