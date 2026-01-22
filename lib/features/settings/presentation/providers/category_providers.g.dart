// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$categoryListHash() => r'859aa22ca3f051ab49050264d009ef8fe0ece03b';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [categoryList].
@ProviderFor(categoryList)
const categoryListProvider = CategoryListFamily();

/// See also [categoryList].
class CategoryListFamily extends Family<AsyncValue<List<CategoryEntity>>> {
  /// See also [categoryList].
  const CategoryListFamily();

  /// See also [categoryList].
  CategoryListProvider call(
    TransactionType type,
  ) {
    return CategoryListProvider(
      type,
    );
  }

  @override
  CategoryListProvider getProviderOverride(
    covariant CategoryListProvider provider,
  ) {
    return call(
      provider.type,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'categoryListProvider';
}

/// See also [categoryList].
class CategoryListProvider
    extends AutoDisposeStreamProvider<List<CategoryEntity>> {
  /// See also [categoryList].
  CategoryListProvider(
    TransactionType type,
  ) : this._internal(
          (ref) => categoryList(
            ref as CategoryListRef,
            type,
          ),
          from: categoryListProvider,
          name: r'categoryListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$categoryListHash,
          dependencies: CategoryListFamily._dependencies,
          allTransitiveDependencies:
              CategoryListFamily._allTransitiveDependencies,
          type: type,
        );

  CategoryListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.type,
  }) : super.internal();

  final TransactionType type;

  @override
  Override overrideWith(
    Stream<List<CategoryEntity>> Function(CategoryListRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CategoryListProvider._internal(
        (ref) => create(ref as CategoryListRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        type: type,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<CategoryEntity>> createElement() {
    return _CategoryListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CategoryListProvider && other.type == type;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, type.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CategoryListRef on AutoDisposeStreamProviderRef<List<CategoryEntity>> {
  /// The parameter `type` of this provider.
  TransactionType get type;
}

class _CategoryListProviderElement
    extends AutoDisposeStreamProviderElement<List<CategoryEntity>>
    with CategoryListRef {
  _CategoryListProviderElement(super.provider);

  @override
  TransactionType get type => (origin as CategoryListProvider).type;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
