import 'package:flutter_test/flutter_test.dart';
import 'dart:async';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_rebuild_service.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import '../../../../../support/event_sourcing/ledger_service_harness.dart';
import '../../../../../support/mocks/mock_shared_preferences.dart';

void main() {
  late LedgerServiceHarness h;
  setUp(() async {
    final prefs = PreferencesRepositoryImpl(MockSharedPreferences());
    await prefs.setCurrency('USD');
    h = LedgerServiceHarness(preferences: prefs);
  });
  tearDown(() => h.close());

  Future<String> account({int balance = 0, String currencyCode = 'USD'}) async {
    await h.accountService.createAccount(
        commandId: 'create-$currencyCode',
        name: 'Cash',
        type: AccountType.cash,
        initialBalanceMinor: balance,
        currencyCode: currencyCode);
    return (await h.db.accountDao.getAllAccounts())
        .firstWhere((a) => a.currencyCode == currencyCode)
        .id;
  }

  test('archive and restore retain totals and survive rebuild', () async {
    final id = await account(balance: 1000);
    expect(
        await h.accountService
            .archiveAccount(commandId: 'archive', accountId: id),
        isA<Success<void>>());
    expect((await h.accountRepository.getAccount(id))!.archived, isTrue);
    expect((await h.accountRepository.getAccount(id))!.includeInTotals, isTrue);
    expect(
        await h.accountService
            .restoreAccount(commandId: 'restore', accountId: id),
        isA<Success<void>>());
    await LedgerRebuildService(h.db, h.eventStore, h.projector).rebuild();
    final restored = (await h.accountRepository.getAccount(id))!;
    expect(restored.archived, isFalse);
    expect(restored.balanceMinor, 1000);
  });

  test('unused account disappears while deletion event survives rebuild',
      () async {
    final id = await account();
    expect(
        await h.accountService
            .deleteAccount(commandId: 'delete', accountId: id),
        isA<Success<void>>());
    expect(await h.accountService.watchAllAccounts().first, isEmpty);
    await LedgerRebuildService(h.db, h.eventStore, h.projector).rebuild();
    expect((await h.db.accountDao.getAccountById(id))!.deleted, isTrue);
    expect(await h.accountService.watchAllAccounts().first, isEmpty);
  });

  test('initial balance does not prevent deletion', () async {
    final id = await account(balance: 100);
    expect((await h.accountService.accountUsage(id)).transactions, 0);
    expect(
        await h.accountService
            .deleteAccount(commandId: 'delete', accountId: id),
        isA<Success<void>>());
    final accountRow = (await h.db.accountDao.getAccountById(id))!;
    expect(accountRow.deleted, isTrue);
    expect(accountRow.balanceMinor, 0);
  });

  test('deleted legacy opening balances leave ledger totals', () async {
    final id = await account();
    await h.eventStore.append([
      envelopeFor(
          OpeningBalanceSet(
              accountId: id, amountMinor: 500, currencyCode: 'USD'),
          aggregateType: AggregateType.account,
          streamVersion: await nextStreamVersion(h.eventStore, id),
          commandId: 'legacy',
          eventId: 'legacy-event'),
    ], options: AppendOptions(apply: h.projector.applyAll));
    expect(
        (await h.ledgerService
                .watchMonthlySnapshot(DateTime.now(), currencyCode: 'USD')
                .first)
            .balanceMinor,
        500);
    expect(
        await h.accountService
            .deleteAccount(commandId: 'delete', accountId: id),
        isA<Success<void>>());
    expect(
        (await h.ledgerService
                .watchMonthlySnapshot(DateTime.now(), currencyCode: 'USD')
                .first)
            .balanceMinor,
        0);
    await LedgerRebuildService(h.db, h.eventStore, h.projector).rebuild();
    expect(
        (await h.ledgerService
                .watchMonthlySnapshot(DateTime.now(), currencyCode: 'USD')
                .first)
            .balanceMinor,
        0);
  });

  test('account can be deleted after its only transaction is deleted',
      () async {
    final id = await account(balance: 100);
    final transaction =
        (await h.ledgerService.watchTransactions(DateTime.now()).first).single;
    expect(
        await h.ledgerService
            .deleteTransaction(transaction.id, commandId: 'reverse'),
        isA<Success<void>>());
    expect((await h.accountService.accountUsage(id)).transactions, 0);
    expect(
        await h.accountService
            .deleteAccount(commandId: 'delete', accountId: id),
        isA<Success<void>>());
    await LedgerRebuildService(h.db, h.eventStore, h.projector).rebuild();
    expect((await h.db.accountDao.getAccountById(id))!.deleted, isTrue);
  });

  test('a correction counts only its active replacement', () async {
    final id = await account(balance: 100);
    final original =
        (await h.ledgerService.watchTransactions(DateTime.now()).first).single;
    expect(
      await h.ledgerService.updateBalancePurpose(
        commandId: 'correct',
        id: original.id,
        signedAmountMinor: 200,
        date: DateTime.now(),
        accountId: id,
        note: 'Corrected',
      ),
      isA<Success<void>>(),
    );
    expect((await h.accountService.accountUsage(id)).transactions, 0);
    final result = await h.accountService
        .deleteAccount(commandId: 'delete', accountId: id);
    expect(result, isA<Success<void>>());
  });

  test('a reversed transfer permits deleting either account', () async {
    final first = await account();
    await h.accountService.createAccount(
      commandId: 'create_other',
      name: 'Bank',
      type: AccountType.bank,
      initialBalanceMinor: 0,
      currencyCode: 'USD',
    );
    final second = (await h.db.accountDao.getAllAccounts())
        .singleWhere((row) => row.id != first)
        .id;
    expect(
      await h.ledgerService.addTransfer(
        commandId: 'transfer',
        amountMinor: 100,
        fromAccountId: first,
        toAccountId: second,
        date: DateTime.now(),
      ),
      isA<Success<void>>(),
    );
    final transaction =
        (await h.ledgerService.watchTransactions(DateTime.now()).first).single;
    for (final id in [first, second]) {
      final result = await h.accountService
          .deleteAccount(commandId: 'try_$id', accountId: id);
      expect(
          (result as Failure<void>).code, LedgerErrorCode.accountHasReferences);
    }
    await h.ledgerService
        .deleteTransaction(transaction.id, commandId: 'reverse');
    for (final id in [first, second]) {
      final result = await h.accountService
          .deleteAccount(commandId: 'delete_$id', accountId: id);
      expect(result, isA<Success<void>>());
    }
    await LedgerRebuildService(h.db, h.eventStore, h.projector).rebuild();
    expect((await h.db.accountDao.getAccountById(first))!.deleted, isTrue);
    expect((await h.db.accountDao.getAccountById(second))!.deleted, isTrue);
  });

  test('moves expenses and reverses source adjustments atomically', () async {
    final source = await account(balance: 1000);
    await h.accountService.createAccount(
        commandId: 'other',
        name: 'Bank',
        type: AccountType.bank,
        initialBalanceMinor: 0,
        currencyCode: 'USD');
    final target = (await h.db.accountDao.getAllAccounts())
        .singleWhere((a) => a.id != source)
        .id;
    await h.categoryService.createCategory(
        commandId: 'category',
        name: 'Food',
        iconKey: '1',
        colorInt: 0,
        type: CategoryType.expense);
    final category = (await h.db.categoriesDao.getAllCategories()).single.id;
    await h.ledgerService.addTransaction(
        commandId: 'expense',
        amountMinor: 200,
        type: TransactionKind.expense,
        date: DateTime.now(),
        categoryId: category,
        accountId: source,
        note: 'Lunch');
    await h.categoryService.renameCategory(
        commandId: 'rename_category', categoryId: category, name: 'Dining');
    expect(
        await h.accountService.moveAccountTransactions(
            commandId: 'move', accountId: source, targetAccountId: target),
        isA<Success<void>>());
    expect((await h.db.accountDao.getAccountById(source))!.deleted, isTrue);
    expect((await h.db.accountDao.getAccountById(source))!.balanceMinor, 0);
    expect((await h.db.accountDao.getAccountById(target))!.balanceMinor, -200);
    final rows = await h.ledgerService.watchTransactions(DateTime.now()).first;
    expect(rows.single.account.id, target);
    expect(rows.single.note, 'Lunch');
    expect(rows.single.category!.name, 'Food');
    await LedgerRebuildService(h.db, h.eventStore, h.projector).rebuild();
    expect((await h.db.accountDao.getAccountById(target))!.balanceMinor, -200);
    expect(
        (await h.ledgerService.watchTransactions(DateTime.now()).first)
            .single
            .category!
            .name,
        'Food');
  });

  test('moving a transfer to its other account rolls back everything',
      () async {
    final source = await account(balance: 1000);
    await h.accountService.createAccount(
        commandId: 'other',
        name: 'Bank',
        type: AccountType.bank,
        initialBalanceMinor: 0,
        currencyCode: 'USD');
    final target = (await h.db.accountDao.getAllAccounts())
        .singleWhere((a) => a.id != source)
        .id;
    await h.ledgerService.addTransfer(
        commandId: 'transfer',
        amountMinor: 100,
        fromAccountId: source,
        toAccountId: target,
        date: DateTime.now());
    final result = await h.accountService.moveAccountTransactions(
        commandId: 'move', accountId: source, targetAccountId: target);
    expect((result as Failure<void>).code, LedgerErrorCode.sameAccountTransfer);
    expect((await h.db.accountDao.getAccountById(source))!.deleted, isFalse);
    expect((await h.db.accountDao.getAccountById(source))!.balanceMinor, 900);
    expect((await h.db.accountDao.getAccountById(target))!.balanceMinor, 100);
  });

  test('concurrent deletion and transfer cannot both succeed', () async {
    final first = await account();
    await h.accountService.createAccount(
      commandId: 'create_other',
      name: 'Bank',
      type: AccountType.bank,
      initialBalanceMinor: 0,
      currencyCode: 'USD',
    );
    final second = (await h.db.accountDao.getAllAccounts())
        .singleWhere((row) => row.id != first)
        .id;
    final results = await Future.wait([
      h.accountService.deleteAccount(commandId: 'delete', accountId: first),
      h.ledgerService.addTransfer(
        commandId: 'transfer',
        amountMinor: 100,
        fromAccountId: first,
        toAccountId: second,
        date: DateTime.now(),
      ),
    ]);
    expect(results.whereType<Success<void>>(), hasLength(1));
    expect(results.whereType<Failure<void>>(), hasLength(1));
  });

  test('archiving removes active series and permits deletion', () async {
    final id = await account();
    await h.seedSystemCategories();
    final category = (await h.db.categoriesDao.getAllCategories())
        .firstWhere((c) => c.type == CategoryType.expense);
    final created = await h.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 100,
        accountId: id,
        categoryId: category.id,
        description: 'Bill',
        frequency: 'MONTHLY',
        interval: 1,
        startDate: DateTime.now().add(const Duration(days: 1)));
    expect(created, isA<Success<void>>());
    final archive = await h.accountService
        .archiveAccount(commandId: 'archive', accountId: id);
    expect(archive, isA<Success<void>>());
    final delete = await h.accountService
        .deleteAccount(commandId: 'delete', accountId: id);
    expect(delete, isA<Success<void>>());
  });

  test(
      'archiving converts overdue auto-post bills to manual planned items and restoring keeps them pending',
      () async {
    // Use JPY while active currency is default (USD) so the overdue
    // auto-post bill stays pending until archive converts it to manual planned.
    final id = await account(currencyCode: 'JPY');
    await h.categoryService.createCategory(
      commandId: 'cat',
      name: 'Food',
      iconKey: '1',
      colorInt: 0,
      type: CategoryType.expense,
    );
    final category = (await h.db.categoriesDao.getAllCategories()).single.id;
    await h.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 100,
      accountId: id,
      categoryId: category,
      description: 'Bill',
      frequency: 'DAILY',
      interval: 1,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      countLimit: 1,
      autoPost: true,
      mode: RecurringSeriesMode.repeating,
    );
    expect(
        await h.accountService
            .archiveAccount(commandId: 'archive', accountId: id),
        isA<Success<void>>());
    await h.recurringService.catchUpAutoPosted();
    expect(
        await h.ledgerService.watchTransactions(DateTime.now()).first, isEmpty);
    expect(
        await h.accountService
            .restoreAccount(commandId: 'restore', accountId: id),
        isA<Success<void>>());
    expect(
        await h.ledgerService.watchTransactions(DateTime.now()).first, isEmpty);
    final remaining = await h.db.recurringDao.watchAllScheduled().first;
    expect(remaining, hasLength(1));
    expect(remaining.single.occurrenceKey, kPlannedOccurrenceKey);
    expect(remaining.single.status, 'scheduled');
  });

  test(
      'archiving removes original rules and future bills while keeping overdue bills and posted transactions',
      () async {
    final id = await account();
    await h.categoryService.createCategory(
        commandId: 'cat',
        name: 'Food',
        iconKey: '1',
        colorInt: 0,
        type: CategoryType.expense);
    final category = (await h.db.categoriesDao.getAllCategories()).single.id;
    await h.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 100,
        accountId: id,
        categoryId: category,
        description: 'Bill',
        frequency: 'DAILY',
        interval: 1,
        startDate: DateTime.now().subtract(const Duration(hours: 25)),
        countLimit: 4);
    final original = (await h.db.recurringDao.getAllSeries()).single;
    final before = await h.db.recurringDao.scheduledForSeries(original.id);
    final now = DateTime.now();
    DateTime effectiveDate(ScheduledTransactionViewRow row) =>
        row.dateOverride ?? row.scheduledDate;
    final overdue =
        before.where((row) => !effectiveDate(row).isAfter(now)).toList();
    final future =
        before.where((row) => effectiveDate(row).isAfter(now)).toList();
    expect(overdue, isNotEmpty);
    expect(future.length, greaterThanOrEqualTo(2));
    expect(
        await h.recurringService
            .postInstance(future.last.id, commandId: 'post_future'),
        isA<Success<void>>());
    expect(
        await h.accountService
            .archiveAccount(commandId: 'archive', accountId: id),
        isA<Success<void>>());
    expect(await h.db.recurringDao.getSeries(original.id), isNull);
    final plans = await h.db.recurringDao.getAllSeries();
    expect(plans, hasLength(overdue.length));
    expect(plans.every((plan) => plan.countLimit == 1), isTrue);
    final remaining = await h.db.recurringDao.watchAllScheduled().first;
    expect(remaining, hasLength(overdue.length));
    expect(
        remaining.every((bill) =>
            !effectiveDate(bill).isAfter(now) && bill.status == 'scheduled'),
        isTrue);
    expect(await h.ledgerService.watchTransactions(DateTime.now()).first,
        hasLength(1));
    await h.accountService.restoreAccount(commandId: 'restore', accountId: id);
    await h.recurringService.materialize();
    final restored = await h.db.recurringDao.watchAllScheduled().first;
    expect(restored, hasLength(overdue.length));
    expect(restored.every((bill) => !effectiveDate(bill).isAfter(now)), isTrue);
    expect(await h.db.recurringDao.getSeries(original.id), isNull);
  });

  test('archiving removes never-ending rules and future plans permanently',
      () async {
    final id = await account();
    await h.categoryService.createCategory(
        commandId: 'cat',
        name: 'Food',
        iconKey: '1',
        colorInt: 0,
        type: CategoryType.expense);
    final category = (await h.db.categoriesDao.getAllCategories()).single.id;
    final date = DateTime.now().add(const Duration(days: 2));
    for (final oneOff in [false, true]) {
      await h.recurringService.createSeries(
          type: RecurringSeriesKind.expense,
          amountMinor: 100,
          accountId: id,
          categoryId: category,
          description: 'Bill',
          frequency: 'DAILY',
          interval: 1,
          startDate: date,
          endDate: oneOff ? date : null);
    }
    expect(await h.db.recurringDao.getAllSeries(), hasLength(2));
    await h.accountService.archiveAccount(commandId: 'archive', accountId: id);
    expect(await h.db.recurringDao.getAllSeries(), isEmpty);
    expect(await h.db.recurringDao.watchAllScheduled().first, isEmpty);
    await h.accountService.restoreAccount(commandId: 'restore', accountId: id);
    await h.recurringService.materialize();
    expect(await h.db.recurringDao.getAllSeries(), isEmpty);
    expect(await h.db.recurringDao.watchAllScheduled().first, isEmpty);
  });

  test('scheduled listeners see overdue bill archive and restore', () async {
    final id = await account();
    await h.categoryService.createCategory(
        commandId: 'cat',
        name: 'Food',
        iconKey: '1',
        colorInt: 0,
        type: CategoryType.expense);
    final category = (await h.db.categoriesDao.getAllCategories()).single.id;
    await h.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 100,
        accountId: id,
        categoryId: category,
        description: 'Bill',
        frequency: 'DAILY',
        interval: 1,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        countLimit: 1);
    final events = StreamIterator(h.recurringService.watchScheduled());
    addTearDown(events.cancel);
    expect(await events.moveNext(), isTrue);
    expect(events.current.single.account!.archived, isFalse);
    await h.accountService.archiveAccount(commandId: 'archive', accountId: id);
    expect(await events.moveNext(), isTrue);
    expect(events.current.single.account!.archived, isTrue);
    await h.accountService.restoreAccount(commandId: 'restore', accountId: id);
    expect(await events.moveNext(), isTrue);
    expect(events.current.single.account!.archived, isFalse);
  });

  test('archived account deletion reverses a transfer on both accounts',
      () async {
    final source = await account(balance: 1000);
    await h.accountService.createAccount(
        commandId: 'other',
        name: 'Bank',
        type: AccountType.bank,
        initialBalanceMinor: 0,
        currencyCode: 'USD');
    final target = (await h.db.accountDao.getAllAccounts())
        .singleWhere((a) => a.id != source)
        .id;
    await h.ledgerService.addTransfer(
        commandId: 'transfer',
        amountMinor: 100,
        fromAccountId: source,
        toAccountId: target,
        date: DateTime.now());
    await h.accountService
        .archiveAccount(commandId: 'archive', accountId: source);
    expect(
        await h.accountService.deleteAccountWithTransactions(
            commandId: 'delete', accountId: source),
        isA<Success<void>>());
    expect((await h.db.accountDao.getAccountById(source))!.balanceMinor, 0);
    expect((await h.db.accountDao.getAccountById(target))!.balanceMinor, 0);
    await LedgerRebuildService(h.db, h.eventStore, h.projector).rebuild();
    expect((await h.db.accountDao.getAccountById(source))!.deleted, isTrue);
    expect((await h.db.accountDao.getAccountById(target))!.balanceMinor, 0);
  });

  test('moving an account moves its pending recurring rule', () async {
    final source = await account();
    await h.accountService.createAccount(
        commandId: 'other',
        name: 'Bank',
        type: AccountType.bank,
        initialBalanceMinor: 0,
        currencyCode: 'USD');
    final target = (await h.db.accountDao.getAllAccounts())
        .singleWhere((a) => a.id != source)
        .id;
    await h.categoryService.createCategory(
        commandId: 'cat',
        name: 'Food',
        iconKey: '1',
        colorInt: 0,
        type: CategoryType.expense);
    final category = (await h.db.categoriesDao.getAllCategories()).single.id;
    await h.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 100,
        accountId: source,
        categoryId: category,
        description: 'Bill',
        frequency: 'MONTHLY',
        interval: 1,
        startDate: DateTime.now().add(const Duration(days: 1)));
    expect(
        await h.accountService.moveAccountTransactions(
            commandId: 'move', accountId: source, targetAccountId: target),
        isA<Success<void>>());
    final items = await h.recurringService.watchScheduled().first;
    expect(items, isNotEmpty);
    expect(items.every((item) => item.account?.id == target), isTrue);
  });

  test('deleting an archived account deletes its pending rules', () async {
    final source = await account();
    await h.categoryService.createCategory(
        commandId: 'cat',
        name: 'Food',
        iconKey: '1',
        colorInt: 0,
        type: CategoryType.expense);
    final category = (await h.db.categoriesDao.getAllCategories()).single.id;
    await h.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 100,
        accountId: source,
        categoryId: category,
        description: 'Bill',
        frequency: 'MONTHLY',
        interval: 1,
        startDate: DateTime.now().add(const Duration(days: 1)));
    await h.accountService
        .archiveAccount(commandId: 'archive', accountId: source);
    expect(
        await h.accountService.deleteAccountWithTransactions(
            commandId: 'delete', accountId: source),
        isA<Success<void>>());
    expect(await h.db.recurringDao.getAllSeries(), isEmpty);
    expect(await h.recurringService.watchScheduled().first, isEmpty);
  });
}
