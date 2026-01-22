import 'package:feather_ledger/core/domain/entities/category.dart';

class ReportCategoryTotal {
  final CategoryEntity category;
  final double total;

  const ReportCategoryTotal({required this.category, required this.total});
}
