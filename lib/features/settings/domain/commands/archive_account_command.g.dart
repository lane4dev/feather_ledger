// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'archive_account_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(archiveAccountCommand)
final archiveAccountCommandProvider = ArchiveAccountCommandProvider._();

final class ArchiveAccountCommandProvider extends $FunctionalProvider<
    ArchiveAccountCommand,
    ArchiveAccountCommand,
    ArchiveAccountCommand> with $Provider<ArchiveAccountCommand> {
  ArchiveAccountCommandProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'archiveAccountCommandProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$archiveAccountCommandHash();

  @$internal
  @override
  $ProviderElement<ArchiveAccountCommand> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ArchiveAccountCommand create(Ref ref) {
    return archiveAccountCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ArchiveAccountCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ArchiveAccountCommand>(value),
    );
  }
}

String _$archiveAccountCommandHash() =>
    r'29c763e62b1c55091f0773df468b1d9486e66e90';
