import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

import '../../../../support/event_sourcing/ledger_service_harness.dart';

/// Regression cover for the three auto-updating budget triggers.
///
/// The month summary, month pending and single-category hint streams are each
/// built on a `customSelect('SELECT 1', readsFrom: {...})` trigger. drift caches
/// live queries by `StreamKey(sql, variables)`, so identical statement text
/// collapses them into one query stream whose `readsFrom` is whichever was
/// created first — every other table set then stops invalidating. Each trigger
/// therefore spells its statement differently; these tests pin that down by
/// keeping all three open at once and asserting every one of them still reacts
/// to its own writes, in every subscription order.
void main() {
  const currency = 'CNY';
  const accountId = 'acc-cny';
  const categoryId = 'cat-dining';
  const novYm = 202611;
  const novemberOccurrence = '2026-11-20';

  Future<LedgerServiceHarness> buildHarness() async {
    final harness = LedgerServiceHarness(
      clock: FixedClock(DateTime(2026, 5, 15, 10)),
    );
    await harness.seedAccount(id: accountId, name: 'Cash', currencyCode: currency);
    await harness.seedCategory(id: categoryId, name: 'Dining');
    return harness;
  }

  /// One monthly expense series whose 2026-11 occurrence stays virtual until a
  /// test materializes it.
  Future<String> seedSeries(LedgerServiceHarness harness) async {
    final created = await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 300000,
      accountId: accountId,
      categoryId: categoryId,
      description: 'rent',
      frequency: 'MONTHLY',
      startDate: DateTime(2026, 5, 20, 9),
      materializeFrom: DateTime(2026, 5, 20, 9),
    );
    return (created as Success<String>).value;
  }

  Future<void> pumpUntil(
    bool Function() condition, {
    required String reason,
  }) async {
    for (var attempt = 0; attempt < 50; attempt++) {
      if (condition()) return;
      await pumpEventQueue();
    }
    fail('Timed out waiting for $reason');
  }

  /// Subscribes all three budget streams in [order], then proves each one is
  /// still invalidated by its own tables.
  Future<void> expectEveryStreamStaysLive(List<String> order) async {
    final harness = await buildHarness();
    addTearDown(harness.close);
    final seriesId = await seedSeries(harness);
    final dao = harness.db.budgetDao;

    var summaryEmissions = 0;
    var pendingEmissions = 0;
    var hintEmissions = 0;

    for (final name in order) {
      switch (name) {
        case 'summary':
          final subscription = dao
              .watchMonthBudgetSummary(currency, novYm)
              .listen((_) => summaryEmissions++);
          addTearDown(subscription.cancel);
        case 'pending':
          final subscription = dao
              .watchMonthPendingExpenses(currency, novYm)
              .listen((_) => pendingEmissions++);
          addTearDown(subscription.cancel);
        case 'hint':
          final subscription = dao
              .watchCategoryBudgetHint(currency, novYm, categoryId)
              .listen((_) => hintEmissions++);
          addTearDown(subscription.cancel);
        default:
          fail('Unknown stream $name');
      }
    }

    await pumpEventQueue();
    expect(summaryEmissions, greaterThanOrEqualTo(1),
        reason: 'summary must emit its first snapshot (order: $order)');
    expect(pendingEmissions, greaterThanOrEqualTo(1),
        reason: 'pending must emit its first snapshot (order: $order)');
    expect(hintEmissions, greaterThanOrEqualTo(1),
        reason: 'hint must emit its first snapshot (order: $order)');

    // 1. A budget-rule write must reach the month summary even when the
    //    already-open pending/hint streams were created first.
    final summaryBefore = summaryEmissions;
    await harness.budgetService.setCategoryBudget(
      currencyCode: currency,
      categoryId: categoryId,
      month: const YearMonth(2026, 11),
      amountMinor: 500000,
      scope: BudgetEditScope.thisAndFollowing,
    );
    await pumpUntil(
      () => summaryEmissions > summaryBefore,
      reason: 'the month summary to re-emit after a budget rule write '
          '(order: $order)',
    );

    // 2. Materializing a virtual bill writes only `scheduled_transactions_view`;
    //    the month pending stream and the category hint must both see it.
    final pendingBefore = pendingEmissions;
    final hintBefore = hintEmissions;
    await harness.recurringService.ensureMaterialized(
      seriesId: seriesId,
      occurrenceKey: novemberOccurrence,
    );
    await pumpUntil(
      () => pendingEmissions > pendingBefore,
      reason: 'the month pending stream to re-emit after ensureMaterialized '
          '(order: $order)',
    );
    await pumpUntil(
      () => hintEmissions > hintBefore,
      reason: 'the category hint to re-emit after ensureMaterialized '
          '(order: $order)',
    );

    final materialized = await dao
        .watchMonthPendingExpenses(currency, novYm)
        .first;
    expect(materialized.bills, hasLength(1));
    expect(materialized.bills.single.isVirtual, isFalse);
  }

  group('budget stream invalidation', () {
    test('summary first: every stream keeps its own trigger tables', () async {
      await expectEveryStreamStaysLive(['summary', 'pending', 'hint']);
    });

    test('pending first: every stream keeps its own trigger tables', () async {
      await expectEveryStreamStaysLive(['pending', 'summary', 'hint']);
    });

    test('hint first: every stream keeps its own trigger tables', () async {
      await expectEveryStreamStaysLive(['hint', 'summary', 'pending']);
    });

    test('materialize and skip refresh the pending stream in place', () async {
      final harness = await buildHarness();
      addTearDown(harness.close);
      final seriesId = await seedSeries(harness);

      final emissions = <List<String>>[];
      final subscription = harness.db.budgetDao
          .watchMonthPendingExpenses(currency, novYm)
          .listen((raw) => emissions.add([
                for (final bill in raw.bills)
                  bill.isVirtual
                      ? 'virtual:${bill.seriesId}:${bill.occurrenceKey}'
                      : 'physical:${bill.scheduledBillId}',
              ]));
      addTearDown(subscription.cancel);

      final virtualKey = 'virtual:$seriesId:$novemberOccurrence';
      await pumpUntil(
        () => emissions.isNotEmpty && emissions.last.length == 1,
        reason: 'the virtual 2026-11 occurrence to appear',
      );
      expect(emissions.last, [virtualKey]);

      final bill = (await harness.recurringService.ensureMaterialized(
        seriesId: seriesId,
        occurrenceKey: novemberOccurrence,
      ) as Success<ScheduledTransactionEntity>)
          .value;
      await pumpUntil(
        () => emissions.last.single.startsWith('physical:'),
        reason: 'the materialized row to replace the virtual one in place',
      );
      expect(emissions.last, ['physical:${bill.id}']);

      await harness.recurringService.deleteBill(
        bill.id,
        scope: RecurringScope.thisOnly,
      );
      await pumpUntil(
        () => emissions.last.isEmpty,
        reason: 'the skipped bill to drop out of budget pending',
      );
    });
  });
}
