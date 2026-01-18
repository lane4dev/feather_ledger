import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/l10n/app_localizations.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/database/app_database.dart';
import 'core/database/seeder.dart';
import 'features/settings/presentation/providers/settings_providers.dart';

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
  await seedDatabase(db);

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
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
      ],
    );
  }
}
