import 'package:feather_ledger/core/domain/enums.dart';

/// What a search is asking for (spec 004, US3 / FR-014).
///
/// Deliberately a plain immutable value with no `copyWith`: nullable-field
/// `copyWith` in Dart needs sentinel wrappers or `clearX` flags to express
/// "set this to null", which is the classic way a filter silently stops
/// clearing. Callers build a whole new value instead — see [withQuery] for
/// the one place that would have been tedious.
///
/// Equality is hand-written and **load-bearing**: this is a Riverpod
/// provider's state, and Riverpod deduplicates by `==`. Without it every
/// keystroke would emit a new state and resubscribe the query stream.
class TransactionFilter {
  /// Free text, matched against the note, the write-time category snapshot
  /// and the account name.
  final String? query;

  /// null means every kind, transfers included.
  final TransactionKind? kind;

  /// Matches a transaction touching this account — either leg of a transfer.
  final String? accountId;

  final String? categoryId;

  /// Inclusive, day-granular. null means unbounded.
  final DateTime? from;
  final DateTime? to;

  const TransactionFilter({
    this.query,
    this.kind,
    this.accountId,
    this.categoryId,
    this.from,
    this.to,
  });

  static const TransactionFilter empty = TransactionFilter();

  bool get isEmpty =>
      query == null &&
      kind == null &&
      accountId == null &&
      categoryId == null &&
      from == null &&
      to == null;

  bool get isNotEmpty => !isEmpty;

  /// The same filter with a different search text. An empty string clears it,
  /// which is the only mutation the text field makes.
  TransactionFilter withQuery(String? value) => TransactionFilter(
        query: (value == null || value.isEmpty) ? null : value,
        kind: kind,
        accountId: accountId,
        categoryId: categoryId,
        from: from,
        to: to,
      );

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.query == query &&
      other.kind == kind &&
      other.accountId == accountId &&
      other.categoryId == categoryId &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode =>
      Object.hash(query, kind, accountId, categoryId, from, to);

  @override
  String toString() => 'TransactionFilter(query: $query, kind: $kind, '
      'accountId: $accountId, categoryId: $categoryId, '
      'from: $from, to: $to)';
}
