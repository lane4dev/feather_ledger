// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(categoryList)
final categoryListProvider = CategoryListFamily._();

final class CategoryListProvider extends $FunctionalProvider<
        AsyncValue<List<CategoryEntity>>,
        List<CategoryEntity>,
        Stream<List<CategoryEntity>>>
    with
        $FutureModifier<List<CategoryEntity>>,
        $StreamProvider<List<CategoryEntity>> {
  CategoryListProvider._(
      {required CategoryListFamily super.from,
      required CategoryType super.argument})
      : super(
          retry: null,
          name: r'categoryListProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$categoryListHash();

  @override
  String toString() {
    return r'categoryListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<CategoryEntity>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<CategoryEntity>> create(Ref ref) {
    final argument = this.argument as CategoryType;
    return categoryList(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CategoryListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$categoryListHash() => r'1f148a69c1fb9bb17f7e9741b7a68a54b63432d2';

final class CategoryListFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<CategoryEntity>>, CategoryType> {
  CategoryListFamily._()
      : super(
          retry: null,
          name: r'categoryListProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  CategoryListProvider call(
    CategoryType type,
  ) =>
      CategoryListProvider._(argument: type, from: this);

  @override
  String toString() => r'categoryListProvider';
}
