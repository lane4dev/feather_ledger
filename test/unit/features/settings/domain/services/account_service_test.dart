import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/constants/category_constants.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_rebuild_service.dart';
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

    test('a starting balance is recorded as a balance adjustment', () async {
      final result = await harness.accountService.createAccount(
        commandId: 'cmd_create_savings',
        name: 'Savings',
        type: AccountType.bank,
        initialBalanceMinor: 200000,
        currencyCode: 'USD',
        initialBalanceNote: 'Initial Balance',
      );

      expect(result, isA<Success<void>>());
      final account = (await harness.db.accountDao.getAllAccounts()).single;
      expect(account.balanceMinor, 200000);

      final transactions =
          await harness.ledgerService.watchTransactions(DateTime.now()).first;
      expect(transactions, hasLength(1));
      final correction = transactions.single;
      expect(correction.type, TransactionKind.balanceAdjustment);
      expect(correction.amount, 200000);
      expect(correction.note, 'Initial Balance');
      expect(correction.category, isNull);
      expect(correction.account.id, account.id);
    });

    test('a negative starting balance remains a signed opening balance',
        () async {
      await harness.accountService.createAccount(
        commandId: 'cmd_create_overdraft',
        name: 'Overdraft',
        type: AccountType.bank,
        initialBalanceMinor: -50000,
        currencyCode: 'USD',
      );

      final account = (await harness.db.accountDao.getAllAccounts()).single;
      expect(account.balanceMinor, -50000);

      final transactions =
          await harness.ledgerService.watchTransactions(DateTime.now()).first;
      expect(transactions.single.type, TransactionKind.balanceAdjustment);
      expect(transactions.single.category, isNull);
    });

    test('a ledger needs no system category to record an opening balance',
        () async {
      final bare = LedgerServiceHarness();
      addTearDown(bare.close);

      final result = await bare.accountService.createAccount(
        commandId: 'cmd_bare',
        name: 'Cash',
        type: AccountType.cash,
        initialBalanceMinor: 1000,
        currencyCode: 'USD',
      );

      expect(result, isA<Success<void>>());
      expect(await bare.db.accountDao.getAllAccounts(), hasLength(1));
    });

    test('a later calibration records a balance adjustment, not income',
        () async {
      await harness.accountService.createAccount(
        commandId: 'cmd_create',
        name: 'Cash',
        type: AccountType.cash,
        initialBalanceMinor: 10000,
        currencyCode: 'USD',
      );
      final account = (await harness.db.accountDao.getAllAccounts()).single;

      final result = await harness.accountService.adjustAccountBalance(
        commandId: 'cmd_reconcile',
        accountId: account.id,
        newBalanceMinor: 12500,
        notes: 'Balance correction',
      );

      expect(result, isA<Success<void>>());
      final rows =
          await harness.ledgerService.watchTransactions(DateTime.now()).first;
      final adjustment = rows.singleWhere(
          (transaction) => transaction.note == 'Balance correction');
      expect(adjustment.type, TransactionKind.balanceAdjustment);
      expect(adjustment.amount, 2500);
      expect(adjustment.category, isNull);
      expect(adjustment.note, 'Balance correction');

      final snapshot = await harness.db.monthlySnapshotDao
          .getForAccount(account.id, DateTime.now().year, DateTime.now().month);
      expect(snapshot!.incomeMinor, 0);
      expect(snapshot.expenseMinor, 0);
      expect(snapshot.closingBalanceMinor, 12500);
    });

    test('a balance adjustment stays in the account\'s own currency',
        () async {
      await harness.accountService.createAccount(
        commandId: 'cmd_create_jpy',
        name: 'Yen wallet',
        type: AccountType.cash,
        initialBalanceMinor: 1000,
        currencyCode: 'JPY',
      );
      final account = (await harness.db.accountDao.getAllAccounts()).single;

      await harness.accountService.adjustAccountBalance(
        commandId: 'cmd_adjust_jpy',
        accountId: account.id,
        newBalanceMinor: 2500,
        notes: 'Reconciled',
      );

      final rows =
          await harness.ledgerService.watchTransactions(DateTime.now()).first;
      final adjustment = rows.singleWhere(
          (transaction) => transaction.note == 'Reconciled');
      expect(adjustment.account.currencyCode, 'JPY',
          reason: 'the adjustment belongs to the account, not any view');
      expect(adjustment.amount, 1500);
    });

    test('a balance-purpose correction reverses and replaces its event',
        () async {
      await harness.accountService.createAccount(
        commandId: 'cmd_create',
        name: 'Cash',
        type: AccountType.cash,
        initialBalanceMinor: 10000,
        currencyCode: 'USD',
      );
      final account = (await harness.db.accountDao.getAllAccounts()).single;
      final original =
          (await harness.ledgerService.watchTransactions(DateTime.now()).first)
              .single;

      final result = await harness.ledgerService.updateBalancePurpose(
        commandId: 'cmd_correct_opening',
        id: original.id,
        signedAmountMinor: 12000,
        date: DateTime.now(),
        accountId: account.id,
        note: 'Corrected opening',
      );

      expect(result, isA<Success<void>>());
      expect(
          (await harness.db.accountDao.getAccountById(account.id))!
              .balanceMinor,
          12000);
      final live =
          await harness.ledgerService.watchTransactions(DateTime.now()).first;
      expect(live.single.type, TransactionKind.balanceAdjustment);
      expect(live.single.note, 'Corrected opening');
      expect(
          (await allEvents())
              .where((event) => event.commandId == 'cmd_correct_opening')
              .map((event) => event.eventType),
          ['TransactionReversed', 'TransactionRecorded']);
    });

    test('legacy reversal-category records rebuild as balance purposes',
        () async {
      await harness.seedSystemCategories();
      await harness.accountService.createAccount(
        commandId: 'cmd_create',
        name: 'Legacy cash',
        type: AccountType.cash,
        initialBalanceMinor: 0,
        currencyCode: 'USD',
      );
      final account = (await harness.db.accountDao.getAllAccounts()).single;

      await harness.ledgerService.addTransaction(
        commandId: 'cmd_legacy-opening',
        amountMinor: 10000,
        type: TransactionKind.income,
        date: DateTime.now(),
        categoryId: CategoryConstants.reversalIncomeId,
        accountId: account.id,
        note: 'Initial balance for a new account.',
      );

      final legacy =
          (await harness.ledgerService.watchTransactions(DateTime.now()).first)
              .single;
      expect(legacy.type, TransactionKind.openingBalance);
      expect(legacy.category, isNull);
      final snapshot = await harness.db.monthlySnapshotDao
          .getForAccount(account.id, DateTime.now().year, DateTime.now().month);
      expect(snapshot!.incomeMinor, 0);
      expect(snapshot.closingBalanceMinor, 10000);
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

  group('includeInTotals', () {
    test('an account is born counting — no event says so', () async {
      final result = await harness.accountService.createAccount(
        commandId: 'cmd_totals_on',
        name: 'Wallet',
        type: AccountType.cash,
        initialBalanceMinor: 0,
        currencyCode: 'USD',
      );

      expect(result, isA<Success<void>>());
      final events = (await allEvents())
          .where((e) => e.commandId.startsWith('cmd_totals_on'))
          .toList();
      expect(events.map((e) => e.eventType), ['AccountCreated'],
          reason: 'counting is the column default, so it is not news');

      final account = (await harness.db.accountDao.getAllAccounts()).single;
      expect(account.includeInTotals, isTrue);
    });

    test('opting out at birth is a second event, not a field', () async {
      // The same shape as a starting balance: create the account, then record
      // the thing about it that is not the default. Keeping it out of
      // `AccountCreated` is what keeps a published payload from having to grow
      // a version for a constant.
      await harness.accountService.createAccount(
        commandId: 'cmd_totals_off',
        name: 'Held for a friend',
        type: AccountType.bank,
        initialBalanceMinor: 0,
        currencyCode: 'USD',
        includeInTotals: false,
      );

      final events = (await allEvents())
          .where((e) => e.commandId.startsWith('cmd_totals_off'))
          .toList();
      expect(events.map((e) => e.eventType),
          ['AccountCreated', 'AccountTotalsInclusionChanged']);

      final account = (await harness.db.accountDao.getAllAccounts()).single;
      expect(account.includeInTotals, isFalse);
    });

    test('toggling appends the event and updates the projection', () async {
      await harness.accountService.createAccount(
        commandId: 'cmd_toggle',
        name: 'Wallet',
        type: AccountType.cash,
        initialBalanceMinor: 0,
        currencyCode: 'USD',
      );
      final accountId =
          (await harness.db.accountDao.getAllAccounts()).single.id;

      final result = await harness.accountService.setTotalsInclusion(
        commandId: 'cmd_toggle_off',
        accountId: accountId,
        includeInTotals: false,
      );

      expect(result, isA<Success<void>>());
      expect(
          (await allEvents()).last.eventType, 'AccountTotalsInclusionChanged');
      final account = await harness.db.accountDao.getAccountById(accountId);
      expect(account!.includeInTotals, isFalse);
      expect(account.archived, isFalse,
          reason: 'the other off-switch is not this one');
      expect(account.balanceMinor, 0, reason: 'a flag moves no money');
    });

    test('the flag survives a rebuild — it is derived, not decoration',
        () async {
      // Without this, a projector branch that returned without writing
      // anything would pass every other test in the suite: the write path
      // would look right until the next rebuild quietly put the account back
      // in the totals.
      await harness.accountService.createAccount(
        commandId: 'cmd_rebuild',
        name: 'Held for a friend',
        type: AccountType.bank,
        initialBalanceMinor: 0,
        currencyCode: 'USD',
        includeInTotals: false,
      );
      final accountId =
          (await harness.db.accountDao.getAllAccounts()).single.id;

      await LedgerRebuildService(
        harness.db,
        harness.eventStore,
        harness.projector,
      ).rebuild();

      final account = await harness.db.accountDao.getAccountById(accountId);
      expect(account!.includeInTotals, isFalse,
          reason: 'the rebuild replays the event that wrote it');
    });

    test('unknown account fails with accountNotFound', () async {
      final result = await harness.accountService.setTotalsInclusion(
        commandId: 'cmd_toggle_missing',
        accountId: 'missing',
        includeInTotals: false,
      );

      expect(
        result,
        isA<Failure<void>>()
            .having((f) => f.code, 'code', LedgerErrorCode.accountNotFound),
      );
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
