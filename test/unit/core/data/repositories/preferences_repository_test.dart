import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';

import '../../../../support/mocks/mock_shared_preferences.dart';

void main() {
  late MockSharedPreferences mockPrefs;
  late PreferencesRepository repository;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    repository = PreferencesRepositoryImpl(mockPrefs);
  });

  tearDown(() {
    mockPrefs.reset();
  });

  group('PreferencesRepository', () {
    group('instantiation', () {
      test('should create instance with shared preferences', () {
        expect(repository, isNotNull);
        expect(repository, isA<PreferencesRepository>());
      });
    });

    group('getThemeMode', () {
      test('should return ThemeMode.light when stored value is "light"', () {
        // Arrange
        mockPrefs.setMockString('app_theme_mode', 'light');

        // Act
        final result = repository.getThemeMode();

        // Assert
        expect(result, ThemeMode.light);
      });

      test('should return ThemeMode.dark when stored value is "dark"', () {
        // Arrange
        mockPrefs.setMockString('app_theme_mode', 'dark');

        // Act
        final result = repository.getThemeMode();

        // Assert
        expect(result, ThemeMode.dark);
      });

      test('should return ThemeMode.system when stored value is "system"', () {
        // Arrange
        mockPrefs.setMockString('app_theme_mode', 'system');

        // Act
        final result = repository.getThemeMode();

        // Assert
        expect(result, ThemeMode.system);
      });

      test('should return ThemeMode.system when no value is stored', () {
        // Arrange - no value set

        // Act
        final result = repository.getThemeMode();

        // Assert
        expect(result, ThemeMode.system);
      });

      test('should return ThemeMode.system for invalid stored value', () {
        // Arrange
        mockPrefs.setMockString('app_theme_mode', 'invalid');

        // Act
        final result = repository.getThemeMode();

        // Assert
        expect(result, ThemeMode.system);
      });
    });

    group('setThemeMode', () {
      test('should store "light" for ThemeMode.light', () async {
        // Arrange & Act
        await repository.setThemeMode(ThemeMode.light);

        // Assert
        expect(mockPrefs.getString('app_theme_mode'), 'light');
      });

      test('should store "dark" for ThemeMode.dark', () async {
        // Arrange & Act
        await repository.setThemeMode(ThemeMode.dark);

        // Assert
        expect(mockPrefs.getString('app_theme_mode'), 'dark');
      });

      test('should store "system" for ThemeMode.system', () async {
        // Arrange & Act
        await repository.setThemeMode(ThemeMode.system);

        // Assert
        expect(mockPrefs.getString('app_theme_mode'), 'system');
      });

      test('should overwrite previous theme mode', () async {
        // Arrange
        await repository.setThemeMode(ThemeMode.light);

        // Act
        await repository.setThemeMode(ThemeMode.dark);

        // Assert
        expect(mockPrefs.getString('app_theme_mode'), 'dark');
      });
    });

    group('getLocale', () {
      test('should return Locale("zh") when stored value is "zh"', () {
        // Arrange
        mockPrefs.setMockString('app_locale', 'zh');

        // Act
        final result = repository.getLocale();

        // Assert
        expect(result, const Locale('zh'));
        expect(result?.languageCode, 'zh');
      });

      test('should return Locale("en") when stored value is "en"', () {
        // Arrange
        mockPrefs.setMockString('app_locale', 'en');

        // Act
        final result = repository.getLocale();

        // Assert
        expect(result, const Locale('en'));
        expect(result?.languageCode, 'en');
      });

      test('should return null when no value is stored', () {
        // Arrange - no value set

        // Act
        final result = repository.getLocale();

        // Assert
        expect(result, null);
      });

      test(
          'should return null for unknown language codes (if implementation logic changed to validate)',
          () {
        // Arrange
        mockPrefs.setMockString('app_locale', 'fr');

        // Act
        final result = repository.getLocale();

        // Assert
        expect(result, null);
      });
    });

    group('setLocale', () {
      test('should store "zh" for Locale("zh")', () async {
        // Arrange
        const locale = Locale('zh');

        // Act
        await repository.setLocale(locale);

        // Assert
        expect(mockPrefs.getString('app_locale'), 'zh');
      });

      test('should store "en" for Locale("en")', () async {
        // Arrange
        const locale = Locale('en');

        // Act
        await repository.setLocale(locale);

        // Assert
        expect(mockPrefs.getString('app_locale'), 'en');
      });

      test('should remove key when locale is null', () async {
        // Arrange
        mockPrefs.setMockString('app_locale', 'zh');

        // Act
        await repository.setLocale(null);

        // Assert
        expect(mockPrefs.getString('app_locale'), null);
      });

      test('should overwrite previous locale', () async {
        // Arrange
        await repository.setLocale(const Locale('zh'));

        // Act
        await repository.setLocale(const Locale('en'));

        // Assert
        expect(mockPrefs.getString('app_locale'), 'en');
      });
    });

    group('getCurrency', () {
      test('should return stored currency code', () {
        // Arrange
        mockPrefs.setMockString('currency_code', 'CNY');

        // Act
        final result = repository.getCurrency();

        // Assert
        expect(result, 'CNY');
      });

      test('should return "USD" as default when no value is stored', () {
        // Arrange - no value set

        // Act
        final result = repository.getCurrency();

        // Assert
        expect(result, 'USD');
      });

      test('should return euro code when stored', () {
        // Arrange
        mockPrefs.setMockString('currency_code', 'EUR');

        // Act
        final result = repository.getCurrency();

        // Assert
        expect(result, 'EUR');
      });

      test('should return pound code when stored', () {
        // Arrange
        mockPrefs.setMockString('currency_code', 'GBP');

        // Act
        final result = repository.getCurrency();

        // Assert
        expect(result, 'GBP');
      });
    });

    group('setCurrency', () {
      test('should store currency code', () async {
        // Arrange
        const code = 'CNY';

        // Act
        await repository.setCurrency(code);

        // Assert
        expect(mockPrefs.getString('currency_code'), 'CNY');
      });

      test('should store dollar code', () async {
        // Arrange
        const code = 'USD';

        // Act
        await repository.setCurrency(code);

        // Assert
        expect(mockPrefs.getString('currency_code'), 'USD');
      });

      test('should store euro code', () async {
        // Arrange
        const code = 'EUR';

        // Act
        await repository.setCurrency(code);

        // Assert
        expect(mockPrefs.getString('currency_code'), 'EUR');
      });

      test('should overwrite previous currency code', () async {
        // Arrange
        await repository.setCurrency('CNY');

        // Act
        await repository.setCurrency('EUR');

        // Assert
        expect(mockPrefs.getString('currency_code'), 'EUR');
      });
    });

    group('integration scenarios', () {
      test('should handle complete settings workflow', () async {
        // Act - Set all settings
        await repository.setThemeMode(ThemeMode.dark);
        await repository.setLocale(const Locale('zh'));
        await repository.setCurrency('CNY');

        // Assert - Verify all settings
        expect(repository.getThemeMode(), ThemeMode.dark);
        expect(repository.getLocale(), const Locale('zh'));
        expect(repository.getCurrency(), 'CNY');
      });

      test('should handle multiple updates correctly', () async {
        // Act - Multiple theme changes
        await repository.setThemeMode(ThemeMode.light);
        await repository.setThemeMode(ThemeMode.dark);
        await repository.setThemeMode(ThemeMode.system);

        // Assert - Should have latest value
        expect(repository.getThemeMode(), ThemeMode.system);
      });

      test('should maintain settings independence', () async {
        // Act - Set different settings
        await repository.setThemeMode(ThemeMode.dark);
        await repository.setLocale(const Locale('en'));
        await repository.setCurrency('USD');

        // Change one setting
        await repository.setLocale(const Locale('zh'));

        // Assert - Other settings unchanged
        expect(repository.getThemeMode(), ThemeMode.dark);
        expect(repository.getLocale(), const Locale('zh'));
        expect(repository.getCurrency(), 'USD');
      });
    });
  });
}
