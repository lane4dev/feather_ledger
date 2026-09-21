import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

part 'watch_scheduled_transactions_query.g.dart';

class WatchScheduledTransactionsQuery {
  final RecurringRepository _recurringRepository;

  WatchScheduledTransactionsQuery(this._recurringRepository);

  /// [currencyCode] scopes the pending-bill list to one ledger currency;
  /// null returns every currency.
  Stream<List<ScheduledTransactionEntity>> execute({String? currencyCode}) {
    return _recurringRepository
        .watchAllScheduled()
        .map((items) => items
            .where((s) =>
                currencyCode == null ||
                s.account?.currencyCode == currencyCode)
            .toList());
  }
}

@riverpod
WatchScheduledTransactionsQuery watchScheduledTransactionsQuery(Ref ref) {
  return WatchScheduledTransactionsQuery(
      ref.watch(recurringRepositoryProvider));
}
