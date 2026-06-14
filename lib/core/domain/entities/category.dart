import 'package:feather_ledger/core/domain/enums.dart';

/// Category projection entity (spec 003, US3). [systemCode] is non-null for
/// the two built-in system categories (fixed ids, cannot be archived).
class CategoryEntity {
  final String id;
  final String name;
  final String iconKey;
  final int colorInt;
  final CategoryType type;
  final bool archived;
  final String? systemCode;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorInt,
    required this.type,
    this.archived = false,
    this.systemCode,
  });
}
