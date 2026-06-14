// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_visibility_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BalanceVisibilityController)
final balanceVisibilityControllerProvider =
    BalanceVisibilityControllerProvider._();

final class BalanceVisibilityControllerProvider
    extends $AsyncNotifierProvider<BalanceVisibilityController, bool> {
  BalanceVisibilityControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'balanceVisibilityControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$balanceVisibilityControllerHash();

  @$internal
  @override
  BalanceVisibilityController create() => BalanceVisibilityController();
}

String _$balanceVisibilityControllerHash() =>
    r'8d0a0f30e6298e0e53c89a517c81600720e90ccf';

abstract class _$BalanceVisibilityController extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<bool>, bool>,
        AsyncValue<bool>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
