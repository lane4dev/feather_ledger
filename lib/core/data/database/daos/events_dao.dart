import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';

import '../app_database.dart';
import '../tables.dart';

part 'events_dao.g.dart';

/// Raw row access for the ledger event store (spec 003, US2/T019).
///
/// Atomicity (batch + projector inside one database transaction) is
/// orchestrated by `DriftEventStore.append`; this DAO only offers the
/// row-level primitives and the row ↔ envelope mapping.
@DriftAccessor(tables: [LedgerEvents])
class EventsDao extends DatabaseAccessor<AppDatabase> with _$EventsDaoMixin {
  EventsDao(super.db);

  /// Inserts one row and returns the assigned GSN (auto-increment id).
  Future<int> insertRow(EventEnvelope envelope) {
    return into(ledgerEvents).insert(toCompanion(envelope));
  }

  Future<List<LedgerEventRow>> getByCommandId(String commandId) {
    return (select(ledgerEvents)..where((t) => t.commandId.equals(commandId)))
        .get();
  }

  Future<LedgerEventRow?> getByStreamVersion(
      String streamId, int streamVersion) {
    return (select(ledgerEvents)
          ..where((t) =>
              t.streamId.equals(streamId) &
              t.streamVersion.equals(streamVersion)))
        .getSingleOrNull();
  }

  Future<List<LedgerEventRow>> getStream(String streamId) {
    return (select(ledgerEvents)
          ..where((t) => t.streamId.equals(streamId))
          ..orderBy([(t) => OrderingTerm.asc(t.streamVersion)]))
        .get();
  }

  Future<List<LedgerEventRow>> getAll() {
    return (select(ledgerEvents)..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  /// Rows with GSN strictly greater than [after], ordered by GSN, capped by
  /// [limit].
  Future<List<LedgerEventRow>> getAfterGsn({int? after, int? limit}) {
    final query = select(ledgerEvents)
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    if (after != null) {
      query.where((t) => t.id.isBiggerThanValue(after));
    }
    if (limit != null) {
      query.limit(limit);
    }
    return query.get();
  }

  Future<int?> getMaxGsn() async {
    final query = selectOnly(ledgerEvents)..addColumns([ledgerEvents.id.max()]);
    final result = await query.getSingle();
    return result.read(ledgerEvents.id.max());
  }

  // Row ↔ envelope mapping ————————————————————————————————————————————

  LedgerEventsCompanion toCompanion(EventEnvelope e) => LedgerEventsCompanion(
        eventId: Value(e.eventId),
        streamId: Value(e.streamId),
        aggregateType: Value(e.aggregateType),
        eventType: Value(e.eventType),
        streamVersion: Value(e.streamVersion),
        occurredAt: Value(e.occurredAt),
        recordedAt: Value(e.recordedAt),
        commandId: Value(e.commandId),
        payload: Value(jsonEncode(e.payloadJson)),
      );

  EventEnvelope toEnvelope(LedgerEventRow row) => EventEnvelope(
        eventId: row.eventId,
        streamId: row.streamId,
        aggregateType: row.aggregateType,
        eventType: row.eventType,
        streamVersion: row.streamVersion,
        globalSequenceNumber: row.id,
        payloadJson:
            (jsonDecode(row.payload) as Map).cast<String, dynamic>(),
        occurredAt: row.occurredAt,
        recordedAt: row.recordedAt,
        commandId: row.commandId,
      );
}
