import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/app/bootstrap/register_ledger_events.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/repositories/account_repository.dart';
import 'package:feather_ledger/core/data/repositories/category_repository.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/event_sourcing/drift_event_store.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_projector.dart';
import 'package:feather_ledger/features/ledger/data/repositories/ledger_repository.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/ledger/domain/commands/convert_scheduled_to_posted_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/correct_transaction_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/record_transaction_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/reverse_transaction_command.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/queries/get_account_balance_query.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_monthly_snapshot_query.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_scheduled_transactions_query.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_transactions_query.dart';
import 'package:feather_ledger/features/ledger/domain/services/ledger_service.dart';


import '../../../../../support/fakes/fake_app_database.dart';

void main() {
  late AppDatabase database;
  late LedgerRepository repository;
  late EventStore eventStore;
  late AccountRepository accountRepository;
  late CategoryRepository categoryRepository;
  late RecurringRepository recurringRepository;
  late RecordTransactionCommand recordCommand;
  late ReverseTransactionCommand reverseCommand;
  late CorrectTransactionCommand correctCommand;
  late ConvertScheduledToPostedCommand convertScheduledCommand;
  late WatchTransactionsQuery watchTransactionsQuery;
  late WatchMonthlySnapshotQuery watchMonthlySnapshotQuery;
  late GetAccountBalanceQuery getAccountBalanceQuery;
  late WatchScheduledTransactionsQuery watchScheduledTransactionsQuery;
  late LedgerService service;

  setUp(() {
    database = FakeAppDatabase();
    repository =
        LedgerRepositoryImpl(database.transactionsDao, database.recurringDao);
    registerLedgerEvents();
    eventStore = DriftEventStore(database, ledgerEventRegistry);
    accountRepository = AccountRepositoryImpl(database.accountDao);
    categoryRepository = CategoryRepositoryImpl(database.categoriesDao);
    recurringRepository = RecurringRepositoryImpl(database.recurringDao);

    final projector = LedgerProjectorImpl(database);
    recordCommand = RecordTransactionCommand(
        eventStore, projector, accountRepository, categoryRepository);
    reverseCommand = ReverseTransactionCommand(eventStore, projector, repository);
    correctCommand = CorrectTransactionCommand(eventStore, projector,
        repository, accountRepository, categoryRepository);
    convertScheduledCommand = ConvertScheduledToPostedCommand(
        eventStore, projector, recurringRepository, accountRepository,
        categoryRepository);
    watchTransactionsQuery = WatchTransactionsQuery(repository);
    watchMonthlySnapshotQuery =
        WatchMonthlySnapshotQuery(database.monthlySnapshotDao, database.accountDao);
    getAccountBalanceQuery = GetAccountBalanceQuery(accountRepository);
    watchScheduledTransactionsQuery =
        WatchScheduledTransactionsQuery(recurringRepository);

    service = LedgerService(
      recordCommand,
      reverseCommand,
      correctCommand,
      convertScheduledCommand,
      watchTransactionsQuery,
      watchMonthlySnapshotQuery,
      getAccountBalanceQuery,
      watchScheduledTransactionsQuery,
    );
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> seedAccount(String id, {int balanceMinor = 0}) =>
      database.accountDao.upsert(AccountsViewCompanion.insert(
        id: id,
        name: 'Cash',
        type: AccountType.cash,
        currencyCode: 'USD',
        balanceMinor: balanceMinor,
        lastUpdatedEventId: 0,
      ));

  Future<void> seedCategory(String id,
          {CategoryType type = CategoryType.expense}) =>
      database.categoriesDao.upsert(CategoriesViewCompanion.insert(
        id: id,
        name: 'Food',
        iconKey: 'icon_food',
        colorInt: 0xFF000000,
        type: type,
        lastUpdatedEventId: 0,
      ));

  group('LedgerService', () {
    group('instantiation', () {
      test('should create instance with repository', () {
        expect(service, isNotNull);
      });
    });

    group('watchTransactions', () {
      test('should map TransactionWithDetails into TransactionEntity',
          () async {
        final month = DateTime(2026, 1);
        final date = DateTime(2026, 1, 15);

        const accountId = 'acc_1';
        const categoryId = 'cat_1';
        await seedAccount(accountId);
        await seedCategory(categoryId);

        // Insert projection rows directly (the write path is covered by
        // record_transaction_test).
        await database.transactionsDao.upsertTransaction(
            TransactionsViewCompanion.insert(
          transactionId: 'txn_1',
          occurredAt: date,
          kind: TransactionKind.expense,
          description: 'Test Note',
          categoryName: const Value('Food'),
          categoryIcon: const Value('icon_food'),
          categoryColorInt: const Value('ff000000'),
          originalEventId: 1,
        ));
        await database.transactionsDao.upsertPosting(
            TransactionPostingsViewCompanion.insert(
          id: 'txn_1:0',
          transactionId: 'txn_1',
          accountId: accountId,
          direction: PostingDirection.debit,
          amountMinor: 10000,
          currencyCode: 'USD',
          categoryId: const Value(categoryId),
        ));

        final stream = service.watchTransactions(month);
        await expectLater(
          stream,
          emits(
            [
              isA<TransactionEntity>()
                  .having((e) => e.id, 'id', 'txn_1')
                  .having((e) => e.amount, 'amount', -10000)
                  .having((e) => e.type, 'type', TransactionKind.expense)
                  .having((e) => e.date, 'date', date)
                  .having((e) => e.note, 'note', 'Test Note')
                  .having((e) => e.category.name, 'category name', 'Food')
                  .having((e) => e.account.name, 'account name', 'Cash')
                  .having((e) => e.isReversed, 'isReversed', false),
            ],
          ),
        );
      });
    });

    group('watchMonthlySnapshot', () {
      test('reads totals from the snapshot projection and current balance',
          () async {
        final month = DateTime(2026, 1);
        final date = DateTime(2026, 1, 15);

        const accountId = 'acc_1';
        await seedAccount(accountId);

        const expenseCategoryId = 'cat_expense';
        const incomeCategoryId = 'cat_income';
        await seedCategory(expenseCategoryId);
        await seedCategory(incomeCategoryId, type: CategoryType.income);

        await service.addTransaction(
          commandId: 'cmd_income',
          amountMinor: 10000,
          type: TransactionKind.income,
          date: date,
          categoryId: incomeCategoryId,
          accountId: accountId,
        );
        await service.addTransaction(
          commandId: 'cmd_expense',
          amountMinor: 2500,
          type: TransactionKind.expense,
          date: date,
          categoryId: expenseCategoryId,
          accountId: accountId,
        );

        final stream = service.watchMonthlySnapshot(month);
        await expectLater(
          stream,
          emits(
            isA<MonthlySnapshotTotals>()
                .having((s) => s.incomeMinor, 'income', 10000)
                .having((s) => s.expenseMinor, 'expense', -2500)
                .having((s) => s.balanceMinor, 'balance', 7500),
          ),
        );
      });
    });

    group('addTransaction', () {
      test('should record TransactionRecorded and update projections',
          () async {
        const accountId = 'acc_1';
        const categoryId = 'cat_1';
        await seedAccount(accountId);
        await seedCategory(categoryId);

        final date = DateTime(2026, 1, 15);

        final result = await service.addTransaction(
          commandId: 'cmd_add_expense',
          amountMinor: 10000,
          type: TransactionKind.expense,
          date: date,
          categoryId: categoryId,
          accountId: accountId,
          note: 'Test note',
        );

        expect(result, isA<Success<void>>());

        final events = (await eventStore.readAll()).events;
        expect(events, hasLength(1));
        expect(events.single.eventType, equals('TransactionRecorded'));

        final txRows = await database.select(database.transactionsView).get();
        expect(txRows, hasLength(1));
        expect(txRows.first.kind, equals(TransactionKind.expense));
        expect(txRows.first.description, equals('Test note'));
        expect(txRows.first.categoryName, equals('Food'));

        final postings =
            await database.select(database.transactionPostingsView).get();
        expect(postings, hasLength(1));
        expect(postings.first.direction, equals(PostingDirection.debit));
        expect(postings.first.amountMinor, equals(10000));

        final account = await database.accountDao.getAccountById(accountId);
        expect(account, isNotNull);
        expect(account!.balanceMinor, equals(-10000));
      });

      test('should accept income transactions', () async {
        const accountId = 'acc_1';
        const categoryId = 'cat_income';
        await seedAccount(accountId);
        await seedCategory(categoryId, type: CategoryType.income);

        final date = DateTime(2026, 1, 15);

        final result = await service.addTransaction(
          commandId: 'cmd_add_income',
          amountMinor: 100000,
          type: TransactionKind.income,
          date: date,
          categoryId: categoryId,
          accountId: accountId,
        );

        expect(result, isA<Success<void>>());

        final events = (await eventStore.readAll()).events;
        expect(events, hasLength(1));
        expect(events.single.eventType, equals('TransactionRecorded'));

        final postings =
            await database.select(database.transactionPostingsView).get();
        expect(postings, hasLength(1));
        expect(postings.first.direction, equals(PostingDirection.credit));
        expect(postings.first.amountMinor, equals(100000));
      });
    });

    group('deleteTransaction', () {
      test('should append reversal event', () async {
        const accountId = 'acc_1';
        const categoryId = 'cat_1';
        await seedAccount(accountId, balanceMinor: -500);
        await seedCategory(categoryId);

        await database.transactionsDao.upsertTransaction(
            TransactionsViewCompanion.insert(
          transactionId: 'txn_1',
          occurredAt: DateTime(2026, 1, 15),
          kind: TransactionKind.expense,
          description: 'Expense',
          categoryName: const Value('Food'),
          categoryIcon: const Value('icon_food'),
          categoryColorInt: const Value('ff000000'),
          originalEventId: 1,
        ));
        await database.transactionsDao.upsertPosting(
            TransactionPostingsViewCompanion.insert(
          id: 'txn_1:0',
          transactionId: 'txn_1',
          accountId: accountId,
          direction: PostingDirection.debit,
          amountMinor: 500,
          currencyCode: 'USD',
          categoryId: const Value(categoryId),
        ));

        final result =
            await service.deleteTransaction('txn_1', commandId: 'cmd_delete');

        expect(result, isA<Success<void>>());
        final events = (await eventStore.readAll()).events;
        expect(events, hasLength(1));
        expect(events.single.eventType, equals('TransactionReversed'));
      });
    });
  });
}
