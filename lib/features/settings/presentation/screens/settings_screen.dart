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
import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_dialog_option.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/core/presentation/providers/theme_provider.dart';
import 'package:feather_ledger/core/presentation/providers/locale_provider.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_rebuild_service.dart';
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
    final autoPost = ref.watch(autoPostSwitchesProvider);
    final restoreSummaries =
        ref.watch(pendingRestoreConfirmationSummariesProvider).value ??
            const <RestoreConfirmationSummary>[];
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
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.metrics.fieldPadding.left,
                context.metrics.fieldPadding.top,
                context.metrics.fieldPadding.right,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.autoPostSettingsTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            // The three per-kind switches (spec 006, US30). Local-only and
            // default-off; the repository keeps them out of the backup.
            SwitchListTile(
              secondary: const Icon(LucideIcons.calendarClock),
              title: Text(l10n.transactionModePlanned),
              value: autoPost[RecurringSeriesMode.planned] ?? false,
              onChanged: (value) => ref
                  .read(autoPostSwitchesProvider.notifier)
                  .setMode(RecurringSeriesMode.planned, value),
            ),
            SwitchListTile(
              secondary: const Icon(LucideIcons.calendarClock),
              title: Text(l10n.transactionModeSubscription),
              value: autoPost[RecurringSeriesMode.subscription] ?? false,
              onChanged: (value) => ref
                  .read(autoPostSwitchesProvider.notifier)
                  .setMode(RecurringSeriesMode.subscription, value),
            ),
            SwitchListTile(
              secondary: const Icon(LucideIcons.calendarClock),
              title: Text(l10n.transactionModeRepeating),
              value: autoPost[RecurringSeriesMode.repeating] ?? false,
              onChanged: (value) => ref
                  .read(autoPostSwitchesProvider.notifier)
                  .setMode(RecurringSeriesMode.repeating, value),
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
          if (restoreSummaries.isNotEmpty)
            AppCard.group(
                child: Column(children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.metrics.fieldPadding.left,
                  context.metrics.fieldPadding.top,
                  context.metrics.fieldPadding.right,
                  0,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.restoreConfirmationTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              for (final summary in restoreSummaries)
                ListTile(
                  leading: const Icon(LucideIcons.shieldAlert),
                  title: Text(l10n.restoreConfirmationCount(summary.count)),
                  subtitle: Text(
                    _restoreSummarySubtitle(l10n, summary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () => _showRestoreConfirmationDialog(
                      context, ref, l10n, summary),
                ),
            ])),
          if (restoreSummaries.isNotEmpty) SizedBox(height: spacing.lg),
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
      builder: (context) => SimpleDialog(
        title: Text(l10n.currencySymbol),
        children: AppCurrencies.supportedCurrencyCodes.map((currencyCode) {
          return FeatherDialogOption(
            label: AppCurrencies.getName(currencyCode, l10n),
            value: currencyCode,
            groupValue: currentCurrency,
            onChanged: (value) {
              ref.read(currencyControllerProvider.notifier).setCurrency(value);
              Navigator.pop(context);
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

  /// One line under a restore-confirmation tile: currency and date range,
  /// followed by the out-of-sync risk.
  String _restoreSummarySubtitle(
      AppLocalizations l10n, RestoreConfirmationSummary summary) {
    final currency = AppCurrencies.getName(summary.currencyCode, l10n);
    final dateFormat = DateFormat.yMMMd(l10n.localeName);
    final range = (summary.firstDate == null || summary.lastDate == null)
        ? ''
        : '${dateFormat.format(summary.firstDate!)} – ${dateFormat.format(summary.lastDate!)}';
    final line = range.isEmpty ? currency : '$currency · $range';
    return '$line\n${l10n.restoreConfirmationRisk}';
  }

  /// Asks for one pending restore batch (spec 006, US62/US63). Confirm posts
  /// its eligible candidates, reject turns them permanently manual, and
  /// deferring (dismissing the dialog) does nothing — the batch stays pending.
  Future<void> _showRestoreConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    RestoreConfirmationSummary summary,
  ) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.restoreConfirmationTitle),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(l10n.restoreConfirmationRisk),
          ),
          ListTile(
            leading: const Icon(LucideIcons.calendarClock),
            title: Text(l10n.restoreConfirmationCount(summary.count)),
            subtitle: Text(AppCurrencies.getName(
                summary.currencyCode, l10n)),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'confirm'),
            child: Text(l10n.postInstance),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'reject'),
            child: Text(l10n.restoreReject),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'defer'),
            child: Text(l10n.restoreDefer),
          ),
        ],
      ),
    );
    if (action == null || action == 'defer') return;

    final service = ref.read(recurringServiceProvider);
    if (action == 'confirm') {
      await service.confirmRestoreBatch(summary.batchId);
    } else if (action == 'reject') {
      await service.rejectRestoreBatch(summary.batchId);
    }
    ref.invalidate(pendingRestoreConfirmationSummariesProvider);
  }
}

/// The three per-kind auto-post switches (spec 006, US30).
///
/// Holds the current on/off for each [RecurringSeriesMode] so the settings
/// screen can render the switches reactively. The persisted values live in
/// [PreferencesRepository] and are deliberately absent from the backup, so a
/// restore never overwrites this device's choice.
@riverpod
class AutoPostSwitches extends _$AutoPostSwitches {
  @override
  Map<RecurringSeriesMode, bool> build() {
    final repo = ref.watch(preferencesRepositoryProvider).value;
    return {
      for (final mode in RecurringSeriesMode.values)
        mode: repo?.getAutoPostEnabled(mode) ?? false,
    };
  }

  Future<void> setMode(RecurringSeriesMode mode, bool enabled) async {
    final repo = await ref.read(preferencesRepositoryProvider.future);
    await repo.setAutoPostEnabled(mode, enabled);
    if (!enabled) {
      // Turning a switch off latches any restore candidates waiting behind the
      // confirmation barrier for this mode (spec 006, US65).
      await ref
          .read(recurringServiceProvider)
          .latchRestoreCandidatesForMode(mode);
    }
    state = {...state, mode: enabled};
  }
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

/// One pending restore batch, reduced to what the confirmation tile shows
/// (spec 006, US62): how many bills it would post, in which currency, and the
/// range of their scheduled dates.
class RestoreConfirmationSummary {
  const RestoreConfirmationSummary({
    required this.batchId,
    required this.currencyCode,
    required this.count,
    this.firstDate,
    this.lastDate,
  });

  final String batchId;
  final String currencyCode;
  final int count;
  final DateTime? firstDate;
  final DateTime? lastDate;
}

/// Lists every still-pending restore confirmation batch, oldest first, with
/// the candidates a confirmation would actually post (eligible + current
/// currency + switch on — the same computation [RecurringService.confirmRestoreBatch]
/// uses). A batch whose candidates are all gone (posted, edited, or switched
/// off) reports a zero count so the user can still dismiss it.
@riverpod
Future<List<RestoreConfirmationSummary>> pendingRestoreConfirmationSummaries(
    Ref ref) async {
  final repo = ref.watch(recurringRepositoryProvider);
  final service = ref.watch(recurringServiceProvider);
  final currencyCode = ref.watch(currencyControllerProvider).value ??
      AppCurrencies.defaultCurrency.code;

  final batches = await repo.pendingRestoreConfirmationBatches();
  final summaries = <RestoreConfirmationSummary>[];
  for (final batch in batches) {
    final candidates = await service.restoreConfirmationEligible(batch.id);
    candidates.sort((a, b) => a.date.compareTo(b.date));
    summaries.add(RestoreConfirmationSummary(
      batchId: batch.id,
      currencyCode: currencyCode,
      count: candidates.length,
      firstDate: candidates.isEmpty ? null : candidates.first.date,
      lastDate: candidates.isEmpty ? null : candidates.last.date,
    ));
  }
  return summaries;
}
