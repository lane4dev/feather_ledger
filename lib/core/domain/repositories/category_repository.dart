import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';

abstract class CategoryRepository {
  /// Watches all categories of a given [type].
  /// Returns a stream of lists of [CategoryEntity].
  Stream<List<CategoryEntity>> watchCategories(TransactionType type);

  /// Retrieves a category by its [id].
  /// Returns a [Future] that completes with the [CategoryEntity] or null if not
  /// found.
  Future<CategoryEntity?> getCategory(String id);

  /// Adds a new category with the given parameters.
  /// Returns a [Future] that completes when the operation is done.
  Future<void> addCategory(CategoryEntity category);

  /// Updates an existing category identified by [id] with the given parameters.
  /// Returns a [Future] that completes when the operation is done.
  Future<void> updateCategory(CategoryEntity category);

  /// Deletes the category identified by [id].
  /// Returns a [Future] that completes when the operation is done.
  /// Deletes the category identified by [id].
  Future<void> deleteCategory(String id);

  /// Retrieves a category by its system code.
  Future<CategoryEntity?> getBySystemCode(String code);

  /// Retrieves a built-in reversal category by its localized name and type.
  Future<CategoryEntity?> getReversalCategory(
      TransactionType type, String localizedName);
}
