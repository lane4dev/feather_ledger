/// Stable event envelope for the ledger event store (spec 003, Event Model).
///
/// The envelope is the *only* shape persisted to `ledger_events`. Everything
/// a projector or a rebuild needs to dispatch and order events lives here;
/// business data lives in [payloadJson] (which carries its own
/// `schemaVersion`).
///
/// Correlation/causation ids and metadata were deliberately cut (spec:
/// sync is future effort, not pre-built).
library;

/// Aggregate root a event belongs to. The string is stable storage vocab;
/// adding a value requires a migration decision, never a rename.
enum AggregateType { transaction, account, category }

/// Wire representation of one event, ready to be persisted or replayed.
///
/// Immutable by convention: once appended, an envelope is never mutated —
/// the event store rejects rewrites via `unique(streamId, streamVersion)`.
class EventEnvelope {
  /// Logical identity of the event (uuid). Stable across replays.
  final String eventId;

  /// Aggregate root id (= transactionId / accountId / categoryId).
  final String streamId;

  final AggregateType aggregateType;

  /// Dart class name of the payload, e.g. `TransactionRecorded`.
  ///
  /// Deliberately a hand-declared stable string — persisting
  /// `runtimeType.toString()` couples storage to refactors and is
  /// forbidden by this migration.
  final String eventType;

  /// 0-based position of this event within its stream. Enforced unique per
  /// stream by the store (optimistic concurrency).
  final int streamVersion;

  /// Global sequence number, assigned by the store at append time. Null for
  /// envelopes not yet persisted (kept nullable so commands can build
  /// envelopes before append).
  final int? globalSequenceNumber;

  /// Serialized payload. Must contain `schemaVersion: int`.
  final Map<String, dynamic> payloadJson;

  /// Business date (e.g. transaction date).
  final DateTime occurredAt;

  /// Wall-clock time when the store persisted the event.
  final DateTime recordedAt;

  /// Idempotency key of the command that produced this event. Duplicate
  /// commandIds short-circuit before append.
  final String commandId;

  const EventEnvelope({
    required this.eventId,
    required this.streamId,
    required this.aggregateType,
    required this.eventType,
    required this.streamVersion,
    this.globalSequenceNumber,
    required this.payloadJson,
    required this.occurredAt,
    required this.recordedAt,
    required this.commandId,
  });

  EventEnvelope withGlobalSequenceNumber(int gsn) => EventEnvelope(
        eventId: eventId,
        streamId: streamId,
        aggregateType: aggregateType,
        eventType: eventType,
        streamVersion: streamVersion,
        globalSequenceNumber: gsn,
        payloadJson: payloadJson,
        occurredAt: occurredAt,
        recordedAt: recordedAt,
        commandId: commandId,
      );

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'streamId': streamId,
        'aggregateType': aggregateType.name,
        'eventType': eventType,
        'streamVersion': streamVersion,
        'globalSequenceNumber': globalSequenceNumber,
        'payload': payloadJson,
        'occurredAt': occurredAt.toIso8601String(),
        'recordedAt': recordedAt.toIso8601String(),
        'commandId': commandId,
      };

  factory EventEnvelope.fromJson(Map<String, dynamic> json) => EventEnvelope(
        eventId: json['eventId'] as String,
        streamId: json['streamId'] as String,
        aggregateType:
            AggregateType.values.byName(json['aggregateType'] as String),
        eventType: json['eventType'] as String,
        streamVersion: json['streamVersion'] as int,
        globalSequenceNumber: json['globalSequenceNumber'] as int?,
        payloadJson: (json['payload'] as Map).cast<String, dynamic>(),
        occurredAt: DateTime.parse(json['occurredAt'] as String),
        recordedAt: DateTime.parse(json['recordedAt'] as String),
        commandId: json['commandId'] as String,
      );

  @override
  bool operator ==(Object other) =>
      other is EventEnvelope && other.eventId == eventId;

  @override
  int get hashCode => eventId.hashCode;

  @override
  String toString() => 'EventEnvelope($globalSequenceNumber $eventType '
      'stream=$streamId@$streamVersion)';
}

/// Raised when deserializing an event whose payload has no registered
/// upcaster — the store hard-fails rather than guess (spec: schema
/// evolution discipline).
class UnknownEventTypeError extends Error {
  final String eventType;
  final String eventId;

  UnknownEventTypeError(this.eventType, this.eventId);

  @override
  String toString() =>
      'UnknownEventTypeError: no factory/upcaster registered for '
      '"$eventType" (event $eventId)';
}
