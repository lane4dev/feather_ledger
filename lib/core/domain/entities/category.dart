import 'package:feather_ledger/core/domain/entities/enums.dart';

class CategoryEntity {
  final int id;
  final String name;
  final String iconKey;
  final int colorInt;
  final TransactionType type;
  final bool isDefault;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorInt,
    required this.type,
    required this.isDefault,
  });
}
