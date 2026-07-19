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

/// Creates an account via `AccountCreated`, projected in the same append
/// transaction (spec 003, US3/T027). The currency defaults to the global
/// setting — callers pass the effective currency code.
///
/// **The account starts empty, always.** A starting balance is not an
/// [OpeningBalanceSet] here any more: [AccountService.createAccount] records
/// it as an ordinary correction transaction instead, so the money shows up in
/// the ledger and reads exactly like every later adjustment of the same
/// account. Money that existed nowhere but a balance column was the older
/// shape, and it was indistinguishable from money appearing from nowhere.
/// (`OpeningBalanceSet` remains in the catalog and still projects — streams
/// written before this carry it.)
///
/// Returns the new account's id so the caller can write against it in the
/// same breath.
class CreateAccountCommand {
  final EventStore _eventStore;
  final LedgerProjector _projector;

  CreateAccountCommand(this._eventStore, this._projector);

  Future<String> execute({
    required String commandId,
    required String name,
    required AccountType type,
    required String currencyCode,
  }) async {
    final accountId = const Uuid().v4();
    final created = AccountCreated(
      accountId: accountId,
      name: name,
      type: type,
      currencyCode: currencyCode,
    );

    await _eventStore.append(
      <EventEnvelope>[
        envelopeFor(
          created,
          aggregateType: AggregateType.account,
          streamVersion: 0,
          commandId: commandId,
          eventId: const Uuid().v4(),
        ),
      ],
      options: AppendOptions(apply: _projector.applyAll),
    );

    return accountId;
  }
}

@riverpod
CreateAccountCommand createAccountCommand(Ref ref) {
  return CreateAccountCommand(
    ref.watch(driftEventStoreProvider),
    ref.watch(ledgerProjectorProvider),
  );
}
