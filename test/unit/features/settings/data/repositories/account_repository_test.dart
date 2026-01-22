import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/entities/enums.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/data/repositories/account_repository.dart';

import '../../../../../support/mocks/mock_account_dao.dart';

void main() {
  late MockAccountDao mockDao;
  late AccountRepository repository;

  setUp(() {
    mockDao = MockAccountDao();
    repository = AccountRepositoryImpl(mockDao);
  });

  tearDown(() {
    mockDao.dispose();
  });

  group('AccountRepositoryImpl', () {
    group('instantiation', () {
      test('should create instance with dao', () {
        expect(repository, isNotNull);
        expect(repository, isA<AccountRepository>());
      });
    });

    group('watchAccounts', () {
      test('should return stream of AccountEntity', () {
        // Arrange & Act
        final stream = repository.watchAccounts();

        // Assert
        expect(stream, isA<Stream<List<AccountEntity>>>());
      });

      test('should transform Account to AccountEntity', () async {
        // Arrange
        const accounts = [
          Account(
            id: 1,
            name: 'Cash',
            type: AccountType.cash,
            initialBalance: 1000.0,
          ),
          Account(
            id: 2,
            name: 'Bank',
            type: AccountType.bank,
            initialBalance: 5000.0,
          ),
        ];

        // Subscribe to stream first, then emit
        final streamFuture = repository.watchAccounts().first;
        await Future.delayed(Duration.zero);
        mockDao.emitAccounts(accounts);

        final result = await streamFuture;

        // Assert
        expect(result.length, 2);
        expect(result[0], isA<AccountEntity>());
        expect(result[0].id, 1);
        expect(result[0].name, 'Cash');
        expect(result[0].type, AccountType.cash);
        expect(result[0].initialBalance, 1000.0);
        expect(result[1].id, 2);
        expect(result[1].name, 'Bank');
        expect(result[1].type, AccountType.bank);
        expect(result[1].initialBalance, 5000.0);
      });

      test('should handle empty account list', () async {
        // Arrange
        final emptyAccounts = <Account>[];

        // Subscribe to stream first, then emit
        final streamFuture = repository.watchAccounts().first;
        await Future.delayed(Duration.zero);
        mockDao.emitAccounts(emptyAccounts);

        final result = await streamFuture;

        // Assert
        expect(result, isEmpty);
      });
    });

    group('addAccount', () {
      test('should call dao.addAccount with correct parameters', () async {
        // Arrange
        const name = 'Savings';
        const type = AccountType.bank;
        const initialBalance = 2000.0;

        // Act
        await repository.addAccount(
          name: name,
          type: type,
          initialBalance: initialBalance,
        );

        // Assert
        expect(mockDao.addAccountCallCount, 1);
        expect(mockDao.lastAddedAccount, isNotNull);
        expect(mockDao.lastAddedAccount!.name.value, name);
        expect(mockDao.lastAddedAccount!.type.value, type);
        expect(mockDao.lastAddedAccount!.initialBalance.value, initialBalance);
      });

      test('should handle cash account type', () async {
        // Arrange
        const name = 'Petty Cash';
        const type = AccountType.cash;
        const initialBalance = 100.0;

        // Act
        await repository.addAccount(
          name: name,
          type: type,
          initialBalance: initialBalance,
        );

        // Assert
        expect(mockDao.lastAddedAccount!.type.value, AccountType.cash);
      });

      test('should handle credit account type', () async {
        // Arrange
        const name = 'Credit Card';
        const type = AccountType.credit;
        const initialBalance = 0.0;

        // Act
        await repository.addAccount(
          name: name,
          type: type,
          initialBalance: initialBalance,
        );

        // Assert
        expect(mockDao.lastAddedAccount!.type.value, AccountType.credit);
      });

      test('should handle zero initial balance', () async {
        // Arrange
        const name = 'New Account';
        const type = AccountType.bank;
        const initialBalance = 0.0;

        // Act
        await repository.addAccount(
          name: name,
          type: type,
          initialBalance: initialBalance,
        );

        // Assert
        expect(mockDao.lastAddedAccount!.initialBalance.value, 0.0);
      });

      test('should handle negative initial balance', () async {
        // Arrange
        const name = 'Overdraft Account';
        const type = AccountType.bank;
        const initialBalance = -500.0;

        // Act
        await repository.addAccount(
          name: name,
          type: type,
          initialBalance: initialBalance,
        );

        // Assert
        expect(mockDao.lastAddedAccount!.initialBalance.value, -500.0);
      });
    });

    group('updateAccount', () {
      test('should call dao.updateAccount with correct parameters', () async {
        // Arrange
        const id = 1;
        const name = 'Updated Account';
        const type = AccountType.bank;
        const initialBalance = 3000.0;

        // Act
        await repository.updateAccount(
          id: id,
          name: name,
          type: type,
          initialBalance: initialBalance,
        );

        // Assert
        expect(mockDao.updateAccountCallCount, 1);
        expect(mockDao.lastUpdatedAccount, isNotNull);
        expect(mockDao.lastUpdatedAccount!.id.value, id);
        expect(mockDao.lastUpdatedAccount!.name.value, name);
        expect(mockDao.lastUpdatedAccount!.type.value, type);
        expect(
            mockDao.lastUpdatedAccount!.initialBalance.value, initialBalance);
      });

      test('should update account type', () async {
        // Arrange
        const id = 1;
        const name = 'Account';
        const type = AccountType.credit;
        const initialBalance = 1000.0;

        // Act
        await repository.updateAccount(
          id: id,
          name: name,
          type: type,
          initialBalance: initialBalance,
        );

        // Assert
        expect(mockDao.lastUpdatedAccount!.type.value, AccountType.credit);
      });

      test('should update initial balance', () async {
        // Arrange
        const id = 1;
        const name = 'Account';
        const type = AccountType.bank;
        const initialBalance = 9999.99;

        // Act
        await repository.updateAccount(
          id: id,
          name: name,
          type: type,
          initialBalance: initialBalance,
        );

        // Assert
        expect(mockDao.lastUpdatedAccount!.initialBalance.value, 9999.99);
      });
    });

    group('deleteAccount', () {
      test('should call dao.deleteAccount with correct id', () async {
        // Arrange
        const accountId = 42;

        // Act
        await repository.deleteAccount(accountId);

        // Assert
        expect(mockDao.deleteAccountCallCount, 1);
        expect(mockDao.lastDeletedId, accountId);
      });

      test('should handle multiple delete calls', () async {
        // Arrange & Act
        await repository.deleteAccount(1);
        await repository.deleteAccount(2);
        await repository.deleteAccount(3);

        // Assert
        expect(mockDao.deleteAccountCallCount, 3);
        expect(mockDao.lastDeletedId, 3);
      });
    });
  });
}
