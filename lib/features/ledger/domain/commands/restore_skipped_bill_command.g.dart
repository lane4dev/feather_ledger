// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restore_skipped_bill_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(restoreSkippedBillCommand)
final restoreSkippedBillCommandProvider = RestoreSkippedBillCommandProvider._();

final class RestoreSkippedBillCommandProvider extends $FunctionalProvider<
    RestoreSkippedBillCommand,
    RestoreSkippedBillCommand,
    RestoreSkippedBillCommand> with $Provider<RestoreSkippedBillCommand> {
  RestoreSkippedBillCommandProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'restoreSkippedBillCommandProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$restoreSkippedBillCommandHash();

  @$internal
  @override
  $ProviderElement<RestoreSkippedBillCommand> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RestoreSkippedBillCommand create(Ref ref) {
    return restoreSkippedBillCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RestoreSkippedBillCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RestoreSkippedBillCommand>(value),
    );
  }
}

String _$restoreSkippedBillCommandHash() =>
    r'dfdd913d7ec45e297cd726ca7d32fddd86d19d96';
