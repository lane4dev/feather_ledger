/// Base class for all ledger events.
/// Note: this is intentionally not `sealed` because concrete events live in
/// feature libraries across the app.
typedef LedgerEventFactory = LedgerEvent Function(Map<String, dynamic> json);

abstract class LedgerEvent {
  int? id;
  final String eventId;
  final DateTime occurredAt;
  final DateTime recordedAt;

  static final Map<String, LedgerEventFactory> _factories =
      <String, LedgerEventFactory>{};

  /// Registers a factory for a concrete event type.
  ///
  /// The [runtimeTypeName] must match what you persist in storage, which in
  /// this codebase is `event.runtimeType.toString()`.
  static void registerFactory(
    String runtimeTypeName,
    LedgerEventFactory factory,
  ) {
    _factories[runtimeTypeName] = factory;
  }

  /// Deserialize a ledger event by dispatching on the `runtimeType` field.
  static LedgerEvent fromJson(Map<String, dynamic> json) {
    final runtimeTypeValue = json['runtimeType'];
    if (runtimeTypeValue is! String || runtimeTypeValue.isEmpty) {
      throw const FormatException(
        'LedgerEvent.fromJson requires a non-empty `runtimeType` field',
      );
    }

    final factory = _factories[runtimeTypeValue];
    if (factory == null) {
      throw UnsupportedError(
        'No LedgerEvent factory registered for runtimeType: $runtimeTypeValue',
      );
    }

    return factory(json);
  }

  LedgerEvent({
    this.id,
    required this.eventId,
    required this.occurredAt,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson();

  /// Convenience for tests/debugging.
  static void clearFactoriesForTest() => _factories.clear();
}
