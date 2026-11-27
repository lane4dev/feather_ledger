import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show protected;

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/recurrence/recurrence_expander.dart';

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

/// Statement text of the auto-updating trigger behind each budget stream.
///
/// drift caches live queries by `StreamKey(sql, variables)`, so three triggers
/// spelled `'SELECT 1'` collapse into one query stream whose `readsFrom` is the
/// first one created — the other tables then never invalidate it. Each trigger
/// therefore carries its own trailing comment, which keeps the statements
/// distinct (and still identical in result) while preserving the invalidation
/// set of every stream.
const _monthSummaryTriggerSql = 'SELECT 1 -- month summary';
const _monthPendingTriggerSql = 'SELECT 1 -- month pending';
const _categoryHintTriggerSql = 'SELECT 1 -- category hint';

/// Whether [category] is active for budget calculations in [targetYm].
///
/// Mirrors `BudgetCalculator`: system categories (`systemCode != null`) never
/// participate; an archived category keeps its archive month
/// (`targetYm <= archiveYm`, ADR-0006 local-month cutoff) and is excluded
/// afterward — including legacy/malformed archived rows without `archivedAt`.
bool _isCategoryActiveForBudgetMonth(CategoryViewRow category, int targetYm) {
  if (category.systemCode != null) return false;
  if (!category.archived) return true;
  final archivedAt = category.archivedAt;
  if (archivedAt == null) return false;
  return targetYm <= dateTimeToYm(archivedAt);
}

/// Whether [category]'s pending bills count toward the budget for [targetYm].
///
/// A missing category row carries no metadata to filter on, so its bill stays.
bool _countsTowardBudgetPending(CategoryViewRow? category, int targetYm) {
  if (category == null) return true;
  return _isCategoryActiveForBudgetMonth(category, targetYm);
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
  final String accountName;

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
    this.accountName = '',
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

/// Raw pending expense bill row (physical or virtual overlay) for a target month.
class BudgetPendingBillRaw {
  final String scheduledBillId;
  final String seriesId;
  final String occurrenceKey;
  final bool isVirtual;
  final String categoryId;
  final String description;
  final int amountMinor;
  final DateTime effectiveDate;
  final String status;
  final String accountId;
  final String frequency;
  final String accountName;

  const BudgetPendingBillRaw({
    required this.scheduledBillId,
    required this.seriesId,
    this.occurrenceKey = '',
    this.isVirtual = false,
    required this.categoryId,
    required this.description,
    required this.amountMinor,
    required this.effectiveDate,
    required this.status,
    required this.accountId,
    required this.frequency,
    this.accountName = '',
  });
}

/// Raw payload emitted by [BudgetDao.watchMonthPendingExpenses].
class BudgetMonthPendingRaw {
  final List<BudgetPendingBillRaw> bills;

  const BudgetMonthPendingRaw({
    required this.bills,
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
    final trigger = db.customSelect(
      _monthSummaryTriggerSql,
      readsFrom: {
        budgetRules,
        budgetReviewNotes,
        categoriesView,
        transactionsView,
        transactionPostingsView,
        accountsView,
      },
    ).watch();

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
        accountName: row.readTable(accountsView).name,
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
  ///
  /// When [includeVirtual] is true (Track / Plan modes: `targetYm >= nowYm`),
  /// active expense recurring series are expanded via [RecurrenceExpander] and
  /// overlaid against physical rows keyed by `(seriesId, occurrenceKey)`.
  /// When false (Review mode: `targetYm < nowYm`), only physical `scheduled` /
  /// `failed` rows are returned.
  ///
  /// Bills of system categories and of categories archived before `targetYm`
  /// are excluded on both paths (see [_countsTowardBudgetPending]);
  /// `categoriesView` is watched so archiving or restoring a category
  /// refreshes the stream in place.
  Stream<BudgetMonthPendingRaw> watchMonthPendingExpenses(
    String currencyCode,
    int targetYm, {
    bool includeVirtual = true,
  }) {
    final trigger = db.customSelect(
      _monthPendingTriggerSql,
      readsFrom: {
        scheduledTransactionsView,
        recurringSeries,
        accountsView,
        categoriesView,
      },
    ).watch();

    return trigger.asyncMap(
      (_) => _loadMonthPendingExpenses(
        currencyCode,
        targetYm,
        includeVirtual: includeVirtual,
      ),
    );
  }

  Future<BudgetMonthPendingRaw> _loadMonthPendingExpenses(
    String currencyCode,
    int targetYm, {
    required bool includeVirtual,
  }) async {
    final bills = await _loadPendingExpenseBills(
      currencyCode: currencyCode,
      targetYm: targetYm,
      includeVirtual: includeVirtual,
    );
    return BudgetMonthPendingRaw(bills: bills);
  }

  /// Shared overlay loader used by both [watchMonthPendingExpenses] and
  /// [watchCategoryBudgetHint] so monthly totals and live form hints never drift.
  ///
  /// Both paths join the category row of each bill so the archive cut-off and
  /// the system-category exclusion apply identically to physical and virtual
  /// occurrences (ADR-0008 invariant 4).
  Future<List<BudgetPendingBillRaw>> _loadPendingExpenseBills({
    required String currencyCode,
    required int targetYm,
    required bool includeVirtual,
    String? categoryId,
  }) async {
    final targetYear = targetYm ~/ 100;
    final targetMonth = targetYm % 100;
    final monthStart = DateTime(targetYear, targetMonth, 1);
    final monthEndExclusive = DateTime(targetYear, targetMonth + 1, 1);

    final effectiveDateExpr = coalesce<DateTime>([
      scheduledTransactionsView.dateOverride,
      scheduledTransactionsView.scheduledDate,
    ]);

    var physicalPredicate =
        recurringSeries.type.equals(RecurringSeriesKind.expense.index) &
            accountsView.currencyCode.equals(currencyCode) &
            accountsView.includeInTotals.equals(true) &
            accountsView.deleted.equals(false) &
            scheduledTransactionsView.status.isIn(['scheduled', 'failed']) &
            effectiveDateExpr.isBiggerOrEqualValue(monthStart) &
            effectiveDateExpr.isSmallerThanValue(monthEndExclusive);
    if (categoryId != null) {
      physicalPredicate =
          physicalPredicate & recurringSeries.categoryId.equals(categoryId);
    }

    final physicalQuery = select(scheduledTransactionsView).join([
      innerJoin(
        recurringSeries,
        recurringSeries.id.equalsExp(scheduledTransactionsView.seriesId),
      ),
      innerJoin(
        accountsView,
        accountsView.id.equalsExp(recurringSeries.accountId),
      ),
      leftOuterJoin(
        categoriesView,
        categoriesView.id.equalsExp(recurringSeries.categoryId),
      ),
    ])
      ..where(physicalPredicate)
      ..orderBy([OrderingTerm.asc(effectiveDateExpr)]);

    final physicalRows = await physicalQuery.get();
    final bills = <BudgetPendingBillRaw>[];
    for (final row in physicalRows) {
      if (!_countsTowardBudgetPending(
        row.readTableOrNull(categoriesView),
        targetYm,
      )) {
        continue;
      }
      final scheduled = row.readTable(scheduledTransactionsView);
      final series = row.readTable(recurringSeries);
      final effectiveDate =
          (scheduled.dateOverride ?? scheduled.scheduledDate).toLocal();
      bills.add(BudgetPendingBillRaw(
        scheduledBillId: scheduled.id,
        seriesId: series.id,
        occurrenceKey: scheduled.occurrenceKey,
        isVirtual: false,
        categoryId: series.categoryId,
        description: scheduled.memoOverride ?? series.description,
        amountMinor:
            (scheduled.amountOverrideMinor ?? series.amountMinor).abs(),
        effectiveDate: effectiveDate,
        status: scheduled.status,
        accountId: series.accountId,
        frequency: series.frequency,
        accountName: row.readTable(accountsView).name,
      ));
    }

    if (!includeVirtual) {
      return bills;
    }

    var activeSeriesPredicate = recurringSeries.isActive.equals(true) &
        recurringSeries.type.equals(RecurringSeriesKind.expense.index) &
        accountsView.currencyCode.equals(currencyCode) &
        accountsView.includeInTotals.equals(true) &
        accountsView.deleted.equals(false) &
        accountsView.archived.equals(false);
    if (categoryId != null) {
      activeSeriesPredicate =
          activeSeriesPredicate & recurringSeries.categoryId.equals(categoryId);
    }

    final activeSeriesRows = await (select(recurringSeries).join([
      innerJoin(
        accountsView,
        accountsView.id.equalsExp(recurringSeries.accountId),
      ),
      leftOuterJoin(
        categoriesView,
        categoriesView.id.equalsExp(recurringSeries.categoryId),
      ),
    ])
          ..where(activeSeriesPredicate))
        .get();

    final visibleSeriesRows = [
      for (final row in activeSeriesRows)
        if (_countsTowardBudgetPending(
          row.readTableOrNull(categoriesView),
          targetYm,
        ))
          row,
    ];

    if (visibleSeriesRows.isEmpty) {
      return bills;
    }

    final activeSeriesIds = [
      for (final row in visibleSeriesRows) row.readTable(recurringSeries).id,
    ];
    final ymPrefix = '${targetYear.toString().padLeft(4, '0')}-'
        '${targetMonth.toString().padLeft(2, '0')}-';

    // Any physical row for (seriesId, occurrenceKey) — whether posted, skipped,
    // scheduled/failed in-month (already added above), or dateOverridden to
    // another month — suppresses virtual generation for that occurrence.
    final overlayPhysicalRows = await (select(scheduledTransactionsView)
          ..where((s) =>
              s.seriesId.isIn(activeSeriesIds) &
              (s.occurrenceKey.like('$ymPrefix%') |
                  s.occurrenceKey.equals(kPlannedOccurrenceKey))))
        .get();

    final existingKeys = <(String, String)>{
      for (final row in overlayPhysicalRows) (row.seriesId, row.occurrenceKey),
    };

    const expander = RecurrenceExpander();
    for (final row in visibleSeriesRows) {
      final series = row.readTable(recurringSeries);
      final account = row.readTable(accountsView);
      final spec = series.toRecurrenceRuleSpec();

      final occurrences = expander.expandForMonth(
        spec,
        targetYear,
        targetMonth,
        respectMaterializeFrom: true,
      );

      for (final occ in occurrences) {
        if (existingKeys.contains((series.id, occ.occurrenceKey))) {
          continue;
        }
        bills.add(BudgetPendingBillRaw(
          scheduledBillId: 'virtual:${series.id}:${occ.occurrenceKey}',
          seriesId: series.id,
          occurrenceKey: occ.occurrenceKey,
          isVirtual: true,
          categoryId: series.categoryId,
          description: series.description,
          amountMinor: series.amountMinor.abs(),
          effectiveDate: occ.scheduledDate,
          status: 'scheduled',
          accountId: series.accountId,
          frequency: series.frequency,
          accountName: account.name,
        ));
      }
    }

    bills.sort((a, b) {
      final dateCmp = a.effectiveDate.compareTo(b.effectiveDate);
      if (dateCmp != 0) return dateCmp;
      final seriesCmp = a.seriesId.compareTo(b.seriesId);
      if (seriesCmp != 0) return seriesCmp;
      return a.occurrenceKey.compareTo(b.occurrenceKey);
    });

    return bills;
  }

  /// Stream 3: ultra-lightweight single-category hint stream for
  /// `TransactionFormScreen`.
  ///
  /// Pending exposure follows the same archive cut-off and system-category
  /// exclusion as [watchMonthPendingExpenses] — the hint and the monthly totals
  /// come from the same loader.
  Stream<BudgetCategoryHintRaw> watchCategoryBudgetHint(
    String currencyCode,
    int targetYm,
    String categoryId, {
    bool includeVirtual = true,
  }) {
    final trigger = db.customSelect(
      _categoryHintTriggerSql,
      readsFrom: {
        budgetRules,
        categoriesView,
        transactionsView,
        transactionPostingsView,
        accountsView,
        scheduledTransactionsView,
        recurringSeries,
      },
    ).watch();

    return trigger.asyncMap(
      (_) => _loadCategoryBudgetHint(
        currencyCode,
        targetYm,
        categoryId,
        includeVirtual: includeVirtual,
      ),
    );
  }

  Future<BudgetCategoryHintRaw> _loadCategoryBudgetHint(
    String currencyCode,
    int targetYm,
    String categoryId, {
    required bool includeVirtual,
  }) async {
    final targetYear = targetYm ~/ 100;
    final targetMonth = targetYm % 100;
    final monthStart = DateTime(targetYear, targetMonth, 1);
    final monthEndExclusive = DateTime(targetYear, targetMonth + 1, 1);

    final category = await db.categoriesDao.getCategoryById(categoryId);
    final isArchived = category?.archived ?? false;

    int? effectiveBudgetMinor;
    if (category != null &&
        category.type == CategoryType.expense &&
        _isCategoryActiveForBudgetMonth(category, targetYm)) {
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

    final pendingBills = await _loadPendingExpenseBills(
      currencyCode: currencyCode,
      targetYm: targetYm,
      includeVirtual: includeVirtual,
      categoryId: categoryId,
    );
    var pendingMinor = 0;
    for (final bill in pendingBills) {
      pendingMinor += bill.amountMinor;
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
  ///
  /// Clearing also deletes the category review notes that belonged to the same
  /// month range, in the same transaction (ADR-0007). A cleared budget must not
  /// keep a stale note, and a failed note delete must not leave the budget
  /// erased.
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

      // Last, so that a failing note delete proves the rule writes above are
      // rolled back together with it.
      if (amountMinor == null) {
        await deleteCategoryReviewNotes(
          currencyCode: currencyCode,
          categoryId: categoryId,
          targetYm: targetYm,
          thisMonthOnly: thisMonthOnly,
        );
      }
    });
  }

  /// Deletes the category review notes covered by clearing a category budget:
  /// [targetYm] alone for [thisMonthOnly], [targetYm] onward otherwise. Only
  /// the given currency and category are touched — month-level notes
  /// (`categoryKey == ''`), other categories, other currencies, the budget
  /// rules and the category itself all stay. Callers run this inside the
  /// transaction that rewrites the rule timeline.
  @protected
  Future<void> deleteCategoryReviewNotes({
    required String currencyCode,
    required String categoryId,
    required int targetYm,
    required bool thisMonthOnly,
  }) async {
    await (delete(budgetReviewNotes)
          ..where((n) =>
              n.currencyCode.equals(currencyCode) &
              n.categoryKey.equals(categoryId) &
              (thisMonthOnly
                  ? n.ym.equals(targetYm)
                  : n.ym.isBiggerOrEqualValue(targetYm))))
        .go();
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
