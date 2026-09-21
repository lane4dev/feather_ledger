import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/design_system/app_button.dart';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/app/config/app_languages.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_dialog_option.dart';

import 'package:feather_ledger/core/presentation/providers/theme_provider.dart';
import 'package:feather_ledger/core/presentation/providers/locale_provider.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_rebuild_service.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/currency_backlog_dialog.dart';
import 'package:feather_ledger/features/settings/domain/services/backup_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

part 'settings_screen.g.dart';

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
        padding:
            context.pagePadding.add(EdgeInsets.symmetric(vertical: spacing.md)),
        children: [
          AppCard.group(
              child: Column(children: [
            // Theme
            ListTile(
              leading: const Icon(LucideIcons.sunMedium),
              title: Text(l10n.theme),
              subtitle: Text(_getThemeLabel(themeAsync.value, l10n)),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () =>
                  _showThemeDialog(context, ref, themeAsync.value, l10n),
            ),
            const FeatherDivider(),

            // Language
            ListTile(
              leading: const Icon(LucideIcons.languages),
              title: Text(l10n.language),
              subtitle: Text(_getLocaleLabel(localeAsync.value, l10n)),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () =>
                  _showLanguageDialog(context, ref, localeAsync.value, l10n),
            ),
            const FeatherDivider(),

            // Currency
            ListTile(
              leading: const Icon(LucideIcons.circleDollarSign),
              title: Text(l10n.currencySymbol),
              subtitle: Text(currencyAsync.when(
                data: (key) => AppCurrencies.getName(key, l10n),
                loading: () => l10n.loading,
                error: (_, __) => '',
              )),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () =>
                  _showCurrencyDialog(context, ref, currencyAsync.value, l10n),
            ),
          ])),
          SizedBox(height: spacing.lg),
          AppCard.group(
              child: Column(children: [
            // Data portability (spec 004, US4).
            ListTile(
              leading: const Icon(LucideIcons.databaseBackup),
              title: Text(l10n.backupNow),
              subtitle: Text(l10n.backupNowHint),
              onTap: () => _createBackup(context, ref, l10n),
            ),
            const FeatherDivider(),
            ListTile(
              leading: const Icon(LucideIcons.history),
              title: Text(l10n.restoreFromBackup),
              subtitle: Text(l10n.restoreFromBackupHint),
              onTap: () => _restoreFromBackup(context, ref, l10n),
            ),
          ])),
          SizedBox(height: spacing.lg),
          AppCard.group(
              child: Column(children: [
            // Developer-only maintenance (spec 003, US8/T059): the rebuild
            // replays the full event history into the projections. Hidden
            // behind a long-press so no regular user flow can touch it.
            ListTile(
              leading: const Icon(LucideIcons.hardHat),
              title: Text(l10n.rebuildProjections),
              subtitle: Text(l10n.rebuildProjectionsHint),
              onLongPress: () => _confirmRebuild(context, ref, l10n),
            ),
          ])),
        ],
      ),
    );
  }

  /// Builds the archive and hands it to the share sheet.
  Future<void> _createBackup(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final service = await ref.read(backupServiceProvider.future);
    final result = await service.createBackup();
    if (!context.mounted) return;

    final message = result.when(
      success: (_) => l10n.backupCreated,
      // `message` is the developer-facing English; the code is what a person
      // may be shown.
      failure: (code, _) => code.message(l10n),
    );
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Picks a backup, states what it would cost, stages it, and tells the user
  /// to restart.
  ///
  /// The restart is not a shortcut — the database is open for the whole run,
  /// so the swap can only happen at startup. See `pending_restore.dart`.
  Future<void> _restoreFromBackup(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final picked =
        await ref.read(backupFilePickerProvider)(l10n.backupFileTypeLabel);
    if (picked == null || !context.mounted) return;

    final service = await ref.read(backupServiceProvider.future);
    final preview = await service.preview(picked);
    if (!context.mounted) return;

    if (preview case Failure(:final code)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(code.message(l10n))));
      return;
    }
    final info = (preview as Success<BackupPreview>).value;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restoreConfirmTitle),
        content: Text(l10n.restoreConfirmMessage(
          info.manifest.eventCount,
          info.currentEventCount,
          info.discardedEventCount,
        )),
        actions: [
          AppButton.text(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          AppButton.text(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.restoreFromBackup),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final staged = await service.stageRestore(picked);
    if (!context.mounted) return;

    if (staged case Failure(:final code)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(code.message(l10n))));
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restoreReadyTitle),
        content: Text(l10n.restoreReadyMessage),
        actions: [
          AppButton.text(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          AppButton.text(
            onPressed: () {
              Navigator.pop(context);
              // Android closes the activity; elsewhere the user reopens the
              // app themselves, which the message already asked for.
              SystemNavigator.pop();
            },
            child: Text(l10n.exitNow),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRebuild(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.rebuildProjections),
        content: Text(l10n.rebuildProjectionsConfirm),
        actions: [
          AppButton.text(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          AppButton.text(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    String message;
    try {
      await ref.read(ledgerRebuildServiceProvider).rebuild();
      message = l10n.rebuildProjectionsSuccess;
    } catch (e) {
      message = l10n.rebuildProjectionsFailure;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
          FeatherDialogOption(
            label: l10n.system,
            value: ThemeMode.system,
            groupValue: currentMode,
            onChanged: (value) {
              ref.read(themeModeControllerProvider.notifier).setTheme(value);
              Navigator.pop(context);
            },
          ),
          FeatherDialogOption(
            label: l10n.light,
            value: ThemeMode.light,
            groupValue: currentMode,
            onChanged: (value) {
              ref.read(themeModeControllerProvider.notifier).setTheme(value);
              Navigator.pop(context);
            },
          ),
          FeatherDialogOption(
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
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.language),
        children: [
          FeatherDialogOption<Locale?>(
            label: l10n.followSystem,
            value: null,
            groupValue: currentLocale,
            onChanged: (value) {
              ref.read(localeControllerProvider.notifier).setLocale(value);
              Navigator.pop(context);
            },
          ),
          ...AppLanguages.supportedLocales.map((locale) {
            return FeatherDialogOption<Locale?>(
              label: AppLanguages.getName(locale, l10n),
              value: locale,
              groupValue: currentLocale,
              onChanged: (value) {
                ref.read(localeControllerProvider.notifier).setLocale(value);
                Navigator.pop(context);
              },
            );
          }),
        ],
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
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.currencySymbol),
        children: AppCurrencies.supportedCurrencyCodes.map((currencyCode) {
          return FeatherDialogOption(
            label: AppCurrencies.getName(currencyCode, l10n),
            value: currencyCode,
            groupValue: currentCurrency,
            onChanged: (value) async {
              ref.read(currencyControllerProvider.notifier).setCurrency(value);
              Navigator.pop(dialogContext);
              // A switch back to a currency with accumulated due auto-post
              // bills asks once how to settle them (spec 006, US49).
              await showCurrencyBacklogDialog(context, ref, value);
            },
          );
        }).toList(),
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

  String _getLocaleLabel(Locale? locale, AppLocalizations l10n) =>
      locale == null ? l10n.followSystem : AppLanguages.getName(locale, l10n);
}

/// Opens the platform file dialog and returns the chosen backup, or null if
/// the user cancelled.
///
/// A provider rather than a direct [openFile] call so a widget test can drive
/// the whole restore flow without a platform channel.
typedef BackupFilePicker = Future<File?> Function(String typeLabel);

@riverpod
BackupFilePicker backupFilePicker(Ref ref) => (String typeLabel) async {
      final picked = await openFile(
        acceptedTypeGroups: [
          // The label is what the platform file dialog shows for the filter,
          // so it is a localized string the caller hands in — a provider has
          // no context to read one from.
          XTypeGroup(label: typeLabel, extensions: const ['flbackup']),
        ],
      );
      return picked == null ? null : File(picked.path);
    };
