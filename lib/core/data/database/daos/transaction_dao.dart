import 'package:drift/drift.dart';

import 'package:feather_ledger/core/domain/enums.dart';

import '../app_database.dart';
import '../tables.dart';

part 'transaction_dao.g.dart';

class TransactionWithDetails {
  final TransactionViewRow transaction;
  final CategoryRow category;
  final AccountViewRow account;

  TransactionWithDetails(this.transaction, this.category, this.account);
}

class CategoryTotal {
  final CategoryRow category;
  final int total;

  CategoryTotal({required this.category, required this.total});
}

@DriftAccessor(tables: [TransactionsView, Categories, AccountsView])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Stream<List<TransactionWithDetails>> watchTransactionsByMonth(
      DateTime datetime) {
    final start = DateTime(datetime.year, datetime.month, 1);
    final end = DateTime(datetime.year, datetime.month + 1, 1)
        .subtract(const Duration(seconds: 1));

    final query = select(transactionsView).join([
      innerJoin(
          categories, categories.id.equalsExp(transactionsView.categoryId)),
      innerJoin(
          accountsView, accountsView.id.equalsExp(transactionsView.accountId)),
    ])
      ..where(transactionsView.date.isBetweenValues(start, end))
      ..orderBy([OrderingTerm.desc(transactionsView.date)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TransactionWithDetails(
          row.readTable(transactionsView),
          row.readTable(categories),
          row.readTable(accountsView),
        );
      }).toList();
    });
  }

  Future<TransactionWithDetails?> getTransaction(String id) async {
    final query = select(transactionsView).join([
      innerJoin(
          categories, categories.id.equalsExp(transactionsView.categoryId)),
      innerJoin(
          accountsView, accountsView.id.equalsExp(transactionsView.accountId)),
    ])
      ..where(transactionsView.transactionId.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return TransactionWithDetails(
      row.readTable(transactionsView),
      row.readTable(categories),
      row.readTable(accountsView),
    );
  }

  Future<void> insertOrReplace(TransactionsViewCompanion transaction) {
    return into(transactionsView).insertOnConflictUpdate(transaction);
  }

  Future<int> deleteTransaction(String id) {
    return (delete(transactionsView)..where((t) => t.id.equals(id))).go();
  }

  Future<void> markTransactionAsReversed(String transactionId) async {
    await (update(transactionsView)
          ..where((t) => t.transactionId.equals(transactionId)))
        .write(
      const TransactionsViewCompanion(isReversed: Value(true)),
    );
  }

  Future<List<CategoryRow>> getAllCategories() => select(categories).get();
  Future<List<AccountViewRow>> getAllAccounts() => select(accountsView).get();

  // Category Access
  Future<CategoryRow?> getCategoryById(String id) {
    return (select(categories)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> addCategory(CategoriesCompanion entry) async {
    if (entry.isBuildIn.value == true) {
      throw ArgumentError('Cannot add a built-in category via addCategory.');
    }
    await into(categories).insert(entry);
  }

  Future<void> updateCategory(CategoriesCompanion entry) async {
    final existingCategory = await (select(categories)
          ..where((c) => c.id.equals(entry.id.value)))
        .getSingleOrNull();
    if (existingCategory != null && existingCategory.isBuildIn) {
      throw ArgumentError('Cannot update a built-in category.');
    }
    await (update(categories)..where((t) => t.id.equals(entry.id.value)))
        .write(entry);
  }

  Future<void> archiveCategory(String id) async {
    final existingCategory = await (select(categories)
          ..where((c) => c.id.equals(id)))
        .getSingleOrNull();
    if (existingCategory != null && existingCategory.isBuildIn) {
      throw ArgumentError('Cannot archive a built-in category.');
    }
    await (update(categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        isArchived: const Value(true),
        archivedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<List<CategoryRow>> watchCategoriesByType(TransactionType type) {
    // Filter out archived and built-in categories
    return (select(categories)
          ..where((c) =>
              c.type.equals(type.index) &
              c.isArchived.equals(false) &
              c.isBuildIn.equals(false)))
        .watch();
  }

  Stream<Map<DateTime, int>> watchDailyTransactionAmounts(DateTime datetime) {
    final start = DateTime(datetime.year, datetime.month - 2, 1);
    final end = DateTime(datetime.year, datetime.month + 1, 1)
        .subtract(const Duration(seconds: 1));

    return (select(transactionsView)
          ..where((t) =>
              t.date.isBetweenValues(start, end) & t.isReversed.equals(false)))
        .watch()
        .map((rows) {
      final map = <DateTime, int>{};
      for (var row in rows) {
        final day = DateTime(row.date.year, row.date.month, row.date.day);
        map[day] = (map[day] ?? 0) + row.amount;
      }
      return map;
    });
  }

  Stream<List<CategoryTotal>> watchCategoryTotals(
      DateTime datetime, TransactionType type) {
    final start = DateTime(datetime.year, datetime.month, 1);
    final end = DateTime(datetime.year, datetime.month + 1, 1)
        .subtract(const Duration(seconds: 1));

    final amountSum = transactionsView.amount.sum();

    // Determine implied type based on amount sign or explicitly join categories
    // MVP: Positive = Income, Negative = Expense? Or use Category Type?
    // Using Category Type filter as per original logic.

    final query = select(transactionsView).join([
      innerJoin(
          categories, categories.id.equalsExp(transactionsView.categoryId))
    ])
      ..addColumns([amountSum])
      ..where(transactionsView.date.isBetweenValues(start, end) &
          categories.type.equals(type.index) &
          transactionsView.isReversed.equals(false))
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

  Stream<Map<String, double>> watchMonthlyTotals(DateTime datetime) {
    final start = DateTime(datetime.year, datetime.month, 1);
    final end = DateTime(datetime.year, datetime.month + 1, 1)
        .subtract(const Duration(seconds: 1));

    final amountSum = transactionsView.amount.sum();
    final type = categories.type;

    final query = select(transactionsView).join([
      innerJoin(
          categories, categories.id.equalsExp(transactionsView.categoryId)),
      innerJoin(
          accountsView, accountsView.id.equalsExp(transactionsView.accountId)),
    ])
      ..addColumns([amountSum, type])
      ..where(transactionsView.date.isBetweenValues(start, end) &
          transactionsView.isReversed.equals(false))
      ..groupBy([type]);

    return query.watch().map((rows) {
      double totalIncome = 0;
      double totalExpense = 0;

      for (var row in rows) {
        final amount = row.read(amountSum) ?? 0;
        final categoryRow = row.readTable(categories);
        if (categoryRow.type == TransactionType.income) {
          totalIncome += amount;
        } else {
          totalExpense += amount;
        }
      }

      return {
        'income': totalIncome / 100.0,
        'expense': totalExpense / 100.0,
      };
    });
  }

  Future<double> getRunningBalance(DateTime dateEnd) async {
    // Base total from AccountsView (seed/initial balance in current MVP)
    final accountSumQuery = selectOnly(accountsView)
      ..addColumns([accountsView.postedBalance.sum()]);
    final accountSumRow = await accountSumQuery.getSingle();
    final currentTotal =
        accountSumRow.read(accountsView.postedBalance.sum()) ?? 0;

    // Apply all transactions up to and including dateEnd
    // final txSumQuery = selectOnly(transactionsView)
    //   ..addColumns([transactionsView.amount.sum()])
    //   ..where(transactionsView.date.isSmallerOrEqualValue(dateEnd) &
    //       transactionsView.isReversed.equals(false));

    // final txRow = await txSumQuery.getSingle();
    // final txSumToMonthEnd = txRow.read(transactionsView.amount.sum()) ?? 0;

    return (currentTotal).toDouble();
  }
}
