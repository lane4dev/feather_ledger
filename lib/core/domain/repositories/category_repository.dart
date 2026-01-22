import 'package:feather_ledger/core/domain/entities/enums.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';

abstract class CategoryRepository {
  Stream<List<CategoryEntity>> watchCategories(TransactionType type);
  Future<void> addCategory({
    required String name,
    required String iconKey,
    required int colorInt,
    required TransactionType type,
  });
  Future<void> updateCategory({
    required int id,
    required String name,
    required String iconKey,
    required int colorInt,
    required TransactionType type,
  });
  Future<void> deleteCategory(int id);
}
