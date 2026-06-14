import 'package:drift/drift.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';

// Write Model — final envelope schema (spec 003, US2/T018).
@TableIndex(name: 'idx_ledger_events_command_id', columns: {#commandId})
@DataClassName('LedgerEventRow')
class LedgerEvents extends Table {
  IntColumn get id => integer().autoIncrement()(); // GSN (global sequence)
  TextColumn get eventId => text().unique()();
  TextColumn get streamId => text()();
  IntColumn get aggregateType => intEnum<AggregateType>()();
  TextColumn get eventType => text()(); // Stable hand-declared string
  IntColumn get streamVersion => integer()();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get commandId => text()(); // Idempotency key
  TextColumn get payload => text()(); // JSON, embeds schemaVersion

  @override
  List<Set<Column>> get uniqueKeys => [
        {streamId, streamVersion},
      ];
}

// Read Models (Projections)

/// Event-sourced account projection (spec 003, US3/T025): single balance,
/// currency, archived flag, source-GSN cursor and projection version.
/// Written only by the ledger projector.
@DataClassName('AccountViewRow')
class AccountsView extends Table {
  TextColumn get id => text()(); // accountId (UUID)
  TextColumn get name => text()();
  IntColumn get type => intEnum<AccountType>()();
  TextColumn get currencyCode => text()();
  IntColumn get balanceMinor => integer()(); // Minor units
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get lastUpdatedEventId => integer()(); // Source GSN cursor
  IntColumn get projectionVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Event-sourced transaction projection (spec 003, US4/T033): one row per
/// transaction (aggregate root), amounts live in
/// [TransactionPostingsView]. Category name/icon/color are write-time
/// snapshots so history survives category archival without joining the
/// live category row. Written only by the ledger projector.
@TableIndex(name: 'idx_transactions_view_occurred_at', columns: {#occurredAt})
@DataClassName('TransactionViewRow')
class TransactionsView extends Table {
  TextColumn get transactionId => text()(); // aggregate root id
  DateTimeColumn get occurredAt => dateTime()();
  IntColumn get kind => intEnum<TransactionKind>()();
  TextColumn get description => text()();
  BoolColumn get isReversed => boolean().withDefault(const Constant(false))();
  // Write-time category snapshots; null for transfers (no category).
  TextColumn get categoryName => text().nullable()();
  TextColumn get categoryIcon => text().nullable()();
  TextColumn get categoryColorInt => text().nullable()(); // ARGB hex
  IntColumn get originalEventId => integer()(); // source GSN
  IntColumn get projectionVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {transactionId};
}

/// Posting-level projection (spec 003, US4/T033): amountMinor is always
/// positive, [direction] carries the sign. One row per posting; a transfer
/// has two rows sharing [transactionId].
@TableIndex(name: 'idx_transaction_postings_tx', columns: {#transactionId})
@DataClassName('TransactionPostingRow')
class TransactionPostingsView extends Table {
  TextColumn get id => text()(); // posting row id (UUID)
  TextColumn get transactionId => text()();
  TextColumn get accountId => text()();
  IntColumn get direction => intEnum<PostingDirection>()();
  IntColumn get amountMinor => integer()();
  TextColumn get currencyCode => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get memo => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Event-sourced category projection (spec 003, US3/T025). System
/// categories (the two built-in reversal adjustments) keep fixed ids and a
/// non-null [systemCode]; they cannot be archived. Written only by the
/// ledger projector.
@DataClassName('CategoryViewRow')
class CategoriesView extends Table {
  TextColumn get id => text()(); // categoryId (UUID; fixed for system rows)
  TextColumn get name => text()();
  TextColumn get iconKey => text()();
  IntColumn get colorInt => integer()();
  IntColumn get type => intEnum<CategoryType>()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get systemCode => text().nullable()();
  IntColumn get lastUpdatedEventId => integer()(); // Source GSN cursor
  IntColumn get projectionVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

// Recurring Series — CRUD-exempt: NOT event-sourced and NOT touched by
// projection rebuild (spec 003, US10/T068). Amounts are int minor units.
@DataClassName('RecurringSeriesRow')
class RecurringSeries extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get rrule => text()(); // RRULE string
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get frequency => text()(); // e.g. DAILY, WEEKLY
  IntColumn get interval => integer().nullable()();
  IntColumn get countLimit => integer()
      .nullable()(); // 'limit' is a reserved keyword in SQL often, using countLimit

  // Template Data
  IntColumn get amountMinor => integer()();
  TextColumn get description => text()();
  TextColumn get categoryId => text()();
  TextColumn get accountId => text()();
  // Type is useful for filtering
  IntColumn get type => intEnum<TransactionKind>()();

  @override
  Set<Column> get primaryKey => {id};
}

// Scheduled Transactions Projection — CRUD-exempt like [RecurringSeries]:
// instances are materialized and status-updated directly, never rebuilt.
@DataClassName('ScheduledTransactionViewRow')
class ScheduledTransactionsView extends Table {
  TextColumn get id => text()(); // Derived ID e.g. "seriesId_date"
  TextColumn get seriesId => text().references(RecurringSeries, #id)();
  DateTimeColumn get date => dateTime()();
  IntColumn get amountMinor => integer()();
  TextColumn get status => text()(); // 'pending', 'posted', 'skipped'
  TextColumn get transactionId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Monthly per-account balance snapshot (spec 003, US7/T051): one row per
/// (accountId, currencyCode, year, month), maintained by the snapshot
/// projector. Income/expense are signed posting impacts by kind (expense
/// negative); transfer legs land in transferIn/Out, never income/expense.
/// [eventSequenceFrom]/[eventSequenceTo] bracket the event GSNs the row's
/// current values were computed from. isClosed stays false — month closing
/// is not enabled (spec: 保留恒 false).
@DataClassName('MonthlyAccountBalanceSnapshot')
class MonthlyAccountBalanceSnapshots extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get accountId => text()();
  TextColumn get currencyCode => text()();
  IntColumn get year => integer()();
  IntColumn get month => integer()();
  IntColumn get openingBalanceMinor => integer()();
  IntColumn get closingBalanceMinor => integer()();
  IntColumn get incomeMinor => integer()();
  IntColumn get expenseMinor => integer()();
  IntColumn get transferInMinor => integer()();
  IntColumn get transferOutMinor => integer()();
  IntColumn get netChangeMinor => integer()();
  IntColumn get transactionCount => integer()();
  IntColumn get eventSequenceFrom => integer()();
  IntColumn get eventSequenceTo => integer()();
  IntColumn get projectionVersion => integer().withDefault(const Constant(1))();
  BoolColumn get isClosed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get rebuiltAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {accountId, currencyCode, year, month},
      ];
}
