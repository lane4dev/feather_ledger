import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/app/config/app_languages.dart';
import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/enums.dart';

import '../../../../support/mocks/mock_shared_preferences.dart';

/// Preference export/import for the backup archive (spec 004, US4 / T022).
///
/// The properties that matter: the export carries *this app's* known keys and
/// nothing else, and the import tolerates an archive it does not fully
/// understand — a backup from a future version must not fail to load.
void main() {
  late MockSharedPreferences mockPrefs;
  late PreferencesRepository repository;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    repository = PreferencesRepositoryImpl(mockPrefs);
  });

  tearDown(() => mockPrefs.reset());

  test('exports exactly the known keys that are set', () async {
    await repository.setThemeMode(ThemeMode.dark);
    await repository.setLocale(AppLanguages.zhHant);
    await repository.setCurrency('CNY');
    await repository.setShowBalance(false);

    expect(repository.exportAll(), {
      'app_theme_mode': 'dark',
      'app_locale': 'zh-Hant',
      'currency_code': 'CNY',
      'show_balance': false,
    });
  });

  test('omits keys that were never set', () {
    expect(repository.exportAll(), isEmpty);

    mockPrefs.setMockString('app_theme_mode', 'light');
    expect(repository.exportAll(), {'app_theme_mode': 'light'});
  });

  test('ignores keys written by other packages', () {
    mockPrefs.setMockString('app_theme_mode', 'light');
    mockPrefs.setMockString('some_other_packages_key', 'noise');

    final exported = repository.exportAll();

    expect(exported.keys, ['app_theme_mode'],
        reason: 'a backup is this app\'s settings, not a dump of the store');
  });

  test('round-trips through a fresh repository', () async {
    await repository.setThemeMode(ThemeMode.dark);
    await repository.setLocale(AppLanguages.zhHant);
    await repository.setCurrency('EUR');
    await repository.setShowBalance(false);

    final exported = repository.exportAll();

    final restoredStore = MockSharedPreferences();
    final restored = PreferencesRepositoryImpl(restoredStore);
    await restored.importAll(exported);

    expect(restored.getThemeMode(), ThemeMode.dark);
    // The script subtag must survive: collapsing 繁體 back to 简体 is the
    // regression the locale tag exists to prevent.
    expect(restored.getLocale(), AppLanguages.zhHant);
    expect(restored.getCurrency(), 'EUR');
    expect(restored.getShowBalance(), isFalse);
  });

  test('import ignores unknown keys from a newer backup', () async {
    await repository.importAll({
      'app_theme_mode': 'light',
      'a_key_from_the_future': 'whatever',
    });

    expect(repository.getThemeMode(), ThemeMode.light);
    expect(mockPrefs.containsKey('a_key_from_the_future'), isFalse,
        reason: 'unknown keys must not be written into this app\'s store');
  });

  test('import skips null and wrong-typed entries instead of throwing',
      () async {
    await repository.importAll({
      'app_theme_mode': 'light',
      'currency_code': null,
      'show_balance': 42,
    });

    expect(repository.getThemeMode(), ThemeMode.light);
    expect(repository.getCurrency(), isNull,
        reason: 'no preference was stored');
    expect(repository.getShowBalance(), isTrue, reason: 'fell back to default');
  });

  test('auto-post switches default off and persist per mode', () async {
    expect(repository.getAutoPostEnabled(RecurringSeriesMode.planned), isFalse);
    expect(
        repository.getAutoPostEnabled(RecurringSeriesMode.subscription), isFalse);
    expect(
        repository.getAutoPostEnabled(RecurringSeriesMode.repeating), isFalse);

    await repository.setAutoPostEnabled(RecurringSeriesMode.planned, true);
    await repository.setAutoPostEnabled(RecurringSeriesMode.repeating, true);

    expect(repository.getAutoPostEnabled(RecurringSeriesMode.planned), isTrue);
    expect(
        repository.getAutoPostEnabled(RecurringSeriesMode.subscription), isFalse,
        reason: 'each switch is configured separately');
    expect(
        repository.getAutoPostEnabled(RecurringSeriesMode.repeating), isTrue);
  });

  test('auto-post switches are not carried by the backup', () async {
    // Source device: every switch on.
    await repository.setAutoPostEnabled(RecurringSeriesMode.planned, true);
    await repository.setAutoPostEnabled(RecurringSeriesMode.subscription, true);
    await repository.setAutoPostEnabled(RecurringSeriesMode.repeating, true);

    final exported = repository.exportAll();
    expect(exported.keys, isNot(contains('autopost_planned')));
    expect(exported.keys, isNot(contains('autopost_subscription')));
    expect(exported.keys, isNot(contains('autopost_repeating')));

    // Target device has its own, different switches: restore keeps them.
    final targetStore = MockSharedPreferences();
    final target = PreferencesRepositoryImpl(targetStore);
    await target.setAutoPostEnabled(RecurringSeriesMode.subscription, true);
    await target.importAll(exported);

    expect(target.getAutoPostEnabled(RecurringSeriesMode.planned), isFalse,
        reason: 'the target device keeps its own switch');
    expect(target.getAutoPostEnabled(RecurringSeriesMode.subscription), isTrue,
        reason: 'restore must not overwrite a local-only switch');
    expect(target.getAutoPostEnabled(RecurringSeriesMode.repeating), isFalse);
  });
}
