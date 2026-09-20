import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/settings/domain/models/restore_confirmation_batch.dart';

import '../../../../support/event_sourcing/ledger_service_harness.dart';
import '../../../../support/mocks/mock_shared_preferences.dart';

void main() {
  late LedgerServiceHarness harness;

  Future<PreferencesRepository> prefsWithSubscriptionOn() async {
    final prefs = PreferencesRepositoryImpl(MockSharedPreferences());
    await prefs.setAutoPostEnabled(RecurringSeriesMode.subscription, true);
    await prefs.setAutoPostEnabledSince(
      RecurringSeriesMode.subscription,
      DateTime.now().subtract(const Duration(days: 30)),
    );
    return prefs;
  }

  Future<PreferencesRepository> prefsAllOff() async =>
      PreferencesRepositoryImpl(MockSharedPreferences());

  setUp(() async {
    harness = LedgerServiceHarness(
      autoPostEnabled: true,
      preferences: await prefsWithSubscriptionOn(),
    );
    await harness.seedSystemCategories();
    await harness.seedAccount(id: 'acc_cash', name: 'Cash');
    await harness.seedCategory(id: 'cat_rent', name: 'Rent');
  });

  tearDown(() => harness.close());

  test(
    'a restore barrier keeps window candidates from auto-posting until confirmed',
    () async {
      // A daily subscription whose first bill fell due before the restore.
      final start = DateTime.now().subtract(const Duration(days: 2));
      await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 20000,
        accountId: 'acc_cash',
        categoryId: 'cat_rent',
        description: 'Rent',
        frequency: 'DAILY',
        interval: 1,
        startDate: start,
        mode: RecurringSeriesMode.subscription,
      );

      // The bills were materialized while still future (so they never got the
      // ticket-32 creation latch); re-arm every overdue bill as eligible.
      final now = DateTime.now();
      final bills = await harness.recurringService.watchScheduled().first;
      for (final bill in bills.where((i) => !i.date.isAfter(now))) {
        final row = await harness.db.recurringDao.getScheduled(bill.id);
        await harness.db.recurringDao.insertOrUpdateScheduled(
          ScheduledTransactionsViewCompanion(
            id: Value(row!.id),
            seriesId: Value(row.seriesId),
            date: Value(row.date),
            amountMinor: Value(row.amountMinor),
            status: Value(row.status),
            transactionId: Value(row.transactionId),
            autoPostEligible: const Value(true),
          ),
        );
      }

      // A backup taken three days ago is restored: every overdue bill falls in
      // the confirmation window and must await explicit confirmation.
      await harness.recurringRepository.createRestoreConfirmationBatch(
        now.subtract(const Duration(days: 3)),
      );

      final eventsBefore = await harness.db.eventsDao.countAll();
      await harness.recurringService.catchUpAutoPosted();

      final after = await harness.recurringService.watchScheduled().first;
      for (final bill in after.where((i) => !i.date.isAfter(now))) {
        expect(bill.status, ScheduledTransactionStatus.scheduled,
            reason: 'overdue bill ${bill.id} was auto-posted before confirmation');
      }
      expect(await harness.db.eventsDao.countAll(), eventsBefore,
          reason: 'no new event may be written before the barrier is confirmed');
    },
  );

  test(
    'confirming one restore batch does not post another deferred batch',
    () async {
      // A daily subscription spanning two separate restore windows.
      final start = DateTime.now().subtract(const Duration(days: 10));
      await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 20000,
        accountId: 'acc_cash',
        categoryId: 'cat_rent',
        description: 'Rent',
        frequency: 'DAILY',
        interval: 1,
        startDate: start,
        mode: RecurringSeriesMode.subscription,
      );

      // Re-arm every overdue bill as eligible (they were latched at creation).
      final now = DateTime.now();
      final bills = await harness.recurringService.watchScheduled().first;
      final overdue = bills.where((i) => !i.date.isAfter(now)).toList();
      for (final bill in overdue) {
        final row = await harness.db.recurringDao.getScheduled(bill.id);
        await harness.db.recurringDao.insertOrUpdateScheduled(
          ScheduledTransactionsViewCompanion(
            id: Value(row!.id),
            seriesId: Value(row.seriesId),
            date: Value(row.date),
            amountMinor: Value(row.amountMinor),
            status: Value(row.status),
            transactionId: Value(row.transactionId),
            autoPostEligible: const Value(true),
          ),
        );
      }

      // Two restores applied at different times; each owns its own window.
      // Batch A covers bills due (now-10d, now-8d]; batch B covers (now-6d, now-4d].
      await harness.recurringRepository.createRestoreConfirmationBatch(
        now.subtract(const Duration(days: 10)),
        createdAt: now.subtract(const Duration(days: 8)),
      );
      final batchB = await harness.recurringRepository
          .createRestoreConfirmationBatch(
        now.subtract(const Duration(days: 6)),
        createdAt: now.subtract(const Duration(days: 4)),
      );

      // The bill due 5 days ago lives in B only.
      final inB = overdue.firstWhere((i) =>
          i.date.isAfter(now.subtract(const Duration(days: 6))) &&
          !i.date.isAfter(now.subtract(const Duration(days: 4))));
      final inAOnly = overdue.firstWhere((i) =>
          i.date.isAfter(now.subtract(const Duration(days: 10))) &&
          !i.date.isAfter(now.subtract(const Duration(days: 8))));

      await harness.recurringService.confirmRestoreBatch(batchB);

      final after = await harness.recurringService.watchScheduled().first;
      final posted = after.firstWhere((i) => i.id == inB.id);
      final deferred = after.firstWhere((i) => i.id == inAOnly.id);
      expect(posted.status, ScheduledTransactionStatus.posted,
          reason: 'the agreed batch posts its own candidates');
      expect(deferred.status, ScheduledTransactionStatus.scheduled,
          reason: 'the other batch stays deferred');
    },
  );

  test('rejecting a restore batch turns its candidates manual', () async {
    final start = DateTime.now().subtract(const Duration(days: 2));
    await harness.recurringService.createSeries(
      type: RecurringSeriesKind.expense,
      amountMinor: 20000,
      accountId: 'acc_cash',
      categoryId: 'cat_rent',
      description: 'Rent',
      frequency: 'DAILY',
      interval: 1,
      startDate: start,
      mode: RecurringSeriesMode.subscription,
    );

    final now = DateTime.now();
    final bills = await harness.recurringService.watchScheduled().first;
    final overdue = bills.where((i) => !i.date.isAfter(now)).toList();
    for (final bill in overdue) {
      final row = await harness.db.recurringDao.getScheduled(bill.id);
      await harness.db.recurringDao.insertOrUpdateScheduled(
        ScheduledTransactionsViewCompanion(
          id: Value(row!.id),
          seriesId: Value(row.seriesId),
          date: Value(row.date),
          amountMinor: Value(row.amountMinor),
          status: Value(row.status),
          transactionId: Value(row.transactionId),
          autoPostEligible: const Value(true),
        ),
      );
    }

    final batch = await harness.recurringRepository
        .createRestoreConfirmationBatch(now.subtract(const Duration(days: 3)));

    await harness.recurringService.rejectRestoreBatch(batch);

    final after = await harness.recurringService.watchScheduled().first;
    for (final bill in after.where((i) => !i.date.isAfter(now))) {
      expect(bill.status, ScheduledTransactionStatus.scheduled);
      expect(bill.autoPostEligible, isFalse,
          reason: 'rejected candidates are permanently manual');
    }
    expect(
      (await harness.recurringRepository.restoreConfirmationBatch(batch))
          ?.status,
      RestoreConfirmationStatus.rejected,
    );
  });

  test(
    'a switch already off at restore latches its window candidates manual',
    () async {
      // Rebuild with every auto-post switch off (spec 006, US65).
      await harness.close();
      harness = LedgerServiceHarness(
        autoPostEnabled: true,
        preferences: await prefsAllOff(),
      );
      await harness.seedSystemCategories();
      await harness.seedAccount(id: 'acc_cash', name: 'Cash');
      await harness.seedCategory(id: 'cat_rent', name: 'Rent');

      final start = DateTime.now().subtract(const Duration(days: 2));
      await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 20000,
        accountId: 'acc_cash',
        categoryId: 'cat_rent',
        description: 'Rent',
        frequency: 'DAILY',
        interval: 1,
        startDate: start,
        mode: RecurringSeriesMode.subscription,
      );

      final now = DateTime.now();
      final bills = await harness.recurringService.watchScheduled().first;
      for (final bill in bills.where((i) => !i.date.isAfter(now))) {
        final row = await harness.db.recurringDao.getScheduled(bill.id);
        await harness.db.recurringDao.insertOrUpdateScheduled(
          ScheduledTransactionsViewCompanion(
            id: Value(row!.id),
            seriesId: Value(row.seriesId),
            date: Value(row.date),
            amountMinor: Value(row.amountMinor),
            status: Value(row.status),
            transactionId: Value(row.transactionId),
            autoPostEligible: const Value(true),
          ),
        );
      }

      await harness.recurringRepository
          .createRestoreConfirmationBatch(now.subtract(const Duration(days: 3)));

      await harness.recurringService.catchUpAutoPosted();

      final after = await harness.recurringService.watchScheduled().first;
      for (final bill in after.where((i) => !i.date.isAfter(now))) {
        expect(bill.status, ScheduledTransactionStatus.scheduled);
        expect(bill.autoPostEligible, isFalse,
            reason: 'a switch that is off at restore leaves candidates manual');
      }
    },
  );

  test(
    'turning a switch off after restore latches its pending candidates manual',
    () async {
      final start = DateTime.now().subtract(const Duration(days: 2));
      await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 20000,
        accountId: 'acc_cash',
        categoryId: 'cat_rent',
        description: 'Rent',
        frequency: 'DAILY',
        interval: 1,
        startDate: start,
        mode: RecurringSeriesMode.subscription,
      );

      final now = DateTime.now();
      final bills = await harness.recurringService.watchScheduled().first;
      for (final bill in bills.where((i) => !i.date.isAfter(now))) {
        final row = await harness.db.recurringDao.getScheduled(bill.id);
        await harness.db.recurringDao.insertOrUpdateScheduled(
          ScheduledTransactionsViewCompanion(
            id: Value(row!.id),
            seriesId: Value(row.seriesId),
            date: Value(row.date),
            amountMinor: Value(row.amountMinor),
            status: Value(row.status),
            transactionId: Value(row.transactionId),
            autoPostEligible: const Value(true),
          ),
        );
      }

      final batch = await harness.recurringRepository
          .createRestoreConfirmationBatch(now.subtract(const Duration(days: 3)));
      expect(
        await harness.recurringService.restoreConfirmationEligible(batch),
        isNotEmpty,
        reason: 'before the switch is turned off the candidates are eligible',
      );

      final prefs = harness.preferences!;
      await prefs.setAutoPostEnabled(RecurringSeriesMode.subscription, false);
      await harness.recurringService
          .latchRestoreCandidatesForMode(RecurringSeriesMode.subscription);

      final after = await harness.recurringService.watchScheduled().first;
      for (final bill in after.where((i) => !i.date.isAfter(now))) {
        expect(bill.autoPostEligible, isFalse,
            reason: 'turning the switch off after restore latches candidates');
      }
      expect(
        (await harness.recurringRepository.restoreConfirmationBatch(batch))
            ?.status,
        RestoreConfirmationStatus.pending,
        reason: 'the batch stays pending until it is explicitly confirmed or rejected',
      );
    },
  );

  test(
    'rescheduling a pending restore candidate into the future keeps its eligibility',
    () async {
      // A monthly subscription whose first bill is overdue.
      final start = DateTime.now().subtract(const Duration(days: 40));
      await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 20000,
        accountId: 'acc_cash',
        categoryId: 'cat_rent',
        description: 'Rent',
        frequency: 'MONTHLY',
        interval: 1,
        startDate: start,
        mode: RecurringSeriesMode.subscription,
      );

      final now = DateTime.now();
      final bills = await harness.recurringService.watchScheduled().first;
      for (final bill in bills.where((i) => !i.date.isAfter(now))) {
        final row = await harness.db.recurringDao.getScheduled(bill.id);
        await harness.db.recurringDao.insertOrUpdateScheduled(
          ScheduledTransactionsViewCompanion(
            id: Value(row!.id),
            seriesId: Value(row.seriesId),
            date: Value(row.date),
            amountMinor: Value(row.amountMinor),
            status: Value(row.status),
            transactionId: Value(row.transactionId),
            autoPostEligible: const Value(true),
          ),
        );
      }

      final batch = await harness.recurringRepository
          .createRestoreConfirmationBatch(now.subtract(const Duration(days: 45)));
      final candidates =
          await harness.recurringService.restoreConfirmationEligible(batch);
      expect(candidates, isNotEmpty);
      final target = candidates.first;

      // Reschedule the overdue candidate into the future, changing nothing else
      // (spec 006, US66: a date-only move keeps its pending-confirmation
      // eligibility so it can be asked again once due).
      final future = now.add(const Duration(days: 10));
      await harness.recurringService.updateBill(
        target.id,
        scope: RecurringScope.thisOnly,
        amountMinor: target.amountMinor,
        date: future,
        categoryId: 'cat_rent',
        accountId: 'acc_cash',
        description: 'Rent',
      );

      final movedDate = DateTime(future.year, future.month, future.day,
          target.date.hour, target.date.minute, target.date.second);
      final movedId = scheduledInstanceId(target.seriesId, movedDate);
      final after = await harness.recurringService.watchScheduled().first;
      final moved = after.firstWhere((i) => i.id == movedId);
      expect(moved.autoPostEligible, isTrue,
          reason: 'rescheduling into the future keeps eligibility');
    },
  );

  test(
    'editing a pending candidate\'s amount latches it so a stale confirmation cannot post it',
    () async {
      final start = DateTime.now().subtract(const Duration(days: 2));
      await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 20000,
        accountId: 'acc_cash',
        categoryId: 'cat_rent',
        description: 'Rent',
        frequency: 'DAILY',
        interval: 1,
        startDate: start,
        mode: RecurringSeriesMode.subscription,
      );

      final now = DateTime.now();
      final bills = await harness.recurringService.watchScheduled().first;
      for (final bill in bills.where((i) => !i.date.isAfter(now))) {
        final row = await harness.db.recurringDao.getScheduled(bill.id);
        await harness.db.recurringDao.insertOrUpdateScheduled(
          ScheduledTransactionsViewCompanion(
            id: Value(row!.id),
            seriesId: Value(row.seriesId),
            date: Value(row.date),
            amountMinor: Value(row.amountMinor),
            status: Value(row.status),
            transactionId: Value(row.transactionId),
            autoPostEligible: const Value(true),
          ),
        );
      }

      final batch = await harness.recurringRepository
          .createRestoreConfirmationBatch(now.subtract(const Duration(days: 3)));
      final candidates =
          await harness.recurringService.restoreConfirmationEligible(batch);
      expect(candidates, isNotEmpty);
      final target = candidates.first;

      // Change only the amount while the confirmation dialog is open (US66).
      await harness.recurringService.updateBill(
        target.id,
        scope: RecurringScope.thisOnly,
        amountMinor: target.amountMinor + 5000,
        date: target.date,
        categoryId: 'cat_rent',
        accountId: 'acc_cash',
        description: 'Rent',
      );

      // The stale confirmation must not post the edited bill.
      await harness.recurringService.confirmRestoreBatch(batch);

      final after = await harness.recurringService.watchScheduled().first;
      final edited = after.firstWhere((i) => i.id == target.id);
      expect(edited.autoPostEligible, isFalse,
          reason: 'an accounting-field change re-confirms by turning it manual');
      expect(edited.status, ScheduledTransactionStatus.scheduled,
          reason: 'a stale confirmation cannot post a changed bill');
    },
  );
}
