// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_transaction_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recordTransactionCommand)
final recordTransactionCommandProvider = RecordTransactionCommandProvider._();

final class RecordTransactionCommandProvider extends $FunctionalProvider<
    RecordTransactionCommand,
    RecordTransactionCommand,
    RecordTransactionCommand> with $Provider<RecordTransactionCommand> {
  RecordTransactionCommandProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'recordTransactionCommandProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$recordTransactionCommandHash();

  @$internal
  @override
  $ProviderElement<RecordTransactionCommand> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecordTransactionCommand create(Ref ref) {
    return recordTransactionCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecordTransactionCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecordTransactionCommand>(value),
    );
  }
}

String _$recordTransactionCommandHash() =>
    r'fe52682c1d878cb4d89ec1a209a69612b0150713';
