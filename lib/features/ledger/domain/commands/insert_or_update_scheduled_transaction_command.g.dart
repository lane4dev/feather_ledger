// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insert_or_update_scheduled_transaction_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(insertOrUpdateScheduledTransactionCommand)
final insertOrUpdateScheduledTransactionCommandProvider =
    InsertOrUpdateScheduledTransactionCommandProvider._();

final class InsertOrUpdateScheduledTransactionCommandProvider
    extends $FunctionalProvider<
        InsertOrUpdateScheduledTransactionCommand,
        InsertOrUpdateScheduledTransactionCommand,
        InsertOrUpdateScheduledTransactionCommand>
    with $Provider<InsertOrUpdateScheduledTransactionCommand> {
  InsertOrUpdateScheduledTransactionCommandProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'insertOrUpdateScheduledTransactionCommandProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() =>
      _$insertOrUpdateScheduledTransactionCommandHash();

  @$internal
  @override
  $ProviderElement<InsertOrUpdateScheduledTransactionCommand> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  InsertOrUpdateScheduledTransactionCommand create(Ref ref) {
    return insertOrUpdateScheduledTransactionCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InsertOrUpdateScheduledTransactionCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<InsertOrUpdateScheduledTransactionCommand>(value),
    );
  }
}

String _$insertOrUpdateScheduledTransactionCommandHash() =>
    r'75f6d2586ceb7302b82e6272c7c20731d85a0610';
