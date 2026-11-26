// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ensure_occurrence_materialized_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ensureOccurrenceMaterializedCommand)
final ensureOccurrenceMaterializedCommandProvider =
    EnsureOccurrenceMaterializedCommandProvider._();

final class EnsureOccurrenceMaterializedCommandProvider
    extends $FunctionalProvider<
        EnsureOccurrenceMaterializedCommand,
        EnsureOccurrenceMaterializedCommand,
        EnsureOccurrenceMaterializedCommand>
    with $Provider<EnsureOccurrenceMaterializedCommand> {
  EnsureOccurrenceMaterializedCommandProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'ensureOccurrenceMaterializedCommandProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() =>
      _$ensureOccurrenceMaterializedCommandHash();

  @$internal
  @override
  $ProviderElement<EnsureOccurrenceMaterializedCommand> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EnsureOccurrenceMaterializedCommand create(Ref ref) {
    return ensureOccurrenceMaterializedCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EnsureOccurrenceMaterializedCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<EnsureOccurrenceMaterializedCommand>(value),
    );
  }
}

String _$ensureOccurrenceMaterializedCommandHash() =>
    r'dcca225a0cd285b27a2f3b68113980c632b41232';
