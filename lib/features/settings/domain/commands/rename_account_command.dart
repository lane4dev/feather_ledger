import 'package:uuid/uuid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/event_sourcing/drift_event_store.dart';

import 'package:feather_ledger/features/ledger/data/projections/ledger_projector.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import 'package:feather_ledger/features/ledger/domain/projections/ledger_projection.dart';

part 'rename_account_command.g.dart';

/// Renames an account via `AccountRenamed` (spec 003, US3/T027).
class RenameAccountCommand {
  final EventStore _eventStore;
  final LedgerProjector _projector;

  RenameAccountCommand(this._eventStore, this._projector);

  Future<void> execute({
    required String commandId,
    required String accountId,
    required String name,
  }) async {
    if (!await _accountExists(accountId)) {
      throw CommandRejected(
          LedgerErrorCode.accountNotFound, 'Account $accountId not found');
    }

    final event = AccountRenamed(accountId: accountId, name: name);
    await _eventStore.append(
      [
        envelopeFor(
          event,
          aggregateType: AggregateType.account,
          streamVersion: await nextStreamVersion(_eventStore, accountId),
          commandId: commandId,
          eventId: const Uuid().v4(),
        ),
      ],
      options: AppendOptions(apply: _projector.applyAll),
    );
  }

  Future<bool> _accountExists(String accountId) async =>
      (await _eventStore.readStream(accountId)).isNotEmpty;
}

@riverpod
RenameAccountCommand renameAccountCommand(Ref ref) {
  return RenameAccountCommand(
    ref.watch(driftEventStoreProvider),
    ref.watch(ledgerProjectorProvider),
  );
}
