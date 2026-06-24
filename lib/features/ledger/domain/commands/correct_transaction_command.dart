import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/core/domain/result/result.dart';

import '../../data/event_sourcing/drift_event_store.dart';
import '../../data/projections/ledger_projector.dart';
import '../../data/repositories/ledger_repository.dart';
import '../../domain/entities/ledger_entities.dart';
import '../../domain/events/ledger_events.dart';
import '../../domain/model/transaction.dart';
import '../../domain/projections/ledger_projection.dart';
import '../../domain/services/posting_context.dart';

part 'correct_transaction_command.g.dart';

/// Edit (spec 003, US6/T046): one command produces the paired events
/// `TransactionReversed(correction)` on the original's stream + a fresh
/// `TransactionRecorded` — both appended and projected in one database
/// transaction. The original's audit chain is preserved and the pair's
/// balance impact cancels out.
///
/// **The original's kind picks the path**, not the incoming arguments
/// (spec 004, FR-004): an income/expense original goes through [execute], a
/// transfer original through [executeTransfer]. Each rejects the other. The
/// earlier version of this guard tested only the *incoming* `type`, so
/// correcting a transfer as income passed — the reversal cancelled both legs
/// and a single-sided income landed, mirroring the two accounts instead of
/// correcting them. Say "this is a different transaction, delete and re-add
/// it" rather than "fixing" the asymmetry below: converting an expense into a
/// transfer is not an edit, it is a different money movement.
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

  /// Corrects an income or expense. A transfer original must use
  /// [executeTransfer].
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
    final original = await _loadCorrectable(originalTransactionId);
    if (original.type == TransactionKind.transfer) {
      throw const CommandRejected(LedgerErrorCode.invalidTransfer,
          'a transfer original must be corrected through executeTransfer');
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
    await _appendCorrection(
      originalTransactionId: originalTransactionId,
      replacement: replacement,
      commandId: commandId,
    );
  }

  /// Corrects a transfer (spec 004, US1): same reversal + replacement pair,
  /// with the replacement built through [Transaction.transfer] so the two-leg
  /// shape is the aggregate's business, not this command's.
  ///
  /// An income/expense original must use [execute].
  Future<void> executeTransfer({
    required String commandId,
    required String originalTransactionId,
    required int amountMinor,
    required DateTime date,
    required String fromAccountId,
    required String toAccountId,
    String? note,
  }) async {
    final original = await _loadCorrectable(originalTransactionId);
    if (original.type != TransactionKind.transfer) {
      throw const CommandRejected(LedgerErrorCode.invalidTransfer,
          'only a transfer original can be corrected as a transfer');
    }

    final context = await _context.resolveForTransfer(
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
    );

    final replacement = Transaction.transfer(
      transactionId: const Uuid().v4(),
      occurredAt: date,
      amountMinor: amountMinor,
      fromAccountId: context.account.id,
      fromCurrencyCode: context.account.currencyCode,
      toAccountId: context.counterAccount!.id,
      toCurrencyCode: context.counterAccount!.currencyCode,
      description: note ?? '',
      notes: note,
    );

    // Same account, mismatched currencies and the two-leg shape are all
    // aggregate invariants — never re-checked here.
    replacement.validateOrThrow();
    await _appendCorrection(
      originalTransactionId: originalTransactionId,
      replacement: replacement,
      commandId: commandId,
    );
  }

  /// Loads the transaction being corrected and applies the two guards that do
  /// not depend on the replacement's shape. Returns it so the caller can read
  /// its kind — which is what decides the legal path.
  Future<TransactionEntity> _loadCorrectable(
      String originalTransactionId) async {
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
    return original;
  }

  /// Paired events, one command, one append transaction (spec Event Model):
  /// the reversal lands on the original's stream, the replacement starts a
  /// new stream.
  ///
  /// **The two envelopes must stay in a single `append` call.** Splitting them
  /// would let a crash land the reversal without its replacement, and the
  /// ledger would read as if the transaction had simply vanished. Both carry
  /// the same `commandId` on purpose — see AGENTS.md.
  Future<void> _appendCorrection({
    required String originalTransactionId,
    required Transaction replacement,
    required String commandId,
  }) async {
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
