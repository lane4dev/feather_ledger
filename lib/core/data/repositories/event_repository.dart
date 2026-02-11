import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/events/ledger_event.dart';
import '../../domain/repositories/event_repository.dart';
import '../database/app_database.dart';
import '../database/daos/events_dao.dart';

export '../../domain/repositories/event_repository.dart';

part 'event_repository.g.dart';

class EventRepositoryImpl implements EventRepository {
  final EventsDao _eventsDao;

  EventRepositoryImpl(this._eventsDao);

  @override
  Future<LedgerEvent> getEventById(String eventId) async {
    final row = await _eventsDao.getEventById(eventId);

    final payload = jsonDecode(row.payload) as Map<String, dynamic>;
    payload.putIfAbsent('eventId', () => row.eventId);
    payload.putIfAbsent('occurredAt', () => row.occurredAt.toIso8601String());
    payload.putIfAbsent('recordedAt', () => row.recordedAt.toIso8601String());
    payload.putIfAbsent('runtimeType', () => row.type);

    return LedgerEvent.fromJson(payload);
  }

  @override
  Future<int> appendEvent(LedgerEvent event) async {
    return _eventsDao.appendEvent(LedgerEventsCompanion(
      eventId: Value(event.eventId),
      type: Value(event.runtimeType.toString()),
      occurredAt: Value(event.occurredAt),
      recordedAt: Value(event.recordedAt),
      payload: Value(jsonEncode(event.toJson())),
    ));
  }
}

@Riverpod(keepAlive: true)
EventRepository eventRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return EventRepositoryImpl(db.eventsDao);
}
