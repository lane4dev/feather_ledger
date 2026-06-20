// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'posting_context.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(postingContextResolver)
final postingContextResolverProvider = PostingContextResolverProvider._();

final class PostingContextResolverProvider extends $FunctionalProvider<
    PostingContextResolver,
    PostingContextResolver,
    PostingContextResolver> with $Provider<PostingContextResolver> {
  PostingContextResolverProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'postingContextResolverProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$postingContextResolverHash();

  @$internal
  @override
  $ProviderElement<PostingContextResolver> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PostingContextResolver create(Ref ref) {
    return postingContextResolver(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostingContextResolver value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostingContextResolver>(value),
    );
  }
}

String _$postingContextResolverHash() =>
    r'7a5f92c8e15217f4c9ca63d4a632190041912cee';
