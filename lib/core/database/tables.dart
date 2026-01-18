import 'package:drift/drift.dart';

enum TransactionType { income, expense }
enum AccountType { cash, bank, credit, other }

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get type => intEnum<AccountType>()();
  RealColumn get initialBalance => real().withDefault(const Constant(0.0))();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get iconKey => text()();
  IntColumn get colorInt => integer()();
  IntColumn get type => intEnum<TransactionType>()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  IntColumn get type => intEnum<TransactionType>()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get accountId => integer().references(Accounts, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
