import 'package:drift/drift.dart';

import 'package:feather_ledger/core/domain/enums.dart';

import '../app_database.dart';
import '../tables.dart';

part 'budget_dao.g.dart';

/// Returns the calendar month immediately following [ym] (`year * 100 + month`).
int nextYearMonth(int ym) {
  final year = ym ~/ 100;
  final month = ym % 100;
  return month == 12 ? (year + 1) * 100 + 1 : year * 100 + month + 1;
}

/// Converts a local [DateTime] to `year * 100 + month`.
int dateTimeToYm(DateTime dt) {
  final local = dt.toLocal();
  return local.year * 100 + local.month;
}

/// Raw expense posting inside the 6-month budget window `[M-5 .. M]`.
class BudgetExpensePostingRaw {
  final String transactionId;
  final String categoryId;
  final DateTime occurredAt;
  final int ym;
  final int amountMinor;
  final String description;
  final String? sourceScheduledBillId;
  final String? categorySnapshotName;
  final String? categorySnapshotIcon;
  final String? categorySnapshotColorInt;

  const BudgetExpensePostingRaw({
    required this.transactionId,
    required this.categoryId,
    required this.occurredAt,
    required this.ym,
    required this.amountMinor,
    required this.description,
    required this.sourceScheduledBillId,
    required this.categorySnapshotName,
    required this.categorySnapshotIcon,
    required this.categorySnapshotColorInt,
  });
}

/// Raw payload emitted by [BudgetDao.watchMonthBudgetSummary].
class BudgetMonthRawSummary {
  final String currencyCode;
  final int targetYm;
  final List<CategoryViewRow> expenseCategories;
  final List<BudgetRuleRow> rules;
  final List<BudgetReviewNoteRow> reviewNotes;
  final List<BudgetExpensePostingRaw> windowExpenses;
  final int? earliestExpenseYm;
  final bool hasAnyActiveAccount;

  const BudgetMonthRawSummary({
    required this.currencyCode,
    required this.targetYm,
    required this.expenseCategories,
    required this.rules,
    required this.reviewNotes,
    required this.windowExpenses,
    required this.earliestExpenseYm,
    required this.hasAnyActiveAccount,
  });
}

/// Raw pending expense bill row for a target month.
class BudgetPendingBillRaw {
  final String scheduledBillId;
  final String seriesId;
  final String categoryId;
  final String description;
  final int amountMinor;
  final DateTime effectiveDate;
  final String status;
  final String accountId;
  final String frequency;

  const BudgetPendingBillRaw({
    required this.scheduledBillId,
    required this.seriesId,
    required this.categoryId,
    required this.description,
    required this.amountMinor,
    required this.effectiveDate,
    required this.status,
    required this.accountId,
    required this.frequency,
  });
}

/// Raw payload emitted by [BudgetDao.watchMonthPendingExpenses].
class BudgetMonthPendingRaw {
  final List<BudgetPendingBillRaw> bills;
  final bool hasHighFrequencyActiveSeries;

  const BudgetMonthPendingRaw({
    required this.bills,
    required this.hasHighFrequencyActiveSeries,
  });
}

/// Raw lightweight budget hint emitted by [BudgetDao.watchCategoryBudgetHint].
class BudgetCategoryHintRaw {
  final String currencyCode;
  final int targetYm;
  final String categoryId;
  final int? effectiveBudgetMinor;
  final int actualMinor;
  final int pendingMinor;
  final bool isCategoryArchived;

  const BudgetCategoryHintRaw({
    required this.currencyCode,
    required this.targetYm,
    required this.categoryId,
    required this.effectiveBudgetMinor,
    required this.actualMinor,
    required this.pendingMinor,
    required this.isCategoryArchived,
  });
}

@DriftAccessor(tables: [
  BudgetRules,
  BudgetReviewNotes,
  CategoriesView,
  TransactionsView,
  TransactionPostingsView,
  AccountsView,
  RecurringSeries,
  ScheduledTransactionsView,
])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  /// Stream 1: watches rules, 6-month `[M-5 .. M]` posted expense postings,
  /// categories, review notes, earliest expense month, and active-account flag.
  Stream<BudgetMonthRawSummary> watchMonthBudgetSummary(
    String currencyCode,
    int targetYm,
  ) {
    final trigger = db
        .customSelect(
          'SELECT 1',
          readsFrom: {
            budgetRules,
            budgetReviewNotes,
            categoriesView,
            transactionsView,
            transactionPostingsView,
            accountsView,
          },
        )
        .watch();

    return trigger.asyncMap(
      (_) => _loadMonthBudgetSummary(currencyCode, targetYm),
    );
  }

  Future<BudgetMonthRawSummary> _loadMonthBudgetSummary(
    String currencyCode,
    int targetYm,
  ) async {
    final targetYear = targetYm ~/ 100;
    final targetMonth = targetYm % 100;
    final windowStart = DateTime(targetYear, targetMonth - 5, 1);
    final windowEndExclusive = DateTime(targetYear, targetMonth + 1, 1);
    final minNoteYm = dateTimeToYm(windowStart);

    final categories = await (select(categoriesView)
          ..where((c) =>
              c.type.equals(CategoryType.expense.index) & c.systemCode.isNull())
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .get();

    final rules = await (select(budgetRules)
          ..where((r) => r.currencyCode.equals(currencyCode))
          ..orderBy([
            (r) => OrderingTerm.asc(r.categoryId),
            (r) => OrderingTerm.asc(r.effectiveYm),
          ]))
        .get();

    final notes = await (select(budgetReviewNotes)
          ..where((n) =>
              n.currencyCode.equals(currencyCode) &
              n.ym.isBiggerOrEqualValue(minNoteYm) &
              n.ym.isSmallerOrEqualValue(targetYm)))
        .get();

    final txQuery = select(transactionsView).join([
      innerJoin(
        transactionPostingsView,
        transactionPostingsView.transactionId
            .equalsExp(transactionsView.transactionId),
      ),
      innerJoin(
        accountsView,
        accountsView.id.equalsExp(transactionPostingsView.accountId),
        useColumns: false,
      ),
    ])
      ..where(
        transactionsView.occurredAt.isBiggerOrEqualValue(windowStart) &
            transactionsView.occurredAt.isSmallerThanValue(windowEndExclusive) &
            transactionsView.kind.equals(TransactionKind.expense.index) &
            transactionsView.isReversed.equals(false) &
            accountsView.currencyCode.equals(currencyCode) &
            accountsView.includeInTotals.equals(true) &
            accountsView.deleted.equals(false),
      )
      ..orderBy([OrderingTerm.desc(transactionsView.occurredAt)]);

    final txRows = await txQuery.get();
    final windowExpenses = <BudgetExpensePostingRaw>[];
    for (final row in txRows) {
      final tx = row.readTable(transactionsView);
      final posting = row.readTable(transactionPostingsView);
      final categoryId = posting.categoryId;
      if (categoryId == null) continue;
      final localOccurred = tx.occurredAt.toLocal();
      windowExpenses.add(BudgetExpensePostingRaw(
        transactionId: tx.transactionId,
        categoryId: categoryId,
        occurredAt: localOccurred,
        ym: dateTimeToYm(localOccurred),
        amountMinor: posting.amountMinor.abs(),
        description: tx.description,
        sourceScheduledBillId: tx.sourceScheduledBillId,
        categorySnapshotName: tx.categoryName,
        categorySnapshotIcon: tx.categoryIcon,
        categorySnapshotColorInt: tx.categoryColorInt,
      ));
    }

    final minOccurredQuery = selectOnly(transactionsView)
      ..addColumns([transactionsView.occurredAt.min()])
      ..join([
        innerJoin(
          transactionPostingsView,
          transactionPostingsView.transactionId
              .equalsExp(transactionsView.transactionId),
          useColumns: false,
        ),
        innerJoin(
          accountsView,
          accountsView.id.equalsExp(transactionPostingsView.accountId),
          useColumns: false,
        ),
      ])
      ..where(
        transactionsView.kind.equals(TransactionKind.expense.index) &
            transactionsView.isReversed.equals(false) &
            accountsView.currencyCode.equals(currencyCode) &
            accountsView.includeInTotals.equals(true) &
            accountsView.deleted.equals(false),
      );

    final minRow = await minOccurredQuery.getSingleOrNull();
    final minDate = minRow?.read(transactionsView.occurredAt.min());
    final earliestExpenseYm = minDate == null ? null : dateTimeToYm(minDate);

    final activeAccountCount = await (select(accountsView)
          ..where((a) =>
              a.currencyCode.equals(currencyCode) &
              a.deleted.equals(false) &
              a.archived.equals(false))
          ..limit(1))
        .get();

    return BudgetMonthRawSummary(
      currencyCode: currencyCode,
      targetYm: targetYm,
      expenseCategories: categories,
      rules: rules,
      reviewNotes: notes,
      windowExpenses: windowExpenses,
      earliestExpenseYm: earliestExpenseYm,
      hasAnyActiveAccount: activeAccountCount.isNotEmpty,
    );
  }

  /// Stream 2: watches pending (`scheduled` or `failed`) expense bills for
  /// [currencyCode] falling in local calendar month [targetYm].
  Stream<BudgetMonthPendingRaw> watchMonthPendingExpenses(
    String currencyCode,
    int targetYm,
  ) {
    final trigger = db
        .customSelect(
          'SELECT 1',
          readsFrom: {
            scheduledTransactionsView,
            recurringSeries,
            accountsView,
          },
        )
        .watch();

    return trigger.asyncMap(
      (_) => _loadMonthPendingExpenses(currencyCode, targetYm),
    );
  }

  Future<BudgetMonthPendingRaw> _loadMonthPendingExpenses(
    String currencyCode,
    int targetYm,
  ) async {
    final targetYear = targetYm ~/ 100;
    final targetMonth = targetYm % 100;
    final monthStart = DateTime(targetYear, targetMonth, 1);
    final monthEndExclusive = DateTime(targetYear, targetMonth + 1, 1);

    final effectiveDateExpr = coalesce<DateTime>([
      scheduledTransactionsView.dateOverride,
      scheduledTransactionsView.scheduledDate,
    ]);

    final query = select(scheduledTransactionsView).join([
      innerJoin(
        recurringSeries,
        recurringSeries.id.equalsExp(scheduledTransactionsView.seriesId),
      ),
      innerJoin(
        accountsView,
        accountsView.id.equalsExp(recurringSeries.accountId),
        useColumns: false,
      ),
    ])
      ..where(
        recurringSeries.type.equals(RecurringSeriesKind.expense.index) &
            accountsView.currencyCode.equals(currencyCode) &
            accountsView.includeInTotals.equals(true) &
            accountsView.deleted.equals(false) &
            scheduledTransactionsView.status.isIn(['scheduled', 'failed']) &
            effectiveDateExpr.isBiggerOrEqualValue(monthStart) &
            effectiveDateExpr.isSmallerThanValue(monthEndExclusive),
      )
      ..orderBy([OrderingTerm.asc(effectiveDateExpr)]);

    final rows = await query.get();
    final bills = <BudgetPendingBillRaw>[];
    for (final row in rows) {
      final scheduled = row.readTable(scheduledTransactionsView);
      final series = row.readTable(recurringSeries);
      final effectiveDate =
          (scheduled.dateOverride ?? scheduled.scheduledDate).toLocal();
      bills.add(BudgetPendingBillRaw(
        scheduledBillId: scheduled.id,
        seriesId: series.id,
        categoryId: series.categoryId,
        description: scheduled.memoOverride ?? series.description,
        amountMinor:
            (scheduled.amountOverrideMinor ?? series.amountMinor).abs(),
        effectiveDate: effectiveDate,
        status: scheduled.status,
        accountId: series.accountId,
        frequency: series.frequency,
      ));
    }

    final highFreqSeries = await (select(recurringSeries).join([
      innerJoin(
        accountsView,
        accountsView.id.equalsExp(recurringSeries.accountId),
        useColumns: false,
      ),
    ])
          ..where(
            recurringSeries.isActive.equals(true) &
                recurringSeries.type.equals(RecurringSeriesKind.expense.index) &
                recurringSeries.frequency.isIn(['DAILY', 'WEEKLY']) &
                recurringSeries.startDate
                    .isSmallerThanValue(monthEndExclusive) &
                (recurringSeries.endDate.isNull() |
                    recurringSeries.endDate.isBiggerOrEqualValue(monthStart)) &
                accountsView.currencyCode.equals(currencyCode) &
                accountsView.includeInTotals.equals(true) &
                accountsView.deleted.equals(false),
          ))
        .get();

    return BudgetMonthPendingRaw(
      bills: bills,
      hasHighFrequencyActiveSeries: highFreqSeries.isNotEmpty,
    );
  }

  /// Stream 3: ultra-lightweight single-category hint stream for
  /// `TransactionFormScreen`.
  Stream<BudgetCategoryHintRaw> watchCategoryBudgetHint(
    String currencyCode,
    int targetYm,
    String categoryId,
  ) {
    final trigger = db
        .customSelect(
          'SELECT 1',
          readsFrom: {
            budgetRules,
            categoriesView,
            transactionsView,
            transactionPostingsView,
            accountsView,
            scheduledTransactionsView,
            recurringSeries,
          },
        )
        .watch();

    return trigger.asyncMap(
      (_) => _loadCategoryBudgetHint(currencyCode, targetYm, categoryId),
    );
  }

  Future<BudgetCategoryHintRaw> _loadCategoryBudgetHint(
    String currencyCode,
    int targetYm,
    String categoryId,
  ) async {
    final targetYear = targetYm ~/ 100;
    final targetMonth = targetYm % 100;
    final monthStart = DateTime(targetYear, targetMonth, 1);
    final monthEndExclusive = DateTime(targetYear, targetMonth + 1, 1);

    final category = await db.categoriesDao.getCategoryById(categoryId);
    final isArchived = category?.archived ?? false;
    final archiveYm =
        category?.archivedAt == null ? null : dateTimeToYm(category!.archivedAt!);

    int? effectiveBudgetMinor;
    if (category != null &&
        category.type == CategoryType.expense &&
        category.systemCode == null &&
        !(isArchived && archiveYm != null && targetYm > archiveYm)) {
      final latestRule = await (select(budgetRules)
            ..where((r) =>
                r.currencyCode.equals(currencyCode) &
                r.categoryId.equals(categoryId) &
                r.effectiveYm.isSmallerOrEqualValue(targetYm))
            ..orderBy([(r) => OrderingTerm.desc(r.effectiveYm)])
            ..limit(1))
          .getSingleOrNull();
      effectiveBudgetMinor = latestRule?.amountMinor;
    }

    final actualQuery = select(transactionPostingsView).join([
      innerJoin(
        transactionsView,
        transactionsView.transactionId
            .equalsExp(transactionPostingsView.transactionId),
        useColumns: false,
      ),
      innerJoin(
        accountsView,
        accountsView.id.equalsExp(transactionPostingsView.accountId),
        useColumns: false,
      ),
    ])
      ..where(
        transactionPostingsView.categoryId.equals(categoryId) &
            transactionsView.occurredAt.isBiggerOrEqualValue(monthStart) &
            transactionsView.occurredAt.isSmallerThanValue(monthEndExclusive) &
            transactionsView.kind.equals(TransactionKind.expense.index) &
            transactionsView.isReversed.equals(false) &
            accountsView.currencyCode.equals(currencyCode) &
            accountsView.includeInTotals.equals(true) &
            accountsView.deleted.equals(false),
      );
    final actualRows = await actualQuery.get();
    var actualMinor = 0;
    for (final row in actualRows) {
      actualMinor += row.readTable(transactionPostingsView).amountMinor.abs();
    }

    final effectiveDateExpr = coalesce<DateTime>([
      scheduledTransactionsView.dateOverride,
      scheduledTransactionsView.scheduledDate,
    ]);
    final pendingQuery = select(scheduledTransactionsView).join([
      innerJoin(
        recurringSeries,
        recurringSeries.id.equalsExp(scheduledTransactionsView.seriesId),
      ),
      innerJoin(
        accountsView,
        accountsView.id.equalsExp(recurringSeries.accountId),
        useColumns: false,
      ),
    ])
      ..where(
        recurringSeries.categoryId.equals(categoryId) &
            recurringSeries.type.equals(RecurringSeriesKind.expense.index) &
            accountsView.currencyCode.equals(currencyCode) &
            accountsView.includeInTotals.equals(true) &
            accountsView.deleted.equals(false) &
            scheduledTransactionsView.status.isIn(['scheduled', 'failed']) &
            effectiveDateExpr.isBiggerOrEqualValue(monthStart) &
            effectiveDateExpr.isSmallerThanValue(monthEndExclusive),
      );
    final pendingRows = await pendingQuery.get();
    var pendingMinor = 0;
    for (final row in pendingRows) {
      final scheduled = row.readTable(scheduledTransactionsView);
      final series = row.readTable(recurringSeries);
      pendingMinor +=
          (scheduled.amountOverrideMinor ?? series.amountMinor).abs();
    }

    return BudgetCategoryHintRaw(
      currencyCode: currencyCode,
      targetYm: targetYm,
      categoryId: categoryId,
      effectiveBudgetMinor: effectiveBudgetMinor,
      actualMinor: actualMinor,
      pendingMinor: pendingMinor,
      isCategoryArchived: isArchived,
    );
  }

  /// Returns true if any explicit rule row exists for `(currencyCode, categoryId)`
  /// strictly after [ym].
  Future<bool> hasFutureRulesAfter(
    String currencyCode,
    String categoryId,
    int ym,
  ) async {
    final row = await (select(budgetRules)
          ..where((r) =>
              r.currencyCode.equals(currencyCode) &
              r.categoryId.equals(categoryId) &
              r.effectiveYm.isBiggerThanValue(ym))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  /// Transactionally sets or clears (`amountMinor == null`) a category budget
  /// using either [thisMonthOnly] (preserving `M+1`'s prior effective state) or
  /// `thisAndFollowing` (removing `> M` breakpoints), then prunes redundant
  /// breakpoints in ascending `effectiveYm` order.
  Future<void> upsertBudgetRule({
    required String currencyCode,
    required String categoryId,
    required int targetYm,
    required int? amountMinor,
    required bool thisMonthOnly,
    required DateTime now,
  }) async {
    await db.transaction(() async {
      if (thisMonthOnly) {
        final nextYm = nextYearMonth(targetYm);
        final existingNext = await (select(budgetRules)
              ..where((r) =>
                  r.currencyCode.equals(currencyCode) &
                  r.categoryId.equals(categoryId) &
                  r.effectiveYm.equals(nextYm)))
            .getSingleOrNull();

        if (existingNext == null) {
          final priorAtTarget = await (select(budgetRules)
                ..where((r) =>
                    r.currencyCode.equals(currencyCode) &
                    r.categoryId.equals(categoryId) &
                    r.effectiveYm.isSmallerOrEqualValue(targetYm))
                ..orderBy([(r) => OrderingTerm.desc(r.effectiveYm)])
                ..limit(1))
              .getSingleOrNull();

          await into(budgetRules).insert(
            BudgetRulesCompanion.insert(
              currencyCode: currencyCode,
              categoryId: categoryId,
              effectiveYm: nextYm,
              amountMinor: Value(priorAtTarget?.amountMinor),
              updatedAt: now,
            ),
          );
        }
      } else {
        await (delete(budgetRules)
              ..where((r) =>
                  r.currencyCode.equals(currencyCode) &
                  r.categoryId.equals(categoryId) &
                  r.effectiveYm.isBiggerThanValue(targetYm)))
            .go();
      }

      await into(budgetRules).insertOnConflictUpdate(
        BudgetRulesCompanion.insert(
          currencyCode: currencyCode,
          categoryId: categoryId,
          effectiveYm: targetYm,
          amountMinor: Value(amountMinor),
          updatedAt: now,
        ),
      );

      // Ascending prune from the earliest breakpoint so leading `null`
      // sentinels and chained redundancies (`M` -> `M_next`) are removed
      // cleanly in one pass.
      final sorted = await (select(budgetRules)
            ..where((r) =>
                r.currencyCode.equals(currencyCode) &
                r.categoryId.equals(categoryId))
            ..orderBy([(r) => OrderingTerm.asc(r.effectiveYm)]))
          .get();

      int? prevState;
      for (final row in sorted) {
        if (row.amountMinor == prevState) {
          await (delete(budgetRules)
                ..where((r) =>
                    r.currencyCode.equals(currencyCode) &
                    r.categoryId.equals(categoryId) &
                    r.effectiveYm.equals(row.effectiveYm)))
              .go();
        } else {
          prevState = row.amountMinor;
        }
      }
    });
  }

  /// Inserts, updates, or deletes a review note (`categoryKey == ''` for
  /// month-level note). Blank/null deletes the row.
  Future<void> upsertReviewNote({
    required String currencyCode,
    required int ym,
    required String categoryKey,
    required String? note,
    required DateTime now,
  }) async {
    final trimmed = note?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      await (delete(budgetReviewNotes)
            ..where((n) =>
                n.currencyCode.equals(currencyCode) &
                n.ym.equals(ym) &
                n.categoryKey.equals(categoryKey)))
          .go();
      return;
    }

    await into(budgetReviewNotes).insertOnConflictUpdate(
      BudgetReviewNotesCompanion.insert(
        currencyCode: currencyCode,
        ym: ym,
        categoryKey: categoryKey,
        note: trimmed,
        updatedAt: now,
      ),
    );
  }

  /// Returns all budget rule rows (diagnostic/test helper).
  Future<List<BudgetRuleRow>> getRulesForCategory(
    String currencyCode,
    String categoryId,
  ) {
    return (select(budgetRules)
          ..where((r) =>
              r.currencyCode.equals(currencyCode) &
              r.categoryId.equals(categoryId))
          ..orderBy([(r) => OrderingTerm.asc(r.effectiveYm)]))
        .get();
  }

  /// Returns all review notes for a currency/month (diagnostic/test helper).
  Future<List<BudgetReviewNoteRow>> getNotesForMonth(
    String currencyCode,
    int ym,
  ) {
    return (select(budgetReviewNotes)
          ..where((n) => n.currencyCode.equals(currencyCode) & n.ym.equals(ym)))
        .get();
  }
}
