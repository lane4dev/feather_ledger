import 'package:drift/drift.dart';

import 'package:feather_ledger/core/domain/enums.dart';

import '../app_database.dart';
import '../tables.dart';

part 'categories_dao.g.dart';

/// Read/write seam for the event-sourced `categories_view` projection
/// (spec 003, US3/T029). Writes come from the ledger projector only;
/// picker reads exclude archived and built-in system categories while the
/// rows themselves are retained for history.
@DriftAccessor(tables: [CategoriesView])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  /// All rows, including archived and system categories (history retained).
  Future<List<CategoryViewRow>> getAllCategories() =>
      select(categoriesView).get();

  Future<CategoryViewRow?> getCategoryById(String id) {
    return (select(categoriesView)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Picker view: excludes archived and built-in system categories.
  Stream<List<CategoryViewRow>> watchCategoriesByType(CategoryType type) {
    return (select(categoriesView)
          ..where((c) =>
              c.type.equals(type.index) &
              c.archived.equals(false) &
              c.systemCode.isNull()))
        .watch();
  }

  /// Projector write seam — the only writer of this projection.
  Future<void> upsert(CategoriesViewCompanion entry) {
    return into(categoriesView).insertOnConflictUpdate(entry);
  }

  /// Projector write seam for existing rows (partial companions — the row
  /// must already exist).
  Future<int> updateRow(CategoriesViewCompanion entry) {
    return (update(categoriesView)..where((c) => c.id.equals(entry.id.value)))
        .write(entry);
  }

  /// Rebuild seam (US8/T057).
  Future<int> clearAll() => delete(categoriesView).go();
}
