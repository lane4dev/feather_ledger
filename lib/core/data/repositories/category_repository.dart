import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/transaction_dao.dart';
import 'package:feather_ledger/core/domain/entities/enums.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/repositories/category_repository.dart';

export 'package:feather_ledger/core/domain/repositories/category_repository.dart';

part 'category_repository.g.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final TransactionDao _dao;

  CategoryRepositoryImpl(this._dao);

  @override
  Stream<List<CategoryEntity>> watchCategories(TransactionType type) {
    return _dao.watchCategoriesByType(type).map((rows) {
      return rows.map((row) {
        return CategoryEntity(
          id: row.id,
          name: row.name,
          iconKey: row.iconKey,
          colorInt: row.colorInt,
          type: row.type,
          isDefault: row.isDefault,
        );
      }).toList();
    });
  }

  @override
  Future<void> addCategory({
    required String name,
    required String iconKey,
    required int colorInt,
    required TransactionType type,
  }) {
    return _dao.addCategory(CategoriesCompanion(
      name: Value(name),
      iconKey: Value(iconKey),
      colorInt: Value(colorInt),
      type: Value(type),
      isDefault: const Value(false),
    ));
  }

  @override
  Future<void> updateCategory({
    required int id,
    required String name,
    required String iconKey,
    required int colorInt,
    required TransactionType type,
  }) {
    return _dao.updateCategory(CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      iconKey: Value(iconKey),
      colorInt: Value(colorInt),
      type: Value(type),
    ));
  }

  @override
  Future<void> deleteCategory(int id) {
    return _dao.deleteCategory(id);
  }
}

@riverpod
CategoryRepository categoryRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return CategoryRepositoryImpl(db.transactionDao);
}
