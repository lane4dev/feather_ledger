import 'package:uuid/uuid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/features/ledger/data/event_sourcing/drift_event_store.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_projector.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import 'package:feather_ledger/features/ledger/domain/projections/ledger_projection.dart';

part 'create_account_command.g.dart';

/// Creates an account via `AccountCreated` (+ `OpeningBalanceSet` when the
/// initial balance is non-zero), projected in the same append transaction
/// (spec 003, US3/T027). The currency defaults to the global setting —
/// callers pass the effective currency code.
class CreateAccountCommand {
  final EventStore _eventStore;
  final LedgerProjector _projector;

  CreateAccountCommand(this._eventStore, this._projector);

  Future<void> execute({
    required String commandId,
    required String name,
    required AccountType type,
    required int initialBalanceMinor,
    required String currencyCode,
  }) async {
    final accountId = const Uuid().v4();
    final created = AccountCreated(
      accountId: accountId,
      name: name,
      type: type,
      currencyCode: currencyCode,
    );

    final envelopes = <EventEnvelope>[
      envelopeFor(
        created,
        aggregateType: AggregateType.account,
        streamVersion: 0,
        commandId: commandId,
        eventId: const Uuid().v4(),
      ),
      if (initialBalanceMinor != 0)
        envelopeFor(
          OpeningBalanceSet(
            accountId: accountId,
            amountMinor: initialBalanceMinor,
            currencyCode: currencyCode,
          ),
          aggregateType: AggregateType.account,
          streamVersion: 1,
          commandId: commandId,
          eventId: const Uuid().v4(),
        ),
    ];

    await _eventStore.append(
      envelopes,
      options: AppendOptions(apply: _projector.applyAll),
    );
  }
}

@riverpod
CreateAccountCommand createAccountCommand(Ref ref) {
  return CreateAccountCommand(
    ref.watch(driftEventStoreProvider),
    ref.watch(ledgerProjectorProvider),
  );
}
