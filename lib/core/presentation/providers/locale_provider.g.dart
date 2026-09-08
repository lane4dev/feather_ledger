// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LocaleController)
final localeControllerProvider = LocaleControllerProvider._();

final class LocaleControllerProvider
    extends $AsyncNotifierProvider<LocaleController, Locale?> {
  LocaleControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'localeControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$localeControllerHash();

  @$internal
  @override
  LocaleController create() => LocaleController();
}

String _$localeControllerHash() => r'824652af124d5aed46e72575e39e12a13800f173';

abstract class _$LocaleController extends $AsyncNotifier<Locale?> {
  FutureOr<Locale?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Locale?>, Locale?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<Locale?>, Locale?>,
        AsyncValue<Locale?>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
