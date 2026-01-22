import 'package:drift/drift.dart';

import '../../../domain/entities/enums.dart';
import '../app_database.dart';
import '../tables.dart';

part 'transaction_dao.g.dart';

class TransactionWithDetails {
  final Transaction transaction;
  final Category category;
  final Account account;

  TransactionWithDetails(this.transaction, this.category, this.account);
}

class CategoryTotal {
  final Category category;
  final double total;

  CategoryTotal({required this.category, required this.total});
}

@DriftAccessor(tables: [Transactions, Categories, Accounts])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Stream<List<TransactionWithDetails>> watchTransactionsByMonth(
      DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1)
        .subtract(const Duration(seconds: 1));

    final query = select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId)),
      innerJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
    ])
      ..where(transactions.date.isBetweenValues(start, end))
      ..orderBy([OrderingTerm.desc(transactions.date)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TransactionWithDetails(
          row.readTable(transactions),
          row.readTable(categories),
          row.readTable(accounts),
        );
      }).toList();
    });
  }

  Future<int> addTransaction(TransactionsCompanion entry) {
    return into(transactions).insert(entry);
  }

  Future<bool> updateTransaction(TransactionsCompanion entry) {
    return update(transactions).replace(entry);
  }

  Future<int> deleteTransaction(int id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  Future<List<Category>> getAllCategories() => select(categories).get();
  Future<List<Account>> getAllAccounts() => select(accounts).get();

  // Category CRUD
  Future<int> addCategory(CategoriesCompanion entry) {
    return into(categories).insert(entry);
  }

  Future<bool> updateCategory(CategoriesCompanion entry) {
    return update(categories).replace(entry);
  }

  Future<int> deleteCategory(int id) {
    return (delete(categories)..where((c) => c.id.equals(id))).go();
  }

  Stream<List<Category>> watchCategoriesByType(TransactionType type) {
    return (select(categories)..where((c) => c.type.equals(type.index)))
        .watch();
  }

  Stream<Map<DateTime, int>> watchDailyTransactionCounts(DateTime month) {
    final start = DateTime(month.year, month.month - 2, 1);
    final end = DateTime(month.year, month.month + 1, 1)
        .subtract(const Duration(seconds: 1));

    return (select(transactions)
          ..where((t) => t.date.isBetweenValues(start, end)))
        .watch()
        .map((rows) {
      final map = <DateTime, int>{};
      for (var row in rows) {
        final day = DateTime(row.date.year, row.date.month, row.date.day);
        map[day] = (map[day] ?? 0) + 1;
      }
      return map;
    });
  }

  Stream<Map<DateTime, int>> watchDailyTransactionAmounts(DateTime month) {
    final start = DateTime(month.year, month.month - 2, 1);
    final end = DateTime(month.year, month.month + 1, 1)
        .subtract(const Duration(seconds: 1));

    return (select(transactions)
          ..where((t) => t.date.isBetweenValues(start, end)))
        .watch()
        .map((rows) {
      final map = <DateTime, int>{};
      for (var row in rows) {
        final day = DateTime(row.date.year, row.date.month, row.date.day);
        // Accumulate amount, rounded to nearest integer for heatmap intensity
        map[day] = (map[day] ?? 0) + row.amount.round();
      }
      return map;
    });
  }

  Stream<List<CategoryTotal>> watchCategoryTotals(
      DateTime month, TransactionType type) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1)
        .subtract(const Duration(seconds: 1));

    final amountSum = transactions.amount.sum();

    final query = select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId))
    ])
      ..addColumns([amountSum])
      ..where(transactions.date.isBetweenValues(start, end) &
          transactions.type.equals(type.index))
      ..groupBy([categories.id]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return CategoryTotal(
          category: row.readTable(categories),
          total: row.read(amountSum) ?? 0,
        );
      }).toList();
    });
  }

  Stream<Map<String, double>> watchMonthlyTotals(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1)
        .subtract(const Duration(seconds: 1));

    final income = transactions.amount.sum();
    final type = transactions.type;

    final query = selectOnly(transactions)
      ..addColumns([income, type])
      ..where(transactions.date.isBetweenValues(start, end))
      ..groupBy([type]);

    return query.watch().map((rows) {
      double totalIncome = 0;
      double totalExpense = 0;

      for (var row in rows) {
        final amount = row.read(income) ?? 0;
        final t = row.read(type);
        if (t == TransactionType.income.index) {
          totalIncome += amount;
        } else {
          totalExpense += amount;
        }
      }

      return {
        'income': totalIncome,
        'expense': totalExpense,
      };
    });
  }

  Future<double> getRunningBalance(DateTime monthEnd) async {
    final accountSumQuery = selectOnly(accounts)
      ..addColumns([accounts.initialBalance.sum()]);
    final accountSumRow = await accountSumQuery.getSingle();
    final initialTotal =
        accountSumRow.read(accounts.initialBalance.sum()) ?? 0.0;

    final txSumQuery = selectOnly(transactions)
      ..addColumns([transactions.amount.sum(), transactions.type])
      ..where(transactions.date.isSmallerOrEqualValue(monthEnd))
      ..groupBy([transactions.type]);

    final txRows = await txSumQuery.get();

    double income = 0;
    double expense = 0;

    for (var row in txRows) {
      final val = row.read(transactions.amount.sum()) ?? 0;
      final t = row.read(transactions.type);
      if (t == TransactionType.income.index) {
        income += val;
      } else {
        expense += val;
      }
    }

    return initialTotal + income - expense;
  }
}
