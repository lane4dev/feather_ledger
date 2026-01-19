import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/database/tables.dart' as db_tables;
import 'package:feather_ledger/features/ledger/data/repositories/ledger_repository.dart';

import '../../../../../support/mocks/mock_transaction_dao.dart';
import '../../../../../support/fixtures/test_data_builder.dart';

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
      test('should complete successfully with all parameters', () async {
        final date = DateTime(2024, 1, 15);

        await expectLater(
          repository.addTransaction(
            amount: 250.0,
            type: db_tables.TransactionType.expense,
            date: date,
            categoryId: 5,
            accountId: 3,
            note: 'Test expense',
          ),
          completes,
        );
      });

      test('should complete successfully with null note', () async {
        final date = DateTime(2024, 1, 20);

        await expectLater(
          repository.addTransaction(
            amount: 100.0,
            type: db_tables.TransactionType.income,
            date: date,
            categoryId: 2,
            accountId: 1,
          ),
          completes,
        );
      });

      test('should complete for income transactions', () async {
        final date = DateTime(2024, 1, 25);

        await expectLater(
          repository.addTransaction(
            amount: 5000.0,
            type: db_tables.TransactionType.income,
            date: date,
            categoryId: 1,
            accountId: 2,
            note: 'Monthly salary',
          ),
          completes,
        );
      });

      test('should complete for expense transactions', () async {
        final date = DateTime(2024, 1, 28);

        await expectLater(
          repository.addTransaction(
            amount: 75.50,
            type: db_tables.TransactionType.expense,
            date: date,
            categoryId: 3,
            accountId: 1,
            note: 'Groceries',
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

      test('should handle deletion of non-existent transaction', () async {
        await expectLater(
          repository.deleteTransaction(99999),
          completes,
        );
      });
    });

    group('watchTransactions', () {
      test('should return a stream', () {
        final month = DateTime(2024, 1);
        final stream = repository.watchTransactions(month);
        expect(stream, isA<Stream>());
      });
    });

    group('watchMonthlySummary', () {
      test('should return a stream', () {
        final month = DateTime(2024, 1);
        final stream = repository.watchMonthlySummary(month);
        expect(stream, isA<Stream>());
      });
    });
  });
}
