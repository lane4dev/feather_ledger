import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_rebuild_service.dart';

import '../../../../../support/event_sourcing/ledger_service_harness.dart';

/// Ticket 47 (spec 006, US47): the event stream — not the projection row that
/// corrections clear — carries a transaction's source bill, so an old
/// notification can always resolve the *latest* transaction after any number
/// of corrections, and survives a full rebuild.
void main() {
  late LedgerServiceHarness harness;
  late LedgerRebuildService rebuildService;

  setUp(() async {
    harness = LedgerServiceHarness();
    await harness.seedSystemCategories();
    rebuildService =
        LedgerRebuildService(harness.db, harness.eventStore, harness.projector);
  });
  tearDown(() => harness.close());

  test('a posted bill and its corrections resolve to the latest transaction '
      'even after a rebuild', () async {
    // Event-sourced fixtures: the rebuild clears the projections, so every
    // referenced account/category must be re-derivable from the event store.
    await harness.accountService.createAccount(
      commandId: 'seed_cash',
      name: 'Cash',
      type: AccountType.cash,
      initialBalanceMinor: 0,
      currencyCode: 'USD',
    );
    await harness.categoryService.createCategory(
      commandId: 'seed_rent',
      categoryId: 'cat_rent',
      name: 'Rent',
      iconKey: '1',
      colorInt: 0xFF000000,
      type: CategoryType.expense,
    );
    final account = (await harness.db.accountDao.getAllAccounts())
        .firstWhere((a) => a.name == 'Cash');

    final seriesStart = DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day)
        .add(const Duration(days: 1));
    await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 5000,
      accountId: account.id,
      categoryId: 'cat_rent',
      description: 'Rent',
      frequency: 'DAILY',
      interval: 1,
      startDate: seriesStart,
    );

    final scheduled = await harness.recurringService.watchScheduled().first;
    final bill = scheduled.first;

    // Post the bill → the first transaction.
    await harness.recurringService.postInstance(bill.id, commandId: 'post');
    final posted = await harness.db.recurringDao.getScheduled(bill.id);
    final t1 = posted!.transactionId!;

    // Correct twice; each replacement carries the same source bill.
    await harness.ledgerService.updateTransaction(
      commandId: 'corr1',
      id: t1,
      amountMinor: 6000,
      type: TransactionKind.expense,
      date: seriesStart,
      categoryId: 'cat_rent',
      accountId: account.id,
    );
    final t2 = (await harness.ledgerService.watchTransactions(seriesStart).first)
        .single
        .id;
    await harness.ledgerService.updateTransaction(
      commandId: 'corr2',
      id: t2,
      amountMinor: 7000,
      type: TransactionKind.expense,
      date: seriesStart,
      categoryId: 'cat_rent',
      accountId: account.id,
    );
    final t3 = (await harness.ledgerService.watchTransactions(seriesStart).first)
        .single
        .id;

    // The source bill resolves to the latest transaction, not the reversed
    // original named by scheduled_transactions_view.transaction_id.
    final latest =
        await harness.ledgerService.getTransactionBySourceBill(bill.id);
    expect(latest?.id, t3);
    expect(latest?.amount, -7000);

    // The event-backed link survives a full projection rebuild.
    await rebuildService.rebuild();
    final after =
        await harness.ledgerService.getTransactionBySourceBill(bill.id);
    expect(after?.id, t3);
    expect(after?.amount, -7000);
  });
}
