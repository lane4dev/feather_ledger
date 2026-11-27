import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_monthly_pending_bills_query.dart';

import '../../../../../support/event_sourcing/ledger_service_harness.dart';

void main() {
  late LedgerServiceHarness harness;
  late WatchMonthlyPendingBillsQuery query;
  late DateTime now;

  setUp(() async {
    now = DateTime(2026, 5, 15, 10);
    harness = LedgerServiceHarness(clock: FixedClock(now));
    query = WatchMonthlyPendingBillsQuery(
      harness.recurringRepository,
      FixedClock(now),
    );

    await harness.seedAccount(
      id: 'acc-cash',
      name: 'Cash',
      currencyCode: 'CNY',
    );
    await harness.seedAccount(
      id: 'acc-excluded',
      name: 'Excluded',
      currencyCode: 'CNY',
    );
    await (harness.db.update(harness.db.accountsView)
          ..where((a) => a.id.equals('acc-excluded')))
        .write(const AccountsViewCompanion(includeInTotals: Value(false)));
    await harness.seedAccount(
      id: 'acc-archived',
      name: 'Archived',
      currencyCode: 'CNY',
    );

    for (final (id, name, type) in const [
      ('dining', 'Dining', CategoryType.expense),
      ('salary', 'Salary', CategoryType.income),
    ]) {
      await harness.categoryService.createCategory(
        commandId: 'cat-$id',
        categoryId: id,
        name: name,
        iconKey: 'utensils',
        colorInt: 0xFFE65100,
        type: type,
      );
    }
  });

  tearDown(() async {
    await harness.close();
  });

  Future<List<ScheduledTransactionEntity>> pendingFor(
    DateTime month, {
    String currencyCode = 'CNY',
  }) =>
      query.execute(month: month, currencyCode: currencyCode).first;

  test(
      'virtual expansion covers M+2 through M+24, including income and '
      'includeInTotals=false accounts, and stops after M+24', () async {
    final daily = await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 2500,
      accountId: 'acc-cash',
      categoryId: 'dining',
      description: 'Daily lunch',
      frequency: 'DAILY',
      startDate: DateTime(2026, 5, 1, 12),
    );
    expect(daily, isA<Success<String>>());

    await harness.recurringService.createSeries(
      type: RecurringSeriesKind.income,
      amountMinor: 500000,
      accountId: 'acc-cash',
      categoryId: 'salary',
      description: 'Paycheck',
      frequency: 'MONTHLY',
      startDate: DateTime(2026, 5, 1, 9),
    );

    await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 9900,
      accountId: 'acc-excluded',
      categoryId: 'dining',
      description: 'Excluded account bill',
      frequency: 'MONTHLY',
      startDate: DateTime(2026, 5, 1, 9),
    );

    final july = await pendingFor(DateTime(2026, 7));
    expect(july, isNotEmpty);
    expect(july.every((bill) => bill.isVirtual), isTrue);
    expect(
      july.where((bill) =>
          bill.recurringTransactionSeries?.description == 'Daily lunch'),
      hasLength(31),
    );
    expect(
      july.where(
          (bill) => bill.recurringTransactionSeries?.description == 'Paycheck'),
      hasLength(1),
    );
    expect(
      july.where((bill) =>
          bill.recurringTransactionSeries?.description ==
          'Excluded account bill'),
      hasLength(1),
    );

    final horizon = await pendingFor(DateTime(2028, 5));
    expect(
      horizon.where((bill) => bill.isVirtual),
      hasLength(33),
      reason: 'M+24 is inclusive: 31 daily + paycheck + excluded bill',
    );

    final beyondHorizon = await pendingFor(DateTime(2028, 6));
    expect(beyondHorizon, isEmpty);

    final history = await pendingFor(DateTime(2026, 4));
    expect(history.where((bill) => bill.isVirtual), isEmpty);
  });

  test(
      'physical rows win over virtual rows; skipping one occurrence does not '
      'resurrect it', () async {
    final daily = await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 2500,
      accountId: 'acc-cash',
      categoryId: 'dining',
      description: 'Daily lunch',
      frequency: 'DAILY',
      startDate: DateTime(2026, 5, 1, 12),
    );
    final seriesId = (daily as Success<String>).value;

    final materialized = await harness.recurringService.ensureMaterialized(
      seriesId: seriesId,
      occurrenceKey: '2026-07-10',
    );
    expect(materialized, isA<Success<ScheduledTransactionEntity>>());
    final bill = (materialized as Success<ScheduledTransactionEntity>).value;
    expect(bill.isVirtual, isFalse);

    await harness.recurringService
        .deleteBill(bill.id, scope: RecurringScope.thisOnly);

    final july = await pendingFor(DateTime(2026, 7));
    final skipped =
        july.where((row) => row.occurrenceKey == '2026-07-10').toList();
    expect(skipped, hasLength(1));
    expect(skipped.single.isVirtual, isFalse);
    expect(skipped.single.status, ScheduledTransactionStatus.skipped);
    expect(
      july.where((row) => row.occurrenceKey == '2026-07-11'),
      hasLength(1),
    );
    expect(july.where((row) => row.isVirtual), hasLength(30));
  });

  test('archived accounts and other currencies do not produce virtual rows',
      () async {
    await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 1000,
      accountId: 'acc-archived',
      categoryId: 'dining',
      description: 'Archived account bill',
      frequency: 'MONTHLY',
      startDate: DateTime(2026, 5, 1, 9),
    );
    final archived = await harness.accountService.archiveAccount(
      commandId: 'archive-acc',
      accountId: 'acc-archived',
    );
    expect(archived, isA<Success<void>>());

    final july = await pendingFor(DateTime(2026, 7));
    expect(
      july.where((row) =>
          row.recurringTransactionSeries?.description ==
          'Archived account bill'),
      isEmpty,
    );
    expect(await pendingFor(DateTime(2026, 7), currencyCode: 'USD'), isEmpty);
  });
}
