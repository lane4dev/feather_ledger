import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/database/app_database.dart';
import 'package:feather_ledger/core/database/tables.dart';

import '../../../support/fakes/fake_app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    // Create an in-memory database for testing using FakeAppDatabase
    database = FakeAppDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  group('AppDatabase', () {
    test('should initialize with correct schema version', () {
      expect(database.schemaVersion, equals(1));
    });

    test('should create all tables on initialization', () async {
      // Verify that all tables are created by checking their existence
      final accountsQuery = database.select(database.accounts);
      final categoriesQuery = database.select(database.categories);
      final transactionsQuery = database.select(database.transactions);

      // These should not throw exceptions if tables exist
      expect(await accountsQuery.get(), isEmpty);
      expect(await categoriesQuery.get(), isEmpty);
      expect(await transactionsQuery.get(), isEmpty);
    });

    test('should have accessible DAOs', () {
      expect(database.transactionDao, isNotNull);
      expect(database.accountDao, isNotNull);
    });

    group('Accounts Table', () {
      test('should insert and retrieve account', () async {
        final account = AccountsCompanion.insert(
          name: 'Test Account',
          type: AccountType.cash,
          initialBalance: const Value(1000.0),
        );

        final id = await database.into(database.accounts).insert(account);
        expect(id, greaterThan(0));

        final retrieved = await (database.select(database.accounts)
              ..where((t) => t.id.equals(id)))
            .getSingle();

        expect(retrieved.name, equals('Test Account'));
        expect(retrieved.type, equals(AccountType.cash));
        expect(retrieved.initialBalance, equals(1000.0));
      });

      test('should use default initial balance of 0.0', () async {
        final account = AccountsCompanion.insert(
          name: 'Default Balance Account',
          type: AccountType.bank,
        );

        final id = await database.into(database.accounts).insert(account);
        final retrieved = await (database.select(database.accounts)
              ..where((t) => t.id.equals(id)))
            .getSingle();

        expect(retrieved.initialBalance, equals(0.0));
      });
    });

    group('Categories Table', () {
      test('should insert and retrieve category', () async {
        final category = CategoriesCompanion.insert(
          name: 'Test Category',
          iconKey: 'shopping_cart',
          colorInt: 0xFF123456,
          type: TransactionType.expense,
        );

        final id = await database.into(database.categories).insert(category);
        expect(id, greaterThan(0));

        final retrieved = await (database.select(database.categories)
              ..where((t) => t.id.equals(id)))
            .getSingle();

        expect(retrieved.name, equals('Test Category'));
        expect(retrieved.iconKey, equals('shopping_cart'));
        expect(retrieved.colorInt, equals(0xFF123456));
        expect(retrieved.type, equals(TransactionType.expense));
        expect(retrieved.isDefault, isFalse);
      });

      test('should support default category flag', () async {
        final category = CategoriesCompanion.insert(
          name: 'Default Category',
          iconKey: 'star',
          colorInt: 0xFF000000,
          type: TransactionType.income,
          isDefault: const Value(true),
        );

        final id = await database.into(database.categories).insert(category);
        final retrieved = await (database.select(database.categories)
              ..where((t) => t.id.equals(id)))
            .getSingle();

        expect(retrieved.isDefault, isTrue);
      });
    });

    group('Transactions Table', () {
      late int accountId;
      late int categoryId;

      setUp(() async {
        // Create test account and category
        accountId = await database.into(database.accounts).insert(
              AccountsCompanion.insert(
                name: 'Test Account',
                type: AccountType.cash,
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

      test('should insert and retrieve transaction', () async {
        final now = DateTime.now();
        final transaction = TransactionsCompanion.insert(
          amount: 100.50,
          type: TransactionType.expense,
          date: now,
          categoryId: categoryId,
          accountId: accountId,
          note: const Value('Test transaction'),
        );

        final id =
            await database.into(database.transactions).insert(transaction);
        expect(id, greaterThan(0));

        final retrieved = await (database.select(database.transactions)
              ..where((t) => t.id.equals(id)))
            .getSingle();

        expect(retrieved.amount, equals(100.50));
        expect(retrieved.type, equals(TransactionType.expense));
        expect(retrieved.note, equals('Test transaction'));
        expect(retrieved.categoryId, equals(categoryId));
        expect(retrieved.accountId, equals(accountId));
      });

      test('should support null note', () async {
        final transaction = TransactionsCompanion.insert(
          amount: 50.0,
          type: TransactionType.income,
          date: DateTime.now(),
          categoryId: categoryId,
          accountId: accountId,
        );

        final id =
            await database.into(database.transactions).insert(transaction);
        final retrieved = await (database.select(database.transactions)
              ..where((t) => t.id.equals(id)))
            .getSingle();

        expect(retrieved.note, isNull);
      });

      test('should auto-set createdAt timestamp', () async {
        final before = DateTime.now();

        final transaction = TransactionsCompanion.insert(
          amount: 75.0,
          type: TransactionType.expense,
          date: DateTime.now(),
          categoryId: categoryId,
          accountId: accountId,
        );

        final id =
            await database.into(database.transactions).insert(transaction);
        final after = DateTime.now();

        final retrieved = await (database.select(database.transactions)
              ..where((t) => t.id.equals(id)))
            .getSingle();

        expect(retrieved.createdAt, isNotNull);
        expect(
          retrieved.createdAt
              .isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(
          retrieved.createdAt.isBefore(after.add(const Duration(seconds: 1))),
          isTrue,
        );
      });
    });

    group('DAOs Integration', () {
      test('AccountDao should be properly initialized', () async {
        final accounts = await database.accountDao.getAllAccounts();
        expect(accounts, isEmpty);
      });

      test('AccountDao should add account', () async {
        final account = AccountsCompanion.insert(
          name: 'DAO Test Account',
          type: AccountType.bank,
          initialBalance: const Value(500.0),
        );

        final id = await database.accountDao.addAccount(account);
        expect(id, greaterThan(0));

        final retrieved = await database.accountDao.getAccountById(id);
        expect(retrieved, isNotNull);
        expect(retrieved!.name, equals('DAO Test Account'));
      });

      test('TransactionDao should be accessible', () async {
        // Create required dependencies
        final accountId = await database.into(database.accounts).insert(
              AccountsCompanion.insert(
                name: 'Test Account',
                type: AccountType.cash,
              ),
            );

        final categoryId = await database.into(database.categories).insert(
              CategoriesCompanion.insert(
                name: 'Test Category',
                iconKey: 'test',
                colorInt: 0xFF000000,
                type: TransactionType.expense,
              ),
            );

        final transaction = TransactionsCompanion.insert(
          amount: 200.0,
          type: TransactionType.expense,
          date: DateTime.now(),
          categoryId: categoryId,
          accountId: accountId,
        );

        final id = await database.transactionDao.addTransaction(transaction);
        expect(id, greaterThan(0));
      });
    });
  });
}
