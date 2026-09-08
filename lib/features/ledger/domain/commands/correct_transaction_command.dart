import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/data/repositories/account_repository.dart';
import 'package:feather_ledger/core/data/repositories/category_repository.dart';

import '../../data/event_sourcing/drift_event_store.dart';
import '../../data/projections/ledger_projector.dart';
import '../../data/repositories/ledger_repository.dart';
import '../../domain/events/ledger_events.dart';
import '../../domain/model/transaction.dart';
import '../../domain/projections/ledger_projection.dart';

part 'correct_transaction_command.g.dart';

/// Edit (spec 003, US6/T046): one command produces the paired events
/// `TransactionReversed(correction)` on the original's stream + a fresh
/// `TransactionRecorded` — both appended and projected in one database
/// transaction. The original's audit chain is preserved and the pair's
/// balance impact cancels out. Only live transactions can be corrected;
/// transfers have no edit form and are rejected.
class CorrectTransactionCommand {
  final EventStore _eventStore;
  final LedgerProjector _projector;
  final LedgerRepository _ledgerRepository;
  final AccountRepository _accountRepository;
  final CategoryRepository _categoryRepository;

  CorrectTransactionCommand(
    this._eventStore,
    this._projector,
    this._ledgerRepository,
    this._accountRepository,
    this._categoryRepository,
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

    // New values pass the same validations as a fresh record (US4/T035).
    if (amountMinor <= 0) {
      throw const CommandRejected(
          LedgerErrorCode.invalidAmount, 'amountMinor must be positive');
    }
    final account = await _accountRepository.getAccount(accountId);
    if (account == null) {
      throw CommandRejected(
          LedgerErrorCode.accountNotFound, 'Account $accountId not found');
    }
    if (account.archived) {
      throw CommandRejected(
          LedgerErrorCode.accountArchived, 'Account $accountId is archived');
    }
    final category = await _categoryRepository.getCategory(categoryId);
    if (category == null) {
      throw CommandRejected(
          LedgerErrorCode.categoryNotFound, 'Category $categoryId not found');
    }
    if (category.archived) {
      throw CommandRejected(
          LedgerErrorCode.categoryArchived, 'Category $categoryId is archived');
    }
    final expectedType = type == TransactionKind.income
        ? CategoryType.income
        : CategoryType.expense;
    if (category.type != expectedType) {
      throw CommandRejected(LedgerErrorCode.categoryTypeMismatch,
          'Category $categoryId is ${category.type.name}, expected '
          '${expectedType.name}');
    }

    final transactionId = const Uuid().v4();
    final direction = type == TransactionKind.income
        ? PostingDirection.credit
        : PostingDirection.debit;

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
            transactionId: transactionId,
            occurredAt: date,
            kind: type,
            description: note ?? '',
            notes: note,
            postings: [
              Posting(
                accountId: accountId,
                direction: direction,
                amountMinor: amountMinor,
                currencyCode: account.currencyCode,
                categoryId: categoryId,
                memo: note,
              ),
            ],
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
    ref.watch(accountRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  );
}
