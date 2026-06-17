import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/data/repositories/category_repository.dart';

import '../commands/create_category_command.dart';
import '../commands/rename_category_command.dart';
import '../commands/archive_category_command.dart';

part 'category_service.g.dart';

/// Category lifecycle facade (spec 003, US3): the UI's single entry point —
/// writes go through the event commands, reads through the projection
/// repository.
class CategoryService {
  final CreateCategoryCommand _createCategoryCommand;
  final RenameCategoryCommand _renameCategoryCommand;
  final ArchiveCategoryCommand _archiveCategoryCommand;
  final CategoryRepository _categoryRepository;

  CategoryService(
    this._createCategoryCommand,
    this._renameCategoryCommand,
    this._archiveCategoryCommand,
    this._categoryRepository,
  );

  Future<Result<void>> createCategory({
    required String commandId,
    String? categoryId,
    required String name,
    required String iconKey,
    required int colorInt,
    required CategoryType type,
    String? systemCode,
  }) {
    return guard(() => _createCategoryCommand.execute(
        commandId: commandId,
        categoryId: categoryId,
        name: name,
        iconKey: iconKey,
        colorInt: colorInt,
        type: type,
        systemCode: systemCode));
  }

  Future<Result<void>> renameCategory({
    required String commandId,
    required String categoryId,
    required String name,
  }) {
    return guard(() => _renameCategoryCommand.execute(
        commandId: commandId, categoryId: categoryId, name: name));
  }

  Future<Result<void>> archiveCategory({
    required String commandId,
    required String categoryId,
  }) {
    return guard(() => _archiveCategoryCommand.execute(
        commandId: commandId, categoryId: categoryId));
  }

  Stream<List<CategoryEntity>> watchCategories(CategoryType type) {
    return _categoryRepository.watchCategories(type);
  }
}

@riverpod
CategoryService categoryService(Ref ref) {
  return CategoryService(
    ref.watch(createCategoryCommandProvider),
    ref.watch(renameCategoryCommandProvider),
    ref.watch(archiveCategoryCommandProvider),
    ref.watch(categoryRepositoryProvider),
  );
}
