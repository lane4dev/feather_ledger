import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/transaction_dao.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/repositories/category_repository.dart';
import 'package:feather_ledger/core/domain/enums.dart';

export 'package:feather_ledger/core/domain/repositories/category_repository.dart';

part 'category_repository.g.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final TransactionsDao _dao;

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
          isBuildIn: row.isBuildIn,
          systemCode: row.systemCode,
        );
      }).toList();
    });
  }

  @override
  Future<CategoryEntity?> getCategory(String id) async {
    final row = await _dao.getCategoryById(id);
    if (row == null) return null;
    return CategoryEntity(
      id: row.id,
      name: row.name,
      iconKey: row.iconKey,
      colorInt: row.colorInt,
      type: row.type,
      isDefault: row.isDefault,
      isBuildIn: row.isBuildIn,
      systemCode: row.systemCode,
    );
  }

  @override
  Future<void> addCategory(CategoryEntity category) {
    final id = const Uuid().v4();

    return _dao.addCategory(CategoriesCompanion(
      id: Value(id),
      name: Value(category.name),
      iconKey: Value(category.iconKey),
      colorInt: Value(category.colorInt),
      type: Value(category.type),
      isDefault: const Value(false),
      isArchived: const Value(false),
      isBuildIn: const Value(false),
    ));
  }

  @override
  Future<void> updateCategory(CategoryEntity category) {
    return _dao.updateCategory(CategoriesCompanion(
      id: Value(category.id),
      name: Value(category.name),
      iconKey: Value(category.iconKey),
      colorInt: Value(category.colorInt),
      type: Value(category.type),
    ));
  }

  @override
  Future<void> deleteCategory(String id) {
    return _dao.archiveCategory(id);
  }

  @override
  Future<CategoryEntity?> getBySystemCode(String code) async {
    final categories = await _dao.getAllCategories();
    final match = categories.where((c) => c.systemCode == code).firstOrNull;
    if (match == null) return null;
    return CategoryEntity(
      id: match.id,
      name: match.name,
      iconKey: match.iconKey,
      colorInt: match.colorInt,
      type: match.type,
      isDefault: match.isDefault,
      isBuildIn: match.isBuildIn,
      systemCode: match.systemCode,
    );
  }

  @override
  Future<CategoryEntity?> getReversalCategory(
      TransactionType type, String localizedName) async {
    // Legacy support or specific fallback logic if needed
    final categories = await _dao.getAllCategories();
    // First try to match by name and built-in flag (ideal)
    final match = categories
        .where((c) => c.type == type && c.isBuildIn && c.name == localizedName)
        .firstOrNull;

    if (match != null) {
      return CategoryEntity(
        id: match.id,
        name: match.name,
        iconKey: match.iconKey,
        colorInt: match.colorInt,
        type: match.type,
        isDefault: match.isDefault,
        isBuildIn: match.isBuildIn,
        systemCode: match.systemCode,
      );
    }

    // Fallback: any built-in category of that type
    final fallback =
        categories.where((c) => c.type == type && c.isBuildIn).firstOrNull;

    if (fallback != null) {
      return CategoryEntity(
        id: fallback.id,
        name: fallback.name,
        iconKey: fallback.iconKey,
        colorInt: fallback.colorInt,
        type: fallback.type,
        isDefault: fallback.isDefault,
        isBuildIn: fallback.isBuildIn,
        systemCode: fallback.systemCode,
      );
    }

    return null;
  }
}

@riverpod
CategoryRepository categoryRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return CategoryRepositoryImpl(TransactionsDao(db));
}
