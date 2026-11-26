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
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  /// Whether this account counts toward the **ledger totals** (CONTEXT.md).
  /// Not the same switch as [archived], and pointed the other way: archiving
  /// takes an account out of the pickers but keeps it in the totals; this one
  /// leaves it everywhere and takes it out of the totals alone.
  ///
  /// The default is what every account that predates this column gets, and it
  /// is the honest answer — nobody had opted out before it existed.
  BoolColumn get includeInTotals =>
      boolean().withDefault(const Constant(true))();
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

  /// JSON metadata copied from `TransactionRecorded.attachments`. The bytes
  /// themselves live in the app-private attachment directory, not SQLite.
  TextColumn get attachmentsJson => text().withDefault(const Constant('[]'))();

  /// The scheduled-bill instance id this transaction was posted from
  /// (spec 006, US47). Null for ad-hoc transactions. Event-backed so the
  /// source-bill → latest-transaction link survives corrections and rebuilds.
  TextColumn get sourceScheduledBillId => text().nullable()();
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
  DateTimeColumn get archivedAt => dateTime().nullable()();
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

  /// 'limit' is a reserved keyword in SQL often, using countLimit
  IntColumn get countLimit => integer().nullable()();

  // Template Data
  IntColumn get amountMinor => integer()();
  TextColumn get description => text()();
  TextColumn get categoryId => text()();
  TextColumn get accountId => text()();
  // Type is useful for filtering. Narrower than TransactionKind: a series
  // has one account, so a transfer is not representable (ADR-0002).
  IntColumn get type => intEnum<RecurringSeriesKind>()();

  /// Whether due instances post themselves at launch. Only valid when
  /// [mode] is [RecurringSeriesMode.repeating].
  BoolColumn get autoPost => boolean().withDefault(const Constant(false))();

  /// The creation mode (计划 / 重复). Persisted so the intent survives a
  /// restart and the backup; immutable after creation.
  IntColumn get mode =>
      intEnum<RecurringSeriesMode>().withDefault(const Constant(0))();

  /// Minutes before each scheduled occurrence; null means no reminder.
  IntColumn get reminderMinutes => integer().nullable()();

  /// Whether this rule is active. Setting false stops future materialization
  /// without touching historical rows.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Lower bound for materialization and budget virtual projection.
  /// Kept separate from [startDate] so historical start dates remain the RRULE
  /// schedule and [countLimit] anchor while skipping unwanted historical bills.
  DateTimeColumn get materializeFrom => dateTime().withDefault(
      Constant(DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)))();

  /// Number of posted occurrences completed prior to a schedule reset.
  /// Subtracted from [countLimit] during expansion so lifetime count remains
  /// exact across schedule edits.
  IntColumn get completedCountOffset =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// Scheduled Transactions Projection — CRUD-exempt like [RecurringSeries]:
// instances use stable UUID PKs and a semantic unique constraint on
// (seriesId, occurrenceKey).
@DataClassName('ScheduledTransactionViewRow')
class ScheduledTransactionsView extends Table {
  TextColumn get id => text()(); // Independent UUID
  TextColumn get seriesId => text().references(RecurringSeries, #id)();
  TextColumn get occurrenceKey => text()(); // YYYY-MM-DD or 'single'
  DateTimeColumn get scheduledDate => dateTime()();
  IntColumn get amountOverrideMinor => integer().nullable()();
  DateTimeColumn get dateOverride => dateTime().nullable()();
  TextColumn get memoOverride => text().nullable()();
  TextColumn get status => text()(); // 'scheduled', 'posted', 'skipped', 'failed'
  BoolColumn get manualOnly => boolean().withDefault(const Constant(false))();
  TextColumn get transactionId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {seriesId, occurrenceKey},
      ];
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

/// Budget rules — CRUD-exempt (ADR-0006): stepped effective-month timeline
/// per `(currencyCode, categoryId)`. `amountMinor == null` is an explicit
/// `unset` breakpoint halting carry-forward from [effectiveYm] onward.
@DataClassName('BudgetRuleRow')
class BudgetRules extends Table {
  TextColumn get currencyCode => text()();
  TextColumn get categoryId => text()();
  IntColumn get effectiveYm => integer()(); // year * 100 + month
  IntColumn get amountMinor => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {currencyCode, categoryId, effectiveYm};
}

/// Review notes — CRUD-exempt (ADR-0006): plain-text retrospective notes per
/// `(currencyCode, ym, categoryKey)`, where `categoryKey == ''` denotes the
/// month-level review note (avoiding SQLite NULL non-uniqueness in PKs).
@DataClassName('BudgetReviewNoteRow')
class BudgetReviewNotes extends Table {
  TextColumn get currencyCode => text()();
  IntColumn get ym => integer()(); // year * 100 + month
  TextColumn get categoryKey => text()(); // '' for month-level, else categoryId
  TextColumn get note => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {currencyCode, ym, categoryKey};
}
