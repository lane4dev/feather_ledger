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
library;

import 'package:feather_ledger/core/domain/enums.dart';

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

  const Transaction({
    required this.transactionId,
    required this.occurredAt,
    required this.description,
    required this.kind,
    this.notes,
    required this.postings,
  });

  /// Validates aggregate invariants. Returns null when valid, otherwise a
  /// short machine-ish reason (mapped to LedgerErrorCode by commands).
  String? validate() {
    if (postings.isEmpty) return 'postings-empty';
    if (postings.any((p) => p.amountMinor <= 0)) return 'amount-not-positive';
    switch (kind) {
      case TransactionKind.income:
      case TransactionKind.expense:
        if (postings.length != 1) return 'posting-count';
        final expected =
            kind == TransactionKind.income ? PostingDirection.credit : PostingDirection.debit;
        if (postings.first.direction != expected) return 'posting-direction';
      case TransactionKind.transfer:
        if (postings.length != 2) return 'posting-count';
        final first = postings.first;
        final second = postings.last;
        if (first.direction == second.direction) return 'transfer-directions';
        if (first.amountMinor != second.amountMinor) {
          return 'transfer-amounts';
        }
        if (first.accountId == second.accountId) return 'transfer-same-account';
        if (first.currencyCode != second.currencyCode) {
          return 'transfer-currency';
        }
    }
    return null;
  }
}
