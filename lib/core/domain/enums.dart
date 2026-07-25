/// Shared domain enums (spec 003, US1/T012).
///
/// Amount enums carry no sign semantics — money direction lives in
/// [PostingDirection]; amounts are int minor units everywhere.
library;

/// Transaction kind. The declaration order is persisted by Drift, so new
/// values must only ever be appended.
enum TransactionKind {
  income,
  expense,
  transfer,
  openingBalance,
  balanceAdjustment,
}

extension TransactionKindSemantics on TransactionKind {
  bool get requiresCategory =>
      this == TransactionKind.income || this == TransactionKind.expense;

  bool get isBalancePurpose =>
      this == TransactionKind.openingBalance ||
      this == TransactionKind.balanceAdjustment;

  bool get contributesToIncomeExpense => requiresCategory;
}

/// Balance direction of a posting (personal-bookkeeping semantics, defined
/// only here): credit = balance increases by amountMinor;
/// debit = balance decreases by amountMinor.
enum PostingDirection { credit, debit }

/// Category kind: income or expense.
enum CategoryType { income, expense }

/// Transaction kind a recurring series may produce.
///
/// Deliberately narrower than [TransactionKind]: a series carries a single
/// account, so a transfer has no second leg to express and is not
/// representable (ADR-0002) — it is refused by the type rather than by a
/// check that a future writer could forget.
///
/// Declaration order matches [TransactionKind]'s first two values, which is
/// what keeps the `recurring_series.type` column encoding unchanged.
/// Reordering this enum would silently reinterpret every stored row.
enum RecurringSeriesKind { income, expense }

extension RecurringSeriesKindMapping on RecurringSeriesKind {
  TransactionKind get toTransactionKind => switch (this) {
        RecurringSeriesKind.income => TransactionKind.income,
        RecurringSeriesKind.expense => TransactionKind.expense,
      };
}

/// Account type: cash, bank, credit card, other.
enum AccountType { cash, bank, credit, other }
