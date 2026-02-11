import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';

part 'watch_scheduled_transactions_query.g.dart';

class WatchScheduledTransactionsQuery {
  final RecurringRepository _recurringRepository;

  WatchScheduledTransactionsQuery(this._recurringRepository);

  Stream<List<ScheduledTransactionEntity>> execute() {
    return _recurringRepository.watchAllScheduled();
  }
}

@riverpod
WatchScheduledTransactionsQuery watchScheduledTransactionsQuery(Ref ref) {
  return WatchScheduledTransactionsQuery(
      ref.watch(recurringRepositoryProvider));
}
