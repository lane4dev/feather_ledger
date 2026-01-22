import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/settings_repository.dart';

part 'settings_providers.g.dart';

@riverpod
class ThemeModeController extends _$ThemeModeController {
  @override
  Future<ThemeMode> build() async {
    final repo = await ref.watch(settingsRepositoryProvider.future);
    return repo.getThemeMode();
  }

  Future<void> setTheme(ThemeMode mode) async {
    final repo = await ref.read(settingsRepositoryProvider.future);
    await repo.setThemeMode(mode);
    state = AsyncData(mode);
  }
}

@riverpod
class LocaleController extends _$LocaleController {
  @override
  Future<Locale?> build() async {
    final repo = await ref.watch(settingsRepositoryProvider.future);
    return repo.getLocale();
  }

  Future<void> setLocale(Locale? locale) async {
    final repo = await ref.read(settingsRepositoryProvider.future);
    await repo.setLocale(locale);
    state = AsyncData(locale);
  }
}

@riverpod
class CurrencyController extends _$CurrencyController {
  @override
  Future<String> build() async {
    final repo = await ref.watch(settingsRepositoryProvider.future);
    return repo.getCurrency();
  }

  Future<void> setCurrency(String symbol) async {
    final repo = await ref.read(settingsRepositoryProvider.future);
    await repo.setCurrency(symbol);
    state = AsyncData(symbol);
  }
}