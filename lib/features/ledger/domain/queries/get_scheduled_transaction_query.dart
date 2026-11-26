import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

part 'get_scheduled_transaction_query.g.dart';

class GetScheduledTransactionQuery {
  final RecurringRepository _recurringRepository;

  GetScheduledTransactionQuery(this._recurringRepository);

  Future<ScheduledTransactionEntity?> execute(String id) {
    return _recurringRepository.getScheduledEntity(id);
  }
}

@riverpod
GetScheduledTransactionQuery getScheduledTransactionQuery(Ref ref) {
  return GetScheduledTransactionQuery(ref.watch(recurringRepositoryProvider));
}
