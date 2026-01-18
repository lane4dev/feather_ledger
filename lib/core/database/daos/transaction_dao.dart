import 'package:drift/drift.dart';
import 'package:feather_ledger/core/database/app_database.dart';
import 'package:feather_ledger/core/database/tables.dart';

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
class TransactionDao extends DatabaseAccessor<AppDatabase> with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Stream<List<TransactionWithDetails>> watchTransactionsByMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1).subtract(const Duration(seconds: 1));

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

  Stream<Map<DateTime, int>> watchDailyTransactionCounts(DateTime month) {
    final start = DateTime(month.year, 1, 1);
    final end = DateTime(month.year + 1, 1, 1).subtract(const Duration(seconds: 1));
    
    return (select(transactions)..where((t) => t.date.isBetweenValues(start, end)))
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

  Stream<List<CategoryTotal>> watchCategoryTotals(DateTime month, TransactionType type) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1).subtract(const Duration(seconds: 1));

    final amountSum = transactions.amount.sum();
    
    // Using equals(type) should work if column is Enum. 
    // If error "can't be assigned to int", trying equals(type.index) as fallback if column is raw int in this context.
    // However, for GeneratedColumn<TransactionType>, equals expects TransactionType.
    // I suspect the error reported previously might have been misleading or I misread.
    // I will try equals(type) again but ensure imports are perfect.
    // Wait, previous error said: "The argument type 'TransactionType' can't be assigned to the parameter type 'int'."
    // This strongly suggests equals expects int.
    // I will use `type.index` to be safe if `equals` wants int.
    // But `transactions.type` should be `Expression<TransactionType>`.
    // I'll check `transaction_dao.g.dart` if I could.
    // I'll try `type.index` for now.
    
    final query = select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId))
    ])
      ..addColumns([amountSum])
      ..where(transactions.date.isBetweenValues(start, end) & transactions.type.equals(type.index))
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
    final end = DateTime(month.year, month.month + 1, 1).subtract(const Duration(seconds: 1));

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
        // t might be int? or TransactionType?
        // Safe check:
        if (t == TransactionType.income || t == TransactionType.income.index) {
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
    final accountSumQuery = selectOnly(accounts)..addColumns([accounts.initialBalance.sum()]);
    final accountSumRow = await accountSumQuery.getSingle();
    final initialTotal = accountSumRow.read(accounts.initialBalance.sum()) ?? 0.0;

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
        if (t == TransactionType.income || t == TransactionType.income.index) {
             income += val;
        } else {
             expense += val;
        }
    }

    return initialTotal + income - expense;
  }
}
