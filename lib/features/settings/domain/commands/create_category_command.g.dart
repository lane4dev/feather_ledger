// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_category_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(createCategoryCommand)
final createCategoryCommandProvider = CreateCategoryCommandProvider._();

final class CreateCategoryCommandProvider extends $FunctionalProvider<
    CreateCategoryCommand,
    CreateCategoryCommand,
    CreateCategoryCommand> with $Provider<CreateCategoryCommand> {
  CreateCategoryCommandProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'createCategoryCommandProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$createCategoryCommandHash();

  @$internal
  @override
  $ProviderElement<CreateCategoryCommand> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CreateCategoryCommand create(Ref ref) {
    return createCategoryCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateCategoryCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateCategoryCommand>(value),
    );
  }
}

String _$createCategoryCommandHash() =>
    r'4dd69da44f3ced010da0c45a3fe3a65ffb3ae3ea';
