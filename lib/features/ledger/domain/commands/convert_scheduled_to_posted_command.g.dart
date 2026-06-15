// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'convert_scheduled_to_posted_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(convertScheduledToPostedCommand)
final convertScheduledToPostedCommandProvider =
    ConvertScheduledToPostedCommandProvider._();

final class ConvertScheduledToPostedCommandProvider extends $FunctionalProvider<
        ConvertScheduledToPostedCommand,
        ConvertScheduledToPostedCommand,
        ConvertScheduledToPostedCommand>
    with $Provider<ConvertScheduledToPostedCommand> {
  ConvertScheduledToPostedCommandProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'convertScheduledToPostedCommandProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$convertScheduledToPostedCommandHash();

  @$internal
  @override
  $ProviderElement<ConvertScheduledToPostedCommand> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ConvertScheduledToPostedCommand create(Ref ref) {
    return convertScheduledToPostedCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConvertScheduledToPostedCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<ConvertScheduledToPostedCommand>(value),
    );
  }
}

String _$convertScheduledToPostedCommandHash() =>
    r'50cf3180a44eefe8ac95ee1aa2809e85acfd5239';
