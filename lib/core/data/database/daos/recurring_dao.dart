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

  /// Every instance of one series, whatever its status.
  ///
  /// Materialization needs the whole set at once: it walks the rule's
  /// candidate dates and has to know, per date, whether an instance already
  /// exists and whether the user has already decided about it.
  Future<List<ScheduledTransactionViewRow>> scheduledForSeries(
      String seriesId) {
    return (select(scheduledTransactionsView)
          ..where((t) => t.seriesId.equals(seriesId)))
        .get();
  }

  Future<void> insertOrUpdateScheduled(
      ScheduledTransactionsViewCompanion entry) {
    return into(scheduledTransactionsView).insertOnConflictUpdate(entry);
  }

  Future<void> saveSeries(RecurringSeriesCompanion entry) {
    return into(recurringSeries).insertOnConflictUpdate(entry);
  }

  /// Deletes instance rows of one series.
  ///
  /// [from] keeps the instances at or after that date, [status] keeps one
  /// storage-encoded status. The two filters together say "the pending bills
  /// from here on"; passing neither deletes every row of the series, which is
  /// what removing the series itself needs. Which status counts as pending is
  /// the caller's policy — this table accessor does not know the enum.
  Future<int> deleteScheduledForSeries(
    String seriesId, {
    DateTime? from,
    String? status,
  }) {
    final query = delete(scheduledTransactionsView)
      ..where((t) => t.seriesId.equals(seriesId));
    if (from != null) query.where((t) => t.date.isBiggerOrEqualValue(from));
    if (status != null) query.where((t) => t.status.equals(status));
    return query.go();
  }

  Future<int> deleteSeries(String seriesId) {
    return (delete(recurringSeries)..where((t) => t.id.equals(seriesId))).go();
  }

  Stream<List<ScheduledTransactionViewRow>> watchAllScheduled() {
    return select(scheduledTransactionsView).watch();
  }
}
