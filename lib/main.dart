import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/l10n/app_localizations.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'app/config/app_languages.dart';
import 'app/bootstrap/seeder.dart';
import 'core/data/database/app_database.dart';
import 'core/presentation/providers/theme_provider.dart';
import 'core/presentation/providers/locale_provider.dart';

void setupEdgeToEdge() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Make the system navigation bar "immersive" = transparent + icon brightness matching
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,

    // Whether to enforce contrast (affects Android's scrim behavior on transparent navigation bar)
    // You can adjust true/false based on your UI needs
    systemNavigationBarContrastEnforced: false,
  ));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  final db = container.read(appDatabaseProvider);

  final systemLocales = WidgetsBinding.instance.platformDispatcher.locales;

  // Default to English
  var seedLocale = const Locale('en');
  // Find the best matching locale for seeding
  for (final systemLocale in systemLocales) {
    if (AppLanguages.supportedLocales.any(
        (supported) => supported.languageCode == systemLocale.languageCode)) {
      seedLocale = systemLocale;
      break;
    }
  }

  final l10n = await AppLocalizations.delegate.load(seedLocale);
  await seedDatabase(db, l10n);

  setupEdgeToEdge();

  runApp(UncontrolledProviderScope(
      container: container, child: const FeatherLedgerApp()));
}

class FeatherLedgerApp extends ConsumerWidget {
  const FeatherLedgerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeAsync = ref.watch(themeModeControllerProvider);
    final localeAsync = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      title: 'Feather Ledger',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeAsync.valueOrNull ?? ThemeMode.system,
      routerConfig: router,
      locale: localeAsync.valueOrNull,
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (localeAsync.valueOrNull != null) {
          return localeAsync.valueOrNull;
        }

        if (deviceLocale == null) {
          return const Locale('en');
        }

        for (final locale in supportedLocales) {
          if (locale.languageCode == deviceLocale.languageCode) {
            return locale;
          }
        }

        return const Locale('en');
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLanguages.supportedLocales,
    );
  }
}
