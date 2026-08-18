import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/event_sourcing/drift_event_store.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_projector.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import 'package:feather_ledger/features/ledger/domain/model/transaction.dart';
import 'package:feather_ledger/features/ledger/domain/projections/ledger_projection.dart';
import 'package:feather_ledger/features/ledger/domain/services/posting_context.dart';

part 'convert_scheduled_to_posted_command.g.dart';

/// Converts a scheduled instance into a real transaction (spec 003,
/// US10/T069): one append transaction carries the `TransactionRecorded`
/// event, its projection AND the scheduled status flip to 'posted' (the
/// CRUD-exempt table's status update joins the same database transaction
/// via the append apply hook). A non-scheduled (already posted) instance is
/// rejected — conversion is one-shot.
///
/// Runs the same context resolution and aggregate validation as a manual
/// record (ADR-0001/ADR-0002). It used to enforce fewer rules than the other
/// two writers — the category-kind match was missing entirely, and a
/// non-positive amount or a transfer-typed series reached the projector and
/// surfaced as an unknown-event failure.
class ConvertScheduledToPostedCommand {
  final EventStore _eventStore;
  final LedgerProjector _projector;
  final RecurringRepository _recurringRepository;
  final PostingContextResolver _context;

  ConvertScheduledToPostedCommand(
    this._eventStore,
    this._projector,
    this._recurringRepository,
    this._context,
  );

  Future<void> execute(String scheduledId, {required String commandId}) async {
    final scheduled = await _recurringRepository.getScheduled(scheduledId);
    if (scheduled == null) {
      throw const CommandRejected(
          LedgerErrorCode.transactionNotFound, 'Scheduled instance not found');
    }
    _requirePending(scheduled.status);

    final series = await _recurringRepository.getSeries(scheduled.seriesId);
    if (series == null) {
      throw const CommandRejected(
          LedgerErrorCode.transactionNotFound, 'Series not found');
    }

    // Same validations as a manual record (spec 红线): the template's
    // account and category must still exist, be usable, and agree on kind.
    final context = await _context.resolveForKind(
      accountId: series.accountId,
      categoryId: series.categoryId,
      kind: series.type.toTransactionKind,
    );

    final transaction = series.type == RecurringSeriesKind.income
        ? Transaction.income(
            transactionId: const Uuid().v4(),
            occurredAt: scheduled.date,
            amountMinor: scheduled.amountMinor,
            accountId: context.account.id,
            currencyCode: context.account.currencyCode,
            categoryId: context.category!.id,
            description: series.description,
          )
        : Transaction.expense(
            transactionId: const Uuid().v4(),
            occurredAt: scheduled.date,
            amountMinor: scheduled.amountMinor,
            accountId: context.account.id,
            currencyCode: context.account.currencyCode,
            categoryId: context.category!.id,
            description: series.description,
          );

    transaction.validateOrThrow();

    await _eventStore.append(
      [
        envelopeFor(
          TransactionRecorded(
            transactionId: transaction.transactionId,
            occurredAt: transaction.occurredAt,
            kind: transaction.kind,
            description: transaction.description,
            notes: transaction.notes,
            postings: transaction.postings,
          ),
          aggregateType: AggregateType.transaction,
          streamVersion: 0,
          commandId: commandId,
          eventId: const Uuid().v4(),
        ),
      ],
      options: AppendOptions(apply: (persisted) async {
        // Recheck after acquiring the append transaction: another action may
        // have posted or skipped the bill while context was being resolved.
        final current = await _recurringRepository.getScheduled(scheduledId);
        if (current == null) {
          throw const CommandRejected(LedgerErrorCode.transactionNotFound,
              'Scheduled instance not found');
        }
        _requirePending(current.status);
        // Projection + the CRUD-exempt status flip share this transaction.
        await _projector.applyAll(persisted);
        await _recurringRepository.insertOrUpdateScheduled(
          ScheduledTransactionsViewCompanion(
            id: Value(scheduled.id),
            seriesId: Value(scheduled.seriesId),
            date: Value(scheduled.date),
            amountMinor: Value(scheduled.amountMinor),
            status: Value(ScheduledTransactionStatus.posted.toStorage()),
            transactionId: Value(transaction.transactionId),
          ),
        );
      }),
    );
  }

  static void _requirePending(String status) {
    final value = decodeScheduledStatus(status);
    if (value == ScheduledTransactionStatus.posted) {
      throw const CommandRejected(LedgerErrorCode.scheduledAlreadyPosted,
          'Scheduled instance already posted');
    }
    if (value != ScheduledTransactionStatus.scheduled) {
      throw const CommandRejected(LedgerErrorCode.transactionNotFound,
          'Scheduled instance no longer pending');
    }
  }
}

@riverpod
ConvertScheduledToPostedCommand convertScheduledToPostedCommand(Ref ref) {
  return ConvertScheduledToPostedCommand(
    ref.watch(driftEventStoreProvider),
    ref.watch(ledgerProjectorProvider),
    ref.watch(recurringRepositoryProvider),
    ref.watch(postingContextResolverProvider),
  );
}
