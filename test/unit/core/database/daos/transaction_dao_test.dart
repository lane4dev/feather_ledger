import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;

import 'package:feather_ledger/core/database/app_database.dart';
import 'package:feather_ledger/core/database/tables.dart';

import '../../../../support/fakes/fake_app_database.dart';

void main() {
  late AppDatabase database;
  late int accountId;
  late int categoryId;

  setUp(() async {
    database = FakeAppDatabase();

    // Create baseline data
    accountId = await database.into(database.accounts).insert(
          AccountsCompanion.insert(
            name: 'Test Account',
            type: AccountType.cash,
            initialBalance: const Value(1000.0),
          ),
        );

    categoryId = await database.into(database.categories).insert(
          CategoriesCompanion.insert(
            name: 'Test Category',
            iconKey: 'test',
            colorInt: 0xFF000000,
            type: TransactionType.expense,
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  group('TransactionDao', () {
    test('should add and update transaction', () async {
      final now = DateTime.now();
      final id = await database.transactionDao.addTransaction(
        TransactionsCompanion.insert(
          amount: 50.0,
          type: TransactionType.expense,
          date: now,
          categoryId: categoryId,
          accountId: accountId,
        ),
      );

      expect(id, greaterThan(0));

      // Drift's replace requires all non-nullable fields without defaults to be present
      await database.transactionDao.updateTransaction(
        TransactionsCompanion(
          id: Value(id),
          amount: const Value(75.0),
          type: const Value(TransactionType.expense),
          date: Value(now),
          categoryId: Value(categoryId),
          accountId: Value(accountId),
        ),
      );

      final retrieved = await (database.select(database.transactions)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      expect(retrieved.amount, equals(75.0));
    });

    test('should delete transaction', () async {
      final id = await database.transactionDao.addTransaction(
        TransactionsCompanion.insert(
          amount: 50.0,
          type: TransactionType.expense,
          date: DateTime.now(),
          categoryId: categoryId,
          accountId: accountId,
        ),
      );

      final deleted = await database.transactionDao.deleteTransaction(id);
      expect(deleted, equals(1));

      final results = await (database.select(database.transactions)
            ..where((t) => t.id.equals(id)))
          .get();
      expect(results, isEmpty);
    });

    test('watchTransactionsByMonth should filter correctly', () async {
      final month = DateTime(2023, 5);

      // Inside May
      await database.transactionDao.addTransaction(
        TransactionsCompanion.insert(
          amount: 10.0,
          type: TransactionType.expense,
          date: DateTime(2023, 5, 15),
          categoryId: categoryId,
          accountId: accountId,
        ),
      );

      // Outside May
      await database.transactionDao.addTransaction(
        TransactionsCompanion.insert(
          amount: 20.0,
          type: TransactionType.expense,
          date: DateTime(2023, 6, 1),
          categoryId: categoryId,
          accountId: accountId,
        ),
      );

      final stream = database.transactionDao.watchTransactionsByMonth(month);
      final list = await stream.first;

      expect(list.length, equals(1));
      expect(list.first.transaction.amount, equals(10.0));
      expect(list.first.account.name, equals('Test Account'));
      expect(list.first.category.name, equals('Test Category'));
    });

    test('watchMonthlyTotals should calculate income and expense', () async {
      final month = DateTime(2023, 5);

      await database.transactionDao.addTransaction(
        TransactionsCompanion.insert(
          amount: 100.0,
          type: TransactionType.income,
          date: DateTime(2023, 5, 10),
          categoryId: categoryId,
          accountId: accountId,
        ),
      );

      await database.transactionDao.addTransaction(
        TransactionsCompanion.insert(
          amount: 40.0,
          type: TransactionType.expense,
          date: DateTime(2023, 5, 12),
          categoryId: categoryId,
          accountId: accountId,
        ),
      );

      final totals =
          await database.transactionDao.watchMonthlyTotals(month).first;
      expect(totals['income'], equals(100.0));
      expect(totals['expense'], equals(40.0));
    });

    test(
        'getRunningBalance should include initial balance and all transactions',
        () async {
      final monthEnd = DateTime(2023, 5, 31);

      // Initial balance of Test Account is 1000.0

      await database.transactionDao.addTransaction(
        TransactionsCompanion.insert(
          amount: 200.0,
          type: TransactionType.income,
          date: DateTime(2023, 5, 10),
          categoryId: categoryId,
          accountId: accountId,
        ),
      );

      await database.transactionDao.addTransaction(
        TransactionsCompanion.insert(
          amount: 50.0,
          type: TransactionType.expense,
          date: DateTime(2023, 5, 12),
          categoryId: categoryId,
          accountId: accountId,
        ),
      );

      final balance = await database.transactionDao.getRunningBalance(monthEnd);
      // 1000 + 200 - 50 = 1150
      expect(balance, equals(1150.0));
    });

    test('watchCategoryTotals should group correctly', () async {
      final month = DateTime(2023, 5);

      final category2Id = await database.into(database.categories).insert(
            CategoriesCompanion.insert(
              name: 'Cat 2',
              iconKey: '2',
              colorInt: 0,
              type: TransactionType.expense,
            ),
          );

      await database.transactionDao.addTransaction(
        TransactionsCompanion.insert(
          amount: 30.0,
          type: TransactionType.expense,
          date: DateTime(2023, 5, 5),
          categoryId: categoryId,
          accountId: accountId,
        ),
      );

      await database.transactionDao.addTransaction(
        TransactionsCompanion.insert(
          amount: 20.0,
          type: TransactionType.expense,
          date: DateTime(2023, 5, 6),
          categoryId: categoryId,
          accountId: accountId,
        ),
      );

      await database.transactionDao.addTransaction(
        TransactionsCompanion.insert(
          amount: 100.0,
          type: TransactionType.expense,
          date: DateTime(2023, 5, 7),
          categoryId: category2Id,
          accountId: accountId,
        ),
      );

      final totals = await database.transactionDao
          .watchCategoryTotals(month, TransactionType.expense)
          .first;

      expect(totals.length, equals(2));
      final cat1Total =
          totals.firstWhere((t) => t.category.id == categoryId).total;
      final cat2Total =
          totals.firstWhere((t) => t.category.id == category2Id).total;

      expect(cat1Total, equals(50.0));
      expect(cat2Total, equals(100.0));
    });
  });
}
