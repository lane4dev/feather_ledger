import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/account_dao.dart';
import 'package:feather_ledger/core/data/database/daos/monthly_snapshot_dao.dart';

part 'watch_monthly_snapshot_query.g.dart';

/// Monthly totals read from the snapshot projection (spec 003, US7/T054).
///
/// Income/expense are the signed snapshot aggregates of the selected month
/// (expense negative). balanceMinor is the sum of the account projections —
/// the *current* balance, which includes future-dated postings by
/// definition (spec US4: 记了就算); a historical month's header balance is
/// therefore today's balance, not that month's closing.
/// A monthly projection total for exactly one currency. This query always
/// filters by [currencyCode]; the app intentionally has no FX conversion.
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

/// Streams the header totals for a month. Re-emits on account changes —
/// every balance event touches an account row, so the snapshots are
/// re-read on every relevant write.
class WatchMonthlySnapshotQuery {
  final MonthlySnapshotDao _snapshotDao;
  final AccountDao _accountDao;

  WatchMonthlySnapshotQuery(this._snapshotDao, this._accountDao);

  Stream<MonthlySnapshotTotals> execute(DateTime month,
      {String currencyCode = 'USD'}) {
    return _accountDao.watchAllAccounts().asyncMap((accounts) async {
      final rows = await _snapshotDao.getAllForMonth(month.year, month.month);
      final currencyRows = rows
          .where((row) => row.currencyCode == currencyCode)
          .toList(growable: false);
      final currencyAccounts = accounts
          .where((account) => account.currencyCode == currencyCode);
      return MonthlySnapshotTotals(
        currencyCode: currencyCode,
        incomeMinor: currencyRows.fold<int>(0, (sum, row) => sum + row.incomeMinor),
        expenseMinor: currencyRows.fold<int>(0, (sum, row) => sum + row.expenseMinor),
        balanceMinor: currencyAccounts.fold<int>(
            0, (sum, account) => sum + account.balanceMinor),
      );
    });
  }
}

@riverpod
WatchMonthlySnapshotQuery watchMonthlySnapshotQuery(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return WatchMonthlySnapshotQuery(db.monthlySnapshotDao, db.accountDao);
}
