// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'correct_transaction_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(correctTransactionCommand)
final correctTransactionCommandProvider = CorrectTransactionCommandProvider._();

final class CorrectTransactionCommandProvider extends $FunctionalProvider<
    CorrectTransactionCommand,
    CorrectTransactionCommand,
    CorrectTransactionCommand> with $Provider<CorrectTransactionCommand> {
  CorrectTransactionCommandProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'correctTransactionCommandProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$correctTransactionCommandHash();

  @$internal
  @override
  $ProviderElement<CorrectTransactionCommand> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CorrectTransactionCommand create(Ref ref) {
    return correctTransactionCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CorrectTransactionCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CorrectTransactionCommand>(value),
    );
  }
}

String _$correctTransactionCommandHash() =>
    r'df479bb848a4a98320b1c8795824a99da3225ace';
