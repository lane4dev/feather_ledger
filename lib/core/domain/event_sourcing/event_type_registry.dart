/// Explicit eventType → factory registry and (eventType, version) upcaster
/// registry (spec 003, Event Model / schema 演进).
///
/// This is the *only* dispatch point between stored event JSON and Dart
/// payloads. Bootstrap registers every event factory here (T021); tests
/// inherit production registration instead of hand-registering.
library;

import 'event_envelope.dart';

/// Reconstructs the domain payload of a stored event from its JSON.
typedef LedgerEventPayloadFactory = Map<String, dynamic> Function(
    Map<String, dynamic> json);

/// Upcasts a stored payload to the current schema version.
typedef LedgerEventUpcaster = Map<String, dynamic> Function(
    Map<String, dynamic> oldPayload);

class EventTypeRegistry {
  final Map<String, LedgerEventPayloadFactory> _factories = {};
  final Map<String, LedgerEventUpcaster> _upcasters = {};

  void registerFactory({
    required String eventType,
    required LedgerEventPayloadFactory factory,
  }) {
    if (_factories.containsKey(eventType)) {
      throw StateError(
          'Duplicate event factory registration for "$eventType"');
    }
    _factories[eventType] = factory;
  }

  /// Registers an upcaster from schema version [fromVersion] to
  /// [fromVersion + 1]. Payloads are stepped through upcasters one version
  /// at a time; projectors only ever see the latest structure.
  void registerUpcaster({
    required String eventType,
    required int fromVersion,
    required LedgerEventUpcaster upcaster,
  }) {
    final key = _upcasterKey(eventType, fromVersion);
    if (_upcasters.containsKey(key)) {
      throw StateError(
          'Duplicate upcaster registration for "$key"');
    }
    _upcasters[key] = upcaster;
  }

  /// Applies registered upcasters to [payload] until it reaches
  /// [targetVersion] (default: current = no further upcaster registered).
  ///
  /// Throws [UnknownEventTypeError] if no factory exists for [eventType] —
  /// an event type nobody can read is a hard failure, not a skip.
  Map<String, dynamic> upcast(
    String eventType,
    Map<String, dynamic> payload, {
    int? targetVersion,
  }) {
    _requireFactory(eventType);

    var current = Map<String, dynamic>.from(payload);
    var version = _schemaVersionOf(current);
    final stop = targetVersion ?? _latestKnownVersion(eventType, version);

    while (version < stop) {
      final upcaster = _upcasters[_upcasterKey(eventType, version)];
      if (upcaster == null) break;
      current = upcaster(current);
      final newVersion = _schemaVersionOf(current);
      if (newVersion <= version) {
        throw StateError(
            'Upcaster for "$eventType" v$version did not advance '
            'schemaVersion (got v$newVersion)');
      }
      version = newVersion;
    }
    return current;
  }

  bool hasFactory(String eventType) => _factories.containsKey(eventType);

  void _requireFactory(String eventType) {
    if (!_factories.containsKey(eventType)) {
      throw UnknownEventTypeError(eventType, '(registry lookup)');
    }
  }

  /// Highest version reachable from [from] via registered upcasters.
  int _latestKnownVersion(String eventType, int from) {
    var version = from;
    while (_upcasters.containsKey(_upcasterKey(eventType, version))) {
      version++;
    }
    return version;
  }

  static int _schemaVersionOf(Map<String, dynamic> payload) =>
      payload['schemaVersion'] as int? ?? 1;

  static String _upcasterKey(String eventType, int fromVersion) =>
      '$eventType@$fromVersion';
}
