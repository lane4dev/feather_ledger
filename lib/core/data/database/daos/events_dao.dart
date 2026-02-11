import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'events_dao.g.dart';

@DriftAccessor(tables: [LedgerEvents])
class EventsDao extends DatabaseAccessor<AppDatabase> with _$EventsDaoMixin {
  EventsDao(super.db);

  Future<int> appendEvent(LedgerEventsCompanion event) {
    return into(ledgerEvents).insert(event);
  }

  Stream<List<LedgerEventRow>> getStream() {
    return (select(ledgerEvents)
          ..orderBy([(t) => OrderingTerm(expression: t.id)]))
        .watch();
  }

  Future<List<LedgerEventRow>> getAllEvents() {
    return (select(ledgerEvents)
          ..orderBy([(t) => OrderingTerm(expression: t.id)]))
        .get();
  }

  Future<LedgerEventRow> getEventById(String eventId) {
    return (select(ledgerEvents)..where((tbl) => tbl.eventId.equals(eventId)))
        .getSingle();
  }

  Future<int?> getMaxEventId() async {
    final query = selectOnly(ledgerEvents)..addColumns([ledgerEvents.id.max()]);
    final result = await query.getSingle();
    return result.read(ledgerEvents.id.max());
  }
}
