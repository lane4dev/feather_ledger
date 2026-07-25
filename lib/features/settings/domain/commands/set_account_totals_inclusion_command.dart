import 'package:uuid/uuid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/event_sourcing/drift_event_store.dart';

import 'package:feather_ledger/features/ledger/data/projections/ledger_projector.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import 'package:feather_ledger/features/ledger/domain/projections/ledger_projection.dart';

part 'set_account_totals_inclusion_command.g.dart';

/// Includes an account in, or takes it out of, the **ledger totals**
/// (CONTEXT.md) via `AccountTotalsInclusionChanged`.
///
/// A flag and nothing else: no balance moves, no snapshot row changes, and
/// the figures follow at read time. See the event's own doc for why.
class SetAccountTotalsInclusionCommand {
  final EventStore _eventStore;
  final LedgerProjector _projector;

  SetAccountTotalsInclusionCommand(this._eventStore, this._projector);

  Future<void> execute({
    required String commandId,
    required String accountId,
    required bool includeInTotals,
  }) async {
    if (!await _accountExists(accountId)) {
      throw CommandRejected(
          LedgerErrorCode.accountNotFound, 'Account $accountId not found');
    }

    final event = AccountTotalsInclusionChanged(
      accountId: accountId,
      includeInTotals: includeInTotals,
    );
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
SetAccountTotalsInclusionCommand setAccountTotalsInclusionCommand(Ref ref) {
  return SetAccountTotalsInclusionCommand(
    ref.watch(driftEventStoreProvider),
    ref.watch(ledgerProjectorProvider),
  );
}
