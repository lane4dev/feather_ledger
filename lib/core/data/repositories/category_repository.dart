import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/categories_dao.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/repositories/category_repository.dart';
import 'package:feather_ledger/core/domain/enums.dart';

export 'package:feather_ledger/core/domain/repositories/category_repository.dart';

part 'category_repository.g.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoriesDao _dao;

  CategoryRepositoryImpl(this._dao);

  @override
  Stream<List<CategoryEntity>> watchCategories(CategoryType type) {
    return _dao.watchCategoriesByType(type).map((rows) {
      return rows.map(_toEntity).toList();
    });
  }

  @override
  Future<CategoryEntity?> getCategory(String id) async {
    final row = await _dao.getCategoryById(id);
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<CategoryEntity?> getBySystemCode(String code) async {
    final categories = await _dao.getAllCategories();
    final match = categories.where((c) => c.systemCode == code).firstOrNull;
    return match == null ? null : _toEntity(match);
  }

  CategoryEntity _toEntity(CategoryViewRow row) => CategoryEntity(
        id: row.id,
        name: row.name,
        iconKey: row.iconKey,
        colorInt: row.colorInt,
        type: row.type,
        archived: row.archived,
        systemCode: row.systemCode,
      );
}

@riverpod
CategoryRepository categoryRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return CategoryRepositoryImpl(db.categoriesDao);
}
