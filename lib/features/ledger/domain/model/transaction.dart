/// Single Transaction + Postings domain model (spec 003, Domain Model).
///
/// One model covers every money movement: income = kind income + one credit
/// posting; expense = kind expense + one debit posting; transfer = kind
/// transfer + one debit and one credit posting (equal amounts, different
/// accounts, same currency → net zero).
///
/// `direction` semantics are personal-bookkeeping semantics, not strict
/// double-entry accounting, and are defined *only here*: credit = balance
/// increases by amountMinor, debit = balance decreases by amountMinor.
///
/// Two doors (ADR-0001): [Transaction.expense] / [.income] / [.transfer]
/// build a legal shape from intent and are what commands use;
/// [Transaction.rehydrate] rebuilds a stored one for replay. The aggregate is
/// validated by the writer *before* the event is built, so a shape error is
/// rejected by the command rather than by a rollback.
library;

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';

export 'package:feather_ledger/core/domain/enums.dart'
    show TransactionKind, PostingDirection;

/// One money movement against one account.
///
/// [amountMinor] is always positive; direction carries the sign. The
/// currency is copied from the account at write time (per-transaction
/// single-currency is validated by commands).
class Posting {
  final String accountId;
  final PostingDirection direction;

  /// Strictly positive int minor units.
  final int amountMinor;
  final String currencyCode;
  final String? categoryId;
  final String? memo;

  const Posting({
    required this.accountId,
    required this.direction,
    required this.amountMinor,
    required this.currencyCode,
    this.categoryId,
    this.memo,
  });

  /// Signed balance impact: +amountMinor for credit, -amountMinor for
  /// debit. This is the only place the sign convention is derived.
  int get signedImpact =>
      direction == PostingDirection.credit ? amountMinor : -amountMinor;

  Map<String, dynamic> toJson() => {
        'accountId': accountId,
        'direction': direction.name,
        'amountMinor': amountMinor,
        'currencyCode': currencyCode,
        if (categoryId != null) 'categoryId': categoryId,
        if (memo != null) 'memo': memo,
      };

  factory Posting.fromJson(Map<String, dynamic> json) => Posting(
        accountId: json['accountId'] as String,
        direction: PostingDirection.values.byName(json['direction'] as String),
        amountMinor: json['amountMinor'] as int,
        currencyCode: json['currencyCode'] as String,
        categoryId: json['categoryId'] as String?,
        memo: json['memo'] as String?,
      );
}

/// A shape rule the transaction breaks. Produced by [Transaction.validate].
///
/// Distinct from [LedgerErrorCode]: several violations share one user-facing
/// code, and a violation is a domain judgement, not a message.
enum TransactionViolation {
  postingsEmpty,
  amountNotPositive,
  postingCount,
  postingDirection,
  transferDirections,
  transferAmounts,
  transferSameAccount,
  transferCurrency,
}

extension TransactionViolationCode on TransactionViolation {
  /// The user-facing code this violation surfaces as.
  LedgerErrorCode get errorCode => switch (this) {
        TransactionViolation.amountNotPositive => LedgerErrorCode.invalidAmount,
        TransactionViolation.transferSameAccount =>
          LedgerErrorCode.sameAccountTransfer,
        TransactionViolation.transferCurrency =>
          LedgerErrorCode.currencyMismatch,
        TransactionViolation.transferDirections ||
        TransactionViolation.transferAmounts =>
          LedgerErrorCode.invalidTransfer,
        // Unreachable through the intent constructors; a structural failure
        // here means a writer went around them.
        TransactionViolation.postingsEmpty ||
        TransactionViolation.postingCount ||
        TransactionViolation.postingDirection =>
          LedgerErrorCode.invalidTransactionShape,
      };

  /// The write path's rejection of this violation.
  CommandRejected toRejection() => CommandRejected(
        errorCode,
        'Transaction violates its shape contract: $name',
      );
}

/// Aggregate root. Invariants (validated in [Transaction.validate]):
/// - postings is non-empty,
/// - income/expense have exactly 1 posting,
/// - transfer has exactly 2 postings with opposite directions, equal
///   positive amounts, distinct accounts and identical currencies,
/// - all amounts are positive minor units.
class Transaction {
  final String transactionId;

  /// Business date.
  final DateTime occurredAt;
  final String description;
  final TransactionKind kind;
  final String? notes;
  final List<Posting> postings;

  /// Rebuilds an already-recorded transaction (replay only).
  ///
  /// Accepts any shape on purpose — the projector validates what it
  /// rehydrates, so a corrupted stored stream is caught rather than
  /// silently projected. New writes use the intent constructors below.
  const Transaction.rehydrate({
    required this.transactionId,
    required this.occurredAt,
    required this.description,
    required this.kind,
    this.notes,
    required this.postings,
  });

  /// A single expense: one debit posting of a positive amount.
  factory Transaction.expense({
    required String transactionId,
    required DateTime occurredAt,
    required int amountMinor,
    required String accountId,
    required String currencyCode,
    required String categoryId,
    String description = '',
    String? notes,
    String? memo,
  }) =>
      Transaction.rehydrate(
        transactionId: transactionId,
        occurredAt: occurredAt,
        description: description,
        kind: TransactionKind.expense,
        notes: notes,
        postings: [
          Posting(
            accountId: accountId,
            direction: PostingDirection.debit,
            amountMinor: amountMinor,
            currencyCode: currencyCode,
            categoryId: categoryId,
            memo: memo,
          ),
        ],
      );

  /// A single income: one credit posting of a positive amount.
  factory Transaction.income({
    required String transactionId,
    required DateTime occurredAt,
    required int amountMinor,
    required String accountId,
    required String currencyCode,
    required String categoryId,
    String description = '',
    String? notes,
    String? memo,
  }) =>
      Transaction.rehydrate(
        transactionId: transactionId,
        occurredAt: occurredAt,
        description: description,
        kind: TransactionKind.income,
        notes: notes,
        postings: [
          Posting(
            accountId: accountId,
            direction: PostingDirection.credit,
            amountMinor: amountMinor,
            currencyCode: currencyCode,
            categoryId: categoryId,
            memo: memo,
          ),
        ],
      );

  /// A transfer: one debit leg out of [fromAccountId] and one equal credit
  /// leg into [toAccountId] — net zero by construction. Both legs carry
  /// their own account's currency; [validate] rejects a mismatch.
  factory Transaction.transfer({
    required String transactionId,
    required DateTime occurredAt,
    required int amountMinor,
    required String fromAccountId,
    required String fromCurrencyCode,
    required String toAccountId,
    required String toCurrencyCode,
    String description = '',
    String? notes,
    String? memo,
  }) =>
      Transaction.rehydrate(
        transactionId: transactionId,
        occurredAt: occurredAt,
        description: description,
        kind: TransactionKind.transfer,
        notes: notes,
        postings: [
          Posting(
            accountId: fromAccountId,
            direction: PostingDirection.debit,
            amountMinor: amountMinor,
            currencyCode: fromCurrencyCode,
            memo: memo,
          ),
          Posting(
            accountId: toAccountId,
            direction: PostingDirection.credit,
            amountMinor: amountMinor,
            currencyCode: toCurrencyCode,
            memo: memo,
          ),
        ],
      );

  /// Validates aggregate invariants, throwing [CommandRejected] on a
  /// violation — what the write path calls before building the event.
  void validateOrThrow() {
    final violation = validate();
    if (violation != null) throw violation.toRejection();
  }

  /// Validates aggregate invariants. Returns null when valid.
  TransactionViolation? validate() {
    if (postings.isEmpty) return TransactionViolation.postingsEmpty;
    if (postings.any((p) => p.amountMinor <= 0)) {
      return TransactionViolation.amountNotPositive;
    }
    switch (kind) {
      case TransactionKind.income:
      case TransactionKind.expense:
        if (postings.length != 1) return TransactionViolation.postingCount;
        final expected = kind == TransactionKind.income
            ? PostingDirection.credit
            : PostingDirection.debit;
        if (postings.first.direction != expected) {
          return TransactionViolation.postingDirection;
        }
      case TransactionKind.transfer:
        if (postings.length != 2) return TransactionViolation.postingCount;
        final first = postings.first;
        final second = postings.last;
        if (first.direction == second.direction) {
          return TransactionViolation.transferDirections;
        }
        if (first.amountMinor != second.amountMinor) {
          return TransactionViolation.transferAmounts;
        }
        if (first.accountId == second.accountId) {
          return TransactionViolation.transferSameAccount;
        }
        if (first.currencyCode != second.currencyCode) {
          return TransactionViolation.transferCurrency;
        }
    }
    return null;
  }
}
