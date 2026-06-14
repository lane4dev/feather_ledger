import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';

/// Read model for the event-sourced `categories_view` projection. Writes go
/// through the category commands (spec 003, US3/T028).
abstract class CategoryRepository {
  /// Watches non-archived, non-system categories of a given [type]
  /// (picker view; archived and system rows are retained in the
  /// projection but not offered here).
  Stream<List<CategoryEntity>> watchCategories(CategoryType type);

  /// Retrieves a category by its [id], or null if not found.
  Future<CategoryEntity?> getCategory(String id);

  /// Retrieves a built-in system category by its [code].
  Future<CategoryEntity?> getBySystemCode(String code);
}
