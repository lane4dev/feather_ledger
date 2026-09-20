// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The three per-kind auto-post switches (spec 006, US30).
///
/// Holds the current on/off for each [RecurringSeriesMode] so the settings
/// screen can render the switches reactively. The persisted values live in
/// [PreferencesRepository] and are deliberately absent from the backup, so a
/// restore never overwrites this device's choice.

@ProviderFor(AutoPostSwitches)
final autoPostSwitchesProvider = AutoPostSwitchesProvider._();

/// The three per-kind auto-post switches (spec 006, US30).
///
/// Holds the current on/off for each [RecurringSeriesMode] so the settings
/// screen can render the switches reactively. The persisted values live in
/// [PreferencesRepository] and are deliberately absent from the backup, so a
/// restore never overwrites this device's choice.
final class AutoPostSwitchesProvider extends $NotifierProvider<AutoPostSwitches,
    Map<RecurringSeriesMode, bool>> {
  /// The three per-kind auto-post switches (spec 006, US30).
  ///
  /// Holds the current on/off for each [RecurringSeriesMode] so the settings
  /// screen can render the switches reactively. The persisted values live in
  /// [PreferencesRepository] and are deliberately absent from the backup, so a
  /// restore never overwrites this device's choice.
  AutoPostSwitchesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'autoPostSwitchesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$autoPostSwitchesHash();

  @$internal
  @override
  AutoPostSwitches create() => AutoPostSwitches();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<RecurringSeriesMode, bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Map<RecurringSeriesMode, bool>>(value),
    );
  }
}

String _$autoPostSwitchesHash() => r'a1491f42fae143cb0e246f391a1e7c72a738e893';

/// The three per-kind auto-post switches (spec 006, US30).
///
/// Holds the current on/off for each [RecurringSeriesMode] so the settings
/// screen can render the switches reactively. The persisted values live in
/// [PreferencesRepository] and are deliberately absent from the backup, so a
/// restore never overwrites this device's choice.

abstract class _$AutoPostSwitches
    extends $Notifier<Map<RecurringSeriesMode, bool>> {
  Map<RecurringSeriesMode, bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref
        as $Ref<Map<RecurringSeriesMode, bool>, Map<RecurringSeriesMode, bool>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<Map<RecurringSeriesMode, bool>,
            Map<RecurringSeriesMode, bool>>,
        Map<RecurringSeriesMode, bool>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(backupFilePicker)
final backupFilePickerProvider = BackupFilePickerProvider._();

final class BackupFilePickerProvider extends $FunctionalProvider<
    BackupFilePicker,
    BackupFilePicker,
    BackupFilePicker> with $Provider<BackupFilePicker> {
  BackupFilePickerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'backupFilePickerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$backupFilePickerHash();

  @$internal
  @override
  $ProviderElement<BackupFilePicker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BackupFilePicker create(Ref ref) {
    return backupFilePicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackupFilePicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackupFilePicker>(value),
    );
  }
}

String _$backupFilePickerHash() => r'd232f9e5d7f9771bcd09b1dde58edbfde6042c69';

/// Lists every still-pending restore confirmation batch, oldest first, with
/// the candidates a confirmation would actually post (eligible + current
/// currency + switch on — the same computation [RecurringService.confirmRestoreBatch]
/// uses). A batch whose candidates are all gone (posted, edited, or switched
/// off) reports a zero count so the user can still dismiss it.

@ProviderFor(pendingRestoreConfirmationSummaries)
final pendingRestoreConfirmationSummariesProvider =
    PendingRestoreConfirmationSummariesProvider._();

/// Lists every still-pending restore confirmation batch, oldest first, with
/// the candidates a confirmation would actually post (eligible + current
/// currency + switch on — the same computation [RecurringService.confirmRestoreBatch]
/// uses). A batch whose candidates are all gone (posted, edited, or switched
/// off) reports a zero count so the user can still dismiss it.

final class PendingRestoreConfirmationSummariesProvider
    extends $FunctionalProvider<
        AsyncValue<List<RestoreConfirmationSummary>>,
        List<RestoreConfirmationSummary>,
        FutureOr<List<RestoreConfirmationSummary>>>
    with
        $FutureModifier<List<RestoreConfirmationSummary>>,
        $FutureProvider<List<RestoreConfirmationSummary>> {
  /// Lists every still-pending restore confirmation batch, oldest first, with
  /// the candidates a confirmation would actually post (eligible + current
  /// currency + switch on — the same computation [RecurringService.confirmRestoreBatch]
  /// uses). A batch whose candidates are all gone (posted, edited, or switched
  /// off) reports a zero count so the user can still dismiss it.
  PendingRestoreConfirmationSummariesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'pendingRestoreConfirmationSummariesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() =>
      _$pendingRestoreConfirmationSummariesHash();

  @$internal
  @override
  $FutureProviderElement<List<RestoreConfirmationSummary>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<RestoreConfirmationSummary>> create(Ref ref) {
    return pendingRestoreConfirmationSummaries(ref);
  }
}

String _$pendingRestoreConfirmationSummariesHash() =>
    r'ee55a481718c5302121852587a819f65a7f61aa7';
