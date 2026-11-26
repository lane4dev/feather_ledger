import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

import '../../../../../support/event_sourcing/ledger_service_harness.dart';

void main() {
  late LedgerServiceHarness harness;
  late DateTime now;

  setUp(() async {
    now = DateTime(2026, 5, 15, 10, 0);
    harness = LedgerServiceHarness(clock: FixedClock(now));
    await harness.seedAccount(
      id: 'acc-cash',
      name: 'Cash',
      type: AccountType.cash,
      currencyCode: 'CNY',
    );
    await harness.seedAccount(
      id: 'acc-excl',
      name: 'Excluded',
      type: AccountType.cash,
      currencyCode: 'CNY',
    );
    await (harness.db.update(harness.db.accountsView)
          ..where((a) => a.id.equals('acc-excl')))
        .write(const AccountsViewCompanion(includeInTotals: Value(false)));
    await harness.categoryService.createCategory(
      commandId: 'cat-dining',
      categoryId: 'dining',
      name: 'Dining',
      iconKey: 'utensils',
      colorInt: 0xFFE65100,
      type: CategoryType.expense,
    );
    await harness.categoryService.createCategory(
      commandId: 'cat-rent',
      categoryId: 'rent',
      name: 'Rent',
      iconKey: 'home',
      colorInt: 0xFF1565C0,
      type: CategoryType.expense,
    );
    await harness.categoryService.createCategory(
      commandId: 'cat-salary',
      categoryId: 'salary',
      name: 'Salary',
      iconKey: 'wallet',
      colorInt: 0xFF2E7D32,
      type: CategoryType.income,
    );
  });

  tearDown(() async {
    await harness.close();
  });

  group('Budget virtual overlay projection (Track / Plan / Review)', () {
    test(
        'Track month includes full DAILY & WEEKLY exposure in summary and '
        'watchTransactionBudgetHint', () async {
      await harness.budgetService.setCategoryBudget(
        currencyCode: 'CNY',
        categoryId: 'dining',
        month: const YearMonth(2026, 5),
        amountMinor: 100000, // 1000.00
        scope: BudgetEditScope.thisAndFollowing,
      );

      // Daily lunch starting May 20 -> May 20..31 = 12 occurrences * 25.00 = 300.00
      final dailyRes = await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 2500,
        accountId: 'acc-cash',
        categoryId: 'dining',
        description: 'Daily lunch',
        frequency: 'DAILY',
        startDate: DateTime(2026, 5, 20, 12, 0),
      );
      expect(dailyRes.isSuccess, isTrue);

      // Weekly groceries on Fridays starting May 1 -> May 1, 8, 15, 22, 29 = 5 * 100.00 = 500.00
      final weeklyRes = await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 10000,
        accountId: 'acc-cash',
        categoryId: 'dining',
        description: 'Weekly groceries',
        frequency: 'WEEKLY',
        weekdays: const [DateTime.friday],
        startDate: DateTime(2026, 5, 1, 9, 0),
      );
      expect(weeklyRes.isSuccess, isTrue);

      // Excluded account series must NOT count
      await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 99900,
        accountId: 'acc-excl',
        categoryId: 'dining',
        description: 'Excluded',
        frequency: 'MONTHLY',
        startDate: DateTime(2026, 5, 1, 9, 0),
      );

      // Income series must NOT count
      await harness.recurringService.createSeries(
        type: RecurringSeriesKind.income,
        amountMinor: 500000,
        accountId: 'acc-cash',
        categoryId: 'salary',
        description: 'Paycheck',
        frequency: 'MONTHLY',
        startDate: DateTime(2026, 5, 1, 9, 0),
      );

      final summary = await harness.budgetService
          .watchMonthBudget(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 5),
          )
          .first;
      final dining = summary.findCategory('dining')!;

      expect(summary.mode, BudgetMode.track);
      expect(dining.pendingMinor, 80000); // 30000 + 50000
      expect(dining.committedBaselineMinor, 80000);
      expect(dining.projectedRemainingMinor, 20000); // 100000 - 80000

      final hint = await harness.budgetService
          .watchTransactionBudgetHint(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 5),
            categoryId: 'dining',
          )
          .first;
      expect(hint.effectiveBudgetMinor, 100000);
      expect(hint.actualMinor, 0);
      expect(hint.pendingMinor, 80000);
    });

    test(
        'Plan far-future months (M+6 and next year) expand virtual bills with '
        'metadata and respect countLimit, endDate, and materializeFrom',
        () async {
      await harness.budgetService.setCategoryBudget(
        currencyCode: 'CNY',
        categoryId: 'rent',
        month: const YearMonth(2026, 5),
        amountMinor: 500000,
        scope: BudgetEditScope.thisAndFollowing,
      );

      // Monthly rent: 36-month contract starting 2 years ago (2024-05-01),
      // materialized from today (2026-05-15).
      // 36 occurrences: 2024-05 .. 2027-04.
      // So 2026-11 (M+6) has 1 virtual occurrence; 2027-04 has 1; 2027-05 has 0!
      final rentSeriesId = (await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 300000,
        accountId: 'acc-cash',
        categoryId: 'rent',
        description: 'Apartment rent',
        frequency: 'MONTHLY',
        startDate: DateTime(2024, 5, 1, 9, 0),
        materializeFrom: DateTime(2026, 5, 15, 0, 0),
        countLimit: 36,
      ) as Success<String>)
          .value;

      // Annual insurance every November starting 2025-11-10 -> lands in 2026-11 & 2027-11
      final insuranceSeriesId = (await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 120000,
        accountId: 'acc-cash',
        categoryId: 'rent',
        description: 'Annual insurance',
        frequency: 'YEARLY',
        startDate: DateTime(2025, 11, 10, 9, 0),
        materializeFrom: DateTime(2026, 5, 15, 0, 0),
      ) as Success<String>)
          .value;

      // M+6: 2026-11 (beyond physical window endOfMonth(2026-07))
      final nov2026 = await harness.budgetService
          .watchMonthBudget(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 11),
          )
          .first;
      expect(nov2026.mode, BudgetMode.plan);
      final novRent = nov2026.findCategory('rent')!;
      expect(novRent.pendingMinor, 420000); // 300000 + 120000
      expect(novRent.committedBaselineMinor, 420000);

      // Rent occurrence in 2026-11 is virtual (beyond physical horizon);
      // Insurance 2026-11 may be physically materialized by minKeep=1 sparse floor.
      final rentContrib = novRent.contributions
          .firstWhere((c) => c.seriesId == rentSeriesId);
      expect(rentContrib.isPending, isTrue);
      expect(rentContrib.isVirtual, isTrue);
      expect(rentContrib.occurrenceKey, '2026-11-01');
      expect(rentContrib.scheduledBillId, isNull);
      expect(rentContrib.amountMinor, 300000);

      final insuranceContrib = novRent.contributions
          .firstWhere((c) => c.seriesId == insuranceSeriesId);
      expect(insuranceContrib.isPending, isTrue);
      expect(insuranceContrib.occurrenceKey, '2026-11-10');
      expect(insuranceContrib.amountMinor, 120000);

      // Hint for far-future month 2026-11 matches exactly
      final novHint = await harness.budgetService
          .watchTransactionBudgetHint(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 11),
            categoryId: 'rent',
          )
          .first;
      expect(novHint.pendingMinor, 420000);

      // 2027-04 is the 36th and final occurrence of rent -> 300000
      final apr2027 = await harness.budgetService
          .watchMonthBudget(
            currencyCode: 'CNY',
            month: const YearMonth(2027, 4),
          )
          .first;
      expect(apr2027.findCategory('rent')!.pendingMinor, 300000);

      // 2027-05: rent countLimit exhausted -> 0!
      final may2027 = await harness.budgetService
          .watchMonthBudget(
            currencyCode: 'CNY',
            month: const YearMonth(2027, 5),
          )
          .first;
      expect(may2027.findCategory('rent')!.pendingMinor, 0);

      // 2027-11: next year's virtual insurance (unmaterialized since minKeep only materialized 2026-11)
      final nov2027 = await harness.budgetService
          .watchMonthBudget(
            currencyCode: 'CNY',
            month: const YearMonth(2027, 11),
          )
          .first;
      final nov2027Rent = nov2027.findCategory('rent')!;
      expect(nov2027Rent.pendingMinor, 120000);
      expect(nov2027Rent.contributions.single.isVirtual, isTrue);
      expect(nov2027Rent.contributions.single.seriesId, insuranceSeriesId);
      expect(nov2027Rent.contributions.single.occurrenceKey, '2027-11-10');

      // 2026-05: rent's 2026-05-01 is BEFORE materializeFrom (2026-05-15), so excluded!
      final may2026 = await harness.budgetService
          .watchMonthBudget(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 5),
          )
          .first;
      expect(may2026.findCategory('rent')!.pendingMinor, 0);
    });

    test(
        'Overlay conservation: posting moves pending->committedActual, '
        'skipping deducts, amount/memo overrides apply, and cross-month '
        'dateOverride conserves total', () async {
      await harness.budgetService.setCategoryBudget(
        currencyCode: 'CNY',
        categoryId: 'dining',
        month: const YearMonth(2026, 5),
        amountMinor: 100000,
        scope: BudgetEditScope.thisAndFollowing,
      );

      // Weekly series on Sundays starting May 3 -> May 3, 10, 17, 24, 31 (5 * 10000 = 50000)
      // June Sundays: June 7, 14, 21, 28 (4 * 10000 = 40000)
      final seriesId = (await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 10000,
        accountId: 'acc-cash',
        categoryId: 'dining',
        description: 'Sunday dinner',
        frequency: 'WEEKLY',
        weekdays: const [DateTime.sunday],
        startDate: DateTime(2026, 5, 3, 18, 0),
      ) as Success<String>)
          .value;

      final scheduledRows =
          await harness.db.recurringDao.scheduledForSeries(seriesId);
      String idForKey(String key) =>
          scheduledRows.firstWhere((r) => r.occurrenceKey == key).id;

      // 1. Post May 3 -> moves 10000 from pending to committedActual
      final postRes = await harness.recurringService
          .postInstance(idForKey('2026-05-03'), commandId: 'post-may-3');
      expect(postRes.isSuccess, isTrue);

      // 2. Skip May 10 -> removes 10000 from pending (must not reappear virtually)
      final skipRes = await harness.recurringService.deleteBill(
        idForKey('2026-05-10'),
        scope: RecurringScope.thisOnly,
      );
      expect(skipRes.isSuccess, isTrue);

      // 3. Edit May 17 amount override to 15000 & memo override
      final editAmtRes = await harness.recurringService.updateBill(
        idForKey('2026-05-17'),
        scope: RecurringScope.thisOnly,
        amountMinor: 15000,
        date: DateTime(2026, 5, 17, 18, 0),
        categoryId: 'dining',
        accountId: 'acc-cash',
        description: 'Birthday dinner',
      );
      expect(editAmtRes.isSuccess, isTrue);

      // 4. Move May 31 via dateOverride into June 2 -> May loses 10000, June gains 10000
      final moveRes = await harness.recurringService.updateBill(
        idForKey('2026-05-31'),
        scope: RecurringScope.thisOnly,
        amountMinor: 10000,
        date: DateTime(2026, 6, 2, 18, 0),
        categoryId: 'dining',
        accountId: 'acc-cash',
        description: 'Sunday dinner',
      );
      expect(moveRes.isSuccess, isTrue);

      // May check:
      // - May 3: posted -> committedActual = 10000
      // - May 10: skipped -> 0
      // - May 17: overridden -> 15000 ('Birthday dinner')
      // - May 24: normal -> 10000
      // - May 31: moved to June 2 -> 0 in May
      // Total pending in May = 25000, committedActual = 10000, committedBaseline = 35000
      final may = await harness.budgetService
          .watchMonthBudget(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 5),
          )
          .first;
      final mayDining = may.findCategory('dining')!;
      expect(mayDining.committedActualMinor, 10000);
      expect(mayDining.pendingMinor, 25000);
      expect(mayDining.committedBaselineMinor, 35000);
      expect(
        mayDining.contributions
            .where((c) => c.isPending)
            .map((c) => (c.occurrenceKey, c.amountMinor, c.description, c.isVirtual))
            .toList(),
        unorderedEquals([
          ('2026-05-17', 15000, 'Birthday dinner', false),
          ('2026-05-24', 10000, 'Sunday dinner', false),
        ]),
      );

      // June check:
      // 4 Sundays (40000) + moved May 31 (10000) = 50000!
      final june = await harness.budgetService
          .watchMonthBudget(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 6),
          )
          .first;
      final juneDining = june.findCategory('dining')!;
      expect(juneDining.pendingMinor, 50000);
      expect(juneDining.contributions.where((c) => c.isPending).length, 5);
    });

    test(
        'Review historical month does NOT expand virtual bills and only '
        'reports physical leftover scheduled/failed bills', () async {
      await harness.budgetService.setCategoryBudget(
        currencyCode: 'CNY',
        categoryId: 'dining',
        month: const YearMonth(2026, 4),
        amountMinor: 100000,
        scope: BudgetEditScope.thisAndFollowing,
      );

      // Insert an active monthly series starting in 2026-01 with NO physical rows in 2026-04
      await harness.db.into(harness.db.recurringSeries).insert(
            RecurringSeriesCompanion.insert(
              id: 's-past-unmaterialized',
              rrule: 'FREQ=MONTHLY;INTERVAL=1',
              startDate: DateTime(2026, 1, 10, 9, 0),
              materializeFrom: Value(DateTime(2026, 1, 10, 9, 0)),
              frequency: 'MONTHLY',
              amountMinor: 20000,
              description: 'Past unmaterialized',
              categoryId: 'dining',
              accountId: 'acc-cash',
              type: RecurringSeriesKind.expense,
              mode: const Value(RecurringSeriesMode.repeating),
            ),
          );

      final aprilNoPhysical = await harness.budgetService
          .watchMonthBudget(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 4),
          )
          .first;
      expect(aprilNoPhysical.mode, BudgetMode.review);
      expect(aprilNoPhysical.hasLeftoverPendingInReview, isFalse);
      expect(aprilNoPhysical.findCategory('dining')!.pendingMinor, 0);

      // Hint in review month also does not inflate with virtual bills
      final aprilHint = await harness.budgetService
          .watchTransactionBudgetHint(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 4),
            categoryId: 'dining',
          )
          .first;
      expect(aprilHint.pendingMinor, 0);

      // Now insert a genuine physical leftover scheduled bill in April 2026
      await harness.db.into(harness.db.scheduledTransactionsView).insert(
            ScheduledTransactionsViewCompanion.insert(
              id: 'b-april-leftover',
              seriesId: 's-past-unmaterialized',
              occurrenceKey: '2026-04-10',
              scheduledDate: DateTime(2026, 4, 10, 9, 0),
              status: 'scheduled',
            ),
          );

      final aprilWithLeftover = await harness.budgetService
          .watchMonthBudget(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 4),
          )
          .first;
      expect(aprilWithLeftover.mode, BudgetMode.review);
      expect(aprilWithLeftover.hasLeftoverPendingInReview, isTrue);
      // Review mode still keeps category pendingMinor = 0 while flagging leftover hint
      expect(aprilWithLeftover.findCategory('dining')!.pendingMinor, 0);
    });

    test(
        'Archived account does not expand virtual future bills, but legacy '
        'physical overdue planned bills still appear in Track', () async {
      await harness.seedAccount(
        id: 'acc-arch',
        name: 'Old Card',
        type: AccountType.credit,
        currencyCode: 'CNY',
      );
      await harness.db.into(harness.db.recurringSeries).insert(
            RecurringSeriesCompanion.insert(
              id: 's-arch-active',
              rrule: 'FREQ=MONTHLY;INTERVAL=1',
              startDate: DateTime(2026, 5, 1, 9, 0),
              materializeFrom: Value(DateTime(2026, 5, 1, 9, 0)),
              frequency: 'MONTHLY',
              amountMinor: 50000,
              description: 'Archived active series',
              categoryId: 'rent',
              accountId: 'acc-arch',
              type: RecurringSeriesKind.expense,
              mode: const Value(RecurringSeriesMode.repeating),
            ),
          );
      await harness.db.into(harness.db.recurringSeries).insert(
            RecurringSeriesCompanion.insert(
              id: 's-arch-legacy-planned',
              rrule: 'FREQ=MONTHLY;INTERVAL=1',
              startDate: DateTime(2026, 5, 5, 9, 0),
              materializeFrom: Value(DateTime(2026, 5, 5, 9, 0)),
              frequency: 'MONTHLY',
              amountMinor: 12000,
              description: 'Legacy overdue bill',
              categoryId: 'rent',
              accountId: 'acc-arch',
              type: RecurringSeriesKind.expense,
              mode: const Value(RecurringSeriesMode.planned),
              isActive: const Value(false),
            ),
          );
      await harness.db.into(harness.db.scheduledTransactionsView).insert(
            ScheduledTransactionsViewCompanion.insert(
              id: 'b-legacy-overdue',
              seriesId: 's-arch-legacy-planned',
              occurrenceKey: kPlannedOccurrenceKey,
              scheduledDate: DateTime(2026, 5, 5, 9, 0),
              status: 'scheduled',
            ),
          );
      // Archive account directly via view to simulate archived state with legacy planned bill
      await (harness.db.update(harness.db.accountsView)
            ..where((a) => a.id.equals('acc-arch')))
          .write(const AccountsViewCompanion(archived: Value(true)));

      // May (Track): only the physical legacy overdue bill (12000), NOT virtual 50000
      final may = await harness.budgetService
          .watchMonthBudget(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 5),
          )
          .first;
      expect(may.findCategory('rent')!.pendingMinor, 12000);

      // Nov (Plan): archived account expands nothing -> 0
      final nov = await harness.budgetService
          .watchMonthBudget(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 11),
          )
          .first;
      expect(nov.findCategory('rent')!.pendingMinor, 0);
    });
  });
}
