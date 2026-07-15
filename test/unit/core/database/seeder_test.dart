import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/enums.dart';

import '../../../support/event_sourcing/ledger_service_harness.dart';
import '../../../support/fakes/fake_app_localizations.dart';

import 'package:feather_ledger/app/bootstrap/seeder.dart';

/// Seeder tests (spec 003, US3/T031): the seed is an event stream —
/// idempotency keyed on an empty event store, replayable projections.
///
/// **Categories only.** A fresh install gets the vocabulary, not a wallet:
/// no accounts and no transactions, so the home page opens empty rather than
/// on somebody else's 1000.00.
void main() {
  late LedgerServiceHarness harness;
  late FakeAppLocalizations l10n;

  setUp(() {
    harness = LedgerServiceHarness();
    l10n = FakeAppLocalizations();
  });

  tearDown(() => harness.close());

  Future<void> seed() => seedDatabase(
        eventStore: harness.eventStore,
        categoryService: harness.categoryService,
        l10n: l10n,
      );

  Future<List<dynamic>> allEvents() async =>
      (await harness.eventStore.readAll()).events;

  group('seedDatabase', () {
    test('empty store produces the full event stream', () async {
      await seed();

      final events = await allEvents();
      final types = events.map((e) => e.eventType).toList();
      expect(
        types.where((t) => t == 'CategoryCreated').length,
        17,
        reason: '10 expense + 2 system + 5 income defaults',
      );
      expect(types, everyElement('CategoryCreated'),
          reason: 'no accounts and no transactions are written on the way in');
    });

    test('projects 17 categories incl. two fixed system categories',
        () async {
      await seed();

      final categories = await harness.db.categoriesDao.getAllCategories();
      expect(categories, hasLength(17));

      final system = categories.where((c) => c.systemCode != null).toList();
      expect(system, hasLength(2));

      final systemIds = system.map((c) => c.id).toSet();
      expect(systemIds, contains('00000000-0000-0000-0000-000000000001'));
      expect(systemIds, contains('00000000-0000-0000-0000-000000000002'));

      final expense = categories.where((c) => c.type == CategoryType.expense);
      final income = categories.where((c) => c.type == CategoryType.income);
      expect(expense.length, 11);
      expect(income.length, 6);
    });

    test('seeds no accounts and no transactions', () async {
      await seed();

      expect(await harness.db.accountDao.getAllAccounts(), isEmpty);
      expect(
          await harness.ledgerService.watchTransactions(DateTime.now()).first,
          isEmpty);
    });

    test('is idempotent — a second run appends nothing', () async {
      await seed();
      final firstCount = (await allEvents()).length;

      await seed();

      final events = await allEvents();
      expect(events, hasLength(firstCount));
      expect(await harness.db.categoriesDao.getAllCategories(), hasLength(17));
    });

    test('skips seeding when the event store is non-empty', () async {
      // Pre-existing event (e.g. a user-created account) — the seed must
      // not run even though the projections hold nothing.
      await harness.accountService.createAccount(
        commandId: 'cmd_pre_existing',
        name: 'Existing',
        type: AccountType.other,
        initialBalanceMinor: 0,
        currencyCode: 'USD',
      );

      await seed();

      final events = await allEvents();
      expect(events, hasLength(1));
      expect(events.single.eventType, 'AccountCreated');
      expect(await harness.db.categoriesDao.getAllCategories(), isEmpty,
          reason: 'non-empty store must not be re-seeded');
    });
  });
}
