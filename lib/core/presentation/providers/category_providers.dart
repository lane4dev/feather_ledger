import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/entities/enums.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/data/repositories/category_repository.dart';

part 'category_providers.g.dart';

@riverpod
Stream<List<CategoryEntity>> categoryList(Ref ref, TransactionType type) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.watchCategories(type);
}
