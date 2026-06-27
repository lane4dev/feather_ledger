// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skip_scheduled_transaction_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(skipScheduledTransactionCommand)
final skipScheduledTransactionCommandProvider =
    SkipScheduledTransactionCommandProvider._();

final class SkipScheduledTransactionCommandProvider extends $FunctionalProvider<
        SkipScheduledTransactionCommand,
        SkipScheduledTransactionCommand,
        SkipScheduledTransactionCommand>
    with $Provider<SkipScheduledTransactionCommand> {
  SkipScheduledTransactionCommandProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'skipScheduledTransactionCommandProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$skipScheduledTransactionCommandHash();

  @$internal
  @override
  $ProviderElement<SkipScheduledTransactionCommand> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SkipScheduledTransactionCommand create(Ref ref) {
    return skipScheduledTransactionCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SkipScheduledTransactionCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<SkipScheduledTransactionCommand>(value),
    );
  }
}

String _$skipScheduledTransactionCommandHash() =>
    r'75b3b79106056846f8e0fa5d067f1374f7477f3e';
