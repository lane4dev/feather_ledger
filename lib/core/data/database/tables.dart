import 'package:drift/drift.dart';

import 'package:feather_ledger/core/domain/enums.dart';

// Write Model
@DataClassName('LedgerEventRow')
class LedgerEvents extends Table {
  IntColumn get id => integer().autoIncrement()(); // GSN
  TextColumn get eventId => text().unique()();
  TextColumn get type => text()();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get payload => text()(); // JSON
  TextColumn get correlationId => text().nullable()();
  TextColumn get metadata => text().nullable()(); // JSON
}

// Read Models (Projections)
@DataClassName('AccountViewRow')
class AccountsView extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text()();
  IntColumn get type => intEnum<AccountType>()();
  IntColumn get postedBalance => integer()(); // Minor units
  IntColumn get availableBalance => integer()(); // Minor units
  IntColumn get lastUpdatedEventId => integer()(); // Cursor

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionViewRow')
class TransactionsView extends Table {
  TextColumn get id => text()(); // UUID (PK) - specific leg ID
  TextColumn get transactionId => text()(); // Group ID (Logic ID)
  TextColumn get accountId => text().references(AccountsView, #id)();
  DateTimeColumn get date => dateTime()();
  IntColumn get amount => integer()(); // Minor units
  TextColumn get description => text()();
  TextColumn get categoryId =>
      text()(); // UUID reference to Categories (assuming updated later) or just ID
  BoolColumn get isReversed => boolean().withDefault(const Constant(false))();
  IntColumn get originalEventId => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// Keeping Categories for now, but will likely need refactor to UUIDs to match TransactionView
@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text()();
  TextColumn get iconKey => text()();
  IntColumn get colorInt => integer()();
  IntColumn get type => intEnum<TransactionType>()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  BoolColumn get isBuildIn => boolean().withDefault(const Constant(false))();
  TextColumn get systemCode => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Recurring Series
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
  IntColumn get amount => integer()();
  TextColumn get description => text()();
  TextColumn get categoryId => text()();
  TextColumn get accountId => text()();
  // Type is useful for filtering
  IntColumn get type => intEnum<TransactionType>()();

  @override
  Set<Column> get primaryKey => {id};
}

// Scheduled Transactions Projection
@DataClassName('ScheduledTransactionViewRow')
class ScheduledTransactionsView extends Table {
  TextColumn get id => text()(); // Derived ID e.g. "seriesId_date"
  TextColumn get seriesId => text().references(RecurringSeries, #id)();
  DateTimeColumn get date => dateTime()();
  IntColumn get amount => integer()();
  TextColumn get status => text()(); // 'pending', 'posted', 'skipped'
  TextColumn get transactionId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
