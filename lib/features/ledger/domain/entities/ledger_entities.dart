import 'package:feather_ledger/core/domain/entities/enums.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';

class TransactionEntity {
  final int id;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String? note;
  final CategoryEntity category;
  final AccountEntity account;

  const TransactionEntity({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
    required this.category,
    required this.account,
  });
}

class MonthlySummary {
  final DateTime month;
  final double totalIncome;
  final double totalExpense;
  final double runningBalance;

  const MonthlySummary({
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.runningBalance,
  });
}
