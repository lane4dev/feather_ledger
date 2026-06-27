import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'recurring_dao.g.dart';

@DriftAccessor(tables: [RecurringSeries, ScheduledTransactionsView])
class RecurringDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringDaoMixin {
  RecurringDao(super.db);

  Future<List<RecurringSeriesRow>> getAllSeries() =>
      select(recurringSeries).get();

  Future<ScheduledTransactionViewRow?> getScheduled(String id) {
    return (select(scheduledTransactionsView)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<RecurringSeriesRow?> getSeries(String id) {
    return (select(recurringSeries)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insertOrUpdateScheduled(
      ScheduledTransactionsViewCompanion entry) {
    return into(scheduledTransactionsView).insertOnConflictUpdate(entry);
  }

  Future<void> saveSeries(RecurringSeriesCompanion entry) {
    return into(recurringSeries).insertOnConflictUpdate(entry);
  }

  Stream<List<ScheduledTransactionViewRow>> watchAllScheduled() {
    return select(scheduledTransactionsView).watch();
  }

  /// Watches the series themselves, not their instances.
  ///
  /// Needed because a series can produce zero scheduled rows — an `endDate`
  /// at or before its `startDate`, or one created before its first instance
  /// materializes — and would otherwise be invisible, including in the moment
  /// right after it is created.
  Stream<List<RecurringSeriesRow>> watchAllSeries() =>
      select(recurringSeries).watch();
}
