import 'package:drift/drift.dart';

import 'package:feather_ledger/core/domain/enums.dart';

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
  final int totalMinor; // signed posting impact

  ReportCategoryRow({
    required this.categoryId,
    required this.name,
    required this.iconKey,
    required this.colorHex,
    required this.totalMinor,
  });
}

/// Monthly income/expense/balance read from the snapshot projection — the
/// single source the reports share with the ledger (spec 003, US9 同源).
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
  MonthlyAccountBalanceSnapshots
])
class ReportsDao extends DatabaseAccessor<AppDatabase> with _$ReportsDaoMixin {
  ReportsDao(super.db);

  /// Daily signed posting impacts for the heatmap's 3-month window,
  /// excluding transfers (net zero) and reversed rows.
  Stream<Map<DateTime, int>> watchDailyTransactionAmounts(DateTime datetime) {
    final start = DateTime(datetime.year, datetime.month - 2, 1);
    final end = DateTime(datetime.year, datetime.month + 1, 1)
        .subtract(const Duration(seconds: 1));

    final query = select(transactionsView).join([
      innerJoin(
          transactionPostingsView,
          transactionPostingsView.transactionId
              .equalsExp(transactionsView.transactionId)),
    ])
      ..where(transactionsView.occurredAt.isBetweenValues(start, end) &
          transactionsView.isReversed.equals(false));

    return query.watch().map((rows) {
      final map = <DateTime, int>{};
      for (final row in rows) {
        final tx = row.readTable(transactionsView);
        if (tx.kind == TransactionKind.transfer) continue; // net zero
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
      DateTime datetime, CategoryType type) {
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
    ])
      ..where(transactionsView.occurredAt.isBetweenValues(start, end) &
          transactionsView.isReversed.equals(false) &
          transactionsView.kind.equals(kind.index));

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
              (existing?.totalMinor ?? 0) + postingSignedImpact(posting),
        );
      }
      return grouped.values.toList();
    });
  }

  /// Monthly income/expense/end-of-month balance from the snapshot
  /// projection, aggregated across accounts.
  Stream<ReportMonthlyTotalsRow> watchMonthlyTotals(DateTime datetime,
      {String currencyCode = 'USD'}) {
    return (select(monthlyAccountBalanceSnapshots)
          ..where((t) =>
              t.year.equals(datetime.year) & t.month.equals(datetime.month) &
              t.currencyCode.equals(currencyCode)))
        .watch()
        .map((rows) => ReportMonthlyTotalsRow(
              incomeMinor: rows.fold<int>(0, (s, r) => s + r.incomeMinor),
              expenseMinor: rows.fold<int>(0, (s, r) => s + r.expenseMinor),
              balanceMinor:
                  rows.fold<int>(0, (s, r) => s + r.closingBalanceMinor),
            ));
  }
}
