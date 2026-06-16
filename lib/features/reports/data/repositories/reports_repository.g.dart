// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reportsRepository)
final reportsRepositoryProvider = ReportsRepositoryProvider._();

final class ReportsRepositoryProvider extends $FunctionalProvider<
    ReportsRepository,
    ReportsRepository,
    ReportsRepository> with $Provider<ReportsRepository> {
  ReportsRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'reportsRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$reportsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReportsRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReportsRepository create(Ref ref) {
    return reportsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReportsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReportsRepository>(value),
    );
  }
}

String _$reportsRepositoryHash() => r'b2a75a2f8cf5e24d0b419f06872134ffe6e6d497';
