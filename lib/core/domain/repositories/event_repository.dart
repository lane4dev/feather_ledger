import '../events/ledger_event.dart';

abstract class EventRepository {
  /// Appends a new ledger event to the event store.
  /// Returns a [Future] that completes when the operation is done.
  Future<int> appendEvent(LedgerEvent event);

  /// Get event by its ID.
  /// Returns a [LedgerEvent] or null if not found.
  /// [eventId] is the ID of the event to retrieve.
  Future<LedgerEvent> getEventById(String eventId);
}
