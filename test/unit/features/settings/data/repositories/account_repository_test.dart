import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';
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

      test('should transform AccountViewRow to AccountEntity', () async {
        // Arrange
        const accounts = <AccountViewRow>[
          AccountViewRow(
            id: 'acc_1',
            name: 'Cash',
            type: AccountType.cash,
            currencyCode: 'USD',
            balanceMinor: 100000,
            archived: false,
            lastUpdatedEventId: 1,
            projectionVersion: 1,
          ),
          AccountViewRow(
            id: 'acc_2',
            name: 'Bank',
            type: AccountType.bank,
            currencyCode: 'USD',
            balanceMinor: 500000,
            archived: false,
            lastUpdatedEventId: 1,
            projectionVersion: 1,
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
        expect(result[0].id, 'acc_1');
        expect(result[0].name, 'Cash');
        expect(result[0].type, AccountType.cash);
        expect(result[0].balanceMinor, 100000);
        expect(result[1].id, 'acc_2');
        expect(result[1].name, 'Bank');
        expect(result[1].type, AccountType.bank);
        expect(result[1].balanceMinor, 500000);
      });

      test('should handle empty account list', () async {
        // Arrange
        final emptyAccounts = <AccountViewRow>[];

        // Subscribe to stream first, then emit
        final streamFuture = repository.watchAccounts().first;
        await Future.delayed(Duration.zero);
        mockDao.emitAccounts(emptyAccounts);

        final result = await streamFuture;

        // Assert
        expect(result, isEmpty);
      });
    });

    group('getAccount', () {
      test('should return AccountEntity when dao returns row', () async {
        // Arrange
        const row = AccountViewRow(
          id: 'acc_1',
          name: 'Cash',
          type: AccountType.cash,
          currencyCode: 'USD',
          balanceMinor: 100000,
          archived: false,
          lastUpdatedEventId: 1,
          projectionVersion: 1,
        );
        mockDao.emitAccounts([row]);

        // Act
        final result = await repository.getAccount('acc_1');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'acc_1');
        expect(result.name, 'Cash');
        expect(result.balanceMinor, 100000);
      });

      test('should return null when dao returns null', () async {
        // Arrange
        mockDao.emitAccounts(const []);

        // Act
        final result = await repository.getAccount('unknown');

        // Assert
        expect(result, isNull);
      });
    });
  });
}
