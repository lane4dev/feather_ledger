import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/preferences_repository.dart';

part 'theme_provider.g.dart';

@riverpod
class ThemeModeController extends _$ThemeModeController {
  @override
  Future<ThemeMode> build() async {
    final repo = await ref.watch(preferencesRepositoryProvider.future);
    return repo.getThemeMode();
  }

  Future<void> setTheme(ThemeMode mode) async {
    final repo = await ref.read(preferencesRepositoryProvider.future);
    await repo.setThemeMode(mode);
    state = AsyncData(mode);
  }
}
