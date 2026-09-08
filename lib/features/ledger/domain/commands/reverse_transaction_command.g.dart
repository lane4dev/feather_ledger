// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reverse_transaction_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reverseTransactionCommand)
final reverseTransactionCommandProvider = ReverseTransactionCommandProvider._();

final class ReverseTransactionCommandProvider extends $FunctionalProvider<
    ReverseTransactionCommand,
    ReverseTransactionCommand,
    ReverseTransactionCommand> with $Provider<ReverseTransactionCommand> {
  ReverseTransactionCommandProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'reverseTransactionCommandProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$reverseTransactionCommandHash();

  @$internal
  @override
  $ProviderElement<ReverseTransactionCommand> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReverseTransactionCommand create(Ref ref) {
    return reverseTransactionCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReverseTransactionCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReverseTransactionCommand>(value),
    );
  }
}

String _$reverseTransactionCommandHash() =>
    r'6644b7a4a17ad97f5a2f34e6d7a5efff4dd94b17';
