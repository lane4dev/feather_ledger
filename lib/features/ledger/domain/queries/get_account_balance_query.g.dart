// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_account_balance_query.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(getAccountBalanceQuery)
final getAccountBalanceQueryProvider = GetAccountBalanceQueryProvider._();

final class GetAccountBalanceQueryProvider extends $FunctionalProvider<
    GetAccountBalanceQuery,
    GetAccountBalanceQuery,
    GetAccountBalanceQuery> with $Provider<GetAccountBalanceQuery> {
  GetAccountBalanceQueryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'getAccountBalanceQueryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$getAccountBalanceQueryHash();

  @$internal
  @override
  $ProviderElement<GetAccountBalanceQuery> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetAccountBalanceQuery create(Ref ref) {
    return getAccountBalanceQuery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetAccountBalanceQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetAccountBalanceQuery>(value),
    );
  }
}

String _$getAccountBalanceQueryHash() =>
    r'0c246e1c266a05924beb37fcf0ba6c44970b074a';
