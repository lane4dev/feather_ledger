import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
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

import '../../../../../support/fakes/fake_app_database.dart';

void main() {
  late AppDatabase db;
  late BudgetService service;
  late FixedClock clock;

  setUp(() {
    db = FakeAppDatabase();
    clock = FixedClock(DateTime(2026, 5, 15, 10, 0));
    final repo = BudgetRepositoryImpl(db.budgetDao, db.categoriesDao);
    service = BudgetService(
      SetCategoryBudgetCommand(repo, clock: clock),
      ClearCategoryBudgetCommand(repo, clock: clock),
      SaveReviewNoteCommand(repo, clock: clock),
      WatchMonthBudgetQuery(repo, clock: clock),
      WatchTransactionBudgetHintQuery(repo),
      repo,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedCategory({
    required String id,
    CategoryType type = CategoryType.expense,
    String? systemCode,
    bool archived = false,
    DateTime? archivedAt,
  }) async {
    await db.into(db.categoriesView).insert(
          CategoriesViewCompanion.insert(
            id: id,
            name: 'Cat $id',
            iconKey: 'utensils',
            colorInt: 0xFFE65100,
            type: type,
            systemCode: Value(systemCode),
            archived: Value(archived),
            archivedAt: Value(archivedAt),
            lastUpdatedEventId: 1,
          ),
        );
  }

  group('BudgetService validation & commands', () {
    test('rejects invalid amount, missing, system, archived, and income cats',
        () async {
      await seedCategory(id: 'dining');
      await seedCategory(id: 'salary', type: CategoryType.income);
      await seedCategory(id: 'sys', systemCode: 'reversal_expense');
      await seedCategory(
        id: 'old-cat',
        archived: true,
        archivedAt: DateTime(2026, 4, 1),
      );

      final zero = await service.setCategoryBudget(
        currencyCode: 'CNY',
        categoryId: 'dining',
        month: const YearMonth(2026, 5),
        amountMinor: 0,
        scope: BudgetEditScope.thisAndFollowing,
      );
      expect(zero, isA<Failure>());
      expect((zero as Failure).code, LedgerErrorCode.invalidAmount);

      final missing = await service.setCategoryBudget(
        currencyCode: 'CNY',
        categoryId: 'unknown',
        month: const YearMonth(2026, 5),
        amountMinor: 1000,
        scope: BudgetEditScope.thisAndFollowing,
      );
      expect((missing as Failure).code, LedgerErrorCode.categoryNotFound);

      final system = await service.setCategoryBudget(
        currencyCode: 'CNY',
        categoryId: 'sys',
        month: const YearMonth(2026, 5),
        amountMinor: 1000,
        scope: BudgetEditScope.thisAndFollowing,
      );
      expect((system as Failure).code, LedgerErrorCode.systemCategoryProtected);

      final archived = await service.setCategoryBudget(
        currencyCode: 'CNY',
        categoryId: 'old-cat',
        month: const YearMonth(2026, 4),
        amountMinor: 1000,
        scope: BudgetEditScope.thisAndFollowing,
      );
      expect((archived as Failure).code, LedgerErrorCode.categoryArchived);

      final income = await service.setCategoryBudget(
        currencyCode: 'CNY',
        categoryId: 'salary',
        month: const YearMonth(2026, 5),
        amountMinor: 1000,
        scope: BudgetEditScope.thisAndFollowing,
      );
      expect((income as Failure).code, LedgerErrorCode.categoryTypeMismatch);
    });

    test('sets and clears stepped budgets with two scopes and streams updates',
        () async {
      await seedCategory(id: 'dining');

      final setMay = await service.setCategoryBudget(
        currencyCode: 'CNY',
        categoryId: 'dining',
        month: const YearMonth(2026, 5),
        amountMinor: 200000,
        scope: BudgetEditScope.thisAndFollowing,
      );
      expect(setMay.isSuccess, isTrue);

      final clearMayOnly = await service.clearCategoryBudget(
        currencyCode: 'CNY',
        categoryId: 'dining',
        month: const YearMonth(2026, 5),
        scope: BudgetEditScope.thisMonthOnly,
      );
      expect(clearMayOnly.isSuccess, isTrue);

      final maySummary = await service
          .watchMonthBudget(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 5),
          )
          .first;
      expect(maySummary.hasAnyBudget, isFalse);

      final juneSummary = await service
          .watchMonthBudget(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 6),
          )
          .first;
      expect(juneSummary.totalBudgetMinor, 200000);
      expect(
        await service.hasFutureRulesAfter(
          currencyCode: 'CNY',
          categoryId: 'dining',
          month: const YearMonth(2026, 5),
        ),
        isTrue,
      );
    });

    test('validates 500-rune limit, archived read-only, and blank delete on notes',
        () async {
      await seedCategory(id: 'dining');
      await seedCategory(
        id: 'old-cat',
        archived: true,
        archivedAt: DateTime(2026, 4, 1),
      );

      final tooLong = await service.saveReviewNote(
        currencyCode: 'CNY',
        month: const YearMonth(2026, 5),
        note: 'a' * 501,
      );
      expect((tooLong as Failure).code, LedgerErrorCode.budgetNoteTooLong);

      final exact500 = await service.saveReviewNote(
        currencyCode: 'CNY',
        month: const YearMonth(2026, 5),
        note: '  ${'b' * 500}  ',
      );
      expect(exact500.isSuccess, isTrue);

      final archivedNote = await service.saveReviewNote(
        currencyCode: 'CNY',
        month: const YearMonth(2026, 4),
        categoryId: 'old-cat',
        note: 'Cannot edit archived note',
      );
      expect((archivedNote as Failure).code, LedgerErrorCode.categoryArchived);

      final summary = await service
          .watchMonthBudget(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 5),
          )
          .first;
      expect(summary.monthReviewNote, 'b' * 500);

      await service.saveReviewNote(
        currencyCode: 'CNY',
        month: const YearMonth(2026, 5),
        note: '   ',
      );
      final afterDelete = await service
          .watchMonthBudget(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 5),
          )
          .first;
      expect(afterDelete.monthReviewNote, isNull);
    });

    test('watchTransactionBudgetHint emits live budget state', () async {
      await seedCategory(id: 'dining');
      await service.setCategoryBudget(
        currencyCode: 'CNY',
        categoryId: 'dining',
        month: const YearMonth(2026, 5),
        amountMinor: 150000,
        scope: BudgetEditScope.thisAndFollowing,
      );

      final hint = await service
          .watchTransactionBudgetHint(
            currencyCode: 'CNY',
            month: const YearMonth(2026, 5),
            categoryId: 'dining',
          )
          .first;
      expect(hint.effectiveBudgetMinor, 150000);
      expect(hint.actualMinor, 0);
      expect(hint.pendingMinor, 0);
      expect(hint.isCategoryArchived, isFalse);
    });
  });
}
