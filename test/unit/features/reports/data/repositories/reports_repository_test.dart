import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';

import 'package:feather_ledger/features/reports/data/repositories/reports_repository.dart';
import 'package:feather_ledger/features/reports/presentation/providers/reports_providers.dart';

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

  Future<void> seedAccount({
    String id = 'acc_1',
    bool includeInTotals = true,
  }) =>
      database.into(database.accountsView).insert(
            AccountsViewCompanion.insert(
              id: id,
              name: 'Cash',
              type: AccountType.cash,
              currencyCode: 'USD',
              balanceMinor: 0,
              includeInTotals: Value(includeInTotals),
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
    await database.transactionsDao
        .upsertTransaction(TransactionsViewCompanion.insert(
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
      await database.transactionsDao
          .upsertPosting(TransactionPostingsViewCompanion.insert(
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

  group('watchHeatmapAmountData', () {
    test('emits daily signed impacts excluding transfers and reversed rows',
        () async {
      final month = DateTime(2024, 1);
      final day1 = DateTime(2024, 1, 15, 12);
      final day2 = DateTime(2024, 1, 20, 18);
      await seedAccount();

      final future = repository.watchHeatmapAmountData(month).firstWhere(
          (map) =>
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

  group('watchHeatmapFrequencyData', () {
    final month = DateTime(2024, 1);
    final day = DateTime(2024, 1, 15);

    test(
        'counts transactions independently of amounts and excludes other kinds',
        () async {
      await seedAccount();
      await seedAccount(id: 'excluded', includeInTotals: false);
      await insertTransaction(
        transactionId: 'income',
        date: day,
        kind: TransactionKind.income,
        amountMinor: 10000,
      );
      await insertTransaction(
        transactionId: 'expense',
        date: day,
        kind: TransactionKind.expense,
        amountMinor: 10000,
      );
      for (final kind in [
        TransactionKind.transfer,
        TransactionKind.openingBalance,
        TransactionKind.balanceAdjustment
      ]) {
        await insertTransaction(
          transactionId: kind.name,
          date: day,
          kind: kind,
        );
      }
      await insertTransaction(
        transactionId: 'reversed',
        date: day,
        kind: TransactionKind.expense,
        isReversed: true,
      );
      await insertTransaction(
        transactionId: 'excluded',
        date: day,
        kind: TransactionKind.expense,
        postings: [('excluded', PostingDirection.debit, 999999)],
      );
      expect(await repository.watchHeatmapFrequencyData(month).first, {day: 2});
      expect(await repository.watchHeatmapAmountData(month).first, {day: 0});
    });

    test('counts a transaction once when the join returns multiple postings',
        () async {
      await seedAccount();
      // Deliberately exercise join fan-out with a multi-posting projection.
      await insertTransaction(
        transactionId: 'one-transaction',
        date: day,
        kind: TransactionKind.expense,
        postings: [
          ('acc_1', PostingDirection.debit, 100),
          ('acc_1', PostingDirection.debit, 200),
        ],
      );
      expect(await repository.watchHeatmapFrequencyData(month).first, {day: 1});
    });

    test('includes the exact three-month window across a year boundary',
        () async {
      await seedAccount();
      final dates = [
        DateTime(2023, 10, 31, 23, 59, 59),
        DateTime(2023, 11, 1),
        DateTime(2024, 1, 31, 23, 59, 59, 999),
        DateTime(2024, 2, 1),
      ];
      for (var index = 0; index < dates.length; index++) {
        await insertTransaction(
          transactionId: 'boundary-$index',
          date: dates[index],
          kind: TransactionKind.expense,
        );
      }
      expect(await repository.watchHeatmapFrequencyData(month).first,
          {DateTime(2023, 11, 1): 1, DateTime(2024, 1, 31): 1});
    });

    test('reacts to inclusion, reversal and new transactions; archival counts',
        () async {
      await seedAccount();
      await insertTransaction(
        transactionId: 'original',
        date: day,
        kind: TransactionKind.expense,
      );
      await (database.update(database.accountsView)
            ..where((account) => account.id.equals('acc_1')))
          .write(const AccountsViewCompanion(archived: Value(true)));
      final iterator =
          StreamIterator(repository.watchHeatmapFrequencyData(month));
      addTearDown(iterator.cancel);
      Future<Map<DateTime, int>> next() async {
        expect(await iterator.moveNext().timeout(const Duration(seconds: 5)),
            isTrue);
        return iterator.current;
      }

      expect(await next(), {day: 1});
      await (database.update(database.accountsView)
            ..where((account) => account.id.equals('acc_1')))
          .write(const AccountsViewCompanion(includeInTotals: Value(false)));
      expect(await next(), isEmpty);
      await (database.update(database.accountsView)
            ..where((account) => account.id.equals('acc_1')))
          .write(const AccountsViewCompanion(includeInTotals: Value(true)));
      expect(await next(), {day: 1});
      await database.transactionsDao.markTransactionAsReversed('original');
      expect(await next(), isEmpty);
      await database.transaction(() => insertTransaction(
            transactionId: 'new',
            date: day,
            kind: TransactionKind.income,
          ));
      expect(await next(), {day: 1});
    });

    test('switching modes subscribes to counts and net amounts respectively',
        () async {
      await seedAccount();
      await insertTransaction(
        transactionId: 'expense',
        date: day,
        kind: TransactionKind.expense,
        amountMinor: 7500,
      );
      final container = ProviderContainer(overrides: [
        reportsRepositoryProvider.overrideWithValue(repository),
      ]);
      addTearDown(container.dispose);
      container.read(selectedDateProvider.notifier).setMonth(month);
      final subscription = container.listen(heatmapDataProvider, (_, __) {});
      addTearDown(subscription.close);
      expect(await container.read(heatmapDataProvider.future), {day: 1});
      container
          .read(heatmapModeStateProvider.notifier)
          .setMode(HeatmapMode.amount);
      expect(await container.read(heatmapDataProvider.future), {day: -7500});
      container
          .read(heatmapModeStateProvider.notifier)
          .setMode(HeatmapMode.frequency);
      expect(await container.read(heatmapDataProvider.future), {day: 1});
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
      expect(result.first.totalMinor, 50000,
          reason: 'magnitude: the breakdown says how much, not which way');
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
      expect(result.first.totalMinor, 30000);
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
      expect(result.first.totalMinor, 20000);
    });
  });

  group('watchMonthlyTotals', () {
    Future<void> seedSnapshot(
            String accountId, int income, int expense, int closing) =>
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

    test('aggregates the snapshot projection across accounts', () async {
      final month = DateTime(2024, 1);

      // Both accounts have to exist as accounts, not just as snapshot rows:
      // the query joins `accounts_view` to apply the include-in-totals flag,
      // so a snapshot for an account that is not there is a row no report can
      // see.
      await seedAccount();
      await seedAccount(id: 'acc_2');

      await seedSnapshot('acc_1', 10000, -5000, 5000);
      await seedSnapshot('acc_2', 2000, 0, 2000);

      final totals = await repository.watchMonthlyTotals(month).first;
      expect(totals.incomeMinor, 12000);
      expect(totals.expenseMinor, -5000);
      expect(totals.balanceMinor, 7000,
          reason: 'month-end balance = Σ closing across accounts');
    });

    test('leaves out an account that is out of the ledger totals', () async {
      final month = DateTime(2024, 1);
      await seedAccount();
      await seedAccount(id: 'acc_held', includeInTotals: false);
      await seedSnapshot('acc_1', 10000, -5000, 5000);
      await seedSnapshot('acc_held', 9000, 0, 9000);

      final totals = await repository.watchMonthlyTotals(month).first;

      expect(totals.incomeMinor, 10000);
      expect(totals.balanceMinor, 5000,
          reason: 'the excluded account is not part of either figure');
    });
  });

  /// Every report query is a cross-account total, so all three answer to the
  /// same flag. The join to `accounts_view` is also what makes them re-emit
  /// when it is toggled — a filter applied after the query would leave the
  /// charts stale until something else moved.
  group('an account out of the ledger totals', () {
    final month = DateTime(2024, 1);

    Future<void> seedExcludedExpense() async {
      await seedAccount();
      await seedAccount(id: 'acc_held', includeInTotals: false);
      await insertTransaction(
        transactionId: 'txn_kept',
        date: DateTime(2024, 1, 15, 12),
        kind: TransactionKind.expense,
        categoryId: 'cat_food',
        amountMinor: 10000,
        postings: [('acc_1', PostingDirection.debit, 10000)],
      );
      await insertTransaction(
        transactionId: 'txn_held',
        date: DateTime(2024, 1, 15, 12),
        kind: TransactionKind.expense,
        categoryId: 'cat_food',
        amountMinor: 90000,
        originalEventId: 2,
        postings: [('acc_held', PostingDirection.debit, 90000)],
      );
    }

    test('is missing from the heatmap', () async {
      await seedExcludedExpense();

      final heatmap = await repository.watchHeatmapAmountData(month).first;

      expect(heatmap[DateTime(2024, 1, 15)], -10000,
          reason: 'only the account that counts');
    });

    test('is missing from the category breakdown', () async {
      await seedExcludedExpense();

      final breakdown = await repository
          .watchCategoryBreakdown(month, CategoryType.expense)
          .first;

      expect(breakdown.single.totalMinor, 10000);
    });
  });
}
