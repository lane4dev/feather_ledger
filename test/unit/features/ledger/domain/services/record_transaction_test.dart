import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import 'package:feather_ledger/features/ledger/domain/model/transaction.dart';

import '../../../../../support/event_sourcing/ledger_service_harness.dart';

/// RecordTransaction service tests (spec 003, US4/T038): the
/// income/expense closed loop — event stream, projections, single-point
/// balance, idempotency and full rollback.
void main() {
  late LedgerServiceHarness harness;

  setUp(() => harness = LedgerServiceHarness());
  tearDown(() => harness.close());

  Future<(String, String)> seedAccountAndCategory({
    CategoryType categoryType = CategoryType.expense,
    AccountType accountType = AccountType.cash,
    int balanceMinor = 0,
  }) async {
    final accountResult = await harness.accountService.createAccount(
      commandId: 'cmd_seed_account_${balanceMinor}_$accountType',
      name: 'Cash',
      type: accountType,
      initialBalanceMinor: balanceMinor,
      currencyCode: 'USD',
    );
    expect(accountResult, isA<Success<void>>());
    final account = (await harness.db.accountDao.getAllAccounts()).single;

    final categoryResult = await harness.categoryService.createCategory(
      commandId: 'cmd_seed_category_$categoryType',
      name: 'Food',
      iconKey: 'icon_food',
      colorInt: 0xFF123456,
      type: categoryType,
    );
    expect(categoryResult, isA<Success<void>>());
    final category = (await harness.db.categoriesDao.getAllCategories()).single;

    return (account.id, category.id);
  }

  group('record expense', () {
    test('10.50 expense writes one debit posting and decrements the balance',
        () async {
      final (accountId, categoryId) = await seedAccountAndCategory();

      final result = await harness.ledgerService.addTransaction(
        commandId: 'cmd_expense_1050',
        amountMinor: 1050,
        type: TransactionKind.expense,
        date: DateTime(2026, 1, 15),
        categoryId: categoryId,
        accountId: accountId,
        note: 'Lunch',
      );

      expect(result, isA<Success<void>>());

      final events = (await harness.eventStore.readAll()).events;
      expect(events, hasLength(3)); // account + category seeds + record
      expect(events.last.eventType, 'TransactionRecorded');
      final recorded =
          TransactionRecorded.fromJson(events.last.payloadJson);
      expect(recorded.kind, TransactionKind.expense);
      expect(recorded.postings.single.direction, PostingDirection.debit);
      expect(recorded.postings.single.amountMinor, 1050);
      expect(recorded.postings.single.currencyCode, 'USD');

      final txRows = await harness.db.select(harness.db.transactionsView).get();
      expect(txRows, hasLength(1));
      expect(txRows.single.categoryName, 'Food');
      expect(txRows.single.categoryIcon, 'icon_food');

      final postings =
          await harness.db.select(harness.db.transactionPostingsView).get();
      expect(postings.single.amountMinor, 1050);

      final account = await harness.db.accountDao.getAccountById(accountId);
      expect(account!.balanceMinor, -1050);
    });

    test('future-dated expense still counts toward the current balance',
        () async {
      final (accountId, categoryId) = await seedAccountAndCategory();

      await harness.ledgerService.addTransaction(
        commandId: 'cmd_future_expense',
        amountMinor: 2000,
        type: TransactionKind.expense,
        date: DateTime(2030, 6, 1), // far future
        categoryId: categoryId,
        accountId: accountId,
      );

      final account = await harness.db.accountDao.getAccountById(accountId);
      expect(account!.balanceMinor, -2000,
          reason: '当前余额包含未来已入账 posting（记了就算）');
    });

    test('expense on an archived account is rejected', () async {
      final (accountId, categoryId) = await seedAccountAndCategory();
      await harness.accountService.archiveAccount(
          commandId: 'cmd_archive', accountId: accountId);

      final result = await harness.ledgerService.addTransaction(
        commandId: 'cmd_on_archived',
        amountMinor: 500,
        type: TransactionKind.expense,
        date: DateTime.now(),
        categoryId: categoryId,
        accountId: accountId,
      );

      expect(
        result,
        isA<Failure<void>>()
            .having((f) => f.code, 'code', LedgerErrorCode.accountArchived),
      );
      final events = (await harness.eventStore.readAll()).events;
      expect(events.where((e) => e.eventType == 'TransactionRecorded'),
          isEmpty,
          reason: 'seed + archive only — no transaction event appended');
      expect(await harness.db.select(harness.db.transactionsView).get(),
          isEmpty);
    });
  });

  group('record income', () {
    test('income writes one credit posting and increases the balance',
        () async {
      final (accountId, categoryId) =
          await seedAccountAndCategory(categoryType: CategoryType.income);

      final result = await harness.ledgerService.addTransaction(
        commandId: 'cmd_income_5000',
        amountMinor: 5000,
        type: TransactionKind.income,
        date: DateTime(2026, 1, 15),
        categoryId: categoryId,
        accountId: accountId,
      );

      expect(result, isA<Success<void>>());
      final events = (await harness.eventStore.readAll()).events;
      final recorded =
          TransactionRecorded.fromJson(events.last.payloadJson);
      expect(recorded.kind, TransactionKind.income);
      expect(recorded.postings.single.direction, PostingDirection.credit);

      final account = await harness.db.accountDao.getAccountById(accountId);
      expect(account!.balanceMinor, 5000);
    });

    test('category type mismatch is rejected', () async {
      // Expense category, income transaction.
      final (accountId, categoryId) = await seedAccountAndCategory();

      final result = await harness.ledgerService.addTransaction(
        commandId: 'cmd_mismatch',
        amountMinor: 1000,
        type: TransactionKind.income,
        date: DateTime.now(),
        categoryId: categoryId,
        accountId: accountId,
      );

      expect(
        result,
        isA<Failure<void>>().having(
            (f) => f.code, 'code', LedgerErrorCode.categoryTypeMismatch),
      );
    });

    test('archived category is rejected', () async {
      final (accountId, categoryId) = await seedAccountAndCategory(
          categoryType: CategoryType.income);
      await harness.categoryService.archiveCategory(
          commandId: 'cmd_archive_cat', categoryId: categoryId);

      final result = await harness.ledgerService.addTransaction(
        commandId: 'cmd_on_archived_cat',
        amountMinor: 1000,
        type: TransactionKind.income,
        date: DateTime.now(),
        categoryId: categoryId,
        accountId: accountId,
      );

      expect(
        result,
        isA<Failure<void>>()
            .having((f) => f.code, 'code', LedgerErrorCode.categoryArchived),
      );
    });
  });

  group('idempotency and atomicity', () {
    test('duplicate commandId produces only one transaction', () async {
      final (accountId, categoryId) = await seedAccountAndCategory();

      final first = await harness.ledgerService.addTransaction(
        commandId: 'cmd_double_tap',
        amountMinor: 3000,
        type: TransactionKind.expense,
        date: DateTime(2026, 1, 15),
        categoryId: categoryId,
        accountId: accountId,
      );
      final second = await harness.ledgerService.addTransaction(
        commandId: 'cmd_double_tap',
        amountMinor: 3000,
        type: TransactionKind.expense,
        date: DateTime(2026, 1, 15),
        categoryId: categoryId,
        accountId: accountId,
      );

      expect(first, isA<Success<void>>());
      expect(second, isA<Failure<void>>());

      final events = (await harness.eventStore.readAll()).events;
      expect(events.where((e) => e.eventType == 'TransactionRecorded'),
          hasLength(1));
      expect(await harness.db.select(harness.db.transactionsView).get(),
          hasLength(1));

      final account = await harness.db.accountDao.getAccountById(accountId);
      expect(account!.balanceMinor, -3000, reason: 'no double debit');
    });

    test('projector failure rolls the whole append back', () async {
      // Append a TransactionRecorded referencing an unknown category —
      // the projector throws inside the transaction, so the event must not
      // persist either.
      final envelope = EventEnvelope(
        eventId: 'evt-bad-category',
        streamId: 'txn-bad',
        aggregateType: AggregateType.transaction,
        eventType: 'TransactionRecorded',
        streamVersion: 0,
        payloadJson: TransactionRecorded(
          transactionId: 'txn-bad',
          occurredAt: DateTime(2026, 1, 15),
          kind: TransactionKind.expense,
          description: 'boom',
          postings: const [
            Posting(
              accountId: 'missing-account',
              direction: PostingDirection.debit,
              amountMinor: 100,
              currencyCode: 'USD',
              categoryId: 'missing-category',
            ),
          ],
        ).toJson(),
        occurredAt: DateTime(2026, 1, 15),
        recordedAt: DateTime(2026, 1, 15),
        commandId: 'cmd-bad',
      );

      await expectLater(
        harness.eventStore.append(
          [envelope],
          options: AppendOptions(apply: harness.projector.applyAll),
        ),
        throwsStateError,
      );

      expect((await harness.eventStore.readAll()).events, isEmpty,
          reason: 'failed projection must not leave the event persisted');
      expect(await harness.db.select(harness.db.transactionsView).get(),
          isEmpty);
    });
  });

  group('archived category history', () {
    test('old transactions keep the write-time category snapshot', () async {
      final (accountId, categoryId) = await seedAccountAndCategory();

      await harness.ledgerService.addTransaction(
        commandId: 'cmd_history',
        amountMinor: 1200,
        type: TransactionKind.expense,
        date: DateTime(2026, 1, 15),
        categoryId: categoryId,
        accountId: accountId,
        note: 'Old hobby',
      );

      // Archive the category; the transaction must still render.
      await harness.categoryService.archiveCategory(
          commandId: 'cmd_archive_cat', categoryId: categoryId);

      final list = await harness.ledgerService
          .watchTransactions(DateTime(2026, 1))
          .first;
      expect(list, hasLength(1));
      expect(list.single.category.name, 'Food',
          reason: '写时快照 — archived category does not blank history');
      expect(list.single.category.archived, isFalse,
          reason: 'snapshot carries no live archived flag');
    });
  });
}
