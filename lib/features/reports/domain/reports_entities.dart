import '../../ledger/domain/entities/ledger_entities.dart';

class ReportCategoryTotal {
  final CategoryEntity category;
  final double total;

  const ReportCategoryTotal({required this.category, required this.total});
}
