import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/budget/domain/entities/budget_entities.dart';
import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

import '../../../../../support/event_sourcing/ledger_service_harness.dart';

/// Ticket 04 of spec 005: the hybrid recurring projection — physical
/// `scheduled_transactions_view` rows plus budget-time virtual expansion —
/// observed only through the service layer (ADR-0008).
///
/// Each case pins one invariant of the merged behaviour: `materializeFrom`
/// phase alignment with a 24-month virtual horizon ([RecurrenceExpander]),
/// physical-wins dedup against manual-only overdue rows, the archived-category
/// cut on both pending paths, the single-month trend point, and
/// materialize-on-write staying idempotent under live budget streams.
void main() {
  const currency = 'CNY';
  late LedgerServiceHarness harness;
  late DateTime now;
  late YearMonth nowYm;

  setUp(() async {
    // Wall clock stays outside this file: every branch below is dated from the
    // FixedClock, including `createSeries` marking past rows manual-only.
    now = DateTime(2026, 5, 15, 10, 0);
    nowYm = YearMonth.fromDate(now);
    harness = LedgerServiceHarness(clock: FixedClock(now));
    await harness.seedAccount(
      id: 'acc-cash',
      name: 'Cash',
      type: AccountType.cash,
      currencyCode: currency,
    );
    await harness.categoryService.createCategory(
      commandId: 'cat-dining',
      categoryId: 'dining',
      name: 'Dining',
      iconKey: 'utensils',
      colorInt: 0xFFE65100,
      type: CategoryType.expense,
    );
  });

  tearDown(() async {
    await harness.close();
  });

  group('Budget hybrid recurring projection', () {
    test(
        'far-past DAILY and WEEKLY series stay phase-aligned and are virtual '
        'only inside the 24-month horizon', () async {
      // A user who picks "only from today" for a rule anchored years ago:
      // `startDate` keeps the phase, `materializeFrom` floors the history.
      final dailyId = await _createMonthlySeries(
        harness,
        description: 'Coffee',
        amountMinor: 1000,
        frequency: 'DAILY',
        startDate: DateTime(2019, 3, 7, 9, 0),
        materializeFrom: DateTime(2026, 5, 15),
      );
      final weeklyId = await _createMonthlySeries(
        harness,
        description: 'Cleaning',
        amountMinor: 5000,
        frequency: 'WEEKLY',
        weekdays: [DateTime.monday],
        startDate: DateTime(2019, 3, 4, 9, 0),
        materializeFrom: DateTime(2026, 5, 15),
      );

      final current = await _summary(harness, currency, nowYm);
      expect(current.mode, BudgetMode.track);
      final currentRow = _row(current, 'dining');
      final dailyInMay =
          _contributionsOf(currentRow, dailyId).where((c) => c.isPending);
      final weeklyInMay =
          _contributionsOf(currentRow, weeklyId).where((c) => c.isPending);

      // May 15..31 for DAILY; Mondays May 18 and May 25 for WEEKLY.
      expect(dailyInMay.length, 17);
      expect(weeklyInMay.length, 2);
      expect(currentRow.pendingMinor, 17 * 1000 + 2 * 5000);

      for (final tx in [...dailyInMay, ...weeklyInMay]) {
        // `materializeFrom` floors the history: nothing before today.
        expect(tx.occurredAt.isBefore(DateTime(2026, 5, 15)), isFalse);
        // The whole month is physically materialized, so the overlay must not
        // add a second copy of any of it.
        expect(tx.isVirtual, isFalse);
        expect(tx.scheduledBillId, isNotNull);
      }
      for (final tx in weeklyInMay) {
        expect(tx.occurredAt.weekday, DateTime.monday);
        expect(tx.occurrenceKey, _dayKey(tx.occurredAt));
      }

      // nowYm + 24 is the last month the overlay expands; past the physical
      // window everything there is virtual and still anchored to 2019.
      final horizon = nowYm.addMonths(24);
      expect(horizon.ym, 202805);
      final horizonSummary = await _summary(harness, currency, horizon);
      expect(horizonSummary.mode, BudgetMode.plan);
      final horizonRow = _row(horizonSummary, 'dining');
      final dailyInHorizon = _contributionsOf(horizonRow, dailyId);
      final weeklyInHorizon = _contributionsOf(horizonRow, weeklyId);
      final horizonDays = _daysInMonth(2028, 5);
      final horizonMondays = _weekdaysInMonth(2028, 5, DateTime.monday);

      expect(dailyInHorizon.length, horizonDays);
      expect(weeklyInHorizon.length, horizonMondays.length);
      expect(horizonRow.pendingMinor,
          horizonDays * 1000 + horizonMondays.length * 5000);
      expect(horizonRow.contributions.every((c) => c.isVirtual), isTrue);
      // Phase alignment: every calendar day for DAILY, every Monday for WEEKLY
      // — a drifted fast-forward anchor would drop or shift these. Contributions
      // are ordered amount-first, so the day sets are compared unordered.
      expect(
        [for (final tx in dailyInHorizon) _dayKey(tx.occurredAt)]..sort(),
        [
          for (var day = 1; day <= horizonDays; day++)
            _dayKey(DateTime(2028, 5, day))
        ]..sort(),
      );
      expect(
        [for (final tx in weeklyInHorizon) _dayKey(tx.occurredAt)]..sort(),
        [for (final day in horizonMondays) _dayKey(day)]..sort(),
      );

      // One month past the horizon: virtual expansion goes silent (physical
      // bills would still show, and there are none that far out).
      final beyondHorizon = nowYm.addMonths(25);
      expect(beyondHorizon.ym, 202806);
      final beyondSummary = await _summary(harness, currency, beyondHorizon);
      expect(beyondSummary.mode, BudgetMode.plan);
      final beyondRow = _row(beyondSummary, 'dining');
      expect(beyondRow.contributions, isEmpty);
      expect(beyondRow.pendingMinor, 0);
      final beyondHint =
          await _hint(harness, currency, beyondHorizon, 'dining');
      expect(beyondHint.pendingMinor, 0);
      expect(beyondSummary.allExpensePendingMinor, 0);
    });

    test(
        'manual-only overdue bills are counted once in Track and are pending-'
        'free in Review', () async {
      await harness.budgetService.setCategoryBudget(
        currencyCode: currency,
        categoryId: 'dining',
        month: nowYm.previous,
        amountMinor: 500000,
        scope: BudgetEditScope.thisAndFollowing,
      );
      final currentMonthOverdue = await _createMonthlySeries(
        harness,
        description: 'Gym (overdue)',
        amountMinor: 25000,
        startDate: DateTime(2026, 5, 5, 9, 0),
      );
      final nearPast = await _createMonthlySeries(
        harness,
        description: 'Internet',
        amountMinor: 40000,
        startDate: DateTime(2026, 4, 20, 9, 0),
      );

      // Creating a series marks everything before today manual-only, so the
      // May 5 occurrence is a real physical row waiting for the user.
      final scheduled =
          await harness.recurringService.watchScheduled(currencyCode: currency).first;
      final overdueMay = scheduled.singleWhere(
          (b) => b.seriesId == currentMonthOverdue && b.occurrenceKey == '2026-05-05');
      expect(overdueMay.manualOnly, isTrue);
      final overdueApril = scheduled.singleWhere(
          (b) => b.seriesId == nearPast && b.occurrenceKey == '2026-04-20');
      expect(overdueApril.manualOnly, isTrue);

      final track = await _summary(harness, currency, nowYm);
      final trackRow = _row(track, 'dining');
      // 25.00 overdue + the current month's 400.00 bill. A virtual duplicate of
      // the manual-only row would make this 650.00 + 250.00.
      expect(trackRow.pendingMinor, 25000 + 40000);
      expect(trackRow.contributions.every((c) => !c.isVirtual), isTrue);
      expect(_contributionsOf(trackRow, currentMonthOverdue).length, 1);
      expect(track.budgetedPendingMinor, trackRow.pendingMinor);
      final trackHint = await _hint(harness, currency, nowYm, 'dining');
      expect(trackHint.pendingMinor, trackRow.pendingMinor);

      final review = await _summary(harness, currency, nowYm.previous);
      expect(review.mode, BudgetMode.review);
      final reviewRow = _row(review, 'dining');
      expect(review.budgetedPendingMinor, 0);
      expect(reviewRow.pendingMinor, 0);
      expect(reviewRow.contributions, isEmpty);
      // The April bill is really there — Review hides it, it does not vanish.
      expect(review.hasLeftoverPendingInReview, isTrue);
      // Review is asserted through the budget summary only: `watchCategoryBudgetHint`
      // still returns the raw physical pending for a past month while
      // `BudgetCalculator` zeroes it. That divergence is recorded as a known
      // follow-up in the ticket notes, so the hint stays out of this assertion.
    });

    test(
        'an archived category keeps month M (physical + virtual) and drops '
        'both paths from M + 1, consistently across all three surfaces',
        () async {
      await harness.budgetService.setCategoryBudget(
        currencyCode: currency,
        categoryId: 'dining',
        month: nowYm,
        amountMinor: 500000,
        scope: BudgetEditScope.thisAndFollowing,
      );
      final physical = await _createMonthlySeries(
        harness,
        description: 'Rent',
        amountMinor: 30000,
        startDate: DateTime(2026, 5, 20, 9, 0),
      );
      await _createMonthlySeries(
        harness,
        description: 'Internet',
        amountMinor: 20000,
        startDate: DateTime(2026, 5, 10, 9, 0),
      );
      // September/October sit past the physical window; materializing one
      // occurrence per month puts a physical bill next to the virtual one that
      // the overlay still synthesizes for the other series.
      await harness.recurringService
          .ensureMaterialized(seriesId: physical, occurrenceKey: '2026-09-20');
      await harness.recurringService
          .ensureMaterialized(seriesId: physical, occurrenceKey: '2026-10-20');

      const september = YearMonth(2026, 9);
      const october = YearMonth(2026, 10);
      final beforeSeptember = await _summary(harness, currency, september);
      final beforeSeptemberRow = _row(beforeSeptember, 'dining');
      expect(beforeSeptemberRow.pendingMinor, 30000 + 20000);
      expect(beforeSeptemberRow.contributions.any((c) => c.isVirtual), isTrue);
      expect(beforeSeptemberRow.contributions.any((c) => !c.isVirtual), isTrue);
      await _expectThreeSurfacesAgree(harness, currency, september, 'dining');
      await _expectThreeSurfacesAgree(harness, currency, october, 'dining');

      // Archive it as of month M = 2026-09. The row is written directly
      // because `CategoryService.archiveCategory` derives `archivedAt` from the
      // projector's wall-clock `recordedAt`, which a FixedClock cannot pin.
      await _archiveCategoryAt(harness, 'dining', DateTime(2026, 9, 20, 8, 0));

      // M itself keeps both kinds of pending bill.
      final kept = await _summary(harness, currency, september);
      final keptRow = _row(kept, 'dining');
      expect(keptRow.isArchived, isTrue);
      expect(keptRow.archiveYm, september);
      expect(keptRow.pendingMinor, 50000);
      expect(keptRow.contributions.where((c) => c.isVirtual).length, 1);
      expect(keptRow.contributions.where((c) => !c.isVirtual).length, 1);
      // Overview, category row and the form hint project the same remainder.
      await _expectThreeSurfacesAgree(harness, currency, september, 'dining');

      // M + 1 drops the physical bill AND the virtual one.
      final dropped = await _summary(harness, currency, october);
      expect(dropped.mode, BudgetMode.plan);
      expect(dropped.allExpensePendingMinor, 0);
      final droppedHint = await _hint(harness, currency, october, 'dining');
      expect(droppedHint.isCategoryArchived, isTrue);
      expect(droppedHint.pendingMinor, 0);
      // No budget is effective past the archive month either, so the row has
      // nothing left to show and is not carried into the summary.
      expect(droppedHint.effectiveBudgetMinor, isNull);
      expect(dropped.findCategory('dining'), isNull);
    });

    test('a six-month plan trend carries pending only at the target month',
        () async {
      await harness.budgetService.setCategoryBudget(
        currencyCode: currency,
        categoryId: 'dining',
        month: nowYm,
        amountMinor: 500000,
        scope: BudgetEditScope.thisAndFollowing,
      );
      await _createMonthlySeries(
        harness,
        description: 'Rent',
        amountMinor: 300000,
        startDate: DateTime(2026, 5, 20, 9, 0),
      );

      final target = nowYm.addMonths(6);
      expect(target.ym, 202611);
      final summary = await _summary(harness, currency, target);
      expect(summary.mode, BudgetMode.plan);
      expect(summary.monthTrend6Months.length, 6);
      expect(
        [for (final point in summary.monthTrend6Months) point.month.ym],
        [202606, 202607, 202608, 202609, 202610, 202611],
      );
      // The budget itself is present for all six months, so the zeros are the
      // trend rule, not an empty trend.
      expect([for (final point in summary.monthTrend6Months) point.budgetMinor],
          [for (var i = 0; i < 6; i++) 500000]);
      expect(
        [for (final point in summary.monthTrend6Months) point.pendingMinor],
        [0, 0, 0, 0, 0, 300000],
      );
      expect(summary.monthTrend6Months.last.pendingMinor,
          summary.allExpensePendingMinor);

      final row = _row(summary, 'dining');
      expect(row.sixMonthTrend.map((p) => p.pendingMinor).toList(),
          [0, 0, 0, 0, 0, 300000]);
    });

    test(
        'materialize-on-write makes a virtual bill real once and the budget '
        'pending follows on the live stream', () async {
      await harness.budgetService.setCategoryBudget(
        currencyCode: currency,
        categoryId: 'dining',
        month: nowYm,
        amountMinor: 500000,
        scope: BudgetEditScope.thisAndFollowing,
      );
      final seriesId = await _createMonthlySeries(
        harness,
        description: 'Rent',
        amountMinor: 300000,
        startDate: DateTime(2026, 5, 20, 9, 0),
      );

      const november = YearMonth(2026, 11);
      final before = await _summary(harness, currency, november);
      final beforeRow = _row(before, 'dining');
      expect(beforeRow.pendingMinor, 300000);
      final virtualBill = beforeRow.contributions.single;
      expect(virtualBill.isVirtual, isTrue);
      expect(virtualBill.occurrenceKey, '2026-11-20');
      expect(virtualBill.scheduledBillId, isNull);

      final emissions = <MonthBudgetSummary>[];
      final subscription = harness.budgetService
          .watchMonthBudget(currencyCode: currency, month: november)
          .listen(emissions.add);
      addTearDown(subscription.cancel);
      await _pumpUntil(() => emissions.isNotEmpty,
          reason: 'the first budget emission');

      final materializeResult = await harness.recurringService.ensureMaterialized(
        seriesId: seriesId,
        occurrenceKey: '2026-11-20',
      );
      expect(materializeResult, isA<Success<ScheduledTransactionEntity>>());
      final bill = (materializeResult as Success<ScheduledTransactionEntity>).value;
      expect(bill.id, isNotEmpty);
      expect(bill.occurrenceKey, '2026-11-20');
      expect(bill.status, ScheduledTransactionStatus.scheduled);
      expect(bill.manualOnly, isFalse);

      // Idempotent: the second call resolves the same UUID row.
      final second = await harness.recurringService.ensureMaterialized(
        seriesId: seriesId,
        occurrenceKey: '2026-11-20',
      );
      expect((second as Success<ScheduledTransactionEntity>).value.id, bill.id);
      final scheduled =
          await harness.recurringService.watchScheduled(currencyCode: currency).first;
      expect(
        scheduled
            .where((b) =>
                b.seriesId == seriesId && b.occurrenceKey == '2026-11-20')
            .length,
        1,
      );

      // Same money, now backed by the physical row instead of a projection.
      await _pumpUntil(
        () =>
            emissions.isNotEmpty &&
            emissions.last.findCategory('dining')!.contributions.single
                    .scheduledBillId ==
                bill.id,
        reason: 'the materialized bill to replace the virtual one',
      );
      expect(emissions.last.findCategory('dining')!.pendingMinor, 300000);
      expect(emissions.last.findCategory('dining')!.contributions.single.isVirtual,
          isFalse);

      // Posting it moves the money from pending to actual.
      final postResult = await harness.recurringService
          .postInstance(bill.id, commandId: 'post-november-rent');
      expect(postResult, isA<Success<void>>());
      await _pumpUntil(
        () => emissions.isNotEmpty && emissions.last.findCategory('dining')!.pendingMinor == 0,
        reason: 'pending to drop after posting',
      );
      final posted = emissions.last.findCategory('dining')!;
      expect(posted.pendingMinor, 0);
      expect(posted.committedActualMinor, 300000);
      expect(posted.actualMinor, 300000);
      // The same money is now a committed posting pointing back at the bill.
      final postedTx = posted.contributions.single;
      expect(postedTx.isPending, isFalse);
      expect(postedTx.sourceScheduledBillId, bill.id);
      expect(postedTx.amountMinor, 300000);

      // Skipping the next occurrence takes its pending off the stream too.
      const december = YearMonth(2026, 12);
      final decemberEmissions = <MonthBudgetSummary>[];
      final decemberSubscription = harness.budgetService
          .watchMonthBudget(currencyCode: currency, month: december)
          .listen(decemberEmissions.add);
      addTearDown(decemberSubscription.cancel);
      await _pumpUntil(() => decemberEmissions.isNotEmpty,
          reason: 'the first December emission');
      expect(decemberEmissions.last.findCategory('dining')!.pendingMinor, 300000);

      final decemberResult = await harness.recurringService.ensureMaterialized(
        seriesId: seriesId,
        occurrenceKey: '2026-12-20',
      );
      final decemberBill =
          (decemberResult as Success<ScheduledTransactionEntity>).value;
      final skipResult = await harness.recurringService.deleteBill(
        decemberBill.id,
        scope: RecurringScope.thisOnly,
      );
      expect(skipResult, isA<Success<void>>());
      await _pumpUntil(
        () =>
            decemberEmissions.isNotEmpty &&
            decemberEmissions.last.findCategory('dining')!.pendingMinor == 0,
        reason: 'pending to drop after skipping',
      );
      final skipped = await harness.recurringService
          .watchScheduled(currencyCode: currency)
          .first;
      expect(
        skipped
            .singleWhere((b) =>
                b.seriesId == seriesId && b.occurrenceKey == '2026-12-20')
            .status,
        ScheduledTransactionStatus.skipped,
      );
    });
  });
}

/// Creates a series through the service the way a form does and returns its id.
Future<String> _createMonthlySeries(
  LedgerServiceHarness harness, {
  required String description,
  required int amountMinor,
  required DateTime startDate,
  String frequency = 'MONTHLY',
  List<int> weekdays = const [],
  DateTime? materializeFrom,
  String categoryId = 'dining',
}) async {
  final result = await harness.recurringService.createSeries(
    type: RecurringSeriesKind.expense,
    amountMinor: amountMinor,
    accountId: 'acc-cash',
    categoryId: categoryId,
    description: description,
    frequency: frequency,
    weekdays: weekdays,
    startDate: startDate,
    materializeFrom: materializeFrom,
  );
  expect(result, isA<Success<String>>(), reason: 'createSeries failed: $result');
  return (result as Success<String>).value;
}

Future<MonthBudgetSummary> _summary(
  LedgerServiceHarness harness,
  String currency,
  YearMonth month,
) =>
    harness.budgetService.watchMonthBudget(currencyCode: currency, month: month).first;

Future<CategoryBudgetHint> _hint(
  LedgerServiceHarness harness,
  String currency,
  YearMonth month,
  String categoryId,
) =>
    harness.budgetService
        .watchTransactionBudgetHint(
          currencyCode: currency,
          month: month,
          categoryId: categoryId,
        )
        .first;

CategoryBudgetSummary _row(MonthBudgetSummary summary, String categoryId) {
  final row = summary.findCategory(categoryId);
  expect(row, isNotNull,
      reason: 'category $categoryId is missing from ${summary.month.ym}');
  return row!;
}

List<BudgetContributionTx> _contributionsOf(
  CategoryBudgetSummary row,
  String seriesId,
) =>
    [
      for (final tx in row.contributions)
        if (tx.seriesId == seriesId) tx
    ];

/// Reads the overview, the category row and the form hint for one month and
/// asserts the three surfaces project exactly the same remainder.
Future<void> _expectThreeSurfacesAgree(
  LedgerServiceHarness harness,
  String currency,
  YearMonth month,
  String categoryId,
) async {
  final summary = await _summary(harness, currency, month);
  final row = _row(summary, categoryId);
  final hint = await _hint(harness, currency, month, categoryId);

  expect(hint.isCategoryArchived, row.isArchived);
  expect(hint.effectiveBudgetMinor, row.budgetMinor);
  expect(hint.actualMinor, row.actualMinor, reason: 'actual at ${month.ym}');
  expect(hint.pendingMinor, row.pendingMinor, reason: 'pending at ${month.ym}');
  expect(summary.budgetedPendingMinor, row.pendingMinor,
      reason: 'overview pending at ${month.ym}');
  expect(row.committedBaselineMinor, row.committedActualMinor + row.pendingMinor);

  final budgetMinor = row.budgetMinor;
  expect(budgetMinor, isNotNull, reason: 'budget at ${month.ym}');
  final expectedRemaining = budgetMinor! - row.actualMinor - row.pendingMinor;
  expect(row.projectedRemainingMinor, expectedRemaining,
      reason: 'category row at ${month.ym}');
  expect(summary.projectedRemainingMinor, expectedRemaining,
      reason: 'overview at ${month.ym}');
  // The form has no projected-remaining field; it derives the same number.
  expect(hint.effectiveBudgetMinor! - hint.actualMinor - hint.pendingMinor,
      expectedRemaining,
      reason: 'form hint at ${month.ym}');
}

/// Archives a category with a deterministic `archivedAt`.
///
/// `CategoryService.archiveCategory` is not usable under a FixedClock: the
/// projector stamps `archived_at` from the event envelope's `recordedAt`,
/// which is always `DateTime.now()` wall clock. Writing the projection row
/// directly is the pattern `budget_dao_test.dart` already uses.
Future<void> _archiveCategoryAt(
  LedgerServiceHarness harness,
  String categoryId,
  DateTime archivedAt,
) async {
  await (harness.db.update(harness.db.categoriesView)
        ..where((c) => c.id.equals(categoryId)))
      .write(CategoriesViewCompanion(
    archived: const Value(true),
    archivedAt: Value(archivedAt),
  ));
}

Future<void> _pumpUntil(bool Function() done, {required String reason}) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (done()) return;
    await pumpEventQueue();
  }
  fail('Timed out waiting for $reason');
}

/// Independent calendar ground truth — deliberately not derived from
/// production code, so a bug there cannot make these expectations agree.
int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

List<DateTime> _weekdaysInMonth(int year, int month, int weekday) => [
      for (var day = 1; day <= _daysInMonth(year, month); day++)
        if (DateTime(year, month, day).weekday == weekday) DateTime(year, month, day)
    ];

String _dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
