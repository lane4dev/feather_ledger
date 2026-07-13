import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/monthly_snapshot_dao.dart';

part 'watch_monthly_snapshot_query.g.dart';

/// A month's three headline figures, read from the snapshot projection
/// (spec 003, US7/T054).
///
/// All three describe **the selected month**, and that is the point: income
/// and expense are the month's aggregates, and the balance is the month's
/// *closing* balance, the end of the opening→closing chain the projector
/// maintains. [balanceMinor] used to be the live `accounts_view` total
/// instead, which meant the big number beside a past month's income and
/// expense was today's money — and that it disagreed with the reports screen,
/// which reads the same three figures off the same projection.
///
/// Signed throughout, like the projection (expense negative; a closing
/// balance can be below zero). A monthly total for exactly one currency: the
/// app intentionally has no FX conversion.
class MonthlySnapshotTotals {
  final String currencyCode;
  final int incomeMinor;
  final int expenseMinor;
  final int balanceMinor;

  const MonthlySnapshotTotals({
    this.currencyCode = 'USD',
    required this.incomeMinor,
    required this.expenseMinor,
    required this.balanceMinor,
  });
}

/// Streams the header totals for a month.
///
/// Watches the month's snapshot rows rather than the accounts: the projector
/// rewrites them inside the same transaction as every append that affects
/// them, so they are both the trigger and the source.
class WatchMonthlySnapshotQuery {
  final MonthlySnapshotDao _snapshotDao;

  WatchMonthlySnapshotQuery(this._snapshotDao);

  /// [currencyCode] is required: a default would silently filter a ledger in
  /// some other currency down to zeroes.
  Stream<MonthlySnapshotTotals> execute(
    DateTime month, {
    required String currencyCode,
  }) {
    return _snapshotDao.watchAllForMonth(month.year, month.month).map((rows) {
      var income = 0;
      var expense = 0;
      var closing = 0;
      for (final row in rows) {
        if (row.currencyCode != currencyCode) continue;
        income += row.incomeMinor;
        expense += row.expenseMinor;
        closing += row.closingBalanceMinor;
      }
      return MonthlySnapshotTotals(
        currencyCode: currencyCode,
        incomeMinor: income,
        expenseMinor: expense,
        balanceMinor: closing,
      );
    });
  }
}

@riverpod
WatchMonthlySnapshotQuery watchMonthlySnapshotQuery(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return WatchMonthlySnapshotQuery(db.monthlySnapshotDao);
}
