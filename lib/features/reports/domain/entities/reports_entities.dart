import 'package:feather_ledger/core/domain/entities/category.dart';

/// One category bucket of the monthly pie breakdown (spec 003, US9/T064).
/// [category] carries the transaction row's write-time snapshot — archived
/// categories keep showing in history. [totalMinor] is how much moved in that
/// category, in int minor units, **always positive**: the bucket is a
/// magnitude and the kind decides which breakdown it appears in.
class ReportCategoryTotal {
  final CategoryEntity category;
  final int totalMinor;

  const ReportCategoryTotal({
    required this.category,
    required this.totalMinor,
  });
}

/// Monthly totals read from the snapshot projection (spec 003, US9).
/// [balanceMinor] is the month-end closing balance across accounts — which is
/// this screen's figure and not the ledger header's: the header's balance is
/// the ledger's running total, the same number whatever month is selected.
/// Income and expense are the same on both screens.
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
