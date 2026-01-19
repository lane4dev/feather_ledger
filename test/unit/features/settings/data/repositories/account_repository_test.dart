import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/database/app_database.dart';
import 'package:feather_ledger/core/database/tables.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/settings/data/repositories/account_repository.dart';

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
        final accounts = [
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
        final name = 'Savings';
        final type = AccountType.bank;
        final initialBalance = 2000.0;

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
        final name = 'Petty Cash';
        final type = AccountType.cash;
        final initialBalance = 100.0;

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
        final name = 'Credit Card';
        final type = AccountType.credit;
        final initialBalance = 0.0;

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
        final name = 'New Account';
        final type = AccountType.bank;
        final initialBalance = 0.0;

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
        final name = 'Overdraft Account';
        final type = AccountType.bank;
        final initialBalance = -500.0;

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
        final id = 1;
        final name = 'Updated Account';
        final type = AccountType.bank;
        final initialBalance = 3000.0;

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
        final id = 1;
        final name = 'Account';
        final type = AccountType.credit;
        final initialBalance = 1000.0;

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
        final id = 1;
        final name = 'Account';
        final type = AccountType.bank;
        final initialBalance = 9999.99;

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
        final accountId = 42;

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
