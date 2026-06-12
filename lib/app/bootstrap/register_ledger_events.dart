/// Bootstrap registration of the final ledger event catalog (spec 003, US2/T021).
///
/// Registers the nine event payloads of
/// `lib/features/ledger/domain/events/ledger_events.dart` into the shared
/// production [EventTypeRegistry]. `main()` calls [registerLedgerEvents]
/// eagerly at startup; tests inherit this registration instead of
/// hand-registering factories (the old `LedgerEvent.registerFactory`
/// pattern is gone with the legacy event repository in T024).
///
/// No upcasters exist yet: every payload is schemaVersion 1. The first
/// payload change adds `registerUpcaster` entries here — never silently
/// reshape a persisted payload.
library;

import 'package:feather_ledger/core/domain/event_sourcing/event_type_registry.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';

/// The shared production registry. Lazy top-level: first access registers.
final EventTypeRegistry ledgerEventRegistry = EventTypeRegistry();

var _registered = false;

/// Idempotent: safe for `main()` and tests to both call.
void registerLedgerEvents() {
  if (_registered) return;
  _registered = true;

  // Transaction stream
  ledgerEventRegistry.registerFactory(
    eventType: 'TransactionRecorded',
    factory: (json) => TransactionRecorded.fromJson(json).toJson(),
  );
  ledgerEventRegistry.registerFactory(
    eventType: 'TransactionReversed',
    factory: (json) => TransactionReversed.fromJson(json).toJson(),
  );

  // Account stream
  ledgerEventRegistry.registerFactory(
    eventType: 'AccountCreated',
    factory: (json) => AccountCreated.fromJson(json).toJson(),
  );
  ledgerEventRegistry.registerFactory(
    eventType: 'AccountRenamed',
    factory: (json) => AccountRenamed.fromJson(json).toJson(),
  );
  ledgerEventRegistry.registerFactory(
    eventType: 'AccountArchived',
    factory: (json) => AccountArchived.fromJson(json).toJson(),
  );

  // Category stream
  ledgerEventRegistry.registerFactory(
    eventType: 'CategoryCreated',
    factory: (json) => CategoryCreated.fromJson(json).toJson(),
  );
  ledgerEventRegistry.registerFactory(
    eventType: 'CategoryRenamed',
    factory: (json) => CategoryRenamed.fromJson(json).toJson(),
  );
  ledgerEventRegistry.registerFactory(
    eventType: 'CategoryArchived',
    factory: (json) => CategoryArchived.fromJson(json).toJson(),
  );

  // Account opening balance
  ledgerEventRegistry.registerFactory(
    eventType: 'OpeningBalanceSet',
    factory: (json) => OpeningBalanceSet.fromJson(json).toJson(),
  );
}
