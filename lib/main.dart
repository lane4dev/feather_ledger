import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app/l10n/app_localizations.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'app/config/app_languages.dart';
import 'app/bootstrap/pending_restore.dart';
import 'app/bootstrap/seeder.dart';
import 'app/bootstrap/register_ledger_events.dart';
import 'core/data/database/app_database.dart';
import 'core/data/repositories/preferences_repository.dart';
import 'core/presentation/providers/theme_provider.dart';
import 'core/presentation/providers/locale_provider.dart';
import 'features/ledger/data/event_sourcing/drift_event_store.dart';
import 'features/ledger/data/projections/ledger_rebuild_service.dart';
import 'features/ledger/domain/services/recurring_service.dart';
import 'features/ledger/data/notifications/recurring_reminders.dart';
import 'features/ledger/presentation/notifications/reminder_response_handler.dart';
import 'features/ledger/presentation/view_model/ledger_view_model.dart';
import 'features/settings/domain/services/category_service.dart';

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

  // Production event catalog registration (spec 003, US2/T021): every event
  // the store persists must be deserializable at startup without test-only
  // factory registration.
  registerLedgerEvents();

  // ⚠️ ORDER IS LOAD-BEARING (spec 004, US4/FR-025): the pending restore must
  // be applied before ANYTHING reads `appDatabaseProvider`. That provider is
  // keep-alive and backed by a LazyDatabase, so the first read opens the file
  // — and then the swap's renames either fail, or worse, succeed underneath
  // a live handle. Nothing in this function may read the database, or any
  // provider that reads it, above this line.
  final supportDir = await getApplicationSupportDirectory();
  final restoredPreferences = await applyPendingRestore(supportDir);

  final container = ProviderContainer();
  // Open the database eagerly (LazyDatabase) so startup work overlaps the
  // locale resolution below.
  container.read(appDatabaseProvider);

  // Restore barrier (spec 006, US58): if the previous launch applied a
  // restore, record the confirmation window now, before any auto-posting can
  // run, then drop the crash-safe marker. The marker outlives a crash between
  // `applyPendingRestore` and here.
  final restoreExportedAt = readRestoreBarrier(supportDir);
  if (restoreExportedAt != null) {
    // Stage 4 wires markPreRestoreManualOnly(restoreExportedAt) here.
    await clearRestoreBarrier(supportDir);
  }

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
  await seedDatabase(
    eventStore: container.read(driftEventStoreProvider),
    categoryService: container.read(categoryServiceProvider),
    l10n: l10n,
  );

  // Startup rebuild gate (spec 003, US8/T058): a schema upgrade already
  // rebuilds destructively (empty event store + re-seed); here any view
  // carrying an outdated projection version is rebuilt from the event
  // store. recurring_series, scheduled_transactions_view and
  // SharedPreferences are exempt.
  final rebuildService = container.read(ledgerRebuildServiceProvider);
  if (await rebuildService.isStale()) {
    await rebuildService.rebuild();
  }

  // Startup catch-up for recurring bills (spec 004, US2): materialize the
  // instances due within the projection horizon.
  //
  // Awaited rather than fired after runApp: it writes no events and no
  // projected rows, so no first frame depends on it, but the pending list
  // would otherwise race its own provider. It is idempotent — instances are
  // keyed by (series, date) and skipped when present — so a partial run, or
  // running it again, costs nothing but the queries.
  //
  // The catch is not decoration: this is new work over user data on the
  // launch path, and one bad series row must not stop the ledger opening.
  try {
    final materializedOverdue =
        await container.read(recurringServiceProvider).materialize();
    if (materializedOverdue > 0) {
      container
          .read(overdueMaterializationCountProvider.notifier)
          .set(materializedOverdue);
    }
  } catch (e) {
    debugPrint('recurring catch-up failed: $e');
  }

  // Apply restored preferences before resolving the notification language.
  if (restoredPreferences != null) {
    final preferences =
        await container.read(preferencesRepositoryProvider.future);
    await preferences.importAll(restoredPreferences);
  }

  final reminders = container.read(recurringRemindersProvider);
  try {
    final preferredLocale =
        await container.read(localeControllerProvider.future);
    final notificationL10n =
        await AppLocalizations.delegate.load(preferredLocale ?? seedLocale);
    await reminders.start(
      title: notificationL10n.reminderNotificationTitle,
      channelName: notificationL10n.reminderChannel,
      postLabel: notificationL10n.postInstance,
      skipLabel: notificationL10n.notificationSkip,
    );
  } catch (e) {
    debugPrint('Reminder startup failed: $e');
  }

  // A cold-start notification action must win over subscription catch-up:
  // otherwise pressing Skip could post the very bill the user just skipped.
  if (reminders.hasPendingResponses) {
    reminders.deferAutoPostCatchUp();
  }

  setupEdgeToEdge();

  runApp(UncontrolledProviderScope(
      container: container, child: const FeatherLedgerApp()));

  // Catch-up runs AFTER the first frame, so opening the app never waits for a
  // large batch of due bills to settle (spec 006, US46). The fixed cutoff is
  // captured inside catchUpAutoPosted when this callback fires.
  if (!reminders.hasPendingResponses) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        container
            .read(recurringServiceProvider)
            .catchUpAutoPosted()
            .catchError((Object e) {
          debugPrint('recurring auto-post catch-up failed: $e');
          return 0;
        }),
      );
    });
  }
}

class FeatherLedgerApp extends ConsumerWidget {
  const FeatherLedgerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeAsync = ref.watch(themeModeControllerProvider);
    final localeAsync = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      // The task-switcher label is user-facing — it reads 记然 in Chinese,
      // not the English product name, so it comes from the same key the About
      // screen uses rather than a literal.
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeAsync.value ?? ThemeMode.system,
      routerConfig: router,
      builder: (context, child) => ReminderResponseHandler(child: child!),
      locale: localeAsync.value,
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (localeAsync.value != null) {
          return localeAsync.value;
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
