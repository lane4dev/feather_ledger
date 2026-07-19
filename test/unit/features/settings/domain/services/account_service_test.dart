import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/constants/category_constants.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';

import '../../../../../support/event_sourcing/ledger_service_harness.dart';

/// Account lifecycle service tests (spec 003, US3/T031): create/rename/
/// archive go through the event stream and project atomically.
void main() {
  late LedgerServiceHarness harness;

  // The correction path files under the seeded system categories; a
  // harness ledger starts empty, so it asks for them the way bootstrap
  // does.
  setUp(() async {
    harness = LedgerServiceHarness();
    await harness.seedSystemCategories();
  });
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
      final created = (await allEvents())
          .where((e) => e.commandId == 'cmd_create_zero')
          .toList();
      expect(created, hasLength(1));
      expect(created.single.eventType, 'AccountCreated');

      final payload = AccountCreated.fromJson(created.single.payloadJson);
      expect(payload.name, 'Wallet');
      expect(payload.type, AccountType.cash);
      expect(payload.currencyCode, 'USD');

      final account =
          await harness.db.accountDao.getAccountById(payload.accountId);
      expect(account, isNotNull);
      expect(account!.balanceMinor, 0);
      expect(account.archived, isFalse);
      expect(account.lastUpdatedEventId, greaterThan(0));
      expect(
          await harness.ledgerService.watchTransactions(DateTime.now()).first,
          isEmpty,
          reason: 'an account opened empty records nothing to correct');
    });

    test('a starting balance is recorded as a correction transaction',
        () async {
      // Money the user types at creation is money: it shows up in the ledger
      // under the system category, with the note saying it is the difference.
      final result = await harness.accountService.createAccount(
        commandId: 'cmd_create_savings',
        name: 'Savings',
        type: AccountType.bank,
        initialBalanceMinor: 200000,
        currencyCode: 'USD',
        initialBalanceNote: 'Difference',
      );

      expect(result, isA<Success<void>>());
      final account = (await harness.db.accountDao.getAllAccounts()).single;
      expect(account.balanceMinor, 200000);

      final transactions = await harness.ledgerService
          .watchTransactions(DateTime.now())
          .first;
      expect(transactions, hasLength(1));
      final correction = transactions.single;
      expect(correction.type, TransactionKind.income);
      expect(correction.amount, 200000);
      expect(correction.note, 'Difference');
      expect(correction.category.id, CategoryConstants.reversalIncomeId);
      expect(correction.account.id, account.id);
    });

    test('a negative starting balance is an expense, sign and all', () async {
      // The retired OpeningBalanceSet path stored the absolute value, so an
      // overdraft opened at +500.00. As a transaction the sign survives.
      await harness.accountService.createAccount(
        commandId: 'cmd_create_overdraft',
        name: 'Overdraft',
        type: AccountType.bank,
        initialBalanceMinor: -50000,
        currencyCode: 'USD',
      );

      final account = (await harness.db.accountDao.getAllAccounts()).single;
      expect(account.balanceMinor, -50000);

      final transactions = await harness.ledgerService
          .watchTransactions(DateTime.now())
          .first;
      expect(transactions.single.type, TransactionKind.expense);
      expect(transactions.single.category.id,
          CategoryConstants.reversalExpenseId);
    });

    test('a ledger without the system categories rejects before writing',
        () async {
      // A harness built here has none: `setUp` only seeds the shared one.
      final bare = LedgerServiceHarness();
      addTearDown(bare.close);

      final result = await bare.accountService.createAccount(
        commandId: 'cmd_bare',
        name: 'Cash',
        type: AccountType.cash,
        initialBalanceMinor: 1000,
        currencyCode: 'USD',
      );

      expect(
        result,
        isA<Failure<void>>()
            .having((f) => f.code, 'code', LedgerErrorCode.categoryNotFound),
      );
      expect(await bare.db.accountDao.getAllAccounts(), isEmpty,
          reason: 'the category resolves before the account is created');
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
      expect(
        (await allEvents())
            .where((e) => e.commandId.startsWith('cmd_dup'))
            .map((e) => e.eventType),
        ['AccountCreated', 'TransactionRecorded'],
        reason: 'the retry appends nothing, and does not double the balance',
      );
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
      final created = AccountCreated.fromJson((await allEvents())
          .firstWhere((e) => e.commandId == 'cmd_create')
          .payloadJson);

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
      expect(
        (await allEvents()).where((e) => e.commandId.startsWith('cmd_rename')),
        isEmpty,
      );
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
      final created = AccountCreated.fromJson((await allEvents())
          .firstWhere((e) => e.commandId == 'cmd_create')
          .payloadJson);

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
