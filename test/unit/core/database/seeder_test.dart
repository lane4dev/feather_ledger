import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/seeder.dart';
import 'package:feather_ledger/core/domain/entities/enums.dart';

import '../../../support/fakes/fake_app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = FakeAppDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  group('seedDatabase', () {
    test('should seed categories when database is empty', () async {
      // Verify database is empty
      var categories = await database.transactionDao.getAllCategories();
      expect(categories, isEmpty);

      // Run seeder
      await seedDatabase(database);

      // Verify categories were inserted
      categories = await database.transactionDao.getAllCategories();
      expect(categories, hasLength(5));

      // Verify specific categories
      final categoryNames = categories.map((c) => c.name).toSet();
      expect(categoryNames,
          containsAll(['Food', 'Transport', 'Shopping', 'Salary', 'Bonus']));
    });

    test('should seed accounts when database is empty', () async {
      // Verify database is empty
      var accounts = await database.transactionDao.getAllAccounts();
      expect(accounts, isEmpty);

      // Run seeder
      await seedDatabase(database);

      // Verify accounts were inserted
      accounts = await database.transactionDao.getAllAccounts();
      expect(accounts, hasLength(2));

      // Verify specific accounts
      final accountNames = accounts.map((a) => a.name).toSet();
      expect(accountNames, containsAll(['Cash', 'Bank Card']));
    });

    test('should insert expense categories with correct properties', () async {
      await seedDatabase(database);

      final categories = await database.transactionDao.getAllCategories();
      final expenseCategories =
          categories.where((c) => c.type == TransactionType.expense).toList();

      expect(expenseCategories, hasLength(3));

      // Verify each expense category has required properties
      for (var category in expenseCategories) {
        expect(category.name, isNotEmpty);
        expect(category.iconKey, isNotEmpty);
        expect(category.colorInt, greaterThan(0));
        expect(category.type, equals(TransactionType.expense));
      }

      // Verify specific expense categories
      final food = categories.firstWhere((c) => c.name == 'Food');
      expect(food.type, equals(TransactionType.expense));
      expect(food.iconKey, isNotEmpty);

      final transport = categories.firstWhere((c) => c.name == 'Transport');
      expect(transport.type, equals(TransactionType.expense));

      final shopping = categories.firstWhere((c) => c.name == 'Shopping');
      expect(shopping.type, equals(TransactionType.expense));
    });

    test('should insert income categories with correct properties', () async {
      await seedDatabase(database);

      final categories = await database.transactionDao.getAllCategories();
      final incomeCategories =
          categories.where((c) => c.type == TransactionType.income).toList();

      expect(incomeCategories, hasLength(2));

      // Verify each income category has required properties
      for (var category in incomeCategories) {
        expect(category.name, isNotEmpty);
        expect(category.iconKey, isNotEmpty);
        expect(category.colorInt, greaterThan(0));
        expect(category.type, equals(TransactionType.income));
      }

      // Verify specific income categories
      final salary = categories.firstWhere((c) => c.name == 'Salary');
      expect(salary.type, equals(TransactionType.income));

      final bonus = categories.firstWhere((c) => c.name == 'Bonus');
      expect(bonus.type, equals(TransactionType.income));
    });

    test('should insert accounts with correct properties', () async {
      await seedDatabase(database);

      final accounts = await database.transactionDao.getAllAccounts();

      // Verify Cash account
      final cash = accounts.firstWhere((a) => a.name == 'Cash');
      expect(cash.type, equals(AccountType.cash));
      expect(cash.initialBalance, equals(0.0));

      // Verify Bank Card account
      final bankCard = accounts.firstWhere((a) => a.name == 'Bank Card');
      expect(bankCard.type, equals(AccountType.bank));
      expect(bankCard.initialBalance, equals(1000.0));
    });

    test('should not duplicate categories when called multiple times',
        () async {
      // Run seeder first time
      await seedDatabase(database);
      var categories = await database.transactionDao.getAllCategories();
      expect(categories, hasLength(5));

      // Run seeder again
      await seedDatabase(database);
      categories = await database.transactionDao.getAllCategories();

      // Should still have only 5 categories
      expect(categories, hasLength(5));
    });

    test('should not duplicate accounts when called multiple times', () async {
      // Run seeder first time
      await seedDatabase(database);
      var accounts = await database.transactionDao.getAllAccounts();
      expect(accounts, hasLength(2));

      // Run seeder again
      await seedDatabase(database);
      accounts = await database.transactionDao.getAllAccounts();

      // Should still have only 2 accounts
      expect(accounts, hasLength(2));
    });

    test('should seed accounts even if categories already exist', () async {
      // Insert a category manually
      await database.into(database.categories).insert(
            CategoriesCompanion.insert(
              name: 'Existing Category',
              iconKey: 'test',
              colorInt: 0xFF000000,
              type: TransactionType.expense,
            ),
          );

      // Run seeder
      await seedDatabase(database);

      // Categories should not be seeded (already exists)
      final categories = await database.transactionDao.getAllCategories();
      expect(categories, hasLength(1));
      expect(categories.first.name, equals('Existing Category'));

      // Accounts should still be seeded
      final accounts = await database.transactionDao.getAllAccounts();
      expect(accounts, hasLength(2));
    });

    test('should seed categories even if accounts already exist', () async {
      // Insert an account manually
      await database.into(database.accounts).insert(
            AccountsCompanion.insert(
              name: 'Existing Account',
              type: AccountType.other,
            ),
          );

      // Run seeder
      await seedDatabase(database);

      // Accounts should not be seeded (already exists)
      final accounts = await database.transactionDao.getAllAccounts();
      expect(accounts, hasLength(1));
      expect(accounts.first.name, equals('Existing Account'));

      // Categories should still be seeded
      final categories = await database.transactionDao.getAllCategories();
      expect(categories, hasLength(5));
    });

    test('should complete successfully on empty database', () async {
      // This should not throw any exceptions
      await expectLater(
        seedDatabase(database),
        completes,
      );
    });

    test('should use batch insert for categories', () async {
      // Run seeder
      await seedDatabase(database);

      // All categories should be inserted
      final categories = await database.transactionDao.getAllCategories();
      expect(categories, hasLength(5));

      // All should have sequential or valid IDs
      final ids = categories.map((c) => c.id).toList();
      expect(ids.every((id) => id > 0), isTrue);
    });

    test('should assign unique IDs to categories', () async {
      await seedDatabase(database);

      final categories = await database.transactionDao.getAllCategories();
      final ids = categories.map((c) => c.id).toList();

      // All IDs should be unique
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('should assign unique IDs to accounts', () async {
      await seedDatabase(database);

      final accounts = await database.transactionDao.getAllAccounts();
      final ids = accounts.map((a) => a.id).toList();

      // All IDs should be unique
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('should insert all default data in a single seed operation', () async {
      await seedDatabase(database);

      final categories = await database.transactionDao.getAllCategories();
      final accounts = await database.transactionDao.getAllAccounts();

      // Verify all expected data was inserted
      expect(categories, hasLength(5));
      expect(accounts, hasLength(2));

      // Verify data integrity
      expect(categories.every((c) => c.name.isNotEmpty), isTrue);
      expect(categories.every((c) => int.tryParse(c.iconKey) != null), isTrue,
          reason: 'iconKey should be a numeric codePoint string');
      expect(accounts.every((a) => a.name.isNotEmpty), isTrue);
    });
  });
}
