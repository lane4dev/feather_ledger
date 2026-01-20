# Data Model & State: Optimize Ledger UI

**Branch**: `002-optimize-ledger-ui`

## Entities (Existing, Unchanged)

### `Transaction`
-   `id`: int (PK)
-   `amount`: double
-   `type`: TransactionType (income/expense)
-   `date`: DateTime
-   `note`: String?
-   `categoryId`: int (FK)
-   `accountId`: int (FK)
-   ... relations (Category, Account)

## Presentation Models (New / Refined)

### `TransactionGroup`
Used to render the `SliverMainAxisGroup`.
-   `date`: DateTime (The anchor date, time stripped)
-   `transactions`: List<Transaction> (Transactions for this day)
-   `dailyTotal`: double (Optional, for future use)

### `LedgerSummary` (Existing)
-   `totalIncome`: double
-   `totalExpense`: double
-   `runningBalance`: double

## ViewModels (Providers)

### `dailyTransactionsProvider` (New)
-   **Type**: `Provider<AsyncValue<Map<DateTime, List<Transaction>>>>`
-   **Logic**:
    1.  Watch `ledgerTransactionsProvider` (returns `List<Transaction>`).
    2.  If loading/error, bubble up.
    3.  If data, group by `DateUtils.dateOnly(tx.date)`.
    4.  Sort keys (Dates) descending.
    5.  Return the Map.

### `selectedDateProvider` (Existing)
-   **Type**: `StateNotifier<DateTime>`
-   **Logic**: Holds the currently viewed month.

## UI State

### `LedgerUiState` (Implicit in Widget Tree)
-   `ScrollController` offset: Managed by `CustomScrollView`.
-   `HeaderCollapsed`: Derived from scroll offset vs `kToolbarHeight`.
