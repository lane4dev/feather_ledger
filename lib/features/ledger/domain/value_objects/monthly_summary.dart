class MonthlySummary {
  final DateTime datetime;
  final double totalIncome;
  final double totalExpense;
  final double runningBalance;

  const MonthlySummary({
    required this.datetime,
    required this.totalIncome,
    required this.totalExpense,
    required this.runningBalance,
  });
}
