import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/core/domain/result/result.dart';

import '../../data/event_sourcing/drift_event_store.dart';
import '../../data/projections/ledger_projector.dart';
import '../../data/repositories/ledger_repository.dart';
import '../../domain/events/ledger_events.dart';
import '../../domain/model/transaction.dart';
import '../../domain/projections/ledger_projection.dart';
import '../../domain/services/posting_context.dart';

part 'correct_transaction_command.g.dart';

/// Edit (spec 003, US6/T046): one command produces the paired events
/// `TransactionReversed(correction)` on the original's stream + a fresh
/// `TransactionRecorded` — both appended and projected in one database
/// transaction. The original's audit chain is preserved and the pair's
/// balance impact cancels out. Only live transactions can be corrected;
/// transfers have no edit form and are rejected.
///
/// The replacement is built and validated as a [Transaction] before either
/// event exists (ADR-0001).
class CorrectTransactionCommand {
  final EventStore _eventStore;
  final LedgerProjector _projector;
  final LedgerRepository _ledgerRepository;
  final PostingContextResolver _context;

  CorrectTransactionCommand(
    this._eventStore,
    this._projector,
    this._ledgerRepository,
    this._context,
  );

  Future<void> execute({
    required String commandId,
    required String originalTransactionId,
    required int amountMinor,
    required TransactionKind type,
    required DateTime date,
    required String categoryId,
    required String accountId,
    String? note,
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
    if (type == TransactionKind.transfer) {
      throw const CommandRejected(
          LedgerErrorCode.invalidTransfer, 'transfers cannot be corrected');
    }

    final context = await _context.resolveForKind(
      accountId: accountId,
      categoryId: categoryId,
      kind: type,
    );

    final transactionId = const Uuid().v4();
    final replacement = type == TransactionKind.income
        ? Transaction.income(
            transactionId: transactionId,
            occurredAt: date,
            amountMinor: amountMinor,
            accountId: context.account.id,
            currencyCode: context.account.currencyCode,
            categoryId: context.category!.id,
            description: note ?? '',
            notes: note,
            memo: note,
          )
        : Transaction.expense(
            transactionId: transactionId,
            occurredAt: date,
            amountMinor: amountMinor,
            accountId: context.account.id,
            currencyCode: context.account.currencyCode,
            categoryId: context.category!.id,
            description: note ?? '',
            notes: note,
            memo: note,
          );

    replacement.validateOrThrow();

    // Paired events, one command, one append transaction (spec Event Model):
    // the reversal lands on the original's stream, the replacement starts a
    // new stream.
    await _eventStore.append(
      [
        envelopeFor(
          TransactionReversed(
            originalTransactionId: originalTransactionId,
            reason: ReversalReason.correction,
          ),
          aggregateType: AggregateType.transaction,
          streamVersion:
              await nextStreamVersion(_eventStore, originalTransactionId),
          commandId: commandId,
          eventId: const Uuid().v4(),
        ),
        envelopeFor(
          TransactionRecorded(
            transactionId: replacement.transactionId,
            occurredAt: replacement.occurredAt,
            kind: replacement.kind,
            description: replacement.description,
            notes: replacement.notes,
            postings: replacement.postings,
          ),
          aggregateType: AggregateType.transaction,
          streamVersion: 0,
          commandId: commandId,
          eventId: const Uuid().v4(),
        ),
      ],
      options: AppendOptions(apply: _projector.applyAll),
    );
  }
}

@riverpod
CorrectTransactionCommand correctTransactionCommand(Ref ref) {
  return CorrectTransactionCommand(
    ref.watch(driftEventStoreProvider),
    ref.watch(ledgerProjectorProvider),
    ref.watch(ledgerRepositoryProvider),
    ref.watch(postingContextResolverProvider),
  );
}
