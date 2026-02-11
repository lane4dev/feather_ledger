import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/preferences_repository.dart';

part 'locale_provider.g.dart';

@riverpod
class LocaleController extends _$LocaleController {
  @override
  Future<Locale?> build() async {
    final repo = await ref.watch(preferencesRepositoryProvider.future);
    return repo.getLocale();
  }

  Future<void> setLocale(Locale? locale) async {
    final repo = await ref.read(preferencesRepositoryProvider.future);
    await repo.setLocale(locale);
    state = AsyncData(locale);
  }
}
