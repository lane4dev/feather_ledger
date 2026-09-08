import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/features/ledger/data/repositories/ledger_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

part 'watch_transactions_query.g.dart';

class WatchTransactionsQuery {
  final LedgerRepository _ledgerRepository;

  WatchTransactionsQuery(this._ledgerRepository);

  Stream<List<TransactionEntity>> execute(DateTime month) {
    return _ledgerRepository
        .watchTransactions(month)
        .map((txs) => txs.where((t) => !t.isReversed).toList());
  }
}

@riverpod
WatchTransactionsQuery watchTransactionsQuery(Ref ref) {
  final repo = ref.watch(ledgerRepositoryProvider);
  return WatchTransactionsQuery(repo);
}
