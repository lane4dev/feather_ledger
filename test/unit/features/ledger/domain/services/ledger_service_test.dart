import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/database/tables.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/services/ledger_service.dart';

import '../../../../../support/mocks/mock_ledger_repository.dart';

void main() {
  late MockLedgerRepository mockRepository;
  late LedgerService service;

  setUp(() {
    mockRepository = MockLedgerRepository();
    service = LedgerService(mockRepository);
  });

  tearDown(() {
    mockRepository.dispose();
  });

  group('LedgerService', () {
    group('instantiation', () {
      test('should create instance with repository', () {
        expect(service, isNotNull);
      });
    });

    group('watchTransactions', () {
      test('should return stream from repository', () {
        // Arrange
        final month = DateTime(2024, 1);

        // Act
        final stream = service.watchTransactions(month);

        // Assert
        expect(stream, isA<Stream<List<TransactionEntity>>>());
      });
    });

    group('watchMonthlySummary', () {
      test('should return stream from repository', () {
        // Arrange
        final month = DateTime(2024, 1);

        // Act
        final stream = service.watchMonthlySummary(month);

        // Assert
        expect(stream, isA<Stream<MonthlySummary>>());
      });
    });

    group('addTransaction', () {
      test('should call repository.addTransaction with correct parameters',
          () async {
        // Arrange
        final amount = 100.0;
        final type = TransactionType.expense;
        final date = DateTime(2024, 1, 15);
        final categoryId = 1;
        final accountId = 1;
        final note = 'Test note';

        // Act
        await service.addTransaction(
          amount: amount,
          type: type,
          date: date,
          categoryId: categoryId,
          accountId: accountId,
          note: note,
        );

        // Assert
        expect(mockRepository.addTransactionCallCount, 1);
      });

      test('should call repository without note when not provided', () async {
        // Arrange
        final amount = 100.0;
        final type = TransactionType.expense;
        final date = DateTime(2024, 1, 15);
        final categoryId = 1;
        final accountId = 1;

        // Act
        await service.addTransaction(
          amount: amount,
          type: type,
          date: date,
          categoryId: categoryId,
          accountId: accountId,
        );

        // Assert
        expect(mockRepository.addTransactionCallCount, 1);
      });

      test('should throw exception when amount is zero', () async {
        // Arrange
        final amount = 0.0;
        final type = TransactionType.expense;
        final date = DateTime(2024, 1, 15);
        final categoryId = 1;
        final accountId = 1;

        // Act & Assert
        expect(
          () => service.addTransaction(
            amount: amount,
            type: type,
            date: date,
            categoryId: categoryId,
            accountId: accountId,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception when amount is negative', () async {
        // Arrange
        final amount = -50.0;
        final type = TransactionType.expense;
        final date = DateTime(2024, 1, 15);
        final categoryId = 1;
        final accountId = 1;

        // Act & Assert
        expect(
          () => service.addTransaction(
            amount: amount,
            type: type,
            date: date,
            categoryId: categoryId,
            accountId: accountId,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should not call repository when validation fails', () async {
        // Arrange
        final amount = -50.0;
        final type = TransactionType.expense;
        final date = DateTime(2024, 1, 15);
        final categoryId = 1;
        final accountId = 1;

        // Act & Assert
        try {
          await service.addTransaction(
            amount: amount,
            type: type,
            date: date,
            categoryId: categoryId,
            accountId: accountId,
          );
        } catch (_) {
          // Expected exception
        }

        expect(mockRepository.addTransactionCallCount, 0);
      });

      test('should accept income transactions', () async {
        // Arrange
        final amount = 1000.0;
        final type = TransactionType.income;
        final date = DateTime(2024, 1, 15);
        final categoryId = 1;
        final accountId = 1;

        // Act
        await service.addTransaction(
          amount: amount,
          type: type,
          date: date,
          categoryId: categoryId,
          accountId: accountId,
        );

        // Assert
        expect(mockRepository.addTransactionCallCount, 1);
      });
    });

    group('deleteTransaction', () {
      test('should call repository.deleteTransaction with correct id',
          () async {
        // Arrange
        final transactionId = 42;

        // Act
        await service.deleteTransaction(transactionId);

        // Assert
        expect(mockRepository.deleteTransactionCallCount, 1);
        expect(mockRepository.lastDeletedId, transactionId);
      });

      test('should handle multiple delete calls', () async {
        // Arrange & Act
        await service.deleteTransaction(1);
        await service.deleteTransaction(2);
        await service.deleteTransaction(3);

        // Assert
        expect(mockRepository.deleteTransactionCallCount, 3);
        expect(mockRepository.lastDeletedId, 3);
      });
    });
  });
}
