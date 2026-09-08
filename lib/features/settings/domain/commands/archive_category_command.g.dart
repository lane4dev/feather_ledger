// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'archive_category_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(archiveCategoryCommand)
final archiveCategoryCommandProvider = ArchiveCategoryCommandProvider._();

final class ArchiveCategoryCommandProvider extends $FunctionalProvider<
    ArchiveCategoryCommand,
    ArchiveCategoryCommand,
    ArchiveCategoryCommand> with $Provider<ArchiveCategoryCommand> {
  ArchiveCategoryCommandProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'archiveCategoryCommandProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$archiveCategoryCommandHash();

  @$internal
  @override
  $ProviderElement<ArchiveCategoryCommand> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ArchiveCategoryCommand create(Ref ref) {
    return archiveCategoryCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ArchiveCategoryCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ArchiveCategoryCommand>(value),
    );
  }
}

String _$archiveCategoryCommandHash() =>
    r'fce1a338254bdf68e45f0ae7c2f578092c03d6a6';
