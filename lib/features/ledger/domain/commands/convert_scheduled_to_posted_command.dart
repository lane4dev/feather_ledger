import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/features/ledger/domain/commands/post_transaction_command.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';

part 'convert_scheduled_to_posted_command.g.dart';

class ConvertScheduledToPostedCommand {
  final RecurringRepository _recurringRepository;
  final PostTransactionCommand _postTransactionCommand;

  ConvertScheduledToPostedCommand(
      this._recurringRepository, this._postTransactionCommand);

  Future<void> execute(String scheduledId) async {
    final scheduled = await _recurringRepository.getScheduled(scheduledId);
    if (scheduled == null) throw Exception('Scheduled transaction not found');

    final series = await _recurringRepository.getSeries(scheduled.seriesId);
    if (series == null) throw Exception('Series not found');

    await _postTransactionCommand.execute(
      amount: scheduled.amount / 100.0,
      type: series.type,
      date: scheduled.date,
      categoryId: series.categoryId,
      accountId: series.accountId,
      note: series.description,
    );

    // Manually construct the companion for update
    await _recurringRepository.insertOrUpdateScheduled(
      ScheduledTransactionsViewCompanion(
        id: Value(scheduled.id),
        seriesId: Value(scheduled.seriesId),
        date: Value(scheduled.date),
        amount: Value(scheduled.amount),
        status: const Value('posted'),
        transactionId: Value(scheduled.transactionId),
      ),
    );
  }
}

@riverpod
ConvertScheduledToPostedCommand convertScheduledToPostedCommand(Ref ref) {
  return ConvertScheduledToPostedCommand(
    ref.watch(recurringRepositoryProvider),
    ref.watch(postTransactionCommandProvider),
  );
}
