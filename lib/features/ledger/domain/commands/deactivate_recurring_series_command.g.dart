// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deactivate_recurring_series_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deactivateRecurringSeriesCommand)
final deactivateRecurringSeriesCommandProvider =
    DeactivateRecurringSeriesCommandProvider._();

final class DeactivateRecurringSeriesCommandProvider
    extends $FunctionalProvider<DeactivateRecurringSeriesCommand,
        DeactivateRecurringSeriesCommand, DeactivateRecurringSeriesCommand>
    with $Provider<DeactivateRecurringSeriesCommand> {
  DeactivateRecurringSeriesCommandProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'deactivateRecurringSeriesCommandProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$deactivateRecurringSeriesCommandHash();

  @$internal
  @override
  $ProviderElement<DeactivateRecurringSeriesCommand> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeactivateRecurringSeriesCommand create(Ref ref) {
    return deactivateRecurringSeriesCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeactivateRecurringSeriesCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<DeactivateRecurringSeriesCommand>(value),
    );
  }
}

String _$deactivateRecurringSeriesCommandHash() =>
    r'45f0a425ea8952a8bcb1cd1fb70b366a595c0632';
