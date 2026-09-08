/// Shared domain enums (spec 003, US1/T012).
///
/// Amount enums carry no sign semantics — money direction lives in
/// [PostingDirection]; amounts are int minor units everywhere.
library;

/// Transaction kind (spec Domain Model). `transfer` is the single
/// exclusion criterion for income/expense statistics — no other code path
/// may invent a second one.
enum TransactionKind { income, expense, transfer }

/// Balance direction of a posting (personal-bookkeeping semantics, defined
/// only here): credit = balance increases by amountMinor;
/// debit = balance decreases by amountMinor.
enum PostingDirection { credit, debit }

/// Category kind: income or expense.
enum CategoryType { income, expense }

/// Account type: cash, bank, credit card, other.
enum AccountType { cash, bank, credit, other }
