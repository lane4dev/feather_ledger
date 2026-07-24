// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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
