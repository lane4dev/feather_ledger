// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_account_by_id_query.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(getAccountByIdQuery)
final getAccountByIdQueryProvider = GetAccountByIdQueryProvider._();

final class GetAccountByIdQueryProvider extends $FunctionalProvider<
    GetAccountByIdQuery,
    GetAccountByIdQuery,
    GetAccountByIdQuery> with $Provider<GetAccountByIdQuery> {
  GetAccountByIdQueryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'getAccountByIdQueryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$getAccountByIdQueryHash();

  @$internal
  @override
  $ProviderElement<GetAccountByIdQuery> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetAccountByIdQuery create(Ref ref) {
    return getAccountByIdQuery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetAccountByIdQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetAccountByIdQuery>(value),
    );
  }
}

String _$getAccountByIdQueryHash() =>
    r'a249c282db4a1435c3a1f987bbb303f36ccbc659';
