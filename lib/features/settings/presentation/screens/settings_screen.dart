import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeModeControllerProvider);
    final localeAsync = ref.watch(localeControllerProvider);
    final currencyAsync = ref.watch(currencyControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          // Theme
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: Text(l10n.theme),
            subtitle: Text(_getThemeLabel(themeAsync.valueOrNull, l10n)),
            trailing: DropdownButton<ThemeMode>(
              value: themeAsync.valueOrNull,
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) {
                  ref
                      .read(themeModeControllerProvider.notifier)
                      .setTheme(newValue);
                }
              },
              items: [
                DropdownMenuItem(
                    value: ThemeMode.system, child: Text(l10n.system)),
                DropdownMenuItem(
                    value: ThemeMode.light, child: Text(l10n.light)),
                DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.dark)),
              ],
            ),
          ),
          const Divider(),

          // Language
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(localeAsync.valueOrNull?.languageCode == 'zh'
                ? l10n.chinese
                : l10n.english),
            trailing: DropdownButton<Locale>(
              value: localeAsync.valueOrNull,
              onChanged: (Locale? newValue) {
                if (newValue != null) {
                  ref
                      .read(localeControllerProvider.notifier)
                      .setLocale(newValue);
                }
              },
              items: [
                DropdownMenuItem(
                    value: const Locale('en'), child: Text(l10n.english)),
                DropdownMenuItem(
                    value: const Locale('zh'), child: Text(l10n.chinese)),
              ],
            ),
          ),
          const Divider(),

          // Currency
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: Text(l10n.currencySymbol),
            subtitle: Text(currencyAsync.valueOrNull ?? l10n.loading),
            trailing: DropdownButton<String>(
              value: currencyAsync.valueOrNull,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  ref
                      .read(currencyControllerProvider.notifier)
                      .setCurrency(newValue);
                }
              },
              items: [
                DropdownMenuItem(value: '\$', child: Text(l10n.dollarCurrency)),
                DropdownMenuItem(value: '¥', child: Text(l10n.yuanYenCurrency)),
                DropdownMenuItem(value: '€', child: Text(l10n.euroCurrency)),
                DropdownMenuItem(value: '£', child: Text(l10n.poundCurrency)),
              ],
            ),
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
}
