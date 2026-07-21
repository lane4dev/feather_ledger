import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/account_dao.dart';
import 'package:feather_ledger/core/data/database/daos/monthly_snapshot_dao.dart';

part 'watch_monthly_snapshot_query.g.dart';

/// A month's three headline figures (spec 003, US7/T054) — two different
/// kinds of number that happen to be shown together.
///
/// **Income and expense are the month's.** They are the selected month's
/// aggregates off the snapshot projection, negative for expense.
///
/// **The balance is not a month figure.** It is what the accounts hold right
/// now, whatever month is on screen, and the header labels it 总余额. Reading
/// it as the selected month's closing balance was tried and is worse: a month
/// later than the projection has no rows at all, so the ledger's total read
/// 0 while its accounts held money, and every month but this one disagreed
/// with the label above it.
///
/// Signed where it can be (expense negative, a balance can be below zero).
/// One currency, always: the app intentionally has no FX conversion.
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
/// Triggered by the accounts rather than by the snapshots, because that is
/// the signal both halves answer to: every write that moves a balance stamps
/// an account row inside the same transaction that rewrites the month's
/// snapshot rows, so one watch covers both and the snapshots are read after
/// it lands. (A snapshot row cannot change without its account changing.)
///
/// Archived accounts stay in the total — archiving takes an account out of
/// the pickers, it does not make the money go away.
class WatchMonthlySnapshotQuery {
  final MonthlySnapshotDao _snapshotDao;
  final AccountDao _accountDao;

  WatchMonthlySnapshotQuery(this._snapshotDao, this._accountDao);

  /// [currencyCode] is required: a default would silently filter a ledger in
  /// some other currency down to zeroes.
  Stream<MonthlySnapshotTotals> execute(
    DateTime month, {
    required String currencyCode,
  }) {
    return _accountDao.watchAllAccounts().asyncMap((accounts) async {
      final rows = await _snapshotDao.getAllForMonth(month.year, month.month);

      var income = 0;
      var expense = 0;
      for (final row in rows) {
        if (row.currencyCode != currencyCode) continue;
        income += row.incomeMinor;
        expense += row.expenseMinor;
      }

      var balance = 0;
      for (final account in accounts) {
        if (account.currencyCode != currencyCode) continue;
        balance += account.balanceMinor;
      }

      return MonthlySnapshotTotals(
        currencyCode: currencyCode,
        incomeMinor: income,
        expenseMinor: expense,
        balanceMinor: balance,
      );
    });
  }
}

@riverpod
WatchMonthlySnapshotQuery watchMonthlySnapshotQuery(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return WatchMonthlySnapshotQuery(db.monthlySnapshotDao, db.accountDao);
}
