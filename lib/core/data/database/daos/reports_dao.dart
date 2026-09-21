import 'package:drift/drift.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/money/money.dart';

import '../app_database.dart';
import '../tables.dart';

import 'transaction_dao.dart' show postingSignedImpact;

part 'reports_dao.g.dart';

/// One category bucket of the monthly breakdown: the category identity and
/// display data come from the transaction row's **write-time snapshot**
/// (spec 003, US9): archived categories keep showing in history without
/// joining the live category row.
class ReportCategoryRow {
  final String categoryId;
  final String name;
  final String iconKey;
  final String colorHex;

  /// How much moved in this category, as a **magnitude**. A breakdown answers
  /// "how much on food", not "which way did it net" — and a chart cannot draw
  /// a negative slice. The sign is already implied by which breakdown this is:
  /// the query filters to one kind.
  final int totalMinor;

  ReportCategoryRow({
    required this.categoryId,
    required this.name,
    required this.iconKey,
    required this.colorHex,
    required this.totalMinor,
  });
}

/// Monthly income/expense/balance read from the snapshot projection — the
/// source the reports share with the ledger for the month's income and
/// expense (spec 003, US9). The balance here is the month's closing one; the
/// ledger header's is the running total, which is a different question.
class ReportMonthlyTotalsRow {
  final int incomeMinor;
  final int expenseMinor;
  final int balanceMinor;

  ReportMonthlyTotalsRow({
    required this.incomeMinor,
    required this.expenseMinor,
    required this.balanceMinor,
  });
}

/// Report queries (spec 003, US9/T063): heatmap and category breakdown read
/// the transaction/postings projections; monthly totals read the snapshot
/// projection. No report query computes its own balance or totals
/// algorithm — everything is derived from the same projections the ledger
/// writes.
@DriftAccessor(tables: [
  TransactionsView,
  TransactionPostingsView,
  MonthlyAccountBalanceSnapshots,
  AccountsView
])
class ReportsDao extends DatabaseAccessor<AppDatabase> with _$ReportsDaoMixin {
  ReportsDao(super.db);

  /// Daily transaction counts for the three-month heatmap window. Count
  /// transactions, not postings: DISTINCT keeps a joined transaction unique.
  /// Joining accounts also makes inclusion changes invalidate the stream.
  Stream<Map<DateTime, int>> watchDailyTransactionCounts(DateTime month,
      {String currencyCode = Money.defaultCurrencyCode}) {
    final start = DateTime(month.year, month.month - 2, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final query = selectOnly(transactionsView, distinct: true)
      ..addColumns([
        transactionsView.transactionId,
        transactionsView.occurredAt,
      ])
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
        transactionsView.occurredAt.isBiggerOrEqualValue(start) &
            transactionsView.occurredAt.isSmallerThanValue(end) &
            transactionsView.kind.isIn([
              TransactionKind.income.index,
              TransactionKind.expense.index,
            ]) &
            transactionsView.isReversed.equals(false) &
            (accountsView.includeInTotals.equals(true) &
                accountsView.deleted.equals(false) &
                accountsView.currencyCode.equals(currencyCode)),
      );

    return query.watch().map((rows) {
      final counts = <DateTime, int>{};
      for (final row in rows) {
        final date = row.read(transactionsView.occurredAt)!;
        final day = DateTime(date.year, date.month, date.day);
        counts[day] = (counts[day] ?? 0) + 1;
      }
      return counts;
    });
  }

  /// Daily signed posting impacts for the heatmap's 3-month window,
  /// excluding transfers (net zero) and reversed rows.
  ///
  /// The join to `accounts_view` is what drops postings on accounts that are
  /// out of the **ledger totals** (CONTEXT.md). It is a join rather than a
  /// filter over the result because `watch()` re-emits on writes to every
  /// table in the statement — without the account table in the query, toggling
  /// the flag would leave this chart stale until something else moved.
  Stream<Map<DateTime, int>> watchDailyTransactionAmounts(DateTime datetime,
      {String currencyCode = Money.defaultCurrencyCode}) {
    final start = DateTime(datetime.year, datetime.month - 2, 1);
    final end = DateTime(datetime.year, datetime.month + 1, 1)
        .subtract(const Duration(seconds: 1));

    final query = select(transactionsView).join([
      innerJoin(
          transactionPostingsView,
          transactionPostingsView.transactionId
              .equalsExp(transactionsView.transactionId)),
      innerJoin(accountsView,
          accountsView.id.equalsExp(transactionPostingsView.accountId)),
    ])
      ..where(transactionsView.occurredAt.isBetweenValues(start, end) &
          transactionsView.isReversed.equals(false) &
          (accountsView.includeInTotals.equals(true) &
              accountsView.deleted.equals(false) &
              accountsView.currencyCode.equals(currencyCode)));

    return query.watch().map((rows) {
      final map = <DateTime, int>{};
      for (final row in rows) {
        final tx = row.readTable(transactionsView);
        if (!tx.kind.contributesToIncomeExpense) continue;
        final posting = row.readTable(transactionPostingsView);
        final day = DateTime(
            tx.occurredAt.year, tx.occurredAt.month, tx.occurredAt.day);
        map[day] = (map[day] ?? 0) + postingSignedImpact(posting);
      }
      return map;
    });
  }

  /// Category breakdown for one month: income/expense rows grouped by the
  /// transaction's write-time category snapshot. Transfers (no category)
  /// and reversed rows are excluded.
  Stream<List<ReportCategoryRow>> watchCategoryBreakdown(
      DateTime datetime, CategoryType type,
      {String currencyCode = Money.defaultCurrencyCode}) {
    final start = DateTime(datetime.year, datetime.month, 1);
    final end = DateTime(datetime.year, datetime.month + 1, 1)
        .subtract(const Duration(seconds: 1));
    final kind = type == CategoryType.income
        ? TransactionKind.income
        : TransactionKind.expense;

    final query = select(transactionsView).join([
      innerJoin(
          transactionPostingsView,
          transactionPostingsView.transactionId
              .equalsExp(transactionsView.transactionId)),
      innerJoin(accountsView,
          accountsView.id.equalsExp(transactionPostingsView.accountId)),
    ])
      ..where(transactionsView.occurredAt.isBetweenValues(start, end) &
          transactionsView.isReversed.equals(false) &
          transactionsView.kind.equals(kind.index) &
          (accountsView.includeInTotals.equals(true) &
              accountsView.deleted.equals(false) &
              accountsView.currencyCode.equals(currencyCode)));

    return query.watch().map((rows) {
      final grouped = <String, ReportCategoryRow>{};
      for (final row in rows) {
        final tx = row.readTable(transactionsView);
        final posting = row.readTable(transactionPostingsView);
        final id = posting.categoryId ?? '';
        final existing = grouped[id];
        grouped[id] = ReportCategoryRow(
          categoryId: id,
          name: tx.categoryName ?? existing?.name ?? '',
          iconKey: tx.categoryIcon ?? existing?.iconKey ?? '',
          colorHex: tx.categoryColorInt ?? existing?.colorHex ?? 'ff000000',
          totalMinor:
              (existing?.totalMinor ?? 0) + postingSignedImpact(posting).abs(),
        );
      }
      return grouped.values.toList();
    });
  }

  /// Monthly income/expense/end-of-month balance from the snapshot
  /// projection, aggregated across accounts — but only the accounts that
  /// count toward the **ledger totals** (CONTEXT.md), hence the join.
  Stream<ReportMonthlyTotalsRow> watchMonthlyTotals(DateTime datetime,
      {String currencyCode = Money.defaultCurrencyCode}) {
    return (select(monthlyAccountBalanceSnapshots).join([
      innerJoin(accountsView,
          accountsView.id.equalsExp(monthlyAccountBalanceSnapshots.accountId)),
    ])
          ..where(monthlyAccountBalanceSnapshots.year.equals(datetime.year) &
              monthlyAccountBalanceSnapshots.month.equals(datetime.month) &
              monthlyAccountBalanceSnapshots.currencyCode.equals(currencyCode) &
              (accountsView.includeInTotals.equals(true) &
                  accountsView.deleted.equals(false))))
        .watch()
        .map((joined) {
      var income = 0;
      var expense = 0;
      var balance = 0;
      for (final row in joined) {
        final snapshot = row.readTable(monthlyAccountBalanceSnapshots);
        income += snapshot.incomeMinor;
        expense += snapshot.expenseMinor;
        balance += snapshot.closingBalanceMinor;
      }
      return ReportMonthlyTotalsRow(
        incomeMinor: income,
        expenseMinor: expense,
        balanceMinor: balance,
      );
    });
  }
}
