import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

part 'skip_scheduled_transaction_command.g.dart';

/// Marks a due instance as skipped (spec 004, US2 / FR-010).
///
/// Skipping writes **no event and touches no balance** — it is the user
/// saying "this month's rent did not happen". That is also why it takes no
/// `commandId`: the idempotency key exists to deduplicate event appends, and
/// there is no append here. `InsertOrUpdateScheduledTransactionCommand`
/// already sets that precedent.
class SkipScheduledTransactionCommand {
  final RecurringRepository _recurringRepository;

  SkipScheduledTransactionCommand(this._recurringRepository);

  Future<void> execute(String scheduledId) async {
    final scheduled = await _recurringRepository.getScheduled(scheduledId);
    if (scheduled == null) {
      throw CommandRejected(LedgerErrorCode.transactionNotFound,
          'Scheduled instance $scheduledId not found');
    }
    if (decodeScheduledStatus(scheduled.status) ==
        ScheduledTransactionStatus.posted) {
      throw const CommandRejected(LedgerErrorCode.scheduledAlreadyPosted,
          'Scheduled instance already posted');
    }

    await _recurringRepository.insertOrUpdateScheduled(
      ScheduledTransactionsViewCompanion(
        id: Value(scheduled.id),
        seriesId: Value(scheduled.seriesId),
        date: Value(scheduled.date),
        amountMinor: Value(scheduled.amountMinor),
        status: Value(ScheduledTransactionStatus.skipped.toStorage()),
        transactionId: Value(scheduled.transactionId),
      ),
    );
  }
}

@riverpod
SkipScheduledTransactionCommand skipScheduledTransactionCommand(Ref ref) {
  return SkipScheduledTransactionCommand(
      ref.watch(recurringRepositoryProvider));
}
