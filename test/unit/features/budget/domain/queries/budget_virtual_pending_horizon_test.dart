import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/budget_dao.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/budget/domain/entities/budget_entities.dart';
import 'package:feather_ledger/features/budget/domain/queries/watch_month_budget_query.dart';
import 'package:feather_ledger/features/budget/domain/queries/watch_transaction_budget_hint_query.dart';
import 'package:feather_ledger/features/budget/domain/repositories/budget_repository.dart';
import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';

final _now = DateTime(2026, 5, 15, 10);
const _nowYm = YearMonth(2026, 5);
const _currencyCode = 'CNY';
const _categoryId = 'rent';
const _categoryBudgetMinor = 100000;
const _physicalBillMinor = 30000;
const _virtualBillMinor = 20000;

/// Records the `includeVirtual` flag each query passes down and answers with a
/// physical bill always plus a virtual overlay bill only when the flag is set —
/// mirroring what `BudgetDao` does for the same month.
class _RecordingBudgetRepository implements BudgetRepository {
  final List<bool> monthPendingIncludeVirtual = [];
  final List<bool> hintIncludeVirtual = [];

  @override
  Stream<BudgetMonthRawSummary> watchMonthBudgetSummary(
    String currencyCode,
    YearMonth month,
  ) {
    return Stream.value(
      BudgetMonthRawSummary(
        currencyCode: currencyCode,
        targetYm: month.ym,
        expenseCategories: const [
          CategoryViewRow(
            id: _categoryId,
            name: 'Rent',
            iconKey: 'home',
            colorInt: 0xFF1565C0,
            type: CategoryType.expense,
            archived: false,
            lastUpdatedEventId: 0,
            projectionVersion: 1,
          ),
        ],
        rules: [
          BudgetRuleRow(
            currencyCode: currencyCode,
            categoryId: _categoryId,
            effectiveYm: _nowYm.ym,
            amountMinor: _categoryBudgetMinor,
            updatedAt: _now,
          ),
        ],
        reviewNotes: const [],
        windowExpenses: const [],
        earliestExpenseYm: null,
        hasAnyActiveAccount: true,
      ),
    );
  }

  @override
  Stream<BudgetMonthPendingRaw> watchMonthPendingExpenses(
    String currencyCode,
    YearMonth month, {
    bool includeVirtual = true,
  }) {
    monthPendingIncludeVirtual.add(includeVirtual);
    return Stream.value(
      BudgetMonthPendingRaw(
        bills: [
          BudgetPendingBillRaw(
            scheduledBillId: 'physical-bill',
            seriesId: 'series-1',
            occurrenceKey: '2026-05-01',
            categoryId: _categoryId,
            description: 'Rent (materialized)',
            amountMinor: _physicalBillMinor,
            effectiveDate: DateTime(month.year, month.month, 1),
            status: 'scheduled',
            accountId: 'acc-cash',
            frequency: 'MONTHLY',
          ),
          if (includeVirtual)
            BudgetPendingBillRaw(
              scheduledBillId: 'virtual-bill',
              seriesId: 'series-1',
              occurrenceKey: '2026-05-15',
              isVirtual: true,
              categoryId: _categoryId,
              description: 'Rent (virtual overlay)',
              amountMinor: _virtualBillMinor,
              effectiveDate: DateTime(month.year, month.month, 15),
              status: 'scheduled',
              accountId: 'acc-cash',
              frequency: 'MONTHLY',
            ),
        ],
      ),
    );
  }

  @override
  Stream<CategoryBudgetHint> watchCategoryBudgetHint({
    required String currencyCode,
    required YearMonth month,
    required String categoryId,
    bool includeVirtual = true,
  }) {
    hintIncludeVirtual.add(includeVirtual);
    return Stream.value(
      CategoryBudgetHint(
        currencyCode: currencyCode,
        month: month,
        categoryId: categoryId,
        isCategoryArchived: false,
        effectiveBudgetMinor: _categoryBudgetMinor,
        actualMinor: 0,
        pendingMinor:
            _physicalBillMinor + (includeVirtual ? _virtualBillMinor : 0),
      ),
    );
  }

  @override
  Future<CategoryEntity?> getCategoryById(String categoryId) async => null;

  @override
  Future<bool> hasFutureRulesAfter({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
  }) async =>
      false;

  @override
  Future<void> upsertBudgetRule({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
    required int? amountMinor,
    required BudgetEditScope scope,
    required DateTime now,
  }) async {}

  @override
  Future<void> upsertReviewNote({
    required String currencyCode,
    required YearMonth month,
    required String? categoryId,
    required String note,
    required DateTime now,
  }) async {}
}

void main() {
  late _RecordingBudgetRepository repository;

  setUp(() {
    repository = _RecordingBudgetRepository();
  });

  WatchMonthBudgetQuery monthQuery() =>
      WatchMonthBudgetQuery(repository, clock: FixedClock(_now));

  WatchTransactionBudgetHintQuery hintQuery() =>
      WatchTransactionBudgetHintQuery(repository, clock: FixedClock(_now));

  Future<MonthBudgetSummary> runMonthQuery(YearMonth month) =>
      monthQuery()
          .execute(currencyCode: _currencyCode, month: month)
          .first;

  Future<CategoryBudgetHint> runHintQuery(YearMonth month) =>
      hintQuery()
          .execute(
            currencyCode: _currencyCode,
            month: month,
            categoryId: _categoryId,
          )
          .first;

  group('WatchMonthBudgetQuery virtual pending horizon', () {
    for (final monthOffset in const [0, 1, 24]) {
      test('includes virtual pending at nowYm + $monthOffset', () async {
        final month = _nowYm.addMonths(monthOffset);

        final summary = await runMonthQuery(month);

        expect(repository.monthPendingIncludeVirtual, [true]);
        expect(
          summary.findCategory(_categoryId)!.pendingMinor,
          _physicalBillMinor + _virtualBillMinor,
        );
      });
    }

    test('skips virtual pending in review mode (nowYm - 1)', () async {
      final summary = await runMonthQuery(_nowYm.addMonths(-1));

      expect(repository.monthPendingIncludeVirtual, [false]);
      expect(summary.budgetedPendingMinor, 0);
      // The physical bill was still delivered — review just refuses to count it.
      expect(summary.hasLeftoverPendingInReview, isTrue);
    });

    test('skips virtual pending at nowYm + 25 but keeps physical pending',
        () async {
      final summary = await runMonthQuery(_nowYm.addMonths(25));

      expect(repository.monthPendingIncludeVirtual, [false]);
      final rent = summary.findCategory(_categoryId)!;
      expect(rent.pendingMinor, _physicalBillMinor);
      expect(
        rent.projectedRemainingMinor,
        _categoryBudgetMinor - _physicalBillMinor,
      );
    });
  });

  group('WatchTransactionBudgetHintQuery virtual pending horizon', () {
    for (final monthOffset in const [0, 1, 24]) {
      test('includes virtual pending at nowYm + $monthOffset', () async {
        final month = _nowYm.addMonths(monthOffset);

        final hint = await runHintQuery(month);

        expect(repository.hintIncludeVirtual, [true]);
        expect(hint.pendingMinor, _physicalBillMinor + _virtualBillMinor);
      });
    }

    test('skips virtual pending in review mode (nowYm - 1)', () async {
      await runHintQuery(_nowYm.addMonths(-1));

      expect(repository.hintIncludeVirtual, [false]);
    });

    test('skips virtual pending at nowYm + 25 but keeps physical pending',
        () async {
      final hint = await runHintQuery(_nowYm.addMonths(25));

      expect(repository.hintIncludeVirtual, [false]);
      expect(hint.pendingMinor, _physicalBillMinor);
    });
  });
}
