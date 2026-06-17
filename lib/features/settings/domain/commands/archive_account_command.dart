import 'package:uuid/uuid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/event_sourcing/drift_event_store.dart';

import 'package:feather_ledger/features/ledger/data/projections/ledger_projector.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import 'package:feather_ledger/features/ledger/domain/projections/ledger_projection.dart';

part 'archive_account_command.g.dart';

/// Archives an account via `AccountArchived` (spec 003, US3/T027) — soft
/// delete; history and balance stay in the projection.
class ArchiveAccountCommand {
  final EventStore _eventStore;
  final LedgerProjector _projector;

  ArchiveAccountCommand(this._eventStore, this._projector);

  Future<void> execute({
    required String commandId,
    required String accountId,
  }) async {
    if (!await _accountExists(accountId)) {
      throw CommandRejected(
          LedgerErrorCode.accountNotFound, 'Account $accountId not found');
    }

    final event = AccountArchived(accountId: accountId);
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
ArchiveAccountCommand archiveAccountCommand(Ref ref) {
  return ArchiveAccountCommand(
    ref.watch(driftEventStoreProvider),
    ref.watch(ledgerProjectorProvider),
  );
}
