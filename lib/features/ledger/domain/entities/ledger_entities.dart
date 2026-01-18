import '../../../../core/database/tables.dart';

class AccountEntity {
  final int id;
  final String name;
  final AccountType type;
  final double initialBalance;

  const AccountEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
  });
}

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
