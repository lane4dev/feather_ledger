import 'package:drift/drift.dart';

import 'package:feather_ledger/core/domain/enums.dart';

import '../app_database.dart';
import '../tables.dart';

part 'transaction_dao.g.dart';

/// Signed balance impact of a posting (personal-bookkeeping semantics,
/// defined only in `domain/model/transaction.dart`): credit adds, debit
/// subtracts.
int postingSignedImpact(TransactionPostingRow posting) =>
    posting.direction == PostingDirection.credit
        ? posting.amountMinor
        : -posting.amountMinor;

/// One transaction joined with its (first) posting and the posting's
/// account. US4 transactions are single-posting; transfers (US5) add a
/// second posting row sharing [transactionId].
class TransactionWithDetails {
  final TransactionViewRow transaction;
  final TransactionPostingRow posting;
  final AccountViewRow account;

  TransactionWithDetails(this.transaction, this.posting, this.account);
}

@DriftAccessor(
    tables: [TransactionsView, TransactionPostingsView, CategoriesView, AccountsView])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Future<TransactionViewRow?> getTransactionRow(String transactionId) {
    return (select(transactionsView)
          ..where((t) => t.transactionId.equals(transactionId)))
        .getSingleOrNull();
  }

  /// Projector write seams — the only writer of these projections.
  Future<void> upsertTransaction(TransactionsViewCompanion entry) {
    return into(transactionsView).insertOnConflictUpdate(entry);
  }

  Future<void> upsertPosting(TransactionPostingsViewCompanion entry) {
    return into(transactionPostingsView).insertOnConflictUpdate(entry);
  }

  Future<void> markTransactionAsReversed(String transactionId) async {
    await (update(transactionsView)
          ..where((t) => t.transactionId.equals(transactionId)))
        .write(
      const TransactionsViewCompanion(isReversed: Value(true)),
    );
  }

  /// Rebuild seam (US8/T057).
  Future<void> clearAll() async {
    await delete(transactionPostingsView).go();
    await delete(transactionsView).go();
  }

  Stream<List<TransactionWithDetails>> watchTransactionsByMonth(
      DateTime datetime) {
    final start = DateTime(datetime.year, datetime.month, 1);
    final end = DateTime(datetime.year, datetime.month + 1, 1)
        .subtract(const Duration(seconds: 1));

    final query = select(transactionsView).join([
      innerJoin(
          transactionPostingsView,
          transactionPostingsView.transactionId
              .equalsExp(transactionsView.transactionId)),
      innerJoin(accountsView,
          accountsView.id.equalsExp(transactionPostingsView.accountId)),
    ])
      ..where(transactionsView.occurredAt.isBetweenValues(start, end))
      ..orderBy([OrderingTerm.desc(transactionsView.occurredAt)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TransactionWithDetails(
          row.readTable(transactionsView),
          row.readTable(transactionPostingsView),
          row.readTable(accountsView),
        );
      }).toList();
    });
  }

  /// Transactions matching a filter, newest first (spec 004, US3).
  ///
  /// Takes primitives rather than the domain's `TransactionFilter`: this
  /// layer must not import `features/ledger/domain`, and
  /// [watchTransactionsByMonth] already set the precedent. The repository
  /// maps the value object onto these.
  ///
  /// Two things here are deliberate:
  ///
  /// - **`isReversed` is filtered in SQL.** Reversed rows are otherwise
  ///   hidden one layer up, in `WatchTransactionsQuery`, so a DAO caller
  ///   that does not know that gets them. `ReportsDao` already filters in
  ///   SQL; this follows it, and the query class must not filter again.
  /// - **Account and category match on the postings**, but the join does
  ///   not: a transfer has two posting rows, and filtering the join would
  ///   return one of them. The rows are grouped back into whole
  ///   transactions by `LedgerRepositoryImpl._toTransactionEntities`, which
  ///   needs both legs present. So the filter selects which *transactions*
  ///   qualify, and every posting of those is returned.
  ///
  /// No new index: `LIKE '%x%'` cannot use one, and the existing
  /// `idx_transactions_view_occurred_at` already covers the date range.
  Stream<List<TransactionWithDetails>> watchTransactionsFiltered({
    String? query,
    TransactionKind? kind,
    String? accountId,
    String? categoryId,
    DateTime? from,
    DateTime? to,
  }) {
    final matching = selectOnly(transactionPostingsView)
      ..addColumns([transactionPostingsView.transactionId]);
    if (accountId != null) {
      matching.where(transactionPostingsView.accountId.equals(accountId));
    }
    if (categoryId != null) {
      matching.where(transactionPostingsView.categoryId.equals(categoryId));
    }
    final hasPostingFilter = accountId != null || categoryId != null;

    final query0 = select(transactionsView).join([
      innerJoin(
          transactionPostingsView,
          transactionPostingsView.transactionId
              .equalsExp(transactionsView.transactionId)),
      innerJoin(accountsView,
          accountsView.id.equalsExp(transactionPostingsView.accountId)),
    ])
      ..where(transactionsView.isReversed.equals(false))
      ..orderBy([OrderingTerm.desc(transactionsView.occurredAt)]);

    if (hasPostingFilter) {
      query0.where(transactionsView.transactionId.isInQuery(matching));
    }
    if (kind != null) {
      query0.where(transactionsView.kind.equalsValue(kind));
    }
    if (from != null) {
      query0.where(transactionsView.occurredAt
          .isBiggerOrEqualValue(DateTime(from.year, from.month, from.day)));
    }
    if (to != null) {
      // End of the day, so a range ending today includes today's rows.
      query0.where(transactionsView.occurredAt.isSmallerOrEqualValue(
          DateTime(to.year, to.month, to.day, 23, 59, 59, 999)));
    }
    final text = query?.trim();
    if (text != null && text.isNotEmpty) {
      final pattern = '%${_escapeLike(text)}%';
      // escapeChar is what makes the escaping below mean anything: without
      // it SQLite reads `\%` as a literal backslash followed by a wildcard.
      query0.where(
        transactionsView.description.like(pattern, escapeChar: _likeEscape) |
            transactionsView.categoryName
                .like(pattern, escapeChar: _likeEscape) |
            accountsView.name.like(pattern, escapeChar: _likeEscape),
      );
    }

    return query0.watch().map((rows) {
      return rows
          .map((row) => TransactionWithDetails(
                row.readTable(transactionsView),
                row.readTable(transactionPostingsView),
                row.readTable(accountsView),
              ))
          .toList();
    });
  }

  /// The escape character declared alongside [_escapeLike]'s patterns.
  static const _likeEscape = r'\';

  /// Escapes LIKE metacharacters so a user typing `%` searches for a literal
  /// percent sign instead of matching every row in the ledger. The backslash
  /// itself must be escaped first, or it would escape the escape.
  static String _escapeLike(String input) => input
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');

  Future<TransactionWithDetails?> getTransaction(String transactionId) async {
    final query = select(transactionsView).join([
      innerJoin(
          transactionPostingsView,
          transactionPostingsView.transactionId
              .equalsExp(transactionsView.transactionId)),
      innerJoin(accountsView,
          accountsView.id.equalsExp(transactionPostingsView.accountId)),
    ])
      ..where(transactionsView.transactionId.equals(transactionId));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return TransactionWithDetails(
      row.readTable(transactionsView),
      row.readTable(transactionPostingsView),
      row.readTable(accountsView),
    );
  }

  /// All posting rows of one transaction (US5/T042 — transfers have two).
  Future<List<TransactionWithDetails>> getTransactionRows(
      String transactionId) async {
    final query = select(transactionsView).join([
      innerJoin(
          transactionPostingsView,
          transactionPostingsView.transactionId
              .equalsExp(transactionsView.transactionId)),
      innerJoin(accountsView,
          accountsView.id.equalsExp(transactionPostingsView.accountId)),
    ])
      ..where(transactionsView.transactionId.equals(transactionId));

    final rows = await query.get();
    return rows
        .map((row) => TransactionWithDetails(
              row.readTable(transactionsView),
              row.readTable(transactionPostingsView),
              row.readTable(accountsView),
            ))
        .toList();
  }
}
