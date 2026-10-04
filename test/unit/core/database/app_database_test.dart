import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';

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
      expect(database.schemaVersion, equals(16));
    });

    test('v6 archived accounts remain archived after upgrade', () async {
      final file = File(p.join(
          Directory.systemTemp.createTempSync('feather_v6').path, 'v6.sqlite'));
      final old = AppDatabase.internal(NativeDatabase(file));
      await old.customStatement('SELECT 1');
      await old
          .customStatement('ALTER TABLE accounts_view DROP COLUMN deleted');
      await old.customStatement(
          'ALTER TABLE transactions_view DROP COLUMN source_scheduled_bill_id');
      await old.customStatement(
          'ALTER TABLE categories_view DROP COLUMN archived_at');
      await old.customStatement('DROP TABLE IF EXISTS budget_rules');
      await old.customStatement('DROP TABLE IF EXISTS budget_review_notes');
      await old.customStatement(
          "INSERT INTO accounts_view (id, name, type, currency_code, balance_minor, archived, last_updated_event_id) VALUES ('archived', 'Cash', 0, 'USD', 0, 1, 1)");
      await old.customStatement('PRAGMA user_version = 6');
      await old.close();
      final upgraded = AppDatabase.internal(NativeDatabase(file));
      addTearDown(upgraded.close);
      final row = (await upgraded.accountDao.getAccountById('archived'))!;
      expect(row.archived, isTrue);
      expect(row.deleted, isFalse);
    });

    test('migrates a v1 database by adding the column, keeping its rows',
        () async {
      final file = File(p.join(
          Directory.systemTemp.createTempSync('feather_v1').path, 'v1.sqlite'));
      final v1 = AppDatabase.internal(NativeDatabase(file));
      await v1.customStatement('SELECT 1'); // opens it, running createAll
      await v1.customStatement('ALTER TABLE accounts_view DROP COLUMN deleted');
      await v1.customStatement(
          'ALTER TABLE accounts_view DROP COLUMN include_in_totals');
      await v1.customStatement(
          'ALTER TABLE transactions_view DROP COLUMN attachments_json');
      await v1.customStatement(
          'ALTER TABLE transactions_view DROP COLUMN source_scheduled_bill_id');
      await v1.customStatement(
          'ALTER TABLE categories_view DROP COLUMN archived_at');
      await v1.customStatement('DROP TABLE IF EXISTS budget_rules');
      await v1.customStatement('DROP TABLE IF EXISTS budget_review_notes');
      await v1.customStatement(
          'INSERT INTO accounts_view (id, name, type, currency_code, '
          'balance_minor, archived, last_updated_event_id, projection_version) '
          "VALUES ('acc_v1', 'Cash', 0, 'USD', 5000, 0, 1, 2)");
      await v1.customStatement('PRAGMA user_version = 1');
      await v1.close();

      final upgraded = AppDatabase.internal(NativeDatabase(file));
      addTearDown(upgraded.close);

      final row = await upgraded.accountDao.getAccountById('acc_v1');
      expect(row, isNotNull,
          reason: 'a migration must not drop the rows it migrates');
      expect(row!.balanceMinor, 5000);
      expect(row.deleted, isFalse);
      expect(row.includeInTotals, isTrue,
          reason: 'every account that predates the flag counts toward the '
              'totals — nobody had opted out before it existed');
    });

    test(
        'migrates a v14 database to v15 by dropping obsolete tables, cleanly rebuilding recurring CRUD tables, and preserving ledger_events & event-sourced views',
        () async {
      final file = File(p.join(
          Directory.systemTemp.createTempSync('feather_v14').path,
          'v14.sqlite'));
      final v14 = AppDatabase.internal(NativeDatabase(file));
      await v14.customStatement('SELECT 1');
      await v14.customStatement('''
        CREATE TABLE IF NOT EXISTS automatic_posting_batches (
          id TEXT PRIMARY KEY,
          currency_code TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          status TEXT NOT NULL
        )
      ''');
      await v14.customStatement('''
        CREATE TABLE IF NOT EXISTS automatic_posting_batch_members (
          batch_id TEXT NOT NULL,
          scheduled_bill_id TEXT NOT NULL,
          outcome TEXT NOT NULL,
          PRIMARY KEY (batch_id, scheduled_bill_id)
        )
      ''');
      await v14.customStatement('''
        CREATE TABLE IF NOT EXISTS restore_confirmation_batches (
          id TEXT PRIMARY KEY,
          currency_code TEXT NOT NULL,
          exported_at INTEGER NOT NULL,
          status TEXT NOT NULL
        )
      ''');
      await v14.customStatement('''
        CREATE TABLE IF NOT EXISTS scheduled_bill_redirects (
          from_id TEXT PRIMARY KEY,
          to_id TEXT NOT NULL
        )
      ''');
      await v14.customStatement(
          'INSERT INTO ledger_events (event_id, stream_id, aggregate_type, event_type, stream_version, occurred_at, recorded_at, command_id, payload) '
          "VALUES ('evt-1', 'acc-1', 0, 'AccountCreated', 1, 1780000000000, 1780000000000, 'cmd-1', '{}')");
      await v14.customStatement(
          'INSERT INTO accounts_view (id, name, type, currency_code, '
          'balance_minor, archived, deleted, include_in_totals, last_updated_event_id, projection_version) '
          "VALUES ('acc-1', 'Cash', 0, 'USD', 5000, 0, 0, 1, 1, 3)");
      await v14.customStatement(
          'INSERT INTO categories_view (id, name, icon_key, color_int, type, archived, last_updated_event_id, projection_version) '
          "VALUES ('cat-1', 'Food', 'food', 0, 1, 0, 1, 3)");
      await v14.customStatement(
          'INSERT INTO transactions_view (transaction_id, occurred_at, kind, description, original_event_id, projection_version) '
          "VALUES ('tx-1', 1780000000000, 1, 'Lunch', 1, 3)");
      await v14.customStatement(
          'INSERT INTO transaction_postings_view (id, transaction_id, account_id, direction, amount_minor, currency_code, category_id) '
          "VALUES ('tx-1:0', 'tx-1', 'acc-1', 1, 1200, 'USD', 'cat-1')");
      await v14.customStatement(
          'ALTER TABLE categories_view DROP COLUMN archived_at');
      await v14.customStatement('DROP TABLE IF EXISTS budget_rules');
      await v14.customStatement('DROP TABLE IF EXISTS budget_review_notes');
      await v14.customStatement('PRAGMA user_version = 14');
      await v14.close();

      final upgraded = AppDatabase.internal(NativeDatabase(file));
      addTearDown(upgraded.close);

      expect(upgraded.schemaVersion, 16);
      final tables = await upgraded
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
          .get();
      final tableNames = tables.map((r) => r.read<String>('name')).toSet();
      expect(tableNames, isNot(contains('automatic_posting_batches')));
      expect(tableNames, isNot(contains('automatic_posting_batch_members')));
      expect(tableNames, isNot(contains('restore_confirmation_batches')));
      expect(tableNames, isNot(contains('scheduled_bill_redirects')));

      final seriesCols = (await upgraded
              .customSelect('PRAGMA table_info(recurring_series)')
              .get())
          .map((r) => r.read<String>('name'))
          .toSet();
      expect(seriesCols, contains('is_active'));

      final scheduledCols = (await upgraded
              .customSelect('PRAGMA table_info(scheduled_transactions_view)')
              .get())
          .map((r) => r.read<String>('name'))
          .toSet();
      expect(
        scheduledCols,
        containsAll([
          'id',
          'series_id',
          'occurrence_key',
          'scheduled_date',
          'amount_override_minor',
          'date_override',
          'memo_override',
          'manual_only',
          'status',
        ]),
      );
      expect(scheduledCols, isNot(contains('auto_post_eligible')));

      final eventsCount = await upgraded
          .customSelect('SELECT COUNT(*) AS c FROM ledger_events')
          .getSingle();
      expect(eventsCount.read<int>('c'), 1);
      final account = await upgraded.accountDao.getAccountById('acc-1');
      expect(account, isNotNull);
      expect(account!.balanceMinor, 5000);
      final categoriesCount = await upgraded
          .customSelect('SELECT COUNT(*) AS c FROM categories_view')
          .getSingle();
      expect(categoriesCount.read<int>('c'), 1);
      final txCount = await upgraded
          .customSelect('SELECT COUNT(*) AS c FROM transactions_view')
          .getSingle();
      expect(txCount.read<int>('c'), 1);
      final postingsCount = await upgraded
          .customSelect('SELECT COUNT(*) AS c FROM transaction_postings_view')
          .getSingle();
      expect(postingsCount.read<int>('c'), 1);
    });

    test('should create all tables on initialization', () async {
      // Verify that all tables are created by checking their existence
      final accountsQuery = database.select(database.accountsView);
      final categoriesQuery = database.select(database.categoriesView);
      final transactionsQuery = database.select(database.transactionsView);

      // These should not throw exceptions if tables exist
      expect(await accountsQuery.get(), isEmpty);
      expect(await categoriesQuery.get(), isEmpty);
      expect(await transactionsQuery.get(), isEmpty);
    });

    test('should have accessible DAOs', () {
      expect(database.transactionsDao, isNotNull);
      expect(database.accountDao, isNotNull);
    });

    group('AccountsView Table', () {
      test('should insert and retrieve account', () async {
        const accountId = 'acc_1';
        final account = AccountsViewCompanion.insert(
          id: accountId,
          name: 'Test Account',
          type: AccountType.cash,
          currencyCode: 'USD',
          balanceMinor: 100000,
          lastUpdatedEventId: 1,
        );

        final rowId =
            await database.into(database.accountsView).insert(account);
        expect(rowId, greaterThan(0));

        final retrieved = await (database.select(database.accountsView)
              ..where((t) => t.id.equals(accountId)))
            .getSingle();

        expect(retrieved.name, equals('Test Account'));
        expect(retrieved.type, equals(AccountType.cash));
        expect(retrieved.balanceMinor, equals(100000));
      });

      test('should allow zero balances', () async {
        const accountId = 'acc_zero';
        final account = AccountsViewCompanion.insert(
          id: accountId,
          name: 'Zero Balance Account',
          type: AccountType.bank,
          currencyCode: 'USD',
          balanceMinor: 0,
          lastUpdatedEventId: 1,
        );

        await database.into(database.accountsView).insert(account);
        final retrieved = await (database.select(database.accountsView)
              ..where((t) => t.id.equals(accountId)))
            .getSingle();

        expect(retrieved.balanceMinor, equals(0));
      });

      test('should support all account types', () async {
        for (final type in AccountType.values) {
          final id = 'acc_${type.name}';
          final account = AccountsViewCompanion.insert(
            id: id,
            name: 'Account $type',
            type: type,
            currencyCode: 'USD',
            balanceMinor: 0,
            lastUpdatedEventId: 1,
          );
          await database.into(database.accountsView).insert(account);
          final retrieved = await (database.select(database.accountsView)
                ..where((t) => t.id.equals(id)))
              .getSingle();
          expect(retrieved.type, equals(type));
        }
      });

      test('should update account', () async {
        const accountId = 'acc_update';
        await database.into(database.accountsView).insert(
              AccountsViewCompanion.insert(
                id: accountId,
                name: 'Original Name',
                type: AccountType.cash,
                currencyCode: 'USD',
                balanceMinor: 0,
                lastUpdatedEventId: 1,
              ),
            );

        await (database.update(database.accountsView)
              ..where((t) => t.id.equals(accountId)))
            .write(const AccountsViewCompanion(name: Value('Updated Name')));

        final retrieved = await (database.select(database.accountsView)
              ..where((t) => t.id.equals(accountId)))
            .getSingle();
        expect(retrieved.name, equals('Updated Name'));
      });

      test('should delete account', () async {
        const accountId = 'acc_delete';
        await database.into(database.accountsView).insert(
              AccountsViewCompanion.insert(
                id: accountId,
                name: 'To Delete',
                type: AccountType.cash,
                currencyCode: 'USD',
                balanceMinor: 0,
                lastUpdatedEventId: 1,
              ),
            );

        final deletedCount = await (database.delete(database.accountsView)
              ..where((t) => t.id.equals(accountId)))
            .go();
        expect(deletedCount, equals(1));

        final results = await (database.select(database.accountsView)
              ..where((t) => t.id.equals(accountId)))
            .get();
        expect(results, isEmpty);
      });
    });

    group('Categories Table', () {
      test('should insert and retrieve category', () async {
        const categoryId = 'cat_1';
        final category = CategoriesViewCompanion.insert(
          id: categoryId,
          name: 'Test Category',
          iconKey: 'shopping_cart',
          colorInt: 0xFF123456,
          type: CategoryType.expense,
          lastUpdatedEventId: 0,
        );

        final rowId =
            await database.into(database.categoriesView).insert(category);
        expect(rowId, greaterThan(0));

        final retrieved = await (database.select(database.categoriesView)
              ..where((t) => t.id.equals(categoryId)))
            .getSingle();

        expect(retrieved.name, equals('Test Category'));
        expect(retrieved.iconKey, equals('shopping_cart'));
        expect(retrieved.colorInt, equals(0xFF123456));
        expect(retrieved.type, equals(CategoryType.expense));
        expect(retrieved.archived, isFalse);
      });

      test('should support archived category flag', () async {
        const categoryId = 'cat_archived';
        final category = CategoriesViewCompanion.insert(
          id: categoryId,
          name: 'Archived Category',
          iconKey: 'star',
          colorInt: 0xFF000000,
          type: CategoryType.income,
          archived: const Value(true),
          lastUpdatedEventId: 0,
        );

        await database.into(database.categoriesView).insert(category);
        final retrieved = await (database.select(database.categoriesView)
              ..where((t) => t.id.equals(categoryId)))
            .getSingle();

        expect(retrieved.archived, isTrue);
      });

      test('should update category', () async {
        const categoryId = 'cat_update';
        await database.into(database.categoriesView).insert(
              CategoriesViewCompanion.insert(
                id: categoryId,
                name: 'Old Category',
                iconKey: 'old',
                colorInt: 0x000000,
                type: CategoryType.expense,
                lastUpdatedEventId: 0,
              ),
            );

        await (database.update(database.categoriesView)
              ..where((t) => t.id.equals(categoryId)))
            .write(const CategoriesViewCompanion(name: Value('New Category')));

        final retrieved = await (database.select(database.categoriesView)
              ..where((t) => t.id.equals(categoryId)))
            .getSingle();
        expect(retrieved.name, equals('New Category'));
      });
    });

    group('TransactionsView Table', () {
      late String accountId;
      late String categoryId;

      setUp(() async {
        // Create test account and category
        accountId = 'acc_tx';
        await database.into(database.accountsView).insert(
              AccountsViewCompanion.insert(
                id: accountId,
                name: 'Test Account',
                type: AccountType.cash,
                currencyCode: 'USD',
                balanceMinor: 0,
                lastUpdatedEventId: 1,
              ),
            );

        categoryId = 'cat_tx';
        await database.into(database.categoriesView).insert(
              CategoriesViewCompanion.insert(
                id: categoryId,
                name: 'Test Category',
                iconKey: 'test',
                colorInt: 0xFF000000,
                type: CategoryType.expense,
                lastUpdatedEventId: 0,
              ),
            );
      });

      test('should insert and retrieve transaction with postings', () async {
        final now = DateTime.now();
        const txId = 'txn_1';
        final transaction = TransactionsViewCompanion.insert(
          transactionId: txId,
          occurredAt: now,
          kind: TransactionKind.expense,
          description: 'Test transaction',
          categoryName: const Value('Test Category'),
          categoryIcon: const Value('test'),
          categoryColorInt: const Value('ff000000'),
          originalEventId: 1,
        );
        await database.into(database.transactionsView).insert(transaction);

        final posting = TransactionPostingsViewCompanion.insert(
          id: 'txn_1:0',
          transactionId: txId,
          accountId: accountId,
          direction: PostingDirection.debit,
          amountMinor: 10050,
          currencyCode: 'USD',
          categoryId: Value(categoryId),
        );
        await database.into(database.transactionPostingsView).insert(posting);

        final retrieved = await (database.select(database.transactionsView)
              ..where((t) => t.transactionId.equals(txId)))
            .getSingle();
        final retrievedPosting =
            await (database.select(database.transactionPostingsView)
                  ..where((p) => p.transactionId.equals(txId)))
                .getSingle();

        expect(retrieved.kind, equals(TransactionKind.expense));
        expect(retrieved.description, equals('Test transaction'));
        expect(retrieved.categoryName, equals('Test Category'));
        expect(retrieved.isReversed, isFalse);
        expect(retrievedPosting.amountMinor, equals(10050));
        expect(retrievedPosting.accountId, equals(accountId));
      });

      test('should update transaction snapshot', () async {
        const txId = 'txn_update';
        await database.into(database.transactionsView).insert(
              TransactionsViewCompanion.insert(
                transactionId: txId,
                occurredAt: DateTime.now(),
                kind: TransactionKind.expense,
                description: 'Old',
                categoryName: const Value('Old'),
                categoryIcon: const Value('old'),
                categoryColorInt: const Value('ff000000'),
                originalEventId: 1,
              ),
            );

        await (database.update(database.transactionsView)
              ..where((t) => t.transactionId.equals(txId)))
            .write(const TransactionsViewCompanion(description: Value('New')));

        final retrieved = await (database.select(database.transactionsView)
              ..where((t) => t.transactionId.equals(txId)))
            .getSingle();
        expect(retrieved.description, equals('New'));
      });

      test('should delete transaction', () async {
        const txId = 'txn_delete';
        await database.into(database.transactionsView).insert(
              TransactionsViewCompanion.insert(
                transactionId: txId,
                occurredAt: DateTime.now(),
                kind: TransactionKind.expense,
                description: 'Delete',
                categoryName: const Value('Delete'),
                categoryIcon: const Value('delete'),
                categoryColorInt: const Value('ff000000'),
                originalEventId: 1,
              ),
            );

        final deletedCount = await (database.delete(database.transactionsView)
              ..where((t) => t.transactionId.equals(txId)))
            .go();
        expect(deletedCount, equals(1));

        final results = await (database.select(database.transactionsView)
              ..where((t) => t.transactionId.equals(txId)))
            .get();
        expect(results, isEmpty);
      });
    });

    group('DAOs Integration', () {
      test('AccountDao should be properly initialized', () async {
        final accounts = await database.accountDao.getAllAccounts();
        expect(accounts, isEmpty);
      });

      test('AccountDao should insertOrReplace account', () async {
        const id = 'acc_dao';
        final account = AccountsViewCompanion.insert(
          id: id,
          name: 'DAO Test Account',
          type: AccountType.bank,
          currencyCode: 'USD',
          balanceMinor: 50000,
          lastUpdatedEventId: 1,
        );

        await database.accountDao.upsert(account);

        final retrieved = await database.accountDao.getAccountById(id);
        expect(retrieved, isNotNull);
        expect(retrieved!.name, equals('DAO Test Account'));
      });

      test('TransactionsDao should be accessible', () async {
        // Create required dependencies
        const accountId = 'acc_dao_tx';
        await database.accountDao.upsert(AccountsViewCompanion.insert(
          id: accountId,
          name: 'Test Account',
          type: AccountType.cash,
          currencyCode: 'USD',
          balanceMinor: 0,
          lastUpdatedEventId: 1,
        ));

        const categoryId = 'cat_dao_tx';
        await database.into(database.categoriesView).insert(
              CategoriesViewCompanion.insert(
                id: categoryId,
                name: 'Test Category',
                iconKey: 'test',
                colorInt: 0xFF000000,
                type: CategoryType.expense,
                lastUpdatedEventId: 0,
              ),
            );

        await database.transactionsDao.upsertTransaction(
          TransactionsViewCompanion.insert(
            transactionId: 'txn_dao',
            occurredAt: DateTime.now(),
            kind: TransactionKind.expense,
            description: 'DAO insert',
            categoryName: const Value('Test Category'),
            categoryIcon: const Value('test'),
            categoryColorInt: const Value('ff000000'),
            originalEventId: 1,
          ),
        );
        await database.transactionsDao.upsertPosting(
          TransactionPostingsViewCompanion.insert(
            id: 'txn_dao:0',
            transactionId: 'txn_dao',
            accountId: accountId,
            direction: PostingDirection.debit,
            amountMinor: 20000,
            currencyCode: 'USD',
            categoryId: const Value('cat_dao_tx'),
          ),
        );

        final retrieved = await (database.select(database.transactionsView)
              ..where((t) => t.transactionId.equals('txn_dao')))
            .getSingle();
        expect(retrieved.kind, equals(TransactionKind.expense));
        final posting = await (database.select(database.transactionPostingsView)
              ..where((p) => p.transactionId.equals('txn_dao')))
            .getSingle();
        expect(posting.amountMinor, equals(20000));
      });
    });
  });
}
