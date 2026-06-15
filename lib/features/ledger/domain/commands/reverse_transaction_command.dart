import 'package:uuid/uuid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/event_sourcing/drift_event_store.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_projector.dart';
import 'package:feather_ledger/features/ledger/data/repositories/ledger_repository.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import 'package:feather_ledger/features/ledger/domain/projections/ledger_projection.dart';

part 'reverse_transaction_command.g.dart';

/// UI delete (spec 003, US6/T046): appends `TransactionReversed
/// (userDeleted)` and applies the projector in the same append transaction —
/// the row is hidden and its balance impact is undone. Only live
/// (non-reversed) transactions can be reversed.
class ReverseTransactionCommand {
  final EventStore _eventStore;
  final LedgerProjector _projector;
  final LedgerRepository _ledgerRepository;

  ReverseTransactionCommand(
    this._eventStore,
    this._projector,
    this._ledgerRepository,
  );

  Future<void> execute(
    String originalTransactionId, {
    required String commandId,
  }) async {
    final original =
        await _ledgerRepository.getTransaction(originalTransactionId);
    if (original == null) {
      throw CommandRejected(LedgerErrorCode.transactionNotFound,
          'Transaction $originalTransactionId not found');
    }
    if (original.isReversed) {
      throw CommandRejected(LedgerErrorCode.transactionAlreadyReversed,
          'Transaction $originalTransactionId is already reversed');
    }

    final event = TransactionReversed(
      originalTransactionId: originalTransactionId,
      reason: ReversalReason.userDeleted,
    );

    await _eventStore.append(
      [
        envelopeFor(
          event,
          aggregateType: AggregateType.transaction,
          streamVersion:
              await nextStreamVersion(_eventStore, originalTransactionId),
          commandId: commandId,
          eventId: const Uuid().v4(),
        ),
      ],
      options: AppendOptions(apply: _projector.applyAll),
    );
  }
}

@riverpod
ReverseTransactionCommand reverseTransactionCommand(Ref ref) {
  return ReverseTransactionCommand(
    ref.watch(driftEventStoreProvider),
    ref.watch(ledgerProjectorProvider),
    ref.watch(ledgerRepositoryProvider),
  );
}
