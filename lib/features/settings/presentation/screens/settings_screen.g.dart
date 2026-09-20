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

String _$autoPostSwitchesHash() => r'7bde3dee4f647e46889753fec836c8d0d2b53ec9';

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
