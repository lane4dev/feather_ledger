import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/budget_dao.dart';
import 'package:feather_ledger/core/domain/enums.dart';

import '../../../../support/fakes/fake_app_database.dart';

void main() {
  late AppDatabase db;
  late BudgetDao dao;

  setUp(() async {
    db = FakeAppDatabase();
    dao = db.budgetDao;
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedAccount({
    required String id,
    required String currencyCode,
    bool includeInTotals = true,
    bool deleted = false,
    bool archived = false,
  }) async {
    await db.into(db.accountsView).insert(
          AccountsViewCompanion.insert(
            id: id,
            name: 'Acc $id',
            type: AccountType.cash,
            currencyCode: currencyCode,
            balanceMinor: 0,
            includeInTotals: Value(includeInTotals),
            deleted: Value(deleted),
            archived: Value(archived),
            lastUpdatedEventId: 1,
          ),
        );
  }

  Future<void> seedCategory({
    required String id,
    CategoryType type = CategoryType.expense,
    String? systemCode,
    bool archived = false,
    DateTime? archivedAt,
  }) async {
    await db.into(db.categoriesView).insert(
          CategoriesViewCompanion.insert(
            id: id,
            name: 'Cat $id',
            iconKey: 'utensils',
            colorInt: 0xFFE65100,
            type: type,
            systemCode: Value(systemCode),
            archived: Value(archived),
            archivedAt: Value(archivedAt),
            lastUpdatedEventId: 1,
          ),
        );
  }

  Future<void> seedExpenseTx({
    required String txId,
    required String accountId,
    required String categoryId,
    required String currencyCode,
    required DateTime occurredAt,
    required int amountMinor,
    TransactionKind kind = TransactionKind.expense,
    bool isReversed = false,
    String? sourceScheduledBillId,
  }) async {
    await db.into(db.transactionsView).insert(
          TransactionsViewCompanion.insert(
            transactionId: txId,
            occurredAt: occurredAt,
            kind: kind,
            description: 'Tx $txId',
            isReversed: Value(isReversed),
            sourceScheduledBillId: Value(sourceScheduledBillId),
            originalEventId: 1,
          ),
        );
    await db.into(db.transactionPostingsView).insert(
          TransactionPostingsViewCompanion.insert(
            id: '$txId:0',
            transactionId: txId,
            accountId: accountId,
            direction: PostingDirection.debit,
            amountMinor: amountMinor,
            currencyCode: currencyCode,
            categoryId: Value(categoryId),
          ),
        );
  }

  group('BudgetDao rule timeline & ascending pruning', () {
    test('thisMonthOnly anchors M+1 across Dec->Jan and prunes redundancies',
        () async {
      final now = DateTime(2026, 5, 1);

      // Set 2026-11 -> 2000 (thisAndFollowing)
      await dao.upsertBudgetRule(
        currencyCode: 'CNY',
        categoryId: 'dining',
        targetYm: 202611,
        amountMinor: 200000,
        thisMonthOnly: false,
        now: now,
      );
      expect(await dao.hasFutureRulesAfter('CNY', 'dining', 202611), isFalse);

      // Edit 2026-12 only -> 1500; must anchor 2027-01 -> 2000 (not 202613!)
      await dao.upsertBudgetRule(
        currencyCode: 'CNY',
        categoryId: 'dining',
        targetYm: 202612,
        amountMinor: 150000,
        thisMonthOnly: true,
        now: now,
      );
      var rows = await dao.getRulesForCategory('CNY', 'dining');
      expect(rows.map((r) => (r.effectiveYm, r.amountMinor)).toList(), [
        (202611, 200000),
        (202612, 150000),
        (202701, 200000),
      ]);
      expect(await dao.hasFutureRulesAfter('CNY', 'dining', 202612), isTrue);

      // Now edit 2026-12 back to 2000 (thisMonthOnly) -> both 202612 and 202701
      // become redundant in ascending order and must be pruned cleanly!
      await dao.upsertBudgetRule(
        currencyCode: 'CNY',
        categoryId: 'dining',
        targetYm: 202612,
        amountMinor: 200000,
        thisMonthOnly: true,
        now: now,
      );
      rows = await dao.getRulesForCategory('CNY', 'dining');
      expect(rows.map((r) => (r.effectiveYm, r.amountMinor)).toList(), [
        (202611, 200000),
      ]);
    });

    test(
      'leading null sentinel is pruned when clearing unset timeline',
      () async {
        final now = DateTime(2026, 5, 1);
        await dao.upsertBudgetRule(
          currencyCode: 'CNY',
          categoryId: 'dining',
          targetYm: 202604,
          amountMinor: 100000,
          thisMonthOnly: true,
          now: now,
        );
        var rows = await dao.getRulesForCategory('CNY', 'dining');
        expect(rows.map((r) => (r.effectiveYm, r.amountMinor)).toList(), [
          (202604, 100000),
          (202605, null),
        ]);

        // Clear 2026-04 only -> both leading null (202604) and trailing null
        // (202605) collapse to zero rows.
        await dao.upsertBudgetRule(
          currencyCode: 'CNY',
          categoryId: 'dining',
          targetYm: 202604,
          amountMinor: null,
          thisMonthOnly: true,
          now: now,
        );
        rows = await dao.getRulesForCategory('CNY', 'dining');
        expect(rows, isEmpty);
      },
    );

    test('review notes enforce composite PK and blank deletion', () async {
      final now = DateTime(2026, 5, 1);
      await dao.upsertReviewNote(
        currencyCode: 'CNY',
        ym: 202605,
        categoryKey: '',
        note: 'Month note v1',
        now: now,
      );
      await dao.upsertReviewNote(
        currencyCode: 'CNY',
        ym: 202605,
        categoryKey: '',
        note: 'Month note v2',
        now: now,
      );
      await dao.upsertReviewNote(
        currencyCode: 'CNY',
        ym: 202605,
        categoryKey: 'dining',
        note: 'Dining note',
        now: now,
      );

      var notes = await dao.getNotesForMonth('CNY', 202605);
      expect(notes.length, 2);
      expect(
        notes.firstWhere((n) => n.categoryKey == '').note,
        'Month note v2',
      );

      await dao.upsertReviewNote(
        currencyCode: 'CNY',
        ym: 202605,
        categoryKey: 'dining',
        note: '   ',
        now: now,
      );
      notes = await dao.getNotesForMonth('CNY', 202605);
      expect(notes.length, 1);
      expect(notes.single.categoryKey, '');
    });
  });

  group('BudgetDao atomic budget clear with category notes', () {
    const currency = 'CNY';
    const categoryId = 'travel';
    final now = DateTime(2026, 5, 1);

    Future<void> seedRule(int ym, int? amountMinor) async {
      await db.into(db.budgetRules).insert(
            BudgetRulesCompanion.insert(
              currencyCode: currency,
              categoryId: categoryId,
              effectiveYm: ym,
              amountMinor: Value(amountMinor),
              updatedAt: now,
            ),
          );
    }

    Future<void> seedNote(
      String currencyCode,
      int ym,
      String categoryKey,
      String note,
    ) =>
        dao.upsertReviewNote(
          currencyCode: currencyCode,
          ym: ym,
          categoryKey: categoryKey,
          note: note,
          now: now,
        );

    // October has its own rule, November has a breakpoint, December only
    // inherits November's amount. Notes exist in all three months, plus
    // month-level and other-category notes that a category clear must keep.
    Future<void> seedOctoberToDecember() async {
      await seedRule(202610, 100000);
      await seedRule(202611, 120000);
      await seedNote(currency, 202610, categoryId, 'Oct travel note');
      await seedNote(currency, 202611, categoryId, 'Nov travel note');
      await seedNote(currency, 202612, categoryId, 'Dec travel note');
      await seedNote(currency, 202611, '', 'Nov month note');
      await seedNote(currency, 202612, '', 'Dec month note');
      await seedNote(currency, 202611, 'groceries', 'Nov groceries note');
      await seedNote('USD', 202611, categoryId, 'USD travel note');
    }

    Future<Map<String, String>> notesFor(String currencyCode, int ym) async {
      final rows = await dao.getNotesForMonth(currencyCode, ym);
      return {for (final row in rows) row.categoryKey: row.note};
    }

    Future<List<(int, int?)>> rulesFor() async {
      final rows = await dao.getRulesForCategory(currency, categoryId);
      return [for (final row in rows) (row.effectiveYm, row.amountMinor)];
    }

    test(
        'this month only clears that month note and keeps the inherited '
        'amount for the next month', () async {
      await seedOctoberToDecember();

      await dao.upsertBudgetRule(
        currencyCode: currency,
        categoryId: categoryId,
        targetYm: 202611,
        amountMinor: null,
        thisMonthOnly: true,
        now: now,
      );

      expect(await rulesFor(), [
        (202610, 100000),
        (202611, null),
        (202612, 120000),
      ]);
      expect(await notesFor(currency, 202611), {
        '': 'Nov month note',
        'groceries': 'Nov groceries note',
      });
      expect(await notesFor(currency, 202610), {categoryId: 'Oct travel note'});
      expect(await notesFor(currency, 202612), {
        '': 'Dec month note',
        categoryId: 'Dec travel note',
      });
      expect(await notesFor('USD', 202611), {categoryId: 'USD travel note'});
    });

    test(
        'this and following clears notes in months that only inherit the '
        'budget, leaving earlier and later breakpoints intact', () async {
      await seedOctoberToDecember();
      expect(
        await dao.hasFutureRulesAfter(currency, categoryId, 202610),
        isTrue,
      );

      await dao.upsertBudgetRule(
        currencyCode: currency,
        categoryId: categoryId,
        targetYm: 202611,
        amountMinor: null,
        thisMonthOnly: false,
        now: now,
      );

      expect(await rulesFor(), [(202610, 100000), (202611, null)]);
      expect(await notesFor(currency, 202610), {categoryId: 'Oct travel note'});
      expect(await notesFor(currency, 202611), {
        '': 'Nov month note',
        'groceries': 'Nov groceries note',
      });
      // December had no rule of its own but was inside the cleared range.
      expect(await notesFor(currency, 202612), {'': 'Dec month note'});
      expect(await notesFor('USD', 202611), {categoryId: 'USD travel note'});
    });

    // The calculator turns these note rows into the trend chart's note marker,
    // so the marker can only disappear with the row.
    test('cleared notes no longer mark the summary trend', () async {
      await seedOctoberToDecember();

      Future<List<String>> markers(int targetYm) async {
        final summary =
            await dao.watchMonthBudgetSummary(currency, targetYm).first;
        return summary.reviewNotes
            .map((note) => '${note.ym}:${note.categoryKey}')
            .toList();
      }

      expect(
        await markers(202611),
        unorderedEquals([
          '202610:$categoryId',
          '202611:$categoryId',
          '202611:',
          '202611:groceries',
        ]),
      );

      await dao.upsertBudgetRule(
        currencyCode: currency,
        categoryId: categoryId,
        targetYm: 202611,
        amountMinor: null,
        thisMonthOnly: false,
        now: now,
      );

      expect(
        await markers(202611),
        unorderedEquals([
          '202610:$categoryId',
          '202611:',
          '202611:groceries',
        ]),
      );
    });

    test('editing the amount keeps every category note', () async {
      await seedOctoberToDecember();

      await dao.upsertBudgetRule(
        currencyCode: currency,
        categoryId: categoryId,
        targetYm: 202611,
        amountMinor: 130000,
        thisMonthOnly: true,
        now: now,
      );

      expect(await notesFor(currency, 202611), {
        categoryId: 'Nov travel note',
        '': 'Nov month note',
        'groceries': 'Nov groceries note',
      });
      expect(await notesFor(currency, 202612), {
        categoryId: 'Dec travel note',
        '': 'Dec month note',
      });
    });

    test(
      'a failing note delete rolls back the rule write and its breakpoints',
      () async {
        await seedOctoberToDecember();
        final failingDao = _FailingNoteDeleteBudgetDao(db);

        await expectLater(
          failingDao.upsertBudgetRule(
            currencyCode: currency,
            categoryId: categoryId,
            targetYm: 202611,
            amountMinor: null,
            thisMonthOnly: true,
            now: now,
          ),
          throwsStateError,
        );

        // The this-month-only clear writes a December breakpoint first; both it
        // and the cleared November rule must be gone again.
        expect(await rulesFor(), [(202610, 100000), (202611, 120000)]);
        expect(
          await dao.hasFutureRulesAfter(currency, categoryId, 202611),
          isFalse,
        );
        expect(await notesFor(currency, 202611), {
          categoryId: 'Nov travel note',
          '': 'Nov month note',
          'groceries': 'Nov groceries note',
        });
        expect(await notesFor(currency, 202612), {
          categoryId: 'Dec travel note',
          '': 'Dec month note',
        });
      },
    );
  });

  group('BudgetDao three streams & filtering', () {
    test(
        'watchMonthBudgetSummary respects local month bounds, systemCode, '
        'includeInTotals, deleted, and archived accounts', () async {
      await seedAccount(id: 'acc-ok', currencyCode: 'CNY');
      await seedAccount(id: 'acc-arch', currencyCode: 'CNY', archived: true);
      await seedAccount(
        id: 'acc-excl',
        currencyCode: 'CNY',
        includeInTotals: false,
      );
      await seedAccount(id: 'acc-del', currencyCode: 'CNY', deleted: true);
      await seedAccount(id: 'acc-usd', currencyCode: 'USD');

      await seedCategory(id: 'dining');
      await seedCategory(id: 'sys-rev', systemCode: 'reversal_expense');
      await seedCategory(id: 'salary', type: CategoryType.income);

      // Inside [2025-12 .. 2026-05] for target 202605
      await seedExpenseTx(
        txId: 'tx-may',
        accountId: 'acc-ok',
        categoryId: 'dining',
        currencyCode: 'CNY',
        occurredAt: DateTime(2026, 5, 1, 0, 10),
        amountMinor: 5000,
      );
      // Archived account stays in totals (consistent with ReportsDao)
      await seedExpenseTx(
        txId: 'tx-arch',
        accountId: 'acc-arch',
        categoryId: 'dining',
        currencyCode: 'CNY',
        occurredAt: DateTime(2026, 5, 15, 23, 59),
        amountMinor: 2000,
      );
      // Should be excluded:
      await seedExpenseTx(
        txId: 'tx-excl',
        accountId: 'acc-excl',
        categoryId: 'dining',
        currencyCode: 'CNY',
        occurredAt: DateTime(2026, 5, 10),
        amountMinor: 9999,
      );
      await seedExpenseTx(
        txId: 'tx-del',
        accountId: 'acc-del',
        categoryId: 'dining',
        currencyCode: 'CNY',
        occurredAt: DateTime(2026, 5, 10),
        amountMinor: 9999,
      );
      await seedExpenseTx(
        txId: 'tx-rev',
        accountId: 'acc-ok',
        categoryId: 'dining',
        currencyCode: 'CNY',
        occurredAt: DateTime(2026, 5, 10),
        amountMinor: 9999,
        isReversed: true,
      );
      await seedExpenseTx(
        txId: 'tx-usd',
        accountId: 'acc-usd',
        categoryId: 'dining',
        currencyCode: 'USD',
        occurredAt: DateTime(2026, 5, 10),
        amountMinor: 9999,
      );
      // Earlier month outside 6-month window sets earliestExpenseYm
      await seedExpenseTx(
        txId: 'tx-old',
        accountId: 'acc-ok',
        categoryId: 'dining',
        currencyCode: 'CNY',
        occurredAt: DateTime(2025, 10, 5),
        amountMinor: 1000,
      );

      final summary = await dao.watchMonthBudgetSummary('CNY', 202605).first;

      expect(summary.expenseCategories.map((c) => c.id), ['dining']);
      expect(
        summary.windowExpenses.map((e) => e.transactionId),
        unorderedEquals(['tx-may', 'tx-arch']),
      );
      expect(
        summary.windowExpenses
            .where((e) => e.transactionId == 'tx-may')
            .single
            .accountName,
        'Acc acc-ok',
      );
      expect(summary.earliestExpenseYm, 202510);
      expect(summary.hasAnyActiveAccount, isTrue);
    });

    test(
        'watchMonthPendingExpenses reads amountOverrideMinor, dateOverride, '
        'scheduled/failed statuses, and filters accounts', () async {
      await seedAccount(id: 'acc-ok', currencyCode: 'CNY');
      await seedAccount(
        id: 'acc-excl',
        currencyCode: 'CNY',
        includeInTotals: false,
      );
      await seedCategory(id: 'rent');

      await db.into(db.recurringSeries).insert(
            RecurringSeriesCompanion.insert(
              id: 's-rent',
              rrule: 'FREQ=MONTHLY;INTERVAL=1',
              startDate: DateTime(2026, 4, 1),
              frequency: 'MONTHLY',
              amountMinor: 300000,
              description: 'Rent',
              categoryId: 'rent',
              accountId: 'acc-ok',
              type: RecurringSeriesKind.expense,
            ),
          );
      await db.into(db.recurringSeries).insert(
            RecurringSeriesCompanion.insert(
              id: 's-excl',
              rrule: 'FREQ=MONTHLY;INTERVAL=1',
              startDate: DateTime(2026, 4, 1),
              frequency: 'DAILY',
              amountMinor: 5000,
              description: 'Ignored',
              categoryId: 'rent',
              accountId: 'acc-excl',
              type: RecurringSeriesKind.expense,
            ),
          );

      // Scheduled in May with amount override
      await db.into(db.scheduledTransactionsView).insert(
            ScheduledTransactionsViewCompanion.insert(
              id: 'b-1',
              seriesId: 's-rent',
              occurrenceKey: '2026-05-01',
              scheduledDate: DateTime(2026, 5, 1),
              amountOverrideMinor: const Value(320000),
              status: 'scheduled',
            ),
          );
      // Failed originally in April but moved via dateOverride into May
      await db.into(db.scheduledTransactionsView).insert(
            ScheduledTransactionsViewCompanion.insert(
              id: 'b-2',
              seriesId: 's-rent',
              occurrenceKey: '2026-04-28',
              scheduledDate: DateTime(2026, 4, 28),
              dateOverride: Value(DateTime(2026, 5, 2)),
              status: 'failed',
            ),
          );
      // Posted / skipped must NOT appear
      await db.into(db.scheduledTransactionsView).insert(
            ScheduledTransactionsViewCompanion.insert(
              id: 'b-3',
              seriesId: 's-rent',
              occurrenceKey: '2026-05-10',
              scheduledDate: DateTime(2026, 5, 10),
              status: 'posted',
            ),
          );
      // Excluded account must NOT appear
      await db.into(db.scheduledTransactionsView).insert(
            ScheduledTransactionsViewCompanion.insert(
              id: 'b-4',
              seriesId: 's-excl',
              occurrenceKey: '2026-05-11',
              scheduledDate: DateTime(2026, 5, 11),
              status: 'scheduled',
            ),
          );

      final pending = await dao.watchMonthPendingExpenses('CNY', 202605).first;

      expect(pending.bills.length, 2);
      expect(pending.bills.map((b) => b.scheduledBillId), ['b-1', 'b-2']);
      expect(pending.bills[0].amountMinor, 320000);
      expect(pending.bills[0].accountName, 'Acc acc-ok');
      expect(pending.bills[0].isVirtual, isFalse);
      expect(pending.bills[0].occurrenceKey, '2026-05-01');
      expect(pending.bills[1].amountMinor, 300000);
      expect(pending.bills[1].isVirtual, isFalse);
    });

    test(
        'watchCategoryBudgetHint returns budget, actual, pending and stops '
        'carry-forward after archiveYm', () async {
      await seedAccount(id: 'acc-ok', currencyCode: 'CNY');
      await seedCategory(
        id: 'dining',
        archived: true,
        archivedAt: DateTime(2026, 5, 20),
      );
      await dao.upsertBudgetRule(
        currencyCode: 'CNY',
        categoryId: 'dining',
        targetYm: 202604,
        amountMinor: 100000,
        thisMonthOnly: false,
        now: DateTime(2026, 4, 1),
      );
      await seedExpenseTx(
        txId: 'tx-1',
        accountId: 'acc-ok',
        categoryId: 'dining',
        currencyCode: 'CNY',
        occurredAt: DateTime(2026, 5, 5),
        amountMinor: 25000,
      );

      // Archive month (202605): rule still applies
      final mayHint =
          await dao.watchCategoryBudgetHint('CNY', 202605, 'dining').first;
      expect(mayHint.effectiveBudgetMinor, 100000);
      expect(mayHint.actualMinor, 25000);
      expect(mayHint.isCategoryArchived, isTrue);

      // Next month (202606 > archiveYm): rule cut off
      final juneHint =
          await dao.watchCategoryBudgetHint('CNY', 202606, 'dining').first;
      expect(juneHint.effectiveBudgetMinor, isNull);
    });

    test(
        'watchMonthPendingExpenses and watchCategoryBudgetHint respect '
        'includeVirtual flag (overlay vs physical-only review)', () async {
      await seedAccount(id: 'acc-ok', currencyCode: 'CNY');
      await seedCategory(id: 'rent');

      await db.into(db.recurringSeries).insert(
            RecurringSeriesCompanion.insert(
              id: 's-rent',
              rrule: 'FREQ=MONTHLY;INTERVAL=1',
              startDate: DateTime(2026, 4, 1, 9, 0),
              materializeFrom: Value(DateTime(2026, 4, 1, 9, 0)),
              frequency: 'MONTHLY',
              amountMinor: 300000,
              description: 'Rent',
              categoryId: 'rent',
              accountId: 'acc-ok',
              type: RecurringSeriesKind.expense,
              mode: const Value(RecurringSeriesMode.repeating),
            ),
          );

      // With includeVirtual: true -> virtual bill emitted for unmaterialized 202611
      final virtualPending = await dao
          .watchMonthPendingExpenses('CNY', 202611, includeVirtual: true)
          .first;
      expect(virtualPending.bills.length, 1);
      expect(virtualPending.bills.single.isVirtual, isTrue);
      expect(virtualPending.bills.single.seriesId, 's-rent');
      expect(virtualPending.bills.single.occurrenceKey, '2026-11-01');
      expect(virtualPending.bills.single.amountMinor, 300000);

      final virtualHint = await dao
          .watchCategoryBudgetHint('CNY', 202611, 'rent', includeVirtual: true)
          .first;
      expect(virtualHint.pendingMinor, 300000);

      // With includeVirtual: false -> physical-only (0 when unmaterialized)
      final physicalOnly = await dao
          .watchMonthPendingExpenses('CNY', 202611, includeVirtual: false)
          .first;
      expect(physicalOnly.bills, isEmpty);

      final physicalHint = await dao
          .watchCategoryBudgetHint('CNY', 202611, 'rent', includeVirtual: false)
          .first;
      expect(physicalHint.pendingMinor, 0);
    });
  });
}

/// Simulates a failing note delete so the rollback test can prove the rule
/// writes above it share the same transaction.
class _FailingNoteDeleteBudgetDao extends BudgetDao {
  _FailingNoteDeleteBudgetDao(super.db);

  @override
  Future<void> deleteCategoryReviewNotes({
    required String currencyCode,
    required String categoryId,
    required int targetYm,
    required bool thisMonthOnly,
  }) async {
    throw StateError('review note delete failed');
  }
}
