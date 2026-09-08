import 'package:uuid/uuid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/data/repositories/account_repository.dart';
import 'package:feather_ledger/core/data/repositories/category_repository.dart';
import 'package:feather_ledger/features/ledger/data/event_sourcing/drift_event_store.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_projector.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import 'package:feather_ledger/features/ledger/domain/model/transaction.dart';
import 'package:feather_ledger/features/ledger/domain/projections/ledger_projection.dart';

part 'record_transaction_command.g.dart';

/// Records an income/expense transaction via `TransactionRecorded`, with
/// the projector applied in the same append transaction (spec 003,
/// US4/T035).
///
/// Domain validations (spec Command Model): account and category exist,
/// neither is archived, the category type matches the transaction kind, and
/// the amount is positive. Rejections throw [CommandRejected] with a
/// presentable [LedgerErrorCode].
class RecordTransactionCommand {
  final EventStore _eventStore;
  final LedgerProjector _projector;
  final AccountRepository _accountRepository;
  final CategoryRepository _categoryRepository;

  RecordTransactionCommand(
    this._eventStore,
    this._projector,
    this._accountRepository,
    this._categoryRepository,
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
    if (kind == TransactionKind.transfer) {
      throw const CommandRejected(LedgerErrorCode.invalidTransfer,
          'transfers go through executeTransfer');
    }
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
    final expectedType = kind == TransactionKind.income
        ? CategoryType.income
        : CategoryType.expense;
    if (category.type != expectedType) {
      throw CommandRejected(LedgerErrorCode.categoryTypeMismatch,
          'Category $categoryId is ${category.type.name}, expected '
          '${expectedType.name}');
    }

    final transactionId = const Uuid().v4();
    final direction = kind == TransactionKind.income
        ? PostingDirection.credit
        : PostingDirection.debit;
    final event = TransactionRecorded(
      transactionId: transactionId,
      occurredAt: occurredAt,
      kind: kind,
      description: note ?? '',
      notes: note,
      postings: [
        Posting(
          accountId: accountId,
          direction: direction,
          amountMinor: amountMinor,
          // Single-currency per transaction: copied from the account at
          // write time (spec 红线).
          currencyCode: account.currencyCode,
          categoryId: categoryId,
          memo: note,
        ),
      ],
    );

    await _append(event, commandId);
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
    if (amountMinor <= 0) {
      throw const CommandRejected(
          LedgerErrorCode.invalidAmount, 'amountMinor must be positive');
    }
    if (fromAccountId == toAccountId) {
      throw const CommandRejected(
          LedgerErrorCode.sameAccountTransfer, 'transfer needs two accounts');
    }

    final from = await _accountRepository.getAccount(fromAccountId);
    if (from == null) {
      throw CommandRejected(LedgerErrorCode.accountNotFound,
          'Account $fromAccountId not found');
    }
    if (from.archived) {
      throw CommandRejected(LedgerErrorCode.accountArchived,
          'Account $fromAccountId is archived');
    }
    final to = await _accountRepository.getAccount(toAccountId);
    if (to == null) {
      throw CommandRejected(
          LedgerErrorCode.accountNotFound, 'Account $toAccountId not found');
    }
    if (to.archived) {
      throw CommandRejected(
          LedgerErrorCode.accountArchived, 'Account $toAccountId is archived');
    }
    // Single-currency per transaction (spec 红线): balances must never be
    // merged across currencies.
    if (from.currencyCode != to.currencyCode) {
      throw const CommandRejected(LedgerErrorCode.currencyMismatch,
          'transfer across currencies is rejected');
    }

    final transactionId = const Uuid().v4();
    final event = TransactionRecorded(
      transactionId: transactionId,
      occurredAt: occurredAt,
      kind: TransactionKind.transfer,
      description: note ?? '',
      notes: note,
      postings: [
        Posting(
          accountId: fromAccountId,
          direction: PostingDirection.debit,
          amountMinor: amountMinor,
          currencyCode: from.currencyCode,
        ),
        Posting(
          accountId: toAccountId,
          direction: PostingDirection.credit,
          amountMinor: amountMinor,
          currencyCode: to.currencyCode,
        ),
      ],
    );

    await _append(event, commandId);
  }

  Future<void> _append(TransactionRecorded event, String commandId) async {
    await _eventStore.append(
      [
        envelopeFor(
          event,
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
    ref.watch(accountRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  );
}
