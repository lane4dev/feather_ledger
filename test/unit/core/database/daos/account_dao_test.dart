import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;

import 'package:feather_ledger/core/database/app_database.dart';
import 'package:feather_ledger/core/database/tables.dart';

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
      final account = AccountsCompanion.insert(
        name: 'Test Account',
        type: AccountType.bank,
      );

      final id = await database.accountDao.addAccount(account);
      expect(id, greaterThan(0));

      final retrieved = await database.accountDao.getAccountById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Test Account'));
    });

    test('should return null for non-existent account', () async {
      final retrieved = await database.accountDao.getAccountById(999);
      expect(retrieved, isNull);
    });

    test('should get all accounts', () async {
      await database.accountDao.addAccount(AccountsCompanion.insert(
        name: 'A1',
        type: AccountType.cash,
      ));
      await database.accountDao.addAccount(AccountsCompanion.insert(
        name: 'A2',
        type: AccountType.bank,
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

      await database.accountDao.addAccount(AccountsCompanion.insert(
        name: 'A1',
        type: AccountType.cash,
      ));
      await database.accountDao.addAccount(AccountsCompanion.insert(
        name: 'A2',
        type: AccountType.bank,
      ));

      await expectation;
    });

    test('should update account', () async {
      final id = await database.accountDao.addAccount(AccountsCompanion.insert(
        name: 'Old',
        type: AccountType.cash,
      ));

      await database.accountDao.updateAccount(AccountsCompanion(
        id: Value(id),
        name: const Value('New'),
      ));

      final retrieved = await database.accountDao.getAccountById(id);
      expect(retrieved!.name, equals('New'));
    });

    test('should delete account', () async {
      final id = await database.accountDao.addAccount(AccountsCompanion.insert(
        name: 'Delete Me',
        type: AccountType.cash,
      ));

      final deleted = await database.accountDao.deleteAccount(id);
      expect(deleted, equals(1));

      final retrieved = await database.accountDao.getAccountById(id);
      expect(retrieved, isNull);
    });
  });
}
