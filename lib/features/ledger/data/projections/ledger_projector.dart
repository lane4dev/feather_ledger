import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/app/bootstrap/register_ledger_events.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/transaction_dao.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import 'package:feather_ledger/features/ledger/domain/model/transaction.dart';
import 'package:feather_ledger/features/ledger/domain/projections/ledger_projection.dart';

import 'monthly_snapshot_projector.dart';

part 'ledger_projector.g.dart';

/// Synchronous ledger projector (spec 003, Projection Model).
///
/// The **only** writer of the event-sourced projections (accounts_view,
/// transactions_view, transaction_postings_view, categories_view, monthly
/// snapshots) and the only balance calculation point. Driven from inside
/// the append transaction via `AppendOptions(apply: ...)`.
///
/// Idempotency: every row records the GSN of the last applied event
/// (`lastUpdatedEventId`); an event at or below that cursor is a no-op, so
/// incremental application and full rebuild share the [apply] code path.
///
/// Account/category/opening branches land in US3 (T026); the transaction
/// and snapshot branches land in US4–US7. Unknown event types hard-fail —
/// a projector that guesses makes the ledger silently drift.
class LedgerProjectorImpl implements LedgerProjector {
  final AppDatabase _db;

  /// Maintains the monthly snapshots after every balance-relevant event
  /// (spec 003, US7/T052).
  late final MonthlySnapshotProjectorImpl _snapshots =
      MonthlySnapshotProjectorImpl(_db);

  LedgerProjectorImpl(this._db);

  /// Applies a persisted batch (the append hook entry point).
  @override
  Future<void> applyAll(List<EventEnvelope> events) async {
    for (final event in events) {
      await apply(event);
    }
  }

  @override
  Future<void> apply(EventEnvelope envelope) async {
    // Projectors only ever see the latest payload structure (schema 演进).
    final payload =
        ledgerEventRegistry.upcast(envelope.eventType, envelope.payloadJson);

    switch (envelope.eventType) {
      case 'AccountCreated':
        final p = AccountCreated.fromJson(payload);
        await _applyAccountCreated(envelope, p);
        await _snapshots.refreshAccount(p.accountId);
      case 'AccountRenamed':
        await _applyAccountRenamed(envelope, AccountRenamed.fromJson(payload));
      case 'AccountArchived':
        await _applyAccountArchived(envelope, AccountArchived.fromJson(payload));
      case 'CategoryCreated':
        await _applyCategoryCreated(envelope, CategoryCreated.fromJson(payload));
      case 'CategoryRenamed':
        await _applyCategoryRenamed(envelope, CategoryRenamed.fromJson(payload));
      case 'CategoryArchived':
        await _applyCategoryArchived(envelope, CategoryArchived.fromJson(payload));
      case 'OpeningBalanceSet':
        final p = OpeningBalanceSet.fromJson(payload);
        await _applyOpeningBalanceSet(envelope, p);
        await _snapshots.refreshAccount(p.accountId);
      case 'TransactionRecorded':
        final p = TransactionRecorded.fromJson(payload);
        await _applyTransactionRecorded(envelope, p);
        for (final posting in p.postings) {
          await _snapshots.refreshAccount(posting.accountId);
        }
      case 'TransactionReversed':
        final p = TransactionReversed.fromJson(payload);
        final affected = await _applyTransactionReversed(envelope, p);
        for (final accountId in affected) {
          await _snapshots.refreshAccount(accountId);
        }
      default:
        throw UnknownEventTypeError(envelope.eventType, envelope.eventId);
    }
  }

  /// — Account stream ————————————————————————————————————————————————

  Future<void> _applyAccountCreated(
      EventEnvelope e, AccountCreated p) async {
    final gsn = e.globalSequenceNumber!;
    final existing = await _db.accountDao.getAccountById(p.accountId);
    if (existing != null) {
      if (existing.lastUpdatedEventId >= gsn) return; // already applied
      throw StateError('AccountCreated for existing account ${p.accountId} '
          'stream=${p.accountId}@${e.streamVersion}');
    }
    await _db.accountDao.upsert(AccountsViewCompanion.insert(
      id: p.accountId,
      name: p.name,
      type: p.type,
      currencyCode: p.currencyCode,
      balanceMinor: 0,
      lastUpdatedEventId: gsn,
      projectionVersion: const Value(ledgerProjectionVersion),
    ));
  }

  Future<void> _applyAccountRenamed(EventEnvelope e, AccountRenamed p) async {
    final gsn = e.globalSequenceNumber!;
    final existing = await _db.accountDao.getAccountById(p.accountId);
    if (existing == null) {
      throw StateError('AccountRenamed for unknown account ${p.accountId} '
          '(event ${e.eventId})');
    }
    if (existing.lastUpdatedEventId >= gsn) return; // already applied
    await _db.accountDao.updateRow(AccountsViewCompanion(
      id: Value(p.accountId),
      name: Value(p.name),
      lastUpdatedEventId: Value(gsn),
    ));
  }

  Future<void> _applyAccountArchived(
      EventEnvelope e, AccountArchived p) async {
    final gsn = e.globalSequenceNumber!;
    final existing = await _db.accountDao.getAccountById(p.accountId);
    if (existing == null) {
      throw StateError('AccountArchived for unknown account ${p.accountId} '
          '(event ${e.eventId})');
    }
    if (existing.lastUpdatedEventId >= gsn) return; // already applied
    await _db.accountDao.updateRow(AccountsViewCompanion(
      id: Value(p.accountId),
      archived: const Value(true),
      lastUpdatedEventId: Value(gsn),
    ));
  }

  Future<void> _applyOpeningBalanceSet(
      EventEnvelope e, OpeningBalanceSet p) async {
    final gsn = e.globalSequenceNumber!;
    final existing = await _db.accountDao.getAccountById(p.accountId);
    if (existing == null) {
      throw StateError('OpeningBalanceSet for unknown account ${p.accountId} '
          '(event ${e.eventId})');
    }
    if (existing.lastUpdatedEventId >= gsn) return; // already applied
    // Spec: the balance is set to the absolute value; the command only
    // emits this at account creation.
    await _db.accountDao.updateRow(AccountsViewCompanion(
      id: Value(p.accountId),
      balanceMinor: Value(p.amountMinor.abs()),
      lastUpdatedEventId: Value(gsn),
    ));
  }

  /// — Category stream ———————————————————————————————————————————————

  Future<void> _applyCategoryCreated(
      EventEnvelope e, CategoryCreated p) async {
    final gsn = e.globalSequenceNumber!;
    final existing = await _db.categoriesDao.getCategoryById(p.categoryId);
    if (existing != null) {
      if (existing.lastUpdatedEventId >= gsn) return; // already applied
      throw StateError('CategoryCreated for existing category '
          '${p.categoryId} stream=${p.categoryId}@${e.streamVersion}');
    }
    await _db.categoriesDao.upsert(CategoriesViewCompanion.insert(
      id: p.categoryId,
      name: p.name,
      iconKey: p.iconKey,
      colorInt: p.colorInt,
      type: p.type,
      systemCode: Value(p.systemCode),
      lastUpdatedEventId: gsn,
      projectionVersion: const Value(ledgerProjectionVersion),
    ));
  }

  Future<void> _applyCategoryRenamed(
      EventEnvelope e, CategoryRenamed p) async {
    final gsn = e.globalSequenceNumber!;
    final existing = await _db.categoriesDao.getCategoryById(p.categoryId);
    if (existing == null) {
      throw StateError('CategoryRenamed for unknown category ${p.categoryId} '
          '(event ${e.eventId})');
    }
    if (existing.lastUpdatedEventId >= gsn) return; // already applied
    await _db.categoriesDao.updateRow(CategoriesViewCompanion(
      id: Value(p.categoryId),
      name: Value(p.name),
      lastUpdatedEventId: Value(gsn),
    ));
  }

  Future<void> _applyCategoryArchived(
      EventEnvelope e, CategoryArchived p) async {
    final gsn = e.globalSequenceNumber!;
    final existing = await _db.categoriesDao.getCategoryById(p.categoryId);
    if (existing == null) {
      throw StateError('CategoryArchived for unknown category ${p.categoryId} '
          '(event ${e.eventId})');
    }
    if (existing.lastUpdatedEventId >= gsn) return; // already applied
    await _db.categoriesDao.updateRow(CategoriesViewCompanion(
      id: Value(p.categoryId),
      archived: const Value(true),
      lastUpdatedEventId: Value(gsn),
    ));
  }

  /// — Transaction stream ————————————————————————————————————————————

  Future<void> _applyTransactionRecorded(
      EventEnvelope e, TransactionRecorded p) async {
    final gsn = e.globalSequenceNumber!;
    final existing = await _db.transactionsDao.getTransactionRow(p.transactionId);
    if (existing != null) {
      if (existing.originalEventId >= gsn) return; // already applied
      throw StateError('TransactionRecorded for existing transaction '
          '${p.transactionId} stream=${p.transactionId}@${e.streamVersion}');
    }

    // Aggregate invariants (single-posting income/expense with
    // direction==kind; two-posting transfer with opposite directions,
    // equal amounts, distinct same-currency accounts — US4/US5).
    final txn = Transaction(
      transactionId: p.transactionId,
      occurredAt: p.occurredAt,
      description: p.description,
      kind: p.kind,
      notes: p.notes,
      postings: p.postings,
    );
    final violation = txn.validate();
    if (violation != null) {
      throw StateError(
          'TransactionRecorded violates invariants: $violation '
          '(event ${e.eventId})');
    }

    // Write-time category snapshot: history survives archival. Transfers
    // carry no category — the snapshot columns stay null.
    final categoryId = p.postings.first.categoryId;
    final category = categoryId == null
        ? null
        : await _db.categoriesDao.getCategoryById(categoryId);
    if (categoryId != null && category == null) {
      throw StateError('TransactionRecorded references unknown category '
          '$categoryId (event ${e.eventId})');
    }

    await _db.transactionsDao.upsertTransaction(TransactionsViewCompanion.insert(
      transactionId: p.transactionId,
      occurredAt: p.occurredAt,
      kind: p.kind,
      description: p.description,
      categoryName: Value(category?.name),
      categoryIcon: Value(category?.iconKey),
      categoryColorInt: Value(category?.colorInt.toRadixString(16)),
      originalEventId: gsn,
      projectionVersion: const Value(ledgerProjectionVersion),
    ));

    // The single balance calculation point: only the projector moves
    // account balances — one increment per posting, by direction.
    for (var i = 0; i < p.postings.length; i++) {
      final posting = p.postings[i];
      final account = await _db.accountDao.getAccountById(posting.accountId);
      if (account == null) {
        throw StateError('TransactionRecorded references unknown account '
            '${posting.accountId} (event ${e.eventId})');
      }
      await _db.transactionsDao.upsertPosting(TransactionPostingsViewCompanion.insert(
        // Deterministic id: rebuild (US8) replays must reproduce the
        // projection field-by-field, so no random ids here.
        id: '${p.transactionId}:$i',
        transactionId: p.transactionId,
        accountId: posting.accountId,
        direction: posting.direction,
        amountMinor: posting.amountMinor,
        currencyCode: posting.currencyCode,
        categoryId: Value(posting.categoryId),
        memo: Value(posting.memo),
      ));
      await _db.accountDao.updateRow(AccountsViewCompanion(
        id: Value(account.id),
        balanceMinor: Value(account.balanceMinor + posting.signedImpact),
        lastUpdatedEventId: Value(gsn),
      ));
    }
  }

  /// Reverses a transaction (spec 003, US6/T045): marks the row
  /// `isReversed` and undoes each posting's balance impact — the pair of
  /// original + reversal cancels out. A transaction can only be reversed
  /// once (domain rule), so `isReversed` doubles as the replay-idempotency
  /// marker: re-applying the event to an already-reversed row is a no-op.
  /// Returns the affected account ids so the caller can refresh their
  /// monthly snapshots.
  Future<Set<String>> _applyTransactionReversed(
      EventEnvelope e, TransactionReversed p) async {
    final gsn = e.globalSequenceNumber!;
    final transaction =
        await _db.transactionsDao.getTransactionRow(p.originalTransactionId);
    if (transaction == null) {
      throw StateError('TransactionReversed for unknown transaction '
          '${p.originalTransactionId} (event ${e.eventId})');
    }
    if (transaction.isReversed) return {}; // already applied

    // Undo each posting's impact on its account — the single balance
    // calculation point stays here.
    final rows = await _db.transactionsDao
        .getTransactionRows(p.originalTransactionId);
    final affected = <String>{};
    for (final row in rows) {
      final account = row.account;
      affected.add(account.id);
      await _db.accountDao.updateRow(AccountsViewCompanion(
        id: Value(account.id),
        balanceMinor:
            Value(account.balanceMinor - postingSignedImpact(row.posting)),
        lastUpdatedEventId: Value(gsn),
      ));
    }

    await _db.transactionsDao.markTransactionAsReversed(p.originalTransactionId);
    return affected;
  }

  @override
  Future<void> clear() async {
    await _db.transaction(() async {
      await _db.accountDao.clearAll();
      await _db.categoriesDao.clearAll();
      await _db.transactionsDao.clearAll();
      await _db.monthlySnapshotDao.clearAll();
    });
  }

  @override
  Future<void> stampProjectionVersion() async {
    await _db.transaction(() async {
      await (_db.update(_db.accountsView)).write(const AccountsViewCompanion(
          projectionVersion: Value(ledgerProjectionVersion)));
      await (_db.update(_db.categoriesView)).write(const CategoriesViewCompanion(
          projectionVersion: Value(ledgerProjectionVersion)));
      await (_db.update(_db.transactionsView)).write(
          const TransactionsViewCompanion(
              projectionVersion: Value(ledgerProjectionVersion)));
      await (_db.update(_db.monthlyAccountBalanceSnapshots)).write(
          const MonthlyAccountBalanceSnapshotsCompanion(
              projectionVersion: Value(ledgerProjectionVersion)));
    });
  }
}

@Riverpod(keepAlive: true)
LedgerProjector ledgerProjector(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return LedgerProjectorImpl(db);
}
