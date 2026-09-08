import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';

part 'insert_or_update_scheduled_transaction_command.g.dart';

class InsertOrUpdateScheduledTransactionCommand {
  final RecurringRepository _recurringRepository;

  InsertOrUpdateScheduledTransactionCommand(this._recurringRepository);

  Future<void> execute(ScheduledTransactionsViewCompanion entry) {
    return _recurringRepository.insertOrUpdateScheduled(entry);
  }
}

@riverpod
InsertOrUpdateScheduledTransactionCommand
    insertOrUpdateScheduledTransactionCommand(Ref ref) {
  return InsertOrUpdateScheduledTransactionCommand(
      ref.watch(recurringRepositoryProvider));
}
