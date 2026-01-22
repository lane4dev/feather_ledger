import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';

import 'package:feather_ledger/core/database/app_database.dart';
import 'package:feather_ledger/core/database/daos/transaction_dao.dart';
import 'package:feather_ledger/core/database/tables.dart' as db_tables;
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

part 'category_repository.g.dart';

abstract class CategoryRepository {
  Stream<List<CategoryEntity>> watchCategories(db_tables.TransactionType type);
  Future<void> addCategory({
    required String name,
    required String iconKey,
    required int colorInt,
    required db_tables.TransactionType type,
  });
  Future<void> updateCategory({
    required int id,
    required String name,
    required String iconKey,
    required int colorInt,
    required db_tables.TransactionType type,
  });
  Future<void> deleteCategory(int id);
}

class CategoryRepositoryImpl implements CategoryRepository {
  final TransactionDao _dao;

  CategoryRepositoryImpl(this._dao);

  @override
  Stream<List<CategoryEntity>> watchCategories(db_tables.TransactionType type) {
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
    required db_tables.TransactionType type,
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
    required db_tables.TransactionType type,
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
