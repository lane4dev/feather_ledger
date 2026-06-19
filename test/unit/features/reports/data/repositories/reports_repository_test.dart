import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';

import 'package:feather_ledger/features/reports/data/repositories/reports_repository.dart';

import '../../../../../support/fakes/fake_app_database.dart';

/// Report repository tests (spec 003, US9/T066): totals come from the
/// snapshot projection; the breakdown groups by the transaction rows'
/// write-time category snapshots (archived categories stay visible);
/// transfers and reversed rows are excluded everywhere.
void main() {
  late AppDatabase database;
  late ReportsRepository repository;

  setUp(() {
    database = FakeAppDatabase();
    repository = ReportsRepositoryImpl(database.reportsDao);
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> seedAccount() => database.into(database.accountsView).insert(
        AccountsViewCompanion.insert(
          id: 'acc_1',
          name: 'Cash',
          type: AccountType.cash,
          currencyCode: 'USD',
          balanceMinor: 0,
          lastUpdatedEventId: 1,
        ),
      );

  Future<void> insertTransaction({
    required String transactionId,
    required DateTime date,
    required TransactionKind kind,
    String? categoryId,
    String categoryName = 'Food',
    String categoryIcon = 'restaurant',
    String categoryColorHex = 'ffff0000',
    int amountMinor = 50000,
    bool isReversed = false,
    int originalEventId = 1,
    List<(String, PostingDirection, int)> postings = const [],
  }) async {
    await database.transactionsDao.upsertTransaction(
        TransactionsViewCompanion.insert(
      transactionId: transactionId,
      occurredAt: date,
      kind: kind,
      description: 'desc',
      categoryName: Value(categoryName),
      categoryIcon: Value(categoryIcon),
      categoryColorInt: Value(categoryColorHex),
      isReversed: Value(isReversed),
      originalEventId: originalEventId,
    ));

    final legs = postings.isEmpty
        ? [
            (
              'acc_1',
              kind == TransactionKind.income
                  ? PostingDirection.credit
                  : PostingDirection.debit,
              amountMinor,
            )
          ]
        : postings;
    for (var i = 0; i < legs.length; i++) {
      final leg = legs[i];
      await database.transactionsDao.upsertPosting(
          TransactionPostingsViewCompanion.insert(
        id: '$transactionId:$i',
        transactionId: transactionId,
        accountId: leg.$1,
        direction: leg.$2,
        amountMinor: leg.$3,
        currencyCode: 'USD',
        categoryId: Value(categoryId),
      ));
    }
  }

  group('watchHeatmapData', () {
    test('emits daily signed impacts excluding transfers and reversed rows',
        () async {
      final month = DateTime(2024, 1);
      final day1 = DateTime(2024, 1, 15, 12);
      final day2 = DateTime(2024, 1, 20, 18);
      await seedAccount();

      final future = repository.watchHeatmapData(month).firstWhere((map) =>
          map[DateTime(2024, 1, 15)] == -500 &&
          map[DateTime(2024, 1, 20)] == -300);

      await insertTransaction(
        transactionId: 'txn_1',
        date: day1,
        kind: TransactionKind.expense,
        categoryId: 'cat_1',
        amountMinor: 500,
      );
      await insertTransaction(
        transactionId: 'txn_2',
        date: day2,
        kind: TransactionKind.expense,
        categoryId: 'cat_1',
        amountMinor: 300,
        originalEventId: 2,
      );
      // Transfer and reversed rows must not appear.
      await insertTransaction(
        transactionId: 'txn_transfer',
        date: DateTime(2024, 1, 16),
        kind: TransactionKind.transfer,
        postings: [
          ('acc_1', PostingDirection.debit, 99900),
          ('acc_1', PostingDirection.credit, 99900),
        ],
        originalEventId: 3,
      );
      await insertTransaction(
        transactionId: 'txn_reversed',
        date: DateTime(2024, 1, 17),
        kind: TransactionKind.expense,
        categoryId: 'cat_1',
        amountMinor: 700,
        isReversed: true,
        originalEventId: 4,
      );

      final result = await future;
      expect(result[DateTime(2024, 1, 15)], equals(-500));
      expect(result[DateTime(2024, 1, 20)], equals(-300));
      expect(result[DateTime(2024, 1, 16)], isNull);
      expect(result[DateTime(2024, 1, 17)], isNull);
    });
  });

  group('watchCategoryBreakdown', () {
    test('groups by write-time snapshot, surviving category archival',
        () async {
      final month = DateTime(2024, 1);
      await seedAccount();

      // The live category row is archived AND renamed — history must still
      // render the recorded snapshot.
      await database.into(database.categoriesView).insert(
            CategoriesViewCompanion.insert(
              id: 'cat_food',
              name: 'Renamed Later',
              iconKey: 'other_icon',
              colorInt: 0xFF00FF00,
              type: CategoryType.expense,
              archived: const Value(true),
              lastUpdatedEventId: 0,
            ),
          );

      final future = repository
          .watchCategoryBreakdown(month, CategoryType.expense)
          .firstWhere((list) => list.isNotEmpty);

      await insertTransaction(
        transactionId: 'txn_food_1',
        date: DateTime(2024, 1, 10),
        kind: TransactionKind.expense,
        categoryId: 'cat_food',
        categoryName: 'Food',
        categoryIcon: 'restaurant',
        categoryColorHex: 'ffff0000',
        amountMinor: 50000,
      );

      final result = await future;
      expect(result, hasLength(1));
      expect(result.first.category.id, 'cat_food');
      expect(result.first.category.name, 'Food',
          reason: 'write-time snapshot, not the live (renamed) row');
      expect(result.first.category.iconKey, 'restaurant');
      expect(result.first.category.colorInt, 0xFFFF0000);
      expect(result.first.totalMinor, -50000);
    });

    test('excludes transfers', () async {
      final month = DateTime(2024, 1);
      await seedAccount();

      final future = repository
          .watchCategoryBreakdown(month, CategoryType.expense)
          .firstWhere((list) => list.isNotEmpty);

      await insertTransaction(
        transactionId: 'txn_transfer',
        date: DateTime(2024, 1, 10),
        kind: TransactionKind.transfer,
        postings: [
          ('acc_1', PostingDirection.debit, 30000),
          ('acc_1', PostingDirection.credit, 30000),
        ],
      );
      await insertTransaction(
        transactionId: 'txn_expense',
        date: DateTime(2024, 1, 11),
        kind: TransactionKind.expense,
        categoryId: 'cat_food',
        amountMinor: 30000,
        originalEventId: 2,
      );

      final result = await future;
      expect(result, hasLength(1),
          reason: 'transfers carry no category and never enter the pie');
      expect(result.first.totalMinor, -30000);
    });

    test('excludes reversed rows', () async {
      final month = DateTime(2024, 1);
      await seedAccount();

      await insertTransaction(
        transactionId: 'txn_reversed',
        date: DateTime(2024, 1, 10),
        kind: TransactionKind.expense,
        categoryId: 'cat_food',
        amountMinor: 50000,
        isReversed: true,
      );
      await insertTransaction(
        transactionId: 'txn_live',
        date: DateTime(2024, 1, 11),
        kind: TransactionKind.expense,
        categoryId: 'cat_food',
        amountMinor: 20000,
        originalEventId: 2,
      );

      final result = await repository
          .watchCategoryBreakdown(month, CategoryType.expense)
          .first;
      expect(result, hasLength(1));
      expect(result.first.totalMinor, -20000);
    });
  });

  group('watchMonthlyTotals', () {
    test('aggregates the snapshot projection across accounts', () async {
      final month = DateTime(2024, 1);

      Future<void> seedSnapshot(String accountId, int income, int expense,
              int closing) =>
          database.monthlySnapshotDao
              .upsert(MonthlyAccountBalanceSnapshotsCompanion.insert(
            accountId: accountId,
            currencyCode: 'USD',
            year: 2024,
            month: 1,
            openingBalanceMinor: closing - income - expense,
            closingBalanceMinor: closing,
            incomeMinor: income,
            expenseMinor: expense,
            transferInMinor: 0,
            transferOutMinor: 0,
            netChangeMinor: income + expense,
            transactionCount: 1,
            eventSequenceFrom: 1,
            eventSequenceTo: 2,
          ));

      await seedSnapshot('acc_1', 10000, -5000, 5000);
      await seedSnapshot('acc_2', 2000, 0, 2000);

      final totals = await repository.watchMonthlyTotals(month).first;
      expect(totals.incomeMinor, 12000);
      expect(totals.expenseMinor, -5000);
      expect(totals.balanceMinor, 7000,
          reason: 'month-end balance = Σ closing across accounts');
    });
  });
}
