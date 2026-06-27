import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/features/ledger/data/repositories/ledger_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/value_objects/transaction_filter.dart';

part 'search_transactions_query.g.dart';

/// Reads the transactions matching a filter (spec 004, US3).
///
/// Unlike [WatchTransactionsQuery] this does not filter reversed rows in
/// Dart — the DAO does it in SQL, where the rest of the predicate already
/// lives. Filtering twice would be harmless but would hide which layer owns
/// the rule.
class SearchTransactionsQuery {
  final LedgerRepository _ledgerRepository;

  SearchTransactionsQuery(this._ledgerRepository);

  Stream<List<TransactionEntity>> execute(TransactionFilter filter) =>
      _ledgerRepository.watchTransactionsFiltered(filter);
}

@riverpod
SearchTransactionsQuery searchTransactionsQuery(Ref ref) {
  return SearchTransactionsQuery(ref.watch(ledgerRepositoryProvider));
}
