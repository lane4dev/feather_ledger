import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';

import '../../../../../support/event_sourcing/ledger_service_harness.dart';

/// Account lifecycle service tests (spec 003, US3/T031): create/rename/
/// archive go through the event stream and project atomically.
void main() {
  late LedgerServiceHarness harness;

  setUp(() => harness = LedgerServiceHarness());
  tearDown(() => harness.close());

  Future<List<dynamic>> allEvents() async =>
      (await harness.eventStore.readAll()).events;

  group('createAccount', () {
    test('zero balance produces AccountCreated only and projects the row',
        () async {
      final result = await harness.accountService.createAccount(
        commandId: 'cmd_create_zero',
        name: 'Wallet',
        type: AccountType.cash,
        initialBalanceMinor: 0,
        currencyCode: 'USD',
      );

      expect(result, isA<Success<void>>());
      final events = await allEvents();
      expect(events, hasLength(1));
      expect(events.single.eventType, 'AccountCreated');

      final created = AccountCreated.fromJson(events.single.payloadJson);
      expect(created.name, 'Wallet');
      expect(created.type, AccountType.cash);
      expect(created.currencyCode, 'USD');

      final account =
          await harness.db.accountDao.getAccountById(created.accountId);
      expect(account, isNotNull);
      expect(account!.balanceMinor, 0);
      expect(account.archived, isFalse);
      expect(account.lastUpdatedEventId, greaterThan(0));
    });

    test('non-zero initial balance adds OpeningBalanceSet in one batch',
        () async {
      final result = await harness.accountService.createAccount(
        commandId: 'cmd_create_savings',
        name: 'Savings',
        type: AccountType.bank,
        initialBalanceMinor: 200000,
        currencyCode: 'USD',
      );

      expect(result, isA<Success<void>>());
      final events = await allEvents();
      expect(events.map((e) => e.eventType).toList(),
          ['AccountCreated', 'OpeningBalanceSet']);

      final created = AccountCreated.fromJson(events.first.payloadJson);
      final opening =
          OpeningBalanceSet.fromJson(events.last.payloadJson);
      expect(opening.accountId, created.accountId);
      expect(opening.amountMinor, 200000);

      final account =
          await harness.db.accountDao.getAccountById(created.accountId);
      expect(account!.balanceMinor, 200000);
    });

    test('negative initial balance is applied as the absolute opening',
        () async {
      await harness.accountService.createAccount(
        commandId: 'cmd_create_overdraft',
        name: 'Overdraft',
        type: AccountType.bank,
        initialBalanceMinor: -50000,
        currencyCode: 'USD',
      );

      final events = await allEvents();
      final opening = OpeningBalanceSet.fromJson(events.last.payloadJson);
      expect(opening.amountMinor, -50000);

      final account =
          await harness.db.accountDao.getAccountById(opening.accountId);
      expect(account!.balanceMinor, 50000,
          reason: 'projector sets the balance to the absolute value');
    });

    test('duplicate commandId short-circuits — no second account', () async {
      await harness.accountService.createAccount(
        commandId: 'cmd_dup',
        name: 'Wallet',
        type: AccountType.cash,
        initialBalanceMinor: 1000,
        currencyCode: 'USD',
      );
      final result = await harness.accountService.createAccount(
        commandId: 'cmd_dup',
        name: 'Wallet Again',
        type: AccountType.cash,
        initialBalanceMinor: 1000,
        currencyCode: 'USD',
      );

      expect(result, isA<Failure<void>>());
      expect(await allEvents(), hasLength(2));
      expect(await harness.db.accountDao.getAllAccounts(), hasLength(1));
    });
  });

  group('renameAccount', () {
    test('appends AccountRenamed and updates the projection', () async {
      await harness.accountService.createAccount(
        commandId: 'cmd_create',
        name: 'Old Name',
        type: AccountType.cash,
        initialBalanceMinor: 0,
        currencyCode: 'USD',
      );
      final created = AccountCreated.fromJson(
          (await allEvents()).single.payloadJson);

      final result = await harness.accountService.renameAccount(
        commandId: 'cmd_rename',
        accountId: created.accountId,
        name: 'New Name',
      );

      expect(result, isA<Success<void>>());
      final events = await allEvents();
      expect(events.last.eventType, 'AccountRenamed');
      expect(
        AccountRenamed.fromJson(events.last.payloadJson).name,
        'New Name',
      );

      final account =
          await harness.db.accountDao.getAccountById(created.accountId);
      expect(account!.name, 'New Name');
    });

    test('unknown account fails with accountNotFound', () async {
      final result = await harness.accountService.renameAccount(
        commandId: 'cmd_rename_missing',
        accountId: 'missing',
        name: 'Whatever',
      );

      expect(
        result,
        isA<Failure<void>>()
            .having((f) => f.code, 'code', LedgerErrorCode.accountNotFound),
      );
      expect(await allEvents(), isEmpty);
    });
  });

  group('archiveAccount', () {
    test('appends AccountArchived and flags the projection', () async {
      await harness.accountService.createAccount(
        commandId: 'cmd_create',
        name: 'To Archive',
        type: AccountType.credit,
        initialBalanceMinor: 0,
        currencyCode: 'USD',
      );
      final created = AccountCreated.fromJson(
          (await allEvents()).single.payloadJson);

      final result = await harness.accountService.archiveAccount(
        commandId: 'cmd_archive',
        accountId: created.accountId,
      );

      expect(result, isA<Success<void>>());
      final events = await allEvents();
      expect(events.last.eventType, 'AccountArchived');

      final account =
          await harness.db.accountDao.getAccountById(created.accountId);
      expect(account!.archived, isTrue);
      expect(account.balanceMinor, 0,
          reason: 'history and balance are retained on archive');
    });

    test('unknown account fails with accountNotFound', () async {
      final result = await harness.accountService.archiveAccount(
        commandId: 'cmd_archive_missing',
        accountId: 'missing',
      );

      expect(
        result,
        isA<Failure<void>>()
            .having((f) => f.code, 'code', LedgerErrorCode.accountNotFound),
      );
    });
  });
}
