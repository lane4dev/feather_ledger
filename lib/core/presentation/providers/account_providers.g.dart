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
