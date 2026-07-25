// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_account_totals_inclusion_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(setAccountTotalsInclusionCommand)
final setAccountTotalsInclusionCommandProvider =
    SetAccountTotalsInclusionCommandProvider._();

final class SetAccountTotalsInclusionCommandProvider
    extends $FunctionalProvider<SetAccountTotalsInclusionCommand,
        SetAccountTotalsInclusionCommand, SetAccountTotalsInclusionCommand>
    with $Provider<SetAccountTotalsInclusionCommand> {
  SetAccountTotalsInclusionCommandProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'setAccountTotalsInclusionCommandProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$setAccountTotalsInclusionCommandHash();

  @$internal
  @override
  $ProviderElement<SetAccountTotalsInclusionCommand> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SetAccountTotalsInclusionCommand create(Ref ref) {
    return setAccountTotalsInclusionCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SetAccountTotalsInclusionCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<SetAccountTotalsInclusionCommand>(value),
    );
  }
}

String _$setAccountTotalsInclusionCommandHash() =>
    r'82fa14e0f5463af69c8b421500de89863b93de1d';
