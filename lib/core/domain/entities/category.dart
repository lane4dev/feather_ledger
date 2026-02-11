import 'package:feather_ledger/core/domain/enums.dart';

class CategoryEntity {
  final String id;
  final String name;
  final String iconKey;
  final int colorInt;
  final TransactionType type;
  final bool isDefault;
  final bool isBuildIn;
  final String? systemCode;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorInt,
    required this.type,
    required this.isDefault,
    this.isBuildIn = false,
    this.systemCode,
  });
}
