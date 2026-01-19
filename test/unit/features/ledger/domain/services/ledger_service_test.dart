import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/database/tables.dart';
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
        final expectedStream = mockRepository.watchTransactions(month);

        // Act
        final stream = service.watchTransactions(month);

        // Assert
        expect(stream, equals(expectedStream));
      });
    });

    group('watchMonthlySummary', () {
      test('should return stream from repository', () {
        // Arrange
        final month = DateTime(2024, 1);
        final expectedStream = mockRepository.watchMonthlySummary(month);

        // Act
        final stream = service.watchMonthlySummary(month);

        // Assert
        expect(stream, equals(expectedStream));
      });
    });

    group('addTransaction', () {
      test('should call repository.addTransaction with correct parameters',
          () async {
        // Arrange
        const amount = 100.0;
        const type = TransactionType.expense;
        const categoryId = 5;
        const accountId = 3;
        const note = 'Test note';

        final date = DateTime(2024, 1, 15);

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
        expect(mockRepository.lastAmount, amount);
        expect(mockRepository.lastType, type);
        expect(mockRepository.lastDate, date);
        expect(mockRepository.lastCategoryId, categoryId);
        expect(mockRepository.lastAccountId, accountId);
        expect(mockRepository.lastNote, note);
      });

      test('should call repository without note when not provided', () async {
        // Arrange
        const amount = 100.0;
        const type = TransactionType.expense;
        const categoryId = 1;
        const accountId = 1;

        final date = DateTime(2024, 1, 15);

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
        expect(mockRepository.lastNote, isNull);
      });

      test('should throw exception when amount is zero', () async {
        // Arrange
        const amount = 0.0;
        const type = TransactionType.expense;
        const categoryId = 1;
        const accountId = 1;

        final date = DateTime(2024, 1, 15);

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
        const amount = -50.0;
        const type = TransactionType.expense;
        const categoryId = 1;
        const accountId = 1;

        final date = DateTime(2024, 1, 15);

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
        const amount = -50.0;
        const type = TransactionType.expense;
        const categoryId = 1;
        const accountId = 1;

        final date = DateTime(2024, 1, 15);

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
        const amount = 1000.0;
        const type = TransactionType.income;
        const categoryId = 1;
        const accountId = 1;

        final date = DateTime(2024, 1, 15);

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
        const transactionId = 42;

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
