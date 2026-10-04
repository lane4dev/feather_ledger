import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:feather_ledger/app/bootstrap/pending_restore.dart';
import 'package:feather_ledger/app/bootstrap/register_ledger_events.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:feather_ledger/features/budget/domain/commands/clear_category_budget_command.dart';
import 'package:feather_ledger/features/budget/domain/commands/save_review_note_command.dart';
import 'package:feather_ledger/features/budget/domain/commands/set_category_budget_command.dart';
import 'package:feather_ledger/features/budget/domain/queries/watch_month_budget_query.dart';
import 'package:feather_ledger/features/budget/domain/queries/watch_transaction_budget_hint_query.dart';
import 'package:feather_ledger/features/budget/domain/services/budget_service.dart';
import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';
import 'package:feather_ledger/features/ledger/data/event_sourcing/drift_event_store.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_projector.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_rebuild_service.dart';
import 'package:feather_ledger/features/settings/domain/services/backup_service.dart';

import '../../../../support/event_sourcing/ledger_service_harness.dart';
import '../../../../support/mocks/mock_shared_preferences.dart';

void main() {
  late LedgerServiceHarness harness;
  late Directory supportDir;
  late MockSharedPreferences mockPrefs;
  late PreferencesRepository preferences;

  setUp(() async {
    harness = LedgerServiceHarness();
    await harness.seedSystemCategories();
    supportDir = Directory.systemTemp.createTempSync('feather_budget_backup_');
    mockPrefs = MockSharedPreferences();
    preferences = PreferencesRepositoryImpl(mockPrefs);
  });

  tearDown(() async {
    await harness.close();
    if (supportDir.existsSync()) supportDir.deleteSync(recursive: true);
    mockPrefs.reset();
  });

  BackupService makeBackupService(AppDatabase db) => BackupService(
        db,
        preferences,
        supportDir: supportDir,
        tempDir: supportDir,
        appVersion: '1.0.0+1',
      );

  BudgetService makeBudgetService(AppDatabase db, {DateTime? now}) {
    final clock = FixedClock(now ?? DateTime(2026, 5, 15));
    final repo = BudgetRepositoryImpl(db.budgetDao, db.categoriesDao);
    return BudgetService(
      SetCategoryBudgetCommand(repo, clock: clock),
      ClearCategoryBudgetCommand(repo, clock: clock),
      SaveReviewNoteCommand(repo, clock: clock),
      WatchMonthBudgetQuery(repo, clock: clock),
      WatchTransactionBudgetHintQuery(repo),
      repo,
    );
  }

  test(
      '.flbackup round-trip preserves budget_rules and budget_review_notes '
      'across staged restore and startup swap', () async {
    await harness.accountService.createAccount(
      commandId: 'cmd_acc',
      name: 'Cash',
      type: AccountType.cash,
      initialBalanceMinor: 0,
      currencyCode: 'CNY',
    );
    await harness.categoryService.createCategory(
      commandId: 'cmd_cat',
      name: 'Dining',
      iconKey: 'utensils',
      colorInt: 0xFFE65100,
      type: CategoryType.expense,
    );
    final categoryId = await harness.userCategoryId();

    final budget = makeBudgetService(harness.db);
    await budget.setCategoryBudget(
      currencyCode: 'CNY',
      categoryId: categoryId,
      month: const YearMonth(2026, 5),
      amountMinor: 150000,
      scope: BudgetEditScope.thisAndFollowing,
    );
    await budget.saveReviewNote(
      currencyCode: 'CNY',
      month: const YearMonth(2026, 5),
      categoryId: categoryId,
      note: 'Dining stayed within plan',
    );
    await budget.saveReviewNote(
      currencyCode: 'CNY',
      month: const YearMonth(2026, 5),
      note: 'Good overall discipline',
    );

    final backupResult = await makeBackupService(harness.db).buildArchive();
    expect(backupResult, isA<Success<String>>());
    final archivePath = (backupResult as Success<String>).value;

    final liveDbFile = File(p.join(supportDir.path, RestoreLayout.liveDb));
    liveDbFile.writeAsStringSync('old placeholder');

    final stageResult =
        await makeBackupService(harness.db).stageRestore(File(archivePath));
    expect(stageResult, isA<Success<void>>());

    final applied = await applyPendingRestore(supportDir);
    expect(applied, isNotNull);

    final restoredDb = AppDatabase.internal(NativeDatabase(liveDbFile));
    addTearDown(restoredDb.close);

    final restoredSummary = await makeBudgetService(restoredDb)
        .watchMonthBudget(
          currencyCode: 'CNY',
          month: const YearMonth(2026, 5),
        )
        .first;
    expect(restoredSummary.totalBudgetMinor, 150000);
    expect(restoredSummary.monthReviewNote, 'Good overall discipline');
    expect(restoredSummary.findCategory(categoryId)?.reviewNote,
        'Dining stayed within plan');
  });

  test(
      'restoring a v15 .flbackup upgrades schema to v16 and self-heals '
      'CategoriesView.archivedAt via LedgerRebuildService', () async {
    await harness.accountService.createAccount(
      commandId: 'cmd_acc',
      name: 'Cash',
      type: AccountType.cash,
      initialBalanceMinor: 0,
      currencyCode: 'USD',
    );
    await harness.categoryService.createCategory(
      commandId: 'cmd_cat',
      name: 'Old Dining',
      iconKey: 'utensils',
      colorInt: 0xFFE65100,
      type: CategoryType.expense,
    );
    final catId = await harness.userCategoryId();
    await harness.categoryService.archiveCategory(
      commandId: 'cmd_arch',
      categoryId: catId,
    );

    final validZip =
        (await makeBackupService(harness.db).buildArchive() as Success<String>)
            .value;
    final archive =
        ZipDecoder().decodeBytes(File(validZip).readAsBytesSync());

    final v15File = File(p.join(supportDir.path, 'v15.sqlite'))
      ..writeAsBytesSync(
          archive.findFile(RestoreLayout.stagedDb)!.content as List<int>);
    final v15Db = AppDatabase.internal(NativeDatabase(v15File));
    await v15Db.customStatement('SELECT 1');
    await v15Db.customStatement('DROP TABLE budget_rules');
    await v15Db.customStatement('DROP TABLE budget_review_notes');
    await v15Db.customStatement(
        'ALTER TABLE categories_view DROP COLUMN archived_at');
    await v15Db
        .customStatement('UPDATE categories_view SET projection_version = 7');
    await v15Db.customStatement('PRAGMA user_version = 15');
    await v15Db.close();

    final manifest = jsonDecode(
      utf8.decode(archive.findFile(RestoreLayout.stagedManifest)!.content),
    ) as Map<String, dynamic>;
    manifest['schemaVersion'] = 15;

    final v15ZipFile = File(p.join(supportDir.path, 'v15.flbackup'));
    final downgradedArchive = Archive()
      ..addFile(ArchiveFile.string(
          RestoreLayout.stagedManifest, jsonEncode(manifest)))
      ..addFile(
          ArchiveFile.bytes(RestoreLayout.stagedDb, v15File.readAsBytesSync()))
      ..addFile(ArchiveFile.string(RestoreLayout.stagedPreferences, '{}'));
    v15ZipFile.writeAsBytesSync(ZipEncoder().encode(downgradedArchive));

    final stage =
        await makeBackupService(harness.db).stageRestore(v15ZipFile);
    expect(stage, isA<Success<void>>());

    final liveDbFile = File(p.join(supportDir.path, RestoreLayout.liveDb));
    await applyPendingRestore(supportDir);

    final upgradedDb = AppDatabase.internal(NativeDatabase(liveDbFile));
    addTearDown(upgradedDb.close);

    registerLedgerEvents();
    final rebuild = LedgerRebuildService(
      upgradedDb,
      DriftEventStore(upgradedDb, ledgerEventRegistry),
      LedgerProjectorImpl(upgradedDb),
    );
    expect(await rebuild.isStale(), isTrue);
    await rebuild.rebuild();
    expect(await rebuild.isStale(), isFalse);

    final catRow = await (upgradedDb.select(upgradedDb.categoriesView)
          ..where((t) => t.id.equals(catId)))
        .getSingle();
    expect(catRow.archived, isTrue);
    expect(catRow.archivedAt, isNotNull);

    final summary = await makeBudgetService(upgradedDb)
        .watchMonthBudget(
          currencyCode: 'USD',
          month: const YearMonth(2026, 5),
        )
        .first;
    expect(summary.currencyCode, 'USD');
  });
}
