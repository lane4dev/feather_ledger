import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_rebuild_service.dart';

import '../../../../../support/event_sourcing/ledger_service_harness.dart';

/// Category lifecycle service tests (spec 003, US3/T031): create/rename/
/// archive via the event stream, picker exclusion, and system-category
/// protection.
void main() {
  late LedgerServiceHarness harness;

  setUp(() => harness = LedgerServiceHarness());
  tearDown(() => harness.close());

  Future<List<dynamic>> allEvents() async =>
      (await harness.eventStore.readAll()).events;

  group('createCategory', () {
    test('produces CategoryCreated and projects the row', () async {
      final result = await harness.categoryService.createCategory(
        commandId: 'cmd_create_cat',
        name: 'Food',
        iconKey: '123',
        colorInt: 0xFF123456,
        type: CategoryType.expense,
      );

      expect(result, isA<Success<void>>());
      final events = await allEvents();
      expect(events, hasLength(1));
      expect(events.single.eventType, 'CategoryCreated');

      final created = CategoryCreated.fromJson(events.single.payloadJson);
      final row =
          await harness.db.categoriesDao.getCategoryById(created.categoryId);
      expect(row, isNotNull);
      expect(row!.name, 'Food');
      expect(row.archived, isFalse);
      expect(row.systemCode, isNull);
      expect(row.lastUpdatedEventId, greaterThan(0));
    });

    test('system category keeps a fixed id and systemCode', () async {
      await harness.categoryService.createCategory(
        commandId: 'cmd_create_system',
        categoryId: 'fixed-system-id',
        name: 'Adjustment',
        iconKey: '1',
        colorInt: 0xFF000000,
        type: CategoryType.income,
        systemCode: 'REVERSAL_INCOME',
      );

      final events = await allEvents();
      final created = CategoryCreated.fromJson(events.single.payloadJson);
      expect(created.categoryId, 'fixed-system-id');
      expect(created.systemCode, 'REVERSAL_INCOME');

      final row =
          await harness.db.categoriesDao.getCategoryById('fixed-system-id');
      expect(row!.systemCode, 'REVERSAL_INCOME');
    });
  });

  group('renameCategory', () {
    test('appends CategoryRenamed and updates the projection', () async {
      await harness.categoryService.createCategory(
        commandId: 'cmd_create',
        name: 'Old',
        iconKey: '1',
        colorInt: 0xFF000000,
        type: CategoryType.expense,
      );
      final created =
          CategoryCreated.fromJson((await allEvents()).single.payloadJson);

      final result = await harness.categoryService.renameCategory(
        commandId: 'cmd_rename',
        categoryId: created.categoryId,
        name: 'New',
      );

      expect(result, isA<Success<void>>());
      final events = await allEvents();
      expect(events.last.eventType, 'CategoryRenamed');

      final row =
          await harness.db.categoriesDao.getCategoryById(created.categoryId);
      expect(row!.name, 'New');
    });

    test('unknown category fails with categoryNotFound', () async {
      final result = await harness.categoryService.renameCategory(
        commandId: 'cmd_rename_missing',
        categoryId: 'missing',
        name: 'Whatever',
      );

      expect(
        result,
        isA<Failure<void>>()
            .having((f) => f.code, 'code', LedgerErrorCode.categoryNotFound),
      );
    });
  });

  test(
      'category edits survive rebuild and preserve earlier transaction snapshots',
      () async {
    await harness.accountService.createAccount(
        commandId: 'account',
        name: 'Cash',
        type: AccountType.cash,
        initialBalanceMinor: 0,
        currencyCode: 'USD');
    final account = (await harness.db.accountDao.getAllAccounts()).single;
    await harness.categoryService.createCategory(
        commandId: 'category',
        categoryId: 'food',
        name: 'Food',
        iconKey: 'old-icon',
        colorInt: 0xff112233,
        type: CategoryType.expense);
    Future<void> record(String id) async {
      final result = await harness.ledgerService.addTransaction(
          commandId: id,
          amountMinor: 100,
          type: TransactionKind.expense,
          date: DateTime(2026, 1, 1),
          categoryId: 'food',
          accountId: account.id);
      expect(result, isA<Success<void>>());
    }

    await record('before');
    final result = await harness.categoryService.updateCategory(
        commandId: 'edit',
        categoryId: 'food',
        name: 'Meals',
        iconKey: 'image/png;base64,example',
        colorInt: 0xff445566);
    expect(result, isA<Success<void>>());
    await record('after');
    final events = (await harness.eventStore.readStream('food'));
    expect(events.map((e) => e.eventType),
        ['CategoryCreated', 'CategoryRenamed', 'CategoryAppearanceChanged']);
    expect(events[1].commandId, events[2].commandId);
    expect(events[2].streamVersion, events[1].streamVersion + 1);

    Future<void> checkProjections() async {
      final category =
          (await harness.db.categoriesDao.getCategoryById('food'))!;
      expect(category.name, 'Meals');
      expect(category.iconKey, 'image/png;base64,example');
      expect(category.colorInt, 0xff445566);
      final rows = await harness.db.select(harness.db.transactionsView).get();
      expect(rows.map((r) => r.categoryIcon).toSet(),
          {'old-icon', 'image/png;base64,example'});
      expect(rows.map((r) => r.categoryName).toSet(), {'Food', 'Meals'});
    }

    await checkProjections();
    await LedgerRebuildService(
            harness.db, harness.eventStore, harness.projector)
        .rebuild();
    await checkProjections();
  });

  group('archiveCategory', () {
    test('appends CategoryArchived and hides it from the picker', () async {
      await harness.categoryService.createCategory(
        commandId: 'cmd_create',
        name: 'Old Hobby',
        iconKey: '1',
        colorInt: 0xFF000000,
        type: CategoryType.expense,
      );
      final created =
          CategoryCreated.fromJson((await allEvents()).single.payloadJson);

      final result = await harness.categoryService.archiveCategory(
        commandId: 'cmd_archive',
        categoryId: created.categoryId,
      );

      expect(result, isA<Success<void>>());
      final events = await allEvents();
      expect(events.last.eventType, 'CategoryArchived');

      final row =
          await harness.db.categoriesDao.getCategoryById(created.categoryId);
      expect(row!.archived, isTrue,
          reason: 'history retains the row, pickers exclude it');

      final picker = await harness.categoryRepository
          .watchCategories(CategoryType.expense)
          .first;
      expect(picker.map((c) => c.id), isNot(contains(created.categoryId)));
    });

    test('system category archive is rejected', () async {
      await harness.categoryService.createCategory(
        commandId: 'cmd_create_system',
        categoryId: 'fixed-system-id',
        name: 'Adjustment',
        iconKey: '1',
        colorInt: 0xFF000000,
        type: CategoryType.expense,
        systemCode: 'REVERSAL_EXPENSE',
      );

      final result = await harness.categoryService.archiveCategory(
        commandId: 'cmd_archive_system',
        categoryId: 'fixed-system-id',
      );

      expect(
        result,
        isA<Failure<void>>().having(
            (f) => f.code, 'code', LedgerErrorCode.systemCategoryProtected),
      );
      final events = await allEvents();
      expect(events, hasLength(1),
          reason: 'no CategoryArchived event may be appended');

      final row =
          await harness.db.categoriesDao.getCategoryById('fixed-system-id');
      expect(row!.archived, isFalse);
    });

    test('unknown category fails with categoryNotFound', () async {
      final result = await harness.categoryService.archiveCategory(
        commandId: 'cmd_archive_missing',
        categoryId: 'missing',
      );

      expect(
        result,
        isA<Failure<void>>()
            .having((f) => f.code, 'code', LedgerErrorCode.categoryNotFound),
      );
    });
  });
}
