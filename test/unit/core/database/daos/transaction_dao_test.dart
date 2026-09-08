import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';

import '../../../../support/fakes/fake_app_database.dart';

void main() {
  late AppDatabase database;
  late String accountId;
  late String expenseCategoryId;
  late String incomeCategoryId;

  setUp(() async {
    database = FakeAppDatabase();

    // Create baseline data
    accountId = 'acc_1';
    await database.accountDao.upsert(AccountsViewCompanion.insert(
      id: accountId,
      name: 'Test Account',
      type: AccountType.cash,
      currencyCode: 'USD',
      balanceMinor: 100000, // $1000.00 in minor units
      lastUpdatedEventId: 1,
    ));

    expenseCategoryId = 'cat_expense';
    await database.categoriesDao.upsert(CategoriesViewCompanion.insert(
      id: expenseCategoryId,
      name: 'Test Category',
      iconKey: 'test',
      colorInt: 0xFF000000,
      type: CategoryType.expense,
      lastUpdatedEventId: 0,
    ));

    incomeCategoryId = 'cat_income';
    await database.categoriesDao.upsert(CategoriesViewCompanion.insert(
      id: incomeCategoryId,
      name: 'Income Category',
      iconKey: 'income',
      colorInt: 0xFF00FF00,
      type: CategoryType.income,
      lastUpdatedEventId: 0,
    ));
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> insertTransaction({
    required String transactionId,
    required DateTime date,
    required TransactionKind kind,
    required String categoryId,
    required PostingDirection direction,
    required int amountMinor,
    int originalEventId = 1,
  }) async {
    await database.transactionsDao.upsertTransaction(
        TransactionsViewCompanion.insert(
      transactionId: transactionId,
      occurredAt: date,
      kind: kind,
      description: 'desc-$transactionId',
      categoryName: Value('cat-$transactionId'),
      categoryIcon: const Value('icon'),
      categoryColorInt: const Value('ff000000'),
      originalEventId: originalEventId,
    ));
    await database.transactionsDao.upsertPosting(
        TransactionPostingsViewCompanion.insert(
      id: '$transactionId:0',
      transactionId: transactionId,
      accountId: accountId,
      direction: direction,
      amountMinor: amountMinor,
      currencyCode: 'USD',
      categoryId: Value(categoryId),
    ));
  }

  group('TransactionsDao', () {
    test('should add and update transaction', () async {
      final now = DateTime.now();
      const id = 'tx_1';
      await insertTransaction(
        transactionId: id,
        date: now,
        kind: TransactionKind.expense,
        categoryId: expenseCategoryId,
        direction: PostingDirection.debit,
        amountMinor: 5000, // $50.00
        originalEventId: 1,
      );
      await insertTransaction(
        transactionId: id,
        date: now,
        kind: TransactionKind.expense,
        categoryId: expenseCategoryId,
        direction: PostingDirection.debit,
        amountMinor: 7500, // $75.00
        originalEventId: 2,
      );

      final retrieved = await (database.select(database.transactionsView)
            ..where((t) => t.transactionId.equals(id)))
          .getSingle();
      final posting = await (database.select(database.transactionPostingsView)
            ..where((p) => p.transactionId.equals(id)))
          .getSingle();
      expect(posting.amountMinor, equals(7500));
      expect(retrieved.kind, TransactionKind.expense);
    });

    test('markTransactionAsReversed flags the row', () async {
      const id = 'tx_delete';
      await insertTransaction(
        transactionId: id,
        date: DateTime.now(),
        kind: TransactionKind.expense,
        categoryId: expenseCategoryId,
        direction: PostingDirection.debit,
        amountMinor: 5000,
      );

      await database.transactionsDao.markTransactionAsReversed(id);

      final results = await (database.select(database.transactionsView)
            ..where((t) => t.transactionId.equals(id)))
          .get();
      expect(results, hasLength(1));
      expect(results.single.isReversed, isTrue);
    });

    test('watchTransactionsByMonth should filter correctly', () async {
      final month = DateTime(2023, 5);

      // Inside May
      await insertTransaction(
        transactionId: 'txn_may',
        date: DateTime(2023, 5, 15),
        kind: TransactionKind.expense,
        categoryId: expenseCategoryId,
        direction: PostingDirection.debit,
        amountMinor: 1000,
      );

      // Outside May
      await insertTransaction(
        transactionId: 'txn_june',
        date: DateTime(2023, 6, 1),
        kind: TransactionKind.expense,
        categoryId: expenseCategoryId,
        direction: PostingDirection.debit,
        amountMinor: 2000,
        originalEventId: 2,
      );

      final stream = database.transactionsDao.watchTransactionsByMonth(month);
      final list = await stream.first;

      expect(list.length, equals(1));
      expect(list.first.transaction.transactionId, equals('txn_may'));
      expect(list.first.account.name, equals('Test Account'));
      expect(list.first.transaction.categoryName, equals('cat-txn_may'));
    });

  });
}
