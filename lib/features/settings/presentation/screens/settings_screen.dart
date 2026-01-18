import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeModeControllerProvider);
    final localeAsync = ref.watch(localeControllerProvider);
    final currencyAsync = ref.watch(currencyControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Theme
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme'),
            subtitle: Text(themeAsync.valueOrNull?.toString().split('.').last ??
                'Loading...'),
            trailing: DropdownButton<ThemeMode>(
              value: themeAsync.valueOrNull,
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) {
                  ref
                      .read(themeModeControllerProvider.notifier)
                      .setTheme(newValue);
                }
              },
              items: const [
                DropdownMenuItem(
                    value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
            ),
          ),
          const Divider(),

          // Language
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: Text(localeAsync.valueOrNull?.languageCode == 'zh'
                ? 'Chinese'
                : 'English'),
            trailing: DropdownButton<Locale>(
              value: localeAsync.valueOrNull,
              onChanged: (Locale? newValue) {
                if (newValue != null) {
                  ref
                      .read(localeControllerProvider.notifier)
                      .setLocale(newValue);
                }
              },
              items: const [
                DropdownMenuItem(value: Locale('en'), child: Text('English')),
                DropdownMenuItem(value: Locale('zh'), child: Text('Chinese')),
              ],
            ),
          ),
          const Divider(),

          // Currency
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Currency Symbol'),
            subtitle: Text(currencyAsync.valueOrNull ?? 'Loading...'),
            trailing: DropdownButton<String>(
              value: currencyAsync.valueOrNull,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  ref
                      .read(currencyControllerProvider.notifier)
                      .setCurrency(newValue);
                }
              },
              items: const [
                DropdownMenuItem(value: '\$', child: Text('\$ (Dollar)')),
                DropdownMenuItem(value: '¥', child: Text('¥ (Yuan/Yen)')),
                DropdownMenuItem(value: '€', child: Text('€ (Euro)')),
                DropdownMenuItem(value: '£', child: Text('£ (Pound)')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
