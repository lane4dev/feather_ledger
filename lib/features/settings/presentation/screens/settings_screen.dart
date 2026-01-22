import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_languages.dart';
import '../../../../app/l10n/app_localizations.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/presentation/widgets/feather_divider.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeModeControllerProvider);
    final localeAsync = ref.watch(localeControllerProvider);
    final currencyAsync = ref.watch(currencyControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: spacing.sm),
        children: [
          // Theme
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: Text(l10n.theme),
            subtitle: Text(_getThemeLabel(themeAsync.valueOrNull, l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _showThemeDialog(context, ref, themeAsync.valueOrNull, l10n),
          ),
          const FeatherDivider(),

          // Language
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            // Show the actual language name. If null (system), resolve the current active locale.
            subtitle: Text(_getLocaleLabel(
                context, localeAsync.valueOrNull, l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(
                context, ref, localeAsync.valueOrNull, l10n),
          ),
          const FeatherDivider(),

          // Currency
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: Text(l10n.currencySymbol),
            subtitle: Text(currencyAsync.valueOrNull ?? l10n.loading),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCurrencyDialog(
                context, ref, currencyAsync.valueOrNull, l10n),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeMode? currentMode,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.theme),
        children: [
          _DialogOption(
            label: l10n.system,
            value: ThemeMode.system,
            groupValue: currentMode,
            onChanged: (value) {
              ref.read(themeModeControllerProvider.notifier).setTheme(value);
              Navigator.pop(context);
            },
          ),
          _DialogOption(
            label: l10n.light,
            value: ThemeMode.light,
            groupValue: currentMode,
            onChanged: (value) {
              ref.read(themeModeControllerProvider.notifier).setTheme(value);
              Navigator.pop(context);
            },
          ),
          _DialogOption(
            label: l10n.dark,
            value: ThemeMode.dark,
            groupValue: currentMode,
            onChanged: (value) {
              ref.read(themeModeControllerProvider.notifier).setTheme(value);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    Locale? currentLocale,
    AppLocalizations l10n,
  ) {
    // If currentLocale is null (System), we want to check which one is active to show the checkmark.
    final effectiveLocale = currentLocale ?? Localizations.localeOf(context);

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.language),
        children: AppLanguages.supportedLocales.map((locale) {
          return _DialogOption(
            label: AppLanguages.getName(locale, l10n),
            value: locale,
            // Compare by languageCode to be safe against 'en' vs 'en_US'
            groupValue: effectiveLocale,
            onChanged: (value) {
              ref.read(localeControllerProvider.notifier).setLocale(value);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showCurrencyDialog(
    BuildContext context,
    WidgetRef ref,
    String? currentCurrency,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.currencySymbol),
        children: [
          _DialogOption(
            label: l10n.dollarCurrency,
            value: '\$',
            groupValue: currentCurrency,
            onChanged: (value) {
              ref.read(currencyControllerProvider.notifier).setCurrency(value);
              Navigator.pop(context);
            },
          ),
          _DialogOption(
            label: l10n.yuanYenCurrency,
            value: '¥',
            groupValue: currentCurrency,
            onChanged: (value) {
              ref.read(currencyControllerProvider.notifier).setCurrency(value);
              Navigator.pop(context);
            },
          ),
          _DialogOption(
            label: l10n.euroCurrency,
            value: '€',
            groupValue: currentCurrency,
            onChanged: (value) {
              ref.read(currencyControllerProvider.notifier).setCurrency(value);
              Navigator.pop(context);
            },
          ),
          _DialogOption(
            label: l10n.poundCurrency,
            value: '£',
            groupValue: currentCurrency,
            onChanged: (value) {
              ref.read(currencyControllerProvider.notifier).setCurrency(value);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  String _getThemeLabel(ThemeMode? mode, AppLocalizations l10n) {
    if (mode == null) return l10n.loading;
    switch (mode) {
      case ThemeMode.system:
        return l10n.system;
      case ThemeMode.light:
        return l10n.light;
      case ThemeMode.dark:
        return l10n.dark;
    }
  }

  String _getLocaleLabel(
      BuildContext context, Locale? locale, AppLocalizations l10n) {
    final effectiveLocale = locale ?? Localizations.localeOf(context);
    return AppLanguages.getName(effectiveLocale, l10n);
  }
}

class _DialogOption<T> extends StatelessWidget {
  final String label;
  final T value;
  final T? groupValue;
  final ValueChanged<T> onChanged;

  const _DialogOption({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Custom equality check for Locale to handle 'en' vs 'en_US' if necessary
    // But since we use AppLanguages.supportedLocales, we expect exact matches
    // usually. However, Localizations.localeOf(context) might return a country-specific one.
    var isSelected = false;
    if (value is Locale && groupValue is Locale) {
      isSelected = (value as Locale).languageCode ==
          (groupValue as Locale).languageCode;
    } else {
      isSelected = value == groupValue;
    }

    return SimpleDialogOption(
      onPressed: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color:
                      isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}