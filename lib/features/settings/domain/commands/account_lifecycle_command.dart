import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/domain/model/transaction.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/data/event_sourcing/drift_event_store.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_projector.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import 'package:feather_ledger/features/ledger/domain/projections/ledger_projection.dart';

class AccountUsage {
  const AccountUsage(
      this.transactions, this.series, this.pending, this.activeSeries);
  final int transactions;
  final int series;
  final int pending;
  final int activeSeries;
}

class AccountLifecycleCommand {
  AccountLifecycleCommand(this._db, this._events, this._projector);
  final AppDatabase _db;
  final EventStore _events;
  final LedgerProjector _projector;

  Future<AccountUsage> usage(String id) async {
    final postings = await (_db.select(_db.transactionPostingsView).join([
      innerJoin(
        _db.transactionsView,
        _db.transactionsView.transactionId
            .equalsExp(_db.transactionPostingsView.transactionId),
      ),
    ])
          ..where(_db.transactionPostingsView.accountId.equals(id) &
              _db.transactionsView.isReversed.equals(false)))
        .get();
    final series = await (_db.select(_db.recurringSeries)
          ..where((t) => t.accountId.equals(id)))
        .get();
    var pending = 0;
    var active = 0;
    for (final rule in series) {
      final instances = await (_db.select(_db.scheduledTransactionsView)
            ..where((t) => t.seriesId.equals(rule.id)))
          .get();
      final scheduled = instances
          .where((e) => e.status == 'scheduled' || e.status == 'failed')
          .length;
      pending += scheduled;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final end = rule.endDate?.toLocal();
      final endedByDate =
          end != null && DateTime(end.year, end.month, end.day).isBefore(today);
      final completed = instances
          .where((e) => e.status == 'posted' || e.status == 'skipped')
          .length;
      final endedByCount =
          rule.countLimit != null && completed >= rule.countLimit!;
      if (scheduled > 0 || (!endedByDate && !endedByCount)) active++;
    }
    return AccountUsage(
        postings
            .where((row) =>
                !row.readTable(_db.transactionsView).kind.isBalancePurpose)
            .map((row) =>
                row.readTable(_db.transactionPostingsView).transactionId)
            .toSet()
            .length,
        series.length,
        pending,
        active);
  }

  Future<void> execute(
      {required String id,
      required String commandId,
      required String action,
      String? targetAccountId}) async {
    await _db.transaction(() async {
      if (await _events.commandExists(commandId)) return;
      final account = await _db.accountDao.getAccountById(id);
      if (account == null || account.deleted) {
        throw const CommandRejected(
            LedgerErrorCode.accountNotFound, 'Account not found');
      }
      final use = await usage(id);
      if (action == 'delete' || action == 'deleteAll' || action == 'move') {
        if (action == 'delete' && (use.transactions > 0 || use.series > 0)) {
          throw const CommandRejected(
              LedgerErrorCode.accountHasReferences, 'Account has references');
        }
        if (action == 'deleteAll' && !account.archived) {
          throw const CommandRejected(LedgerErrorCode.accountHasReferences,
              'Archive the account first');
        }
        await _deleteAccount(account, commandId, action, targetAccountId);
        return;
      }
      if ((action == 'archive' && account.archived) ||
          (action == 'restore' && !account.archived)) return;
      if (action == 'archive') {
        final now = DateTime.now();
        final series = await (_db.select(_db.recurringSeries)
              ..where((row) => row.accountId.equals(id)))
            .get();
        for (final rule in series) {
          final overdue = await (_db.select(_db.scheduledTransactionsView)
                ..where((row) =>
                    row.seriesId.equals(rule.id) &
                    coalesce([row.dateOverride, row.scheduledDate])
                        .isSmallerOrEqualValue(now) &
                    row.status.isIn(['scheduled', 'failed'])))
              .get();
          // A pending bill needs a series for its account and template. Keep
          // overdue bills as one-off plans before removing the original rule.
          for (final bill in overdue) {
            final planId = const Uuid().v4();
            final effectiveDate = bill.dateOverride ?? bill.scheduledDate;
            await _db
                .into(_db.recurringSeries)
                .insert(rule.toCompanion(true).copyWith(
                      id: Value(planId),
                      rrule: const Value('FREQ=DAILY;COUNT=1'),
                      frequency: const Value('DAILY'),
                      interval: const Value(1),
                      startDate: Value(effectiveDate),
                      endDate: Value(effectiveDate),
                      countLimit: const Value(1),
                      autoPost: const Value(false),
                      mode: const Value(RecurringSeriesMode.planned),
                      isActive: const Value(true),
                    ));
            await _db.into(_db.scheduledTransactionsView).insert(
                  bill.toCompanion(true).copyWith(
                        id: Value(const Uuid().v4()),
                        seriesId: Value(planId),
                        occurrenceKey: const Value(kPlannedOccurrenceKey),
                        scheduledDate: Value(effectiveDate),
                        dateOverride: const Value(null),
                      ),
                );
          }
          await (_db.delete(_db.scheduledTransactionsView)
                ..where((row) => row.seriesId.equals(rule.id)))
              .go();
          await (_db.delete(_db.recurringSeries)
                ..where((row) => row.id.equals(rule.id)))
              .go();
        }
      }
      final event = switch (action) {
        'archive' => AccountArchived(accountId: id),
        'restore' => AccountRestored(accountId: id),
        'delete' => AccountDeleted(accountId: id),
        _ => throw ArgumentError.value(action),
      };
      await _events.append([
        envelopeFor(event,
            aggregateType: AggregateType.account,
            streamVersion: await nextStreamVersion(_events, id),
            commandId: commandId,
            eventId: const Uuid().v4()),
      ], options: AppendOptions(apply: _projector.applyAll));
    });
  }

  Future<void> _deleteAccount(AccountViewRow account, String commandId,
      String action, String? targetId) async {
    AccountViewRow? target;
    if (action == 'move') {
      target = targetId == null
          ? null
          : await _db.accountDao.getAccountById(targetId);
      if (target == null ||
          target.deleted ||
          target.archived ||
          target.id == account.id) {
        throw const CommandRejected(
            LedgerErrorCode.accountNotFound, 'Select an active destination');
      }
      if (target.currencyCode != account.currencyCode) {
        throw const CommandRejected(LedgerErrorCode.currencyMismatch,
            'Accounts must use the same currency');
      }
    }
    final rows = await (_db.select(_db.transactionPostingsView).join([
      innerJoin(
          _db.transactionsView,
          _db.transactionsView.transactionId
              .equalsExp(_db.transactionPostingsView.transactionId)),
    ])
          ..where(_db.transactionPostingsView.accountId.equals(account.id) &
              _db.transactionsView.isReversed.equals(false)))
        .get();
    final transactionRows = {
      for (final row in rows)
        row.readTable(_db.transactionsView).transactionId:
            row.readTable(_db.transactionsView)
    };
    final envelopes = <EventEnvelope>[];
    final replacements = <String, String>{};
    for (final transaction in transactionRows.values) {
      final stream = await _events.readStream(transaction.transactionId);
      final originalEnvelope = stream
          .firstWhere((event) => event.eventType == 'TransactionRecorded');
      final original = TransactionRecorded.fromJson(_events.registry.upcast(
          originalEnvelope.eventType, originalEnvelope.payloadJson,
          eventId: originalEnvelope.eventId));
      final shouldMove = action == 'move' && !transaction.kind.isBalancePurpose;
      envelopes.add(envelopeFor(
          TransactionReversed(
              originalTransactionId: transaction.transactionId,
              reason: shouldMove
                  ? ReversalReason.correction
                  : ReversalReason.userDeleted),
          aggregateType: AggregateType.transaction,
          streamVersion: stream.length,
          commandId: commandId,
          eventId: const Uuid().v4()));
      if (!shouldMove) continue;
      final id = const Uuid().v4();
      final sourcePosting =
          original.postings.firstWhere((p) => p.accountId == account.id);
      final Transaction replacement;
      if (transaction.kind == TransactionKind.transfer) {
        final debit = original.postings
            .firstWhere((p) => p.direction == PostingDirection.debit);
        final credit = original.postings
            .firstWhere((p) => p.direction == PostingDirection.credit);
        final from =
            debit.accountId == account.id ? target!.id : debit.accountId;
        final to =
            credit.accountId == account.id ? target!.id : credit.accountId;
        replacement = Transaction.transfer(
            transactionId: id,
            occurredAt: original.occurredAt,
            amountMinor: debit.amountMinor,
            fromAccountId: from,
            fromCurrencyCode: debit.currencyCode,
            toAccountId: to,
            toCurrencyCode: credit.currencyCode,
            description: original.description,
            notes: original.notes,
            memo: debit.memo,
            attachments: original.attachments);
      } else if (transaction.kind == TransactionKind.income) {
        replacement = Transaction.income(
            transactionId: id,
            occurredAt: original.occurredAt,
            amountMinor: sourcePosting.amountMinor,
            accountId: target!.id,
            currencyCode: target.currencyCode,
            categoryId: sourcePosting.categoryId!,
            description: original.description,
            notes: original.notes,
            memo: sourcePosting.memo,
            attachments: original.attachments);
      } else {
        replacement = Transaction.expense(
            transactionId: id,
            occurredAt: original.occurredAt,
            amountMinor: sourcePosting.amountMinor,
            accountId: target!.id,
            currencyCode: target.currencyCode,
            categoryId: sourcePosting.categoryId!,
            description: original.description,
            notes: original.notes,
            memo: sourcePosting.memo,
            attachments: original.attachments);
      }
      replacement.validateOrThrow();
      replacements[transaction.transactionId] = id;
      envelopes.add(envelopeFor(
          TransactionRecorded(
              transactionId: id,
              occurredAt: replacement.occurredAt,
              kind: replacement.kind,
              description: replacement.description,
              notes: replacement.notes,
              postings: replacement.postings,
              categorySnapshotName: transaction.categoryName,
              categorySnapshotIcon: transaction.categoryIcon,
              categorySnapshotColor: transaction.categoryColorInt,
              attachments: replacement.attachments),
          aggregateType: AggregateType.transaction,
          streamVersion: 0,
          commandId: commandId,
          eventId: const Uuid().v4()));
    }
    final series = await (_db.select(_db.recurringSeries)
          ..where((s) => s.accountId.equals(account.id)))
        .get();
    if (action == 'move') {
      await (_db.update(_db.recurringSeries)
            ..where((s) => s.accountId.equals(account.id)))
          .write(RecurringSeriesCompanion(accountId: Value(target!.id)));
      for (final pair in replacements.entries) {
        await (_db.update(_db.scheduledTransactionsView)
              ..where((t) => t.transactionId.equals(pair.key)))
            .write(ScheduledTransactionsViewCompanion(
                transactionId: Value(pair.value)));
      }
    } else if (action == 'deleteAll') {
      for (final rule in series) {
        await (_db.delete(_db.scheduledTransactionsView)
              ..where((s) => s.seriesId.equals(rule.id)))
            .go();
      }
      await (_db.delete(_db.recurringSeries)
            ..where((s) => s.accountId.equals(account.id)))
          .go();
    }
    envelopes.add(envelopeFor(AccountDeleted(accountId: account.id),
        aggregateType: AggregateType.account,
        streamVersion: await nextStreamVersion(_events, account.id),
        commandId: commandId,
        eventId: const Uuid().v4()));
    await _events.append(envelopes,
        options: AppendOptions(apply: _projector.applyAll));
  }
}

final accountLifecycleCommandProvider = Provider<AccountLifecycleCommand>(
    (ref) => AccountLifecycleCommand(
        ref.watch(appDatabaseProvider),
        ref.watch(driftEventStoreProvider),
        ref.watch(ledgerProjectorProvider)));
