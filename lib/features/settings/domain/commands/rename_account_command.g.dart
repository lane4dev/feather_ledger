// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rename_account_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(renameAccountCommand)
final renameAccountCommandProvider = RenameAccountCommandProvider._();

final class RenameAccountCommandProvider extends $FunctionalProvider<
    RenameAccountCommand,
    RenameAccountCommand,
    RenameAccountCommand> with $Provider<RenameAccountCommand> {
  RenameAccountCommandProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'renameAccountCommandProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$renameAccountCommandHash();

  @$internal
  @override
  $ProviderElement<RenameAccountCommand> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RenameAccountCommand create(Ref ref) {
    return renameAccountCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RenameAccountCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RenameAccountCommand>(value),
    );
  }
}

String _$renameAccountCommandHash() =>
    r'7f447508a247ca2f8c4976570092a26a9d5a2dfc';
