import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:feather_ledger/core/database/tables.dart';
import 'package:feather_ledger/features/settings/data/repositories/category_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

part 'category_providers.g.dart';

@riverpod
Stream<List<CategoryEntity>> categoryList(Ref ref, TransactionType type) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.watchCategories(type);
}
