// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_dao.dart';

// ignore_for_file: type=lint
mixin _$BudgetDaoMixin on DatabaseAccessor<AppDatabase> {
  $BudgetRulesTable get budgetRules => attachedDatabase.budgetRules;
  $BudgetReviewNotesTable get budgetReviewNotes =>
      attachedDatabase.budgetReviewNotes;
  $CategoriesViewTable get categoriesView => attachedDatabase.categoriesView;
  $TransactionsViewTable get transactionsView =>
      attachedDatabase.transactionsView;
  $TransactionPostingsViewTable get transactionPostingsView =>
      attachedDatabase.transactionPostingsView;
  $AccountsViewTable get accountsView => attachedDatabase.accountsView;
  $RecurringSeriesTable get recurringSeries => attachedDatabase.recurringSeries;
  $ScheduledTransactionsViewTable get scheduledTransactionsView =>
      attachedDatabase.scheduledTransactionsView;
  BudgetDaoManager get managers => BudgetDaoManager(this);
}

class BudgetDaoManager {
  final _$BudgetDaoMixin _db;
  BudgetDaoManager(this._db);
  $$BudgetRulesTableTableManager get budgetRules =>
      $$BudgetRulesTableTableManager(_db.attachedDatabase, _db.budgetRules);
  $$BudgetReviewNotesTableTableManager get budgetReviewNotes =>
      $$BudgetReviewNotesTableTableManager(
          _db.attachedDatabase, _db.budgetReviewNotes);
  $$CategoriesViewTableTableManager get categoriesView =>
      $$CategoriesViewTableTableManager(
          _db.attachedDatabase, _db.categoriesView);
  $$TransactionsViewTableTableManager get transactionsView =>
      $$TransactionsViewTableTableManager(
          _db.attachedDatabase, _db.transactionsView);
  $$TransactionPostingsViewTableTableManager get transactionPostingsView =>
      $$TransactionPostingsViewTableTableManager(
          _db.attachedDatabase, _db.transactionPostingsView);
  $$AccountsViewTableTableManager get accountsView =>
      $$AccountsViewTableTableManager(_db.attachedDatabase, _db.accountsView);
  $$RecurringSeriesTableTableManager get recurringSeries =>
      $$RecurringSeriesTableTableManager(
          _db.attachedDatabase, _db.recurringSeries);
  $$ScheduledTransactionsViewTableTableManager get scheduledTransactionsView =>
      $$ScheduledTransactionsViewTableTableManager(
          _db.attachedDatabase, _db.scheduledTransactionsView);
}
