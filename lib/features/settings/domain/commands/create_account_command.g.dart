// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_account_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(createAccountCommand)
final createAccountCommandProvider = CreateAccountCommandProvider._();

final class CreateAccountCommandProvider extends $FunctionalProvider<
    CreateAccountCommand,
    CreateAccountCommand,
    CreateAccountCommand> with $Provider<CreateAccountCommand> {
  CreateAccountCommandProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'createAccountCommandProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$createAccountCommandHash();

  @$internal
  @override
  $ProviderElement<CreateAccountCommand> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CreateAccountCommand create(Ref ref) {
    return createAccountCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateAccountCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateAccountCommand>(value),
    );
  }
}

String _$createAccountCommandHash() =>
    r'e93feece561b228a4a16b416c7b74de21fb2a05f';
