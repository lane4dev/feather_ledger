// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rename_category_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(renameCategoryCommand)
final renameCategoryCommandProvider = RenameCategoryCommandProvider._();

final class RenameCategoryCommandProvider extends $FunctionalProvider<
    RenameCategoryCommand,
    RenameCategoryCommand,
    RenameCategoryCommand> with $Provider<RenameCategoryCommand> {
  RenameCategoryCommandProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'renameCategoryCommandProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$renameCategoryCommandHash();

  @$internal
  @override
  $ProviderElement<RenameCategoryCommand> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RenameCategoryCommand create(Ref ref) {
    return renameCategoryCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RenameCategoryCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RenameCategoryCommand>(value),
    );
  }
}

String _$renameCategoryCommandHash() =>
    r'08881cda360a7498b626bd2c74c7284f2b29e1b6';
