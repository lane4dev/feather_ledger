import 'package:uuid/uuid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/event_sourcing/drift_event_store.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_projector.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import 'package:feather_ledger/features/ledger/domain/model/transaction.dart';
import 'package:feather_ledger/features/ledger/domain/projections/ledger_projection.dart';
import 'package:feather_ledger/features/ledger/domain/services/posting_context.dart';

part 'record_transaction_command.g.dart';

/// Records a transaction via `TransactionRecorded`, with
/// the projector applied in the same append transaction (spec 003,
/// US4/T035).
///
/// The command builds and validates the [Transaction] aggregate *before* the
/// event exists (ADR-0001), so a shape error is rejected here rather than by
/// a projector rollback. What may be recorded is context — does the account
/// exist, is it archived, does the category's kind match — and that resolves
/// through [PostingContextResolver].
class RecordTransactionCommand {
  final EventStore _eventStore;
  final LedgerProjector _projector;
  final PostingContextResolver _context;

  RecordTransactionCommand(
    this._eventStore,
    this._projector,
    this._context,
  );

  Future<void> execute({
    required String commandId,
    required int amountMinor,
    required TransactionKind kind,
    required DateTime occurredAt,
    required String categoryId,
    required String accountId,
    String? note,
  }) async {
    // Describes this entry point, not the transaction: transfers and balance
    // purposes have their own category-free construction paths.
    if (!kind.requiresCategory) {
      throw const CommandRejected(LedgerErrorCode.invalidTransactionShape,
          'only income and expense use execute');
    }

    final context = await _context.resolveForKind(
      accountId: accountId,
      categoryId: categoryId,
      kind: kind,
    );

    final transactionId = const Uuid().v4();
    final transaction = kind == TransactionKind.income
        ? Transaction.income(
            transactionId: transactionId,
            occurredAt: occurredAt,
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
            occurredAt: occurredAt,
            amountMinor: amountMinor,
            accountId: context.account.id,
            currencyCode: context.account.currencyCode,
            categoryId: context.category!.id,
            description: note ?? '',
            notes: note,
            memo: note,
          );

    transaction.validateOrThrow();
    await _append(transaction, commandId);
  }

  /// Records a transfer (kind=transfer): one debit posting on
  /// [fromAccountId] and one equal credit posting on [toAccountId] — net
  /// zero by construction (spec 003, US5/T040). Credit-card repayment is
  /// simply a savings→credit transfer; no separate model exists.
  Future<void> executeTransfer({
    required String commandId,
    required int amountMinor,
    required DateTime occurredAt,
    required String fromAccountId,
    required String toAccountId,
    String? note,
  }) async {
    final context = await _context.resolveForTransfer(
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
    );

    final transaction = Transaction.transfer(
      transactionId: const Uuid().v4(),
      occurredAt: occurredAt,
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
    transaction.validateOrThrow();
    await _append(transaction, commandId);
  }

  /// Records a non-zero opening balance without inventing income, expense or
  /// a category. The transaction stream remains the sole source for the
  /// balance and ledger row.
  Future<void> executeOpeningBalance({
    required String commandId,
    required int signedAmountMinor,
    required DateTime occurredAt,
    required String accountId,
    String? note,
  }) =>
      _executeBalancePurpose(
        commandId: commandId,
        signedAmountMinor: signedAmountMinor,
        occurredAt: occurredAt,
        accountId: accountId,
        note: note,
        kind: TransactionKind.openingBalance,
      );

  /// Records the difference produced by a reconciliation or explicit balance
  /// calibration. It is separate from an opening balance in the event data
  /// and in downstream report semantics.
  Future<void> executeBalanceAdjustment({
    required String commandId,
    required int signedAmountMinor,
    required DateTime occurredAt,
    required String accountId,
    String? note,
  }) =>
      _executeBalancePurpose(
        commandId: commandId,
        signedAmountMinor: signedAmountMinor,
        occurredAt: occurredAt,
        accountId: accountId,
        note: note,
        kind: TransactionKind.balanceAdjustment,
      );

  Future<void> _executeBalancePurpose({
    required String commandId,
    required int signedAmountMinor,
    required DateTime occurredAt,
    required String accountId,
    required String? note,
    required TransactionKind kind,
  }) async {
    if (!kind.isBalancePurpose || signedAmountMinor == 0) {
      throw const CommandRejected(LedgerErrorCode.invalidAmount,
          'a balance-purpose transaction needs a non-zero signed amount');
    }
    final context =
        await _context.resolveForBalancePurpose(accountId: accountId);
    final transaction = kind == TransactionKind.openingBalance
        ? Transaction.openingBalance(
            transactionId: const Uuid().v4(),
            occurredAt: occurredAt,
            signedAmountMinor: signedAmountMinor,
            accountId: context.account.id,
            currencyCode: context.account.currencyCode,
            description: note ?? '',
            notes: note,
          )
        : Transaction.balanceAdjustment(
            transactionId: const Uuid().v4(),
            occurredAt: occurredAt,
            signedAmountMinor: signedAmountMinor,
            accountId: context.account.id,
            currencyCode: context.account.currencyCode,
            description: note ?? '',
            notes: note,
          );
    transaction.validateOrThrow();
    await _append(transaction, commandId);
  }

  /// The validated aggregate is what gets persisted, so the event cannot
  /// drift from the shape that was checked.
  Future<void> _append(Transaction transaction, String commandId) async {
    await _eventStore.append(
      [
        envelopeFor(
          TransactionRecorded(
            transactionId: transaction.transactionId,
            occurredAt: transaction.occurredAt,
            kind: transaction.kind,
            description: transaction.description,
            notes: transaction.notes,
            postings: transaction.postings,
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
RecordTransactionCommand recordTransactionCommand(Ref ref) {
  return RecordTransactionCommand(
    ref.watch(driftEventStoreProvider),
    ref.watch(ledgerProjectorProvider),
    ref.watch(postingContextResolverProvider),
  );
}
