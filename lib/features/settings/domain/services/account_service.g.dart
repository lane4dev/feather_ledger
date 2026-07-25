// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(accountService)
final accountServiceProvider = AccountServiceProvider._();

final class AccountServiceProvider
    extends $FunctionalProvider<AccountService, AccountService, AccountService>
    with $Provider<AccountService> {
  AccountServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'accountServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$accountServiceHash();

  @$internal
  @override
  $ProviderElement<AccountService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AccountService create(Ref ref) {
    return accountService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountService>(value),
    );
  }
}

String _$accountServiceHash() => r'779ae0d6d6251fa6e612614f5f2fec8a39e2a519';
