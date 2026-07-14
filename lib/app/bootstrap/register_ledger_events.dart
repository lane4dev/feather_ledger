/// Bootstrap registration of the final ledger event catalog (spec 003, US2/T021).
///
/// Registers the nine event payloads of
/// `lib/features/ledger/domain/events/ledger_events.dart` into the shared
/// production [EventTypeRegistry]. `main()` calls [registerLedgerEvents]
/// eagerly at startup; tests inherit this registration instead of
/// hand-registering factories (the old `LedgerEvent.registerFactory`
/// pattern is gone with the legacy event repository in T024).
///
/// One upcaster exists: `CategoryCreated` v1→v2, because the app's icons moved
/// from Material to Lucide and v1 payloads named a Material code point. The
/// rule stands — a payload is never silently reshaped; a change in what a
/// field *means* is a version bump plus an entry here.
library;

import 'package:feather_ledger/core/domain/event_sourcing/event_type_registry.dart';
import 'package:feather_ledger/app/theme/category_tokens.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  // v1 named a Material Icons code point; v2 names a Lucide one. Translating
  // rather than leaving it alone is the difference between an old ledger
  // rebuilding to the right icons and rebuilding to whatever glyph happens to
  // sit at a Material number.
  ledgerEventRegistry.registerUpcaster(
    eventType: 'CategoryCreated',
    fromVersion: 1,
    upcaster: (old) {
      final legacy = int.tryParse(old['iconKey'] as String? ?? '');
      final translated = legacy == null
          ? LucideIcons.tag.codePoint
          : CategoryTokens.legacyIconCodePoints[legacy] ??
              LucideIcons.tag.codePoint;
      return {...old, 'schemaVersion': 2, 'iconKey': '$translated'};
    },
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
