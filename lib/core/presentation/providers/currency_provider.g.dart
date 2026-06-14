// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currency_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CurrencyController)
final currencyControllerProvider = CurrencyControllerProvider._();

final class CurrencyControllerProvider
    extends $AsyncNotifierProvider<CurrencyController, String> {
  CurrencyControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'currencyControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currencyControllerHash();

  @$internal
  @override
  CurrencyController create() => CurrencyController();
}

String _$currencyControllerHash() =>
    r'aeda4d681144994436db730da771396e129be008';

abstract class _$CurrencyController extends $AsyncNotifier<String> {
  FutureOr<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String>, String>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<String>, String>,
        AsyncValue<String>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
