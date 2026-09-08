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
