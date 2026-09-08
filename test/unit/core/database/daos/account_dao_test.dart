import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';

import '../../../../support/fakes/fake_app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = FakeAppDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  group('AccountDao', () {
    test('should add and retrieve account', () async {
      const id = 'acc_1';
      final account = AccountsViewCompanion.insert(
        id: id,
        name: 'Test Account',
        type: AccountType.bank,
        currencyCode: 'USD',
        balanceMinor: 0,
        lastUpdatedEventId: 1,
      );

      await database.accountDao.upsert(account);

      final retrieved = await database.accountDao.getAccountById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Test Account'));
    });

    test('should return null for non-existent account', () async {
      final retrieved = await database.accountDao.getAccountById('missing');
      expect(retrieved, isNull);
    });

    test('should get all accounts', () async {
      await database.accountDao.upsert(AccountsViewCompanion.insert(
        id: 'acc_1',
        name: 'A1',
        type: AccountType.cash,
        currencyCode: 'USD',
        balanceMinor: 0,
        lastUpdatedEventId: 1,
      ));
      await database.accountDao.upsert(AccountsViewCompanion.insert(
        id: 'acc_2',
        name: 'A2',
        type: AccountType.bank,
        currencyCode: 'USD',
        balanceMinor: 0,
        lastUpdatedEventId: 2,
      ));

      final accounts = await database.accountDao.getAllAccounts();
      expect(accounts.length, equals(2));
      expect(accounts.any((a) => a.name == 'A1'), isTrue);
      expect(accounts.any((a) => a.name == 'A2'), isTrue);
    });

    test('should watch all accounts', () async {
      final stream = database.accountDao.watchAllAccounts();

      // Verify initial state
      expect(await stream.first, isEmpty);

      // Listen for subsequent changes, skipping the initial emission
      final expectation = expectLater(
          stream.skip(1),
          emitsInOrder([
            hasLength(1),
            hasLength(2),
          ]));

      await database.accountDao.upsert(AccountsViewCompanion.insert(
        id: 'acc_1',
        name: 'A1',
        type: AccountType.cash,
        currencyCode: 'USD',
        balanceMinor: 0,
        lastUpdatedEventId: 1,
      ));
      await database.accountDao.upsert(AccountsViewCompanion.insert(
        id: 'acc_2',
        name: 'A2',
        type: AccountType.bank,
        currencyCode: 'USD',
        balanceMinor: 0,
        lastUpdatedEventId: 2,
      ));

      await expectation;
    });

    test('should update account', () async {
      const id = 'acc_1';
      await database.accountDao.upsert(AccountsViewCompanion.insert(
        id: id,
        name: 'Old',
        type: AccountType.cash,
        currencyCode: 'USD',
        balanceMinor: 0,
        lastUpdatedEventId: 1,
      ));

      await database.accountDao.upsert(AccountsViewCompanion.insert(
        id: id,
        name: 'New',
        type: AccountType.cash,
        currencyCode: 'USD',
        balanceMinor: 0,
        lastUpdatedEventId: 2,
      ));

      final retrieved = await database.accountDao.getAccountById(id);
      expect(retrieved!.name, equals('New'));
    });

    test('should delete account', () async {
      const id = 'acc_1';
      await database.accountDao.upsert(AccountsViewCompanion.insert(
        id: id,
        name: 'Delete Me',
        type: AccountType.cash,
        currencyCode: 'USD',
        balanceMinor: 0,
        lastUpdatedEventId: 1,
      ));

      await database.accountDao.clearAll();

      final retrieved = await database.accountDao.getAccountById(id);
      expect(retrieved, isNull);
    });
  });
}
