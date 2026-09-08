import 'package:feather_ledger/core/domain/entities/category.dart';

/// One category bucket of the monthly pie breakdown (spec 003, US9/T064).
/// [category] carries the transaction row's write-time snapshot — archived
/// categories keep showing in history. [totalMinor] is the signed posting
/// impact in int minor units (expense negative).
class ReportCategoryTotal {
  final CategoryEntity category;
  final int totalMinor;

  const ReportCategoryTotal({
    required this.category,
    required this.totalMinor,
  });
}

/// Monthly totals read from the snapshot projection — the same source the
/// ledger header uses (spec 003, US9 同源). [balanceMinor] is the month-end
/// closing balance across accounts.
class ReportMonthlyTotals {
  final int incomeMinor;
  final int expenseMinor;
  final int balanceMinor;

  const ReportMonthlyTotals({
    required this.incomeMinor,
    required this.expenseMinor,
    required this.balanceMinor,
  });
}
