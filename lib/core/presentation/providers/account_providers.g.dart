// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(accountList)
final accountListProvider = AccountListProvider._();

final class AccountListProvider extends $FunctionalProvider<
        AsyncValue<List<AccountEntity>>,
        List<AccountEntity>,
        Stream<List<AccountEntity>>>
    with
        $FutureModifier<List<AccountEntity>>,
        $StreamProvider<List<AccountEntity>> {
  AccountListProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'accountListProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$accountListHash();

  @$internal
  @override
  $StreamProviderElement<List<AccountEntity>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<AccountEntity>> create(Ref ref) {
    return accountList(ref);
  }
}

String _$accountListHash() => r'd1561cdbf3c899355572ad145962baa644cacf68';

/// The same accounts, with their balances written out.
///
/// The row a screen builds should not be the thing that knows what an amount
/// is; this is the seam where the entity becomes something printable, and
/// both the ledger's picker and the management screen read it.

@ProviderFor(accountUiList)
final accountUiListProvider = AccountUiListProvider._();

/// The same accounts, with their balances written out.
///
/// The row a screen builds should not be the thing that knows what an amount
/// is; this is the seam where the entity becomes something printable, and
/// both the ledger's picker and the management screen read it.

final class AccountUiListProvider extends $FunctionalProvider<
        AsyncValue<List<AccountUiModel>>,
        AsyncValue<List<AccountUiModel>>,
        AsyncValue<List<AccountUiModel>>>
    with $Provider<AsyncValue<List<AccountUiModel>>> {
  /// The same accounts, with their balances written out.
  ///
  /// The row a screen builds should not be the thing that knows what an amount
  /// is; this is the seam where the entity becomes something printable, and
  /// both the ledger's picker and the management screen read it.
  AccountUiListProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'accountUiListProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$accountUiListHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<AccountUiModel>>> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AsyncValue<List<AccountUiModel>> create(Ref ref) {
    return accountUiList(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<AccountUiModel>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<List<AccountUiModel>>>(value),
    );
  }
}

String _$accountUiListHash() => r'd4abe94edd9dd3d40f66c936e7f6fba46468f3b7';
