import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_rebuild_service.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';

import '../../../../../support/event_sourcing/ledger_service_harness.dart';

/// Scheduled-instance conversion tests (spec 003, US10/T071): converting a
/// scheduled instance records a real `TransactionRecorded` and flips the
/// CRUD-exempt row to 'posted' in the same transaction; double conversion
/// is rejected; rebuild never touches the exempt tables.
void main() {
  late LedgerServiceHarness harness;

  setUp(() => harness = LedgerServiceHarness());
  tearDown(() => harness.close());

  late String cashId;
  late String foodId;

  Future<void> seedSeriesAndScheduled() async {
    await harness.accountService.createAccount(
      commandId: 'conv_seed_cash',
      name: 'Cash',
      type: AccountType.cash,
      initialBalanceMinor: 0,
      currencyCode: 'USD',
    );
    await harness.categoryService.createCategory(
      commandId: 'conv_seed_food',
      name: 'Food',
      iconKey: '1',
      colorInt: 0xFF000000,
      type: CategoryType.expense,
    );
    cashId = (await harness.db.accountDao.getAllAccounts())
        .firstWhere((a) => a.name == 'Cash')
        .id;
    foodId = (await harness.db.categoriesDao.getAllCategories()).single.id;

    // CRUD-exempt seed: series + one materialized instance.
    await harness.db.recurringDao.saveSeries(RecurringSeriesCompanion.insert(
      id: 'series_1',
      rrule: 'FREQ=MONTHLY',
      startDate: DateTime(2026, 1, 1),
      frequency: 'MONTHLY',
      amountMinor: 5000,
      description: 'Rent',
      categoryId: foodId,
      accountId: cashId,
      type: TransactionKind.expense,
    ));
    await harness.db.recurringDao.insertOrUpdateScheduled(
        ScheduledTransactionsViewCompanion.insert(
      id: 'sched_1',
      seriesId: 'series_1',
      date: DateTime(2026, 1, 5),
      amountMinor: 5000,
      status: 'scheduled',
      transactionId: const Value(null),
    ));
  }

  test('conversion records the transaction and flips the status', () async {
    await seedSeriesAndScheduled();

    final result = await harness.ledgerService
        .convertScheduledToPosted('sched_1', commandId: 'conv_1');
    expect(result, isA<Success<void>>());

    final events = (await harness.eventStore.readAll()).events;
    final recorded = TransactionRecorded.fromJson(events.last.payloadJson);
    expect(recorded.kind, TransactionKind.expense);
    expect(recorded.postings.single.amountMinor, 5000);
    expect(recorded.postings.single.accountId, cashId);
    expect(recorded.postings.single.categoryId, foodId);

    // Projections updated like any manual record.
    final cash = await harness.db.accountDao.getAccountById(cashId);
    expect(cash!.balanceMinor, -5000);
    expect(
        await harness.db.transactionsDao.getTransactionRow(
            recorded.transactionId),
        isNotNull);

    // The exempt row flips in the same write.
    final scheduled =
        await harness.db.recurringDao.getScheduled('sched_1');
    expect(scheduled!.status, 'posted');
    expect(scheduled.transactionId, recorded.transactionId);
  });

  test('converting an already-posted instance is rejected', () async {
    await seedSeriesAndScheduled();
    await harness.ledgerService
        .convertScheduledToPosted('sched_1', commandId: 'conv_1');

    final result = await harness.ledgerService
        .convertScheduledToPosted('sched_1', commandId: 'conv_2');

    expect(
      result,
      isA<Failure<void>>().having((f) => f.code, 'code',
          LedgerErrorCode.transactionAlreadyReversed),
    );
    final events = (await harness.eventStore.readAll()).events;
    expect(
        events
            .where((e) => e.eventType == 'TransactionRecorded')
            .length,
        1);
  });

  test('converting an unknown instance is rejected', () async {
    await seedSeriesAndScheduled();

    final result = await harness.ledgerService
        .convertScheduledToPosted('nope', commandId: 'conv_unknown');

    expect(
      result,
      isA<Failure<void>>().having(
          (f) => f.code, 'code', LedgerErrorCode.transactionNotFound),
    );
  });

  test('rebuild leaves the exempt tables untouched', () async {
    await seedSeriesAndScheduled();
    await harness.ledgerService
        .convertScheduledToPosted('sched_1', commandId: 'conv_1');

    final seriesBefore =
        await harness.db.recurringDao.getAllSeries();
    final scheduledBefore =
        await harness.db.recurringDao.getScheduled('sched_1');

    await LedgerRebuildService(harness.db, harness.eventStore, harness.projector)
        .rebuild();

    final seriesAfter = await harness.db.recurringDao.getAllSeries();
    final scheduledAfter =
        await harness.db.recurringDao.getScheduled('sched_1');
    expect(seriesAfter.map((r) => r.id).toList(),
        seriesBefore.map((r) => r.id).toList());
    expect(seriesAfter.single.amountMinor, 5000);
    expect(scheduledAfter!.status, 'posted',
        reason: 'status survives the rebuild (CRUD exemption)');
    expect(scheduledAfter.amountMinor, scheduledBefore!.amountMinor);
  });
}
