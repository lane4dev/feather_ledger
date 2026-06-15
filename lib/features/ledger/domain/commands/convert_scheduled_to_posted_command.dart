import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/repositories/account_repository.dart';
import 'package:feather_ledger/core/data/repositories/category_repository.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/event_sourcing/drift_event_store.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_projector.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import 'package:feather_ledger/features/ledger/domain/model/transaction.dart';
import 'package:feather_ledger/features/ledger/domain/projections/ledger_projection.dart';

part 'convert_scheduled_to_posted_command.g.dart';

/// Converts a scheduled instance into a real transaction (spec 003,
/// US10/T069): one append transaction carries the `TransactionRecorded`
/// event, its projection AND the scheduled status flip to 'posted' (the
/// CRUD-exempt table's status update joins the same database transaction
/// via the append apply hook). A non-scheduled (already posted) instance is
/// rejected — conversion is one-shot.
class ConvertScheduledToPostedCommand {
  final EventStore _eventStore;
  final LedgerProjector _projector;
  final RecurringRepository _recurringRepository;
  final AccountRepository _accountRepository;
  final CategoryRepository _categoryRepository;

  ConvertScheduledToPostedCommand(
    this._eventStore,
    this._projector,
    this._recurringRepository,
    this._accountRepository,
    this._categoryRepository,
  );

  Future<void> execute(String scheduledId, {required String commandId}) async {
    final scheduled = await _recurringRepository.getScheduled(scheduledId);
    if (scheduled == null) {
      throw const CommandRejected(
          LedgerErrorCode.transactionNotFound, 'Scheduled instance not found');
    }
    if (scheduled.status == 'posted') {
      throw const CommandRejected(LedgerErrorCode.transactionAlreadyReversed,
          'Scheduled instance already posted');
    }

    final series = await _recurringRepository.getSeries(scheduled.seriesId);
    if (series == null) {
      throw const CommandRejected(
          LedgerErrorCode.transactionNotFound, 'Series not found');
    }

    // Same validations as a manual record (spec 红线): the template's
    // account and category must still exist and be usable.
    final account = await _accountRepository.getAccount(series.accountId);
    if (account == null) {
      throw CommandRejected(LedgerErrorCode.accountNotFound,
          'Account ${series.accountId} not found');
    }
    if (account.archived) {
      throw CommandRejected(LedgerErrorCode.accountArchived,
          'Account ${series.accountId} is archived');
    }
    final category = await _categoryRepository.getCategory(series.categoryId);
    if (category == null) {
      throw CommandRejected(LedgerErrorCode.categoryNotFound,
          'Category ${series.categoryId} not found');
    }
    if (category.archived) {
      throw CommandRejected(LedgerErrorCode.categoryArchived,
          'Category ${series.categoryId} is archived');
    }

    final transactionId = const Uuid().v4();
    final direction = series.type == TransactionKind.income
        ? PostingDirection.credit
        : PostingDirection.debit;
    final recorded = TransactionRecorded(
      transactionId: transactionId,
      occurredAt: scheduled.date,
      kind: series.type,
      description: series.description,
      postings: [
        Posting(
          accountId: series.accountId,
          direction: direction,
          amountMinor: scheduled.amountMinor,
          currencyCode: account.currencyCode,
          categoryId: series.categoryId,
        ),
      ],
    );

    await _eventStore.append(
      [
        envelopeFor(
          recorded,
          aggregateType: AggregateType.transaction,
          streamVersion: 0,
          commandId: commandId,
          eventId: const Uuid().v4(),
        ),
      ],
      options: AppendOptions(apply: (persisted) async {
        // Projection + the CRUD-exempt status flip share this transaction.
        await _projector.applyAll(persisted);
        await _recurringRepository.insertOrUpdateScheduled(
          ScheduledTransactionsViewCompanion(
            id: Value(scheduled.id),
            seriesId: Value(scheduled.seriesId),
            date: Value(scheduled.date),
            amountMinor: Value(scheduled.amountMinor),
            status: const Value('posted'),
            transactionId: Value(transactionId),
          ),
        );
      }),
    );
  }
}

@riverpod
ConvertScheduledToPostedCommand convertScheduledToPostedCommand(Ref ref) {
  return ConvertScheduledToPostedCommand(
    ref.watch(driftEventStoreProvider),
    ref.watch(ledgerProjectorProvider),
    ref.watch(recurringRepositoryProvider),
    ref.watch(accountRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  );
}
