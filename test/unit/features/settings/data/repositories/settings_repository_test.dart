import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/features/settings/data/repositories/settings_repository.dart';

import '../../../../../support/mocks/mock_shared_preferences.dart';

void main() {
  late MockSharedPreferences mockPrefs;
  late SettingsRepository repository;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    repository = SettingsRepositoryImpl(mockPrefs);
  });

  tearDown(() {
    mockPrefs.reset();
  });

  group('SettingsRepository', () {
    group('instantiation', () {
      test('should create instance with shared preferences', () {
        expect(repository, isNotNull);
        expect(repository, isA<SettingsRepository>());
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
        // Note: The current implementation just returns null if not 'zh' or 'en' in the switch statement
        // or actually looking at the code:
        // if (val == 'zh') return const Locale('zh');
        // if (val == 'en') return const Locale('en');
        // return null;

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
      test('should return stored currency symbol', () {
        // Arrange
        mockPrefs.setMockString('currency_symbol', '¥');

        // Act
        final result = repository.getCurrency();

        // Assert
        expect(result, '¥');
      });

      test('should return "\$" as default when no value is stored', () {
        // Arrange - no value set

        // Act
        final result = repository.getCurrency();

        // Assert
        expect(result, '\$');
      });

      test('should return euro symbol when stored', () {
        // Arrange
        mockPrefs.setMockString('currency_symbol', '€');

        // Act
        final result = repository.getCurrency();

        // Assert
        expect(result, '€');
      });

      test('should return pound symbol when stored', () {
        // Arrange
        mockPrefs.setMockString('currency_symbol', '£');

        // Act
        final result = repository.getCurrency();

        // Assert
        expect(result, '£');
      });
    });

    group('setCurrency', () {
      test('should store currency symbol', () async {
        // Arrange
        const symbol = '¥';

        // Act
        await repository.setCurrency(symbol);

        // Assert
        expect(mockPrefs.getString('currency_symbol'), '¥');
      });

      test('should store dollar symbol', () async {
        // Arrange
        const symbol = '\$';

        // Act
        await repository.setCurrency(symbol);

        // Assert
        expect(mockPrefs.getString('currency_symbol'), '\$');
      });

      test('should store euro symbol', () async {
        // Arrange
        const symbol = '€';

        // Act
        await repository.setCurrency(symbol);

        // Assert
        expect(mockPrefs.getString('currency_symbol'), '€');
      });

      test('should overwrite previous currency symbol', () async {
        // Arrange
        await repository.setCurrency('¥');

        // Act
        await repository.setCurrency('€');

        // Assert
        expect(mockPrefs.getString('currency_symbol'), '€');
      });
    });

    group('integration scenarios', () {
      test('should handle complete settings workflow', () async {
        // Act - Set all settings
        await repository.setThemeMode(ThemeMode.dark);
        await repository.setLocale(const Locale('zh'));
        await repository.setCurrency('¥');

        // Assert - Verify all settings
        expect(repository.getThemeMode(), ThemeMode.dark);
        expect(repository.getLocale(), const Locale('zh'));
        expect(repository.getCurrency(), '¥');
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
        await repository.setCurrency('\$');

        // Change one setting
        await repository.setLocale(const Locale('zh'));

        // Assert - Other settings unchanged
        expect(repository.getThemeMode(), ThemeMode.dark);
        expect(repository.getLocale(), const Locale('zh'));
        expect(repository.getCurrency(), '\$');
      });
    });
  });
}
