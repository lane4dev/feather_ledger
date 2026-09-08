import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_rebuild_service.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';

import '../../../../../support/event_sourcing/ledger_service_harness.dart';

/// Golden equivalence (spec 003, US8/T060): after a fixed and a seeded-
/// random operation sequence, clearing the event-sourced projections and
/// replaying the event store reproduces every projection field-for-field —
/// incremental application and full replay are the same computation.
///
/// Snapshot rows compare business fields only: id/createdAt/updatedAt are
/// storage/timestamp artifacts, not event-derived.
void main() {
  late LedgerServiceHarness harness;
  late LedgerRebuildService rebuildService;

  setUp(() {
    harness = LedgerServiceHarness();
    rebuildService =
        LedgerRebuildService(harness.db, harness.eventStore, harness.projector);
  });
  tearDown(() => harness.close());

  late String cashId;
  late String bankId;
  late String foodId;
  late String salaryId;

  Future<void> seedFixtures() async {
    await harness.accountService.createAccount(
      commandId: 'seed_cash',
      name: 'Cash',
      type: AccountType.cash,
      initialBalanceMinor: 0,
      currencyCode: 'USD',
    );
    await harness.accountService.createAccount(
      commandId: 'seed_bank',
      name: 'Bank',
      type: AccountType.bank,
      initialBalanceMinor: 100000,
      currencyCode: 'USD',
    );
    await harness.categoryService.createCategory(
      commandId: 'seed_food',
      name: 'Food',
      iconKey: '1',
      colorInt: 0xFF000000,
      type: CategoryType.expense,
    );
    await harness.categoryService.createCategory(
      commandId: 'seed_salary',
      name: 'Salary',
      iconKey: '2',
      colorInt: 0xFF00FF00,
      type: CategoryType.income,
    );
    final accounts = await harness.db.accountDao.getAllAccounts();
    cashId = accounts.firstWhere((a) => a.name == 'Cash').id;
    bankId = accounts.firstWhere((a) => a.name == 'Bank').id;
    final categories = await harness.db.categoriesDao.getAllCategories();
    foodId = categories.firstWhere((c) => c.name == 'Food').id;
    salaryId = categories.firstWhere((c) => c.name == 'Salary').id;
  }

  /// Business-field projection snapshot, deep-equal via records.
  Future<ProjectionState> capture() async {
    final accounts = await harness.db.select(harness.db.accountsView).get();
    final transactions =
        await harness.db.select(harness.db.transactionsView).get();
    final postings =
        await harness.db.select(harness.db.transactionPostingsView).get();
    final categories = await harness.db.select(harness.db.categoriesView).get();
    final snapshots = await harness.db
        .select(harness.db.monthlyAccountBalanceSnapshots)
        .get();

    List<T> sorted<T>(List<T> rows, Comparable Function(T) keyOf) =>
        rows..sort((a, b) => keyOf(a).compareTo(keyOf(b) as dynamic));

    return ProjectionState(
      accounts: sorted(accounts, (r) => r.id).map((r) {
        return (
          id: r.id,
          name: r.name,
          type: r.type,
          currencyCode: r.currencyCode,
          balanceMinor: r.balanceMinor,
          archived: r.archived,
          lastUpdatedEventId: r.lastUpdatedEventId,
          projectionVersion: r.projectionVersion,
        );
      }).toList(),
      categories: sorted(categories, (r) => r.id).map((r) {
        return (
          id: r.id,
          name: r.name,
          iconKey: r.iconKey,
          colorInt: r.colorInt,
          type: r.type,
          archived: r.archived,
          systemCode: r.systemCode,
          lastUpdatedEventId: r.lastUpdatedEventId,
          projectionVersion: r.projectionVersion,
        );
      }).toList(),
      transactions: sorted(transactions, (r) => r.transactionId).map((r) {
        return (
          transactionId: r.transactionId,
          occurredAt: r.occurredAt,
          kind: r.kind,
          description: r.description,
          isReversed: r.isReversed,
          categoryName: r.categoryName,
          categoryIcon: r.categoryIcon,
          categoryColorInt: r.categoryColorInt,
          originalEventId: r.originalEventId,
          projectionVersion: r.projectionVersion,
        );
      }).toList(),
      postings: sorted(postings, (r) => r.id).map((r) {
        return (
          id: r.id,
          transactionId: r.transactionId,
          accountId: r.accountId,
          direction: r.direction,
          amountMinor: r.amountMinor,
          currencyCode: r.currencyCode,
          categoryId: r.categoryId,
          memo: r.memo,
        );
      }).toList(),
      snapshots:
          sorted(snapshots, (r) => '${r.accountId}-${r.year}-${r.month}')
              .map((r) {
        return (
          accountId: r.accountId,
          currencyCode: r.currencyCode,
          year: r.year,
          month: r.month,
          openingBalanceMinor: r.openingBalanceMinor,
          closingBalanceMinor: r.closingBalanceMinor,
          incomeMinor: r.incomeMinor,
          expenseMinor: r.expenseMinor,
          transferInMinor: r.transferInMinor,
          transferOutMinor: r.transferOutMinor,
          netChangeMinor: r.netChangeMinor,
          transactionCount: r.transactionCount,
          eventSequenceFrom: r.eventSequenceFrom,
          eventSequenceTo: r.eventSequenceTo,
          projectionVersion: r.projectionVersion,
          isClosed: r.isClosed,
        );
      }).toList(),
    );
  }

  Future<void> expectRebuildEquivalent() async {
    final eventsBefore = await harness.eventStore.readAll();
    final stateBefore = await capture();

    await rebuildService.rebuild();

    final eventsAfter = await harness.eventStore.readAll();
    final stateAfter = await capture();

    expect(eventsAfter.events.length, eventsBefore.events.length,
        reason: 'rebuild never touches the event store');
    expect(stateAfter.accounts, equals(stateBefore.accounts));
    expect(stateAfter.categories, equals(stateBefore.categories));
    expect(stateAfter.transactions, equals(stateBefore.transactions));
    expect(stateAfter.postings, equals(stateBefore.postings));
    expect(stateAfter.snapshots, equals(stateBefore.snapshots));
  }

  test('fixed sequence replays to a field-by-field equal projection',
      () async {
    await seedFixtures();

    Future<void> recordExpense(int amount, String cmd, DateTime date) =>
        harness.ledgerService.addTransaction(
          commandId: cmd,
          amountMinor: amount,
          type: TransactionKind.expense,
          date: date,
          categoryId: foodId,
          accountId: cashId,
        );
    await recordExpense(5000, 'fx_expense', DateTime(2026, 1, 10));
    await harness.ledgerService.addTransaction(
      commandId: 'fx_income',
      amountMinor: 20000,
      type: TransactionKind.income,
      date: DateTime(2026, 1, 12),
      categoryId: salaryId,
      accountId: bankId,
    );
    await harness.ledgerService.addTransfer(
      commandId: 'fx_transfer',
      amountMinor: 3000,
      fromAccountId: bankId,
      toAccountId: cashId,
      date: DateTime(2026, 1, 15),
    );
    await recordExpense(7000, 'fx_expense2', DateTime(2026, 2, 5));

    final visible = await harness.ledgerService
        .watchTransactions(DateTime(2026, 1))
        .first;
    final toCorrect = visible
        .firstWhere((t) => t.type == TransactionKind.expense)
        .id;
    await harness.ledgerService.updateTransaction(
      commandId: 'fx_correct',
      id: toCorrect,
      amountMinor: 8000,
      type: TransactionKind.expense,
      date: DateTime(2026, 1, 10),
      categoryId: foodId,
      accountId: cashId,
    );

    final corrected = (await harness.ledgerService
            .watchTransactions(DateTime(2026, 1))
            .first)
        .firstWhere((t) => t.amount == -8000)
        .id;
    await harness.ledgerService.deleteTransaction(corrected,
        commandId: 'fx_delete');

    await expectRebuildEquivalent();
  });

  test('seeded-random sequence replays to a field-by-field equal projection',
      () async {
    await seedFixtures();
    final rnd = Random(42);
    final accountIds = [cashId, bankId];

    Future<List<String>> visibleIds() async {
      final events = (await harness.eventStore.readAll()).events;
      final reversed = <String>{};
      for (final e in events) {
        if (e.eventType == 'TransactionReversed') {
          reversed.add(TransactionReversed.fromJson(e.payloadJson)
              .originalTransactionId);
        }
      }
      return [
        for (final e in events)
          if (e.eventType == 'TransactionRecorded' &&
              !reversed.contains(
                  TransactionRecorded.fromJson(e.payloadJson).transactionId))
            TransactionRecorded.fromJson(e.payloadJson).transactionId,
      ];
    }

    for (var i = 0; i < 25; i++) {
      final op = rnd.nextInt(100);
      final date = DateTime(2026, 1 + rnd.nextInt(12), 1 + rnd.nextInt(28));
      if (op < 40) {
        final isIncome = rnd.nextBool();
        await harness.ledgerService.addTransaction(
          commandId: 'rnd_$i',
          amountMinor: 100 + rnd.nextInt(100000),
          type:
              isIncome ? TransactionKind.income : TransactionKind.expense,
          date: date,
          categoryId: isIncome ? salaryId : foodId,
          accountId: accountIds[rnd.nextInt(accountIds.length)],
        );
      } else if (op < 60) {
        final from = accountIds[rnd.nextInt(accountIds.length)];
        var to = accountIds[rnd.nextInt(accountIds.length)];
        if (from == to) {
          to = accountIds[(accountIds.indexOf(from) + 1) % accountIds.length];
        }
        await harness.ledgerService.addTransfer(
          commandId: 'rnd_$i',
          amountMinor: 100 + rnd.nextInt(50000),
          fromAccountId: from,
          toAccountId: to,
          date: date,
        );
      } else {
        final visible = await visibleIds();
        if (visible.isEmpty) continue;
        final target = visible[rnd.nextInt(visible.length)];
        if (op < 80) {
          await harness.ledgerService.updateTransaction(
            commandId: 'rnd_$i',
            id: target,
            amountMinor: 100 + rnd.nextInt(100000),
            type: rnd.nextBool()
                ? TransactionKind.income
                : TransactionKind.expense,
            date: date,
            categoryId: rnd.nextBool() ? salaryId : foodId,
            accountId: accountIds[rnd.nextInt(accountIds.length)],
          );
        } else {
          await harness.ledgerService.deleteTransaction(target,
              commandId: 'rnd_$i');
        }
      }
    }

    await expectRebuildEquivalent();
  });
}

/// All four event-sourced projections plus snapshots, business fields only.
class ProjectionState {
  final List<Object> accounts;
  final List<Object> categories;
  final List<Object> transactions;
  final List<Object> postings;
  final List<Object> snapshots;

  ProjectionState({
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.postings,
    required this.snapshots,
  });
}
