// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_recurring_series_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(createRecurringSeriesCommand)
final createRecurringSeriesCommandProvider =
    CreateRecurringSeriesCommandProvider._();

final class CreateRecurringSeriesCommandProvider extends $FunctionalProvider<
    CreateRecurringSeriesCommand,
    CreateRecurringSeriesCommand,
    CreateRecurringSeriesCommand> with $Provider<CreateRecurringSeriesCommand> {
  CreateRecurringSeriesCommandProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'createRecurringSeriesCommandProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$createRecurringSeriesCommandHash();

  @$internal
  @override
  $ProviderElement<CreateRecurringSeriesCommand> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CreateRecurringSeriesCommand create(Ref ref) {
    return createRecurringSeriesCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateRecurringSeriesCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateRecurringSeriesCommand>(value),
    );
  }
}

String _$createRecurringSeriesCommandHash() =>
    r'9e20733d4a02c6917fb03758a916ba2742aff87a';
