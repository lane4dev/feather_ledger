/// EventStore port (spec 003, Event Model).
///
/// The write model of the whole ledger. Implementations must:
/// - persist [EventEnvelope]s immutably with a monotonic global sequence
///   number (GSN),
/// - enforce `unique(streamId, streamVersion)` (optimistic concurrency),
/// - reject duplicate [EventEnvelope.commandId]s (idempotency),
/// - drive the projector **inside the same database transaction** as the
///   append (see [AppendOptions.apply]).
///
/// Drift implementation lands in US2 (T019/T020).
library;

import 'event_envelope.dart';
import 'event_type_registry.dart';

/// Appending two events with the same `(streamId, streamVersion)` must
/// fail with this error — write corruption should surface early, not
/// silently overwrite a stream position.
class StreamVersionConflictError extends Error {
  final String streamId;
  final int streamVersion;

  StreamVersionConflictError(this.streamId, this.streamVersion);

  @override
  String toString() => 'StreamVersionConflictError: $streamId already has '
      'version $streamVersion';
}

/// A command already produced an event with this commandId — the store
/// short-circuits and reports the existing event instead of appending a
/// duplicate.
class DuplicateCommandError extends Error {
  final String commandId;
  final EventEnvelope existingEvent;

  DuplicateCommandError(this.commandId, this.existingEvent);

  @override
  String toString() =>
      'DuplicateCommandError: command $commandId already produced '
      '${existingEvent.eventType} (GSN ${existingEvent.globalSequenceNumber})';
}

/// Side effects run in the append's database transaction. [apply] receives
/// the persisted envelopes (GSN assigned) in order and is awaited inside the
/// transaction; a throw from [apply] rolls the append back.
class AppendOptions {
  final Future<void> Function(List<EventEnvelope> persisted) apply;

  const AppendOptions({required this.apply});
}

/// Next free streamVersion for a stream whose commands don't track
/// versions themselves: the current stream length (spec 003, US3+ — until
/// a stream-version table exists).
Future<int> nextStreamVersion(EventStore store, String streamId) async =>
    (await store.readStream(streamId)).length;

/// Page of events read back from the store.
class EventPage {
  final List<EventEnvelope> events;

  /// GSN to pass next as [EventStoreRead.after] — null when the stream end
  /// was reached.
  final int? nextAfter;

  const EventPage({required this.events, this.nextAfter});
}

abstract class EventStore {
  /// Registry consulted for payload (de)serialization and upcasting.
  EventTypeRegistry get registry;

  /// Atomically persists [envelopes] in one batch.
  ///
  /// Guarantees:
  /// - all-or-nothing (single database transaction),
  /// - GSNs are assigned monotonically in list order,
  /// - if any envelope's commandId already exists, nothing is appended and
  ///   [DuplicateCommandError] reports the original event,
  /// - if any `(streamId, streamVersion)` already exists, nothing is
  ///   appended and [StreamVersionConflictError] is thrown,
  /// - when [options.apply] is given, it runs inside the transaction with
  ///   the persisted envelopes — this is where the projector hooks in.
  ///
  /// Returns the envelopes with GSNs assigned.
  Future<List<EventEnvelope>> append(
    List<EventEnvelope> envelopes, {
    AppendOptions? options,
  });

  /// True if some event with [commandId] exists — commands use this to
  /// short-circuit before building events.
  Future<bool> commandExists(String commandId);

  /// Reads events with GSN strictly greater than [after], ordered by GSN.
  /// [limit] caps the page; [EventPage.nextAfter] tells the caller how to
  /// continue. Reading with `after: null` starts from the beginning.
  Future<EventPage> readAll({int? after, int? limit});

  /// All events of one stream, ordered by streamVersion.
  Future<List<EventEnvelope>> readStream(String streamId);

  /// Highest assigned GSN, or null on an empty store.
  Future<int?> readMaxGlobalSequenceNumber();
}
