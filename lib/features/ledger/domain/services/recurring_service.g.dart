// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recurringService)
final recurringServiceProvider = RecurringServiceProvider._();

final class RecurringServiceProvider extends $FunctionalProvider<
    RecurringService,
    RecurringService,
    RecurringService> with $Provider<RecurringService> {
  RecurringServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'recurringServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$recurringServiceHash();

  @$internal
  @override
  $ProviderElement<RecurringService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecurringService create(Ref ref) {
    return recurringService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecurringService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecurringService>(value),
    );
  }
}

String _$recurringServiceHash() => r'6bc3bf0b288400e665e7852f547d3d22410704f8';
