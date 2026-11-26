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
    await harness.categoryService.createCategory(
      commandId: 'cat-rent',
      categoryId: 'rent',
      name: 'Rent',
      iconKey: 'home',
      colorInt: 0xFF1565C0,
      type: CategoryType.expense,
    );
  });

  tearDown(() async {
    await harness.close();
  });

  group('Virtual bill materialize-on-write (ensureMaterialized)', () {
    test(
        'materializes a far-future M+6 virtual occurrence idempotently with the '
        'same UUID and resolved metadata', () async {
      final created = await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 300000,
        accountId: 'acc-cash',
        categoryId: 'rent',
        description: 'Apartment rent',
        frequency: 'MONTHLY',
        startDate: DateTime(2026, 5, 1, 9, 0),
        materializeFrom: DateTime(2026, 5, 15, 0, 0),
      );
      expect(created.isSuccess, isTrue);
      final seriesId = (created as Success<String>).value;

      // M+6 (2026-11) is beyond the 3-month physical horizon (2026-07-31),
      // so the budget overlay exposes it as a virtual pending contribution.
      final beforeSummary = await harness.budgetService
          .watchMonthBudget(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 11),
          )
          .first;
      final beforeRent = beforeSummary.findCategory('rent')!;
      expect(beforeRent.allTransactions, hasLength(1));
      final virtualTx = beforeRent.allTransactions!.single;
      expect(virtualTx.isVirtual, isTrue);
      expect(virtualTx.seriesId, seriesId);
      expect(virtualTx.occurrenceKey, '2026-11-01');

      // First materialize-on-write creates a physical scheduled UUID row.
      final first = await harness.recurringService.ensureMaterialized(
        seriesId: seriesId,
        occurrenceKey: '2026-11-01',
      );
      expect(first.isSuccess, isTrue);
      final bill1 = (first as Success<ScheduledTransactionEntity>).value;
      expect(bill1.id, isNotEmpty);
      expect(bill1.seriesId, seriesId);
      expect(bill1.occurrenceKey, '2026-11-01');
      expect(bill1.scheduledDate, DateTime(2026, 11, 1, 9, 0));
      expect(bill1.status, ScheduledTransactionStatus.scheduled);
      expect(bill1.manualOnly, isFalse);
      expect(bill1.account?.id, 'acc-cash');
      expect(bill1.category?.id, 'rent');
      expect(bill1.recurringTransactionSeries?.id, seriesId);

      // Second call is strictly idempotent: same UUID, no duplicate row.
      final second = await harness.recurringService.ensureMaterialized(
        seriesId: seriesId,
        occurrenceKey: '2026-11-01',
      );
      expect(second.isSuccess, isTrue);
      final bill2 = (second as Success<ScheduledTransactionEntity>).value;
      expect(bill2.id, bill1.id);

      final allScheduled =
          await harness.recurringService.watchScheduled().first;
      final novRows = allScheduled
          .where(
              (r) => r.seriesId == seriesId && r.occurrenceKey == '2026-11-01')
          .toList();
      expect(novRows, hasLength(1));
      expect(novRows.single.id, bill1.id);
    });

    test(
        'rejects stopped series, archived/deleted accounts, and invalid or '
        'out-of-schedule occurrence keys without writing dirty rows', () async {
      // Monthly series: 12 installments from 2026-01-05, materialized from
      // 2026-05-15 -> valid occurrences are 2026-06-05 .. 2026-12-05.
      final seriesId = (await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 150000,
        accountId: 'acc-cash',
        categoryId: 'rent',
        description: 'Installment',
        frequency: 'MONTHLY',
        startDate: DateTime(2026, 1, 5, 9, 0),
        materializeFrom: DateTime(2026, 5, 15, 0, 0),
        countLimit: 12,
      ) as Success<String>)
          .value;

      Future<int> rowCountForSeries() async =>
          (await harness.recurringRepository.scheduledForSeries(seriesId))
              .length;
      final initialCount = await rowCountForSeries();

      // 1. Unknown series -> recurringSeriesStopped
      final missingSeries = await harness.recurringService.ensureMaterialized(
        seriesId: 'does-not-exist',
        occurrenceKey: '2026-11-05',
      );
      expect(missingSeries, isA<Failure<ScheduledTransactionEntity>>());
      expect(
        (missingSeries as Failure).code,
        LedgerErrorCode.recurringSeriesStopped,
      );

      // 2. Non-matching day -> transactionNotFound
      final wrongDay = await harness.recurringService.ensureMaterialized(
        seriesId: seriesId,
        occurrenceKey: '2026-11-06',
      );
      expect((wrongDay as Failure).code, LedgerErrorCode.transactionNotFound);

      // 3. Invalid calendar date & malformed key -> transactionNotFound
      final badDate = await harness.recurringService.ensureMaterialized(
        seriesId: seriesId,
        occurrenceKey: '2026-02-30',
      );
      expect((badDate as Failure).code, LedgerErrorCode.transactionNotFound);

      final plannedKeyOnRepeating =
          await harness.recurringService.ensureMaterialized(
        seriesId: seriesId,
        occurrenceKey: kPlannedOccurrenceKey,
      );
      expect(
        (plannedKeyOnRepeating as Failure).code,
        LedgerErrorCode.transactionNotFound,
      );

      // 4. Before materializeFrom -> transactionNotFound
      final beforeMaterializeFrom =
          await harness.recurringService.ensureMaterialized(
        seriesId: seriesId,
        occurrenceKey: '2026-05-05',
      );
      expect(
        (beforeMaterializeFrom as Failure).code,
        LedgerErrorCode.transactionNotFound,
      );

      // 5. Past countLimit (13th occurrence: 2027-01-05) -> transactionNotFound
      final pastCountLimit = await harness.recurringService.ensureMaterialized(
        seriesId: seriesId,
        occurrenceKey: '2027-01-05',
      );
      expect(
        (pastCountLimit as Failure).code,
        LedgerErrorCode.transactionNotFound,
      );

      expect(await rowCountForSeries(), initialCount);

      // 6. Archived account -> accountArchived
      await (harness.db.update(harness.db.accountsView)
            ..where((a) => a.id.equals('acc-cash')))
          .write(const AccountsViewCompanion(archived: Value(true)));
      final archivedAcc = await harness.recurringService.ensureMaterialized(
        seriesId: seriesId,
        occurrenceKey: '2026-11-05',
      );
      expect((archivedAcc as Failure).code, LedgerErrorCode.accountArchived);
      expect(await rowCountForSeries(), initialCount);

      // 7. Deleted account -> accountNotFound
      await (harness.db.update(harness.db.accountsView)
            ..where((a) => a.id.equals('acc-cash')))
          .write(const AccountsViewCompanion(
        archived: Value(false),
        deleted: Value(true),
      ));
      final deletedAcc = await harness.recurringService.ensureMaterialized(
        seriesId: seriesId,
        occurrenceKey: '2026-11-05',
      );
      expect((deletedAcc as Failure).code, LedgerErrorCode.accountNotFound);
      expect(await rowCountForSeries(), initialCount);

      // Restore account, then stop series -> recurringSeriesStopped
      await (harness.db.update(harness.db.accountsView)
            ..where((a) => a.id.equals('acc-cash')))
          .write(const AccountsViewCompanion(deleted: Value(false)));
      await (harness.db.update(harness.db.recurringSeries)
            ..where((s) => s.id.equals(seriesId)))
          .write(const RecurringSeriesCompanion(isActive: Value(false)));
      final stoppedSeries = await harness.recurringService.ensureMaterialized(
        seriesId: seriesId,
        occurrenceKey: '2026-11-05',
      );
      expect(
        (stoppedSeries as Failure).code,
        LedgerErrorCode.recurringSeriesStopped,
      );
      expect(await rowCountForSeries(), initialCount);
    });

    test(
        'supports single occurrenceKey for planned series and rejects other '
        'keys on planned series', () async {
      final plannedSeriesId = (await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 80000,
        accountId: 'acc-cash',
        categoryId: 'rent',
        description: 'One-off deposit',
        frequency: 'MONTHLY',
        startDate: DateTime(2026, 11, 20, 14, 0),
        endDate: DateTime(2026, 11, 20, 14, 0),
        mode: RecurringSeriesMode.planned,
      ) as Success<String>)
          .value;

      // Remove physical row to exercise materialization of a missing planned row
      await harness.recurringRepository
          .deleteAllScheduledForSeries(plannedSeriesId);

      final wrongKey = await harness.recurringService.ensureMaterialized(
        seriesId: plannedSeriesId,
        occurrenceKey: '2026-11-20',
      );
      expect((wrongKey as Failure).code, LedgerErrorCode.transactionNotFound);

      final first = await harness.recurringService.ensureMaterialized(
        seriesId: plannedSeriesId,
        occurrenceKey: kPlannedOccurrenceKey,
      );
      expect(first.isSuccess, isTrue);
      final bill = (first as Success<ScheduledTransactionEntity>).value;
      expect(bill.occurrenceKey, kPlannedOccurrenceKey);
      expect(bill.scheduledDate, DateTime(2026, 11, 20, 14, 0));

      final second = await harness.recurringService.ensureMaterialized(
        seriesId: plannedSeriesId,
        occurrenceKey: kPlannedOccurrenceKey,
      );
      expect((second as Success<ScheduledTransactionEntity>).value.id, bill.id);
    });

    test(
        'end-to-end M+6 materialize -> thisOnly amount override, cross-month '
        'dateOverride, and skip immediately update BudgetService', () async {
      await harness.budgetService.setCategoryBudget(
        currencyCode: 'CNY',
        categoryId: 'rent',
        month: const YearMonth(2026, 5),
        amountMinor: 500000,
        scope: BudgetEditScope.thisAndFollowing,
      );

      final seriesId = (await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 300000,
        accountId: 'acc-cash',
        categoryId: 'rent',
        description: 'Apartment rent',
        frequency: 'MONTHLY',
        startDate: DateTime(2026, 5, 1, 9, 0),
        materializeFrom: DateTime(2026, 5, 15, 0, 0),
      ) as Success<String>)
          .value;

      // 1. Materialize M+6 (2026-11-01): budget total stays 3000.00 (no double count)
      final novMat = await harness.recurringService.ensureMaterialized(
        seriesId: seriesId,
        occurrenceKey: '2026-11-01',
      );
      expect(novMat.isSuccess, isTrue);
      final novBill = (novMat as Success<ScheduledTransactionEntity>).value;

      final afterMat = await harness.budgetService
          .watchMonthBudget(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 11),
          )
          .first;
      final afterMatRent = afterMat.findCategory('rent')!;
      expect(afterMatRent.pendingMinor, 300000);
      expect(afterMatRent.allTransactions!.single.isVirtual, isFalse);
      expect(afterMatRent.allTransactions!.single.scheduledBillId, novBill.id);

      // 2. Apply thisOnly amount override: 3000.00 -> 3500.00
      final editAmount = await harness.recurringService.updateBill(
        novBill.id,
        scope: RecurringScope.thisOnly,
        amountMinor: 350000,
        date: novBill.scheduledDate,
        categoryId: 'rent',
        accountId: 'acc-cash',
        description: 'Apartment rent (winter heating)',
      );
      expect(editAmount.isSuccess, isTrue);

      final afterAmountEdit = await harness.budgetService
          .watchMonthBudget(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 11),
          )
          .first;
      expect(afterAmountEdit.findCategory('rent')!.pendingMinor, 350000);
      expect(
        afterAmountEdit.findCategory('rent')!.committedBaselineMinor,
        350000,
      );

      // 3. Apply thisOnly cross-month dateOverride: 2026-11-01 -> 2026-12-03
      final moveMonth = await harness.recurringService.updateBill(
        novBill.id,
        scope: RecurringScope.thisOnly,
        amountMinor: 350000,
        date: DateTime(2026, 12, 3, 9, 0),
        categoryId: 'rent',
        accountId: 'acc-cash',
        description: 'Apartment rent (winter heating)',
      );
      expect(moveMonth.isSuccess, isTrue);

      final novAfterMove = await harness.budgetService
          .watchMonthBudget(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 11),
          )
          .first;
      expect(novAfterMove.findCategory('rent')!.pendingMinor, 0);

      final decAfterMove = await harness.budgetService
          .watchMonthBudget(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 12),
          )
          .first;
      // 2026-12 has its own virtual 3000.00 + moved physical 3500.00 = 6500.00
      expect(decAfterMove.findCategory('rent')!.pendingMinor, 650000);

      // 4. Materialize M+7 (2026-12-01) and skip it -> 2026-12 drops back to 3500.00
      final decMat = await harness.recurringService.ensureMaterialized(
        seriesId: seriesId,
        occurrenceKey: '2026-12-01',
      );
      final decBill = (decMat as Success<ScheduledTransactionEntity>).value;
      final skipped = await harness.recurringService.deleteBill(
        decBill.id,
        scope: RecurringScope.thisOnly,
      );
      expect(skipped.isSuccess, isTrue);

      final decAfterSkip = await harness.budgetService
          .watchMonthBudget(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 12),
          )
          .first;
      expect(decAfterSkip.findCategory('rent')!.pendingMinor, 350000);
    });

    test(
        'thisOnly dateOverride rejects colliding with an unmaterialized '
        'virtual occurrence, but allows landing on a skipped or moved-away '
        'occurrence date', () async {
      final seriesId = (await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 300000,
        accountId: 'acc-cash',
        categoryId: 'rent',
        description: 'Apartment rent',
        frequency: 'MONTHLY',
        startDate: DateTime(2026, 5, 1, 9, 0),
        materializeFrom: DateTime(2026, 5, 15, 0, 0),
      ) as Success<String>)
          .value;

      // Materialize M+6 (2026-11-01); M+7 (2026-12-01) and M+8 (2027-01-01)
      // remain unmaterialized virtual occurrences.
      final novBill = (await harness.recurringService.ensureMaterialized(
        seriesId: seriesId,
        occurrenceKey: '2026-11-01',
      ) as Success<ScheduledTransactionEntity>)
          .value;

      // 1. Rescheduling M+6 onto M+7's unmaterialized occurrence date must fail.
      final collideVirtual = await harness.recurringService.updateBill(
        novBill.id,
        scope: RecurringScope.thisOnly,
        amountMinor: 300000,
        date: DateTime(2026, 12, 1, 14, 30),
        categoryId: 'rent',
        accountId: 'acc-cash',
        description: 'Apartment rent',
      );
      expect(collideVirtual, isA<Failure<void>>());
      expect(
        (collideVirtual as Failure).code,
        LedgerErrorCode.scheduledDateTaken,
      );

      // 2. Materialize M+7 and skip it -> M+6 can now move onto 2026-12-01.
      final decBill = (await harness.recurringService.ensureMaterialized(
        seriesId: seriesId,
        occurrenceKey: '2026-12-01',
      ) as Success<ScheduledTransactionEntity>)
          .value;
      final skipDec = await harness.recurringService.deleteBill(
        decBill.id,
        scope: RecurringScope.thisOnly,
      );
      expect(skipDec.isSuccess, isTrue);

      final moveOntoSkipped = await harness.recurringService.updateBill(
        novBill.id,
        scope: RecurringScope.thisOnly,
        amountMinor: 300000,
        date: DateTime(2026, 12, 1, 14, 30),
        categoryId: 'rent',
        accountId: 'acc-cash',
        description: 'Apartment rent',
      );
      expect(moveOntoSkipped.isSuccess, isTrue);

      // 3. Materialize M+8 (2027-01-01) and move it away to 2027-01-05 ->
      //    M+6 can now move onto 2027-01-01.
      final janBill = (await harness.recurringService.ensureMaterialized(
        seriesId: seriesId,
        occurrenceKey: '2027-01-01',
      ) as Success<ScheduledTransactionEntity>)
          .value;
      final moveJanAway = await harness.recurringService.updateBill(
        janBill.id,
        scope: RecurringScope.thisOnly,
        amountMinor: 300000,
        date: DateTime(2027, 1, 5, 9, 0),
        categoryId: 'rent',
        accountId: 'acc-cash',
        description: 'Apartment rent',
      );
      expect(moveJanAway.isSuccess, isTrue);

      final moveOntoMovedAway = await harness.recurringService.updateBill(
        novBill.id,
        scope: RecurringScope.thisOnly,
        amountMinor: 300000,
        date: DateTime(2027, 1, 1, 9, 0),
        categoryId: 'rent',
        accountId: 'acc-cash',
        description: 'Apartment rent',
      );
      expect(moveOntoMovedAway.isSuccess, isTrue);
    });
  });
}
