import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/app/bootstrap/register_ledger_events.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_type_registry.dart';

part 'drift_event_store.g.dart';

/// Drift-backed [EventStore] (spec 003, US2/T020).
///
/// Append is one database transaction: commandId dedup, stream version
/// enforcement, row insert and the optional [AppendOptions.apply] projector
/// hook either all commit or all roll back.
class DriftEventStore implements EventStore {
  final AppDatabase _db;

  @override
  final EventTypeRegistry registry;

  DriftEventStore(this._db, this.registry);

  @override
  Future<List<EventEnvelope>> append(
    List<EventEnvelope> envelopes, {
    AppendOptions? options,
  }) async {
    final persisted = <EventEnvelope>[];
    await _db.transaction(() async {
      // Pre-check the whole batch against *pre-existing* rows before
      // inserting anything: several envelopes may legitimately share one
      // commandId (one command producing multiple events), and the dedup
      // check must not trip over rows inserted earlier in the same batch.
      for (final envelope in envelopes) {
        final existingCommand =
            await _db.eventsDao.getByCommandId(envelope.commandId);
        if (existingCommand.isNotEmpty) {
          throw DuplicateCommandError(
            envelope.commandId,
            _db.eventsDao.toEnvelope(existingCommand.first),
          );
        }

        final existingVersion = await _db.eventsDao.getByStreamVersion(
          envelope.streamId,
          envelope.streamVersion,
        );
        if (existingVersion != null) {
          throw StreamVersionConflictError(
            envelope.streamId,
            envelope.streamVersion,
          );
        }
      }

      for (final envelope in envelopes) {
        final gsn = await _db.eventsDao.insertRow(envelope);
        persisted.add(envelope.withGlobalSequenceNumber(gsn));
      }

      await options?.apply(persisted);
    });
    return persisted;
  }

  @override
  Future<bool> commandExists(String commandId) async =>
      (await _db.eventsDao.getByCommandId(commandId)).isNotEmpty;

  @override
  Future<EventPage> readAll({int? after, int? limit}) async {
    // Fetch one extra row to detect whether the stream end was reached so
    // [EventPage.nextAfter] can be null exactly at the end.
    final rows = await _db.eventsDao.getAfterGsn(
      after: after,
      limit: limit == null ? null : limit + 1,
    );
    final events = rows
        .take(limit ?? rows.length)
        .map(_db.eventsDao.toEnvelope)
        .toList();
    final reachedEnd = limit == null || rows.length <= limit;
    return EventPage(
      events: events,
      nextAfter: reachedEnd ? null : events.last.globalSequenceNumber,
    );
  }

  @override
  Future<List<EventEnvelope>> readStream(String streamId) async =>
      (await _db.eventsDao.getStream(streamId))
          .map(_db.eventsDao.toEnvelope)
          .toList();

  @override
  Future<int?> readMaxGlobalSequenceNumber() => _db.eventsDao.getMaxGsn();
}

@Riverpod(keepAlive: true)
EventStore driftEventStore(Ref ref) {
  registerLedgerEvents();
  final db = ref.watch(appDatabaseProvider);
  return DriftEventStore(db, ledgerEventRegistry);
}
