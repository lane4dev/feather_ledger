import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/features/ledger/data/repositories/ledger_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

part 'watch_transactions_query.g.dart';

class WatchTransactionsQuery {
  final LedgerRepository _ledgerRepository;

  WatchTransactionsQuery(this._ledgerRepository);

  /// [currencyCode] scopes the read to one ledger currency (spec 006). When
  /// null, every currency is returned — the bootstrap/catch-up paths read the
  /// whole event stream, not a screen's currency.
  Stream<List<TransactionEntity>> execute(DateTime month,
      {String? currencyCode}) {
    return _ledgerRepository
        .watchTransactions(month, currencyCode: currencyCode)
        .map((txs) => txs.where((t) => !t.isReversed).toList());
  }

  /// The latest non-reversed transaction posted from a scheduled bill
  /// (spec 006, US47).
  Future<TransactionEntity?> getBySourceBill(String sourceScheduledBillId) =>
      _ledgerRepository.getTransactionBySourceBill(sourceScheduledBillId);
}

@riverpod
WatchTransactionsQuery watchTransactionsQuery(Ref ref) {
  final repo = ref.watch(ledgerRepositoryProvider);
  return WatchTransactionsQuery(repo);
}
