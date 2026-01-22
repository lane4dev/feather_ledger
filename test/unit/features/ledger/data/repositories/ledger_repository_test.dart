import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/entities/enums.dart';
import 'package:feather_ledger/core/data/database/daos/transaction_dao.dart';
import 'package:feather_ledger/features/ledger/data/repositories/ledger_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

import '../../../../../support/mocks/mock_transaction_dao.dart';

void main() {
  late LedgerRepository repository;
  late MockTransactionDao mockDao;

  setUp(() {
    mockDao = MockTransactionDao();
    repository = LedgerRepositoryImpl(mockDao);
  });

  tearDown(() {
    mockDao.dispose();
  });

  group('LedgerRepositoryImpl', () {
    test('should be instantiated correctly', () {
      expect(repository, isA<LedgerRepository>());
      expect(repository, isA<LedgerRepositoryImpl>());
    });

    group('addTransaction', () {
      test(
          'should complete successfully and potentially be verified via spy if implemented',
          () async {
        final date = DateTime(2024, 1, 15);

        // Since we are using a hand-rolled mock, we can't easily verify arguments
        // without adding spy logic to the mock.
        // For now, we ensure it completes without error, verifying the contract.
        await expectLater(
          repository.addTransaction(
            amount: 250.0,
            type: TransactionType.expense,
            date: date,
            categoryId: 5,
            accountId: 3,
            note: 'Test expense',
          ),
          completes,
        );
      });
    });

    group('deleteTransaction', () {
      test('should complete successfully', () async {
        await expectLater(
          repository.deleteTransaction(42),
          completes,
        );
      });
    });

    group('watchTransactions', () {
      test('should transform DAO objects to Entities correctly', () async {
        final month = DateTime(2024, 1);
        final date = DateTime(2024, 1, 15);

        // Prepare mock data
        final mockTransaction = Transaction(
          id: 1,
          amount: 100.0,
          type: TransactionType.expense,
          date: date,
          note: 'Test Note',
          categoryId: 2,
          accountId: 3,
          createdAt: DateTime.now(),
        );

        const mockCategory = Category(
          id: 2,
          name: 'Food',
          iconKey: 'icon_food',
          colorInt: 0xFF0000,
          type: TransactionType.expense,
          isDefault: false,
        );

        const mockAccount = Account(
          id: 3,
          name: 'Cash',
          type: AccountType.cash,
          initialBalance: 0.0,
        );

        final daoData = [
          TransactionWithDetails(mockTransaction, mockCategory, mockAccount)
        ];

        // Setup stream listener
        final stream = repository.watchTransactions(month);

        final expectation = expectLater(
            stream,
            emits([
              isA<TransactionEntity>()
                  .having((e) => e.id, 'id', 1)
                  .having((e) => e.amount, 'amount', 100.0)
                  .having((e) => e.type, 'type', TransactionType.expense)
                  .having((e) => e.date, 'date', date)
                  .having((e) => e.note, 'note', 'Test Note')
                  .having((e) => e.category.name, 'category name', 'Food')
                  .having((e) => e.account.name, 'account name', 'Cash'),
            ]));

        // Emit data
        mockDao.emitTransactions(daoData);

        await expectation;
      });

      test('should handle empty list', () async {
        final month = DateTime(2024, 1);
        final stream = repository.watchTransactions(month);

        final expectation = expectLater(stream, emits(isEmpty));

        mockDao.emitTransactions([]);

        await expectation;
      });
    });

    group('watchMonthlySummary', () {
      test('should combine totals and running balance into MonthlySummary',
          () async {
        final month = DateTime(2024, 1);

        // Setup mock return values
        mockDao.setRunningBalance(5000.0);

        final stream = repository.watchMonthlySummary(month);

        final expectation = expectLater(
            stream,
            emits(
              isA<MonthlySummary>()
                  .having((s) => s.month, 'month', month)
                  .having((s) => s.totalIncome, 'income', 2000.0)
                  .having((s) => s.totalExpense, 'expense', 1000.0)
                  .having((s) => s.runningBalance, 'balance', 5000.0),
            ));

        // Allow async* generator to initialize subscription
        await Future.delayed(Duration.zero);

        // Emit totals update
        mockDao.emitMonthlyTotals(2000.0, 1000.0);

        await expectation;
      });

      test('should update summary when totals change', () async {
        final month = DateTime(2024, 1);
        mockDao.setRunningBalance(5000.0);

        final stream = repository.watchMonthlySummary(month);

        final expectation = expectLater(
            stream,
            emitsInOrder([
              isA<MonthlySummary>()
                  .having((s) => s.totalIncome, 'income 1', 100.0),
              isA<MonthlySummary>()
                  .having((s) => s.totalIncome, 'income 2', 200.0),
            ]));

        // Allow async* generator to initialize subscription
        await Future.delayed(Duration.zero);

        mockDao.emitMonthlyTotals(100.0, 50.0);
        // Small delay to allow stream to process
        await Future.delayed(Duration.zero);
        mockDao.emitMonthlyTotals(200.0, 50.0);

        await expectation;
      });
    });
  });
}
