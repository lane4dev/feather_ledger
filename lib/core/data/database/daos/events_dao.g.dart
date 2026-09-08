// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'events_dao.dart';

// ignore_for_file: type=lint
mixin _$EventsDaoMixin on DatabaseAccessor<AppDatabase> {
  $LedgerEventsTable get ledgerEvents => attachedDatabase.ledgerEvents;
  EventsDaoManager get managers => EventsDaoManager(this);
}

class EventsDaoManager {
  final _$EventsDaoMixin _db;
  EventsDaoManager(this._db);
  $$LedgerEventsTableTableManager get ledgerEvents =>
      $$LedgerEventsTableTableManager(_db.attachedDatabase, _db.ledgerEvents);
}
