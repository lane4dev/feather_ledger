import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/features/ledger/data/event_sourcing/drift_event_store.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';

part 'get_transaction_history_query.g.dart';

/// One entry of a transaction's audit chain (spec 003, US6/T048): the
/// recorded event plus, for edited/deleted transactions, its reversal with
/// the reason. The chain is read from the event store — never reconstructed
/// from the projection.
class TransactionHistoryEntry {
  final String eventType;
  final DateTime occurredAt;
  final ReversalReason? reversalReason;

  const TransactionHistoryEntry({
    required this.eventType,
    required this.occurredAt,
    this.reversalReason,
  });
}

/// Reads the full event chain of one transaction, ordered by streamVersion.
class GetTransactionHistoryQuery {
  final EventStore _eventStore;

  GetTransactionHistoryQuery(this._eventStore);

  Future<List<TransactionHistoryEntry>> execute(String transactionId) async {
    final envelopes = await _eventStore.readStream(transactionId);
    return envelopes.map((e) {
      ReversalReason? reason;
      if (e.eventType == 'TransactionReversed') {
        // Read through the upcaster like the projector does (schema 演进).
        final payload = _eventStore.registry.upcast(e.eventType, e.payloadJson);
        reason = TransactionReversed.fromJson(payload).reason;
      }
      return TransactionHistoryEntry(
        eventType: e.eventType,
        occurredAt: e.occurredAt,
        reversalReason: reason,
      );
    }).toList();
  }
}

@riverpod
GetTransactionHistoryQuery getTransactionHistoryQuery(Ref ref) {
  return GetTransactionHistoryQuery(ref.watch(driftEventStoreProvider));
}

@riverpod
Future<List<TransactionHistoryEntry>> getTransactionHistory(
  Ref ref,
  String transactionId,
) {
  return ref.watch(getTransactionHistoryQueryProvider).execute(transactionId);
}
