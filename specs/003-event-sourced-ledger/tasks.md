# Tasks: Event-Sourced Ledger Core

**Feature Branch**: `003-event-sourced-ledger`
**Feature Status**: Planned

## Phase 1: Setup & Infrastructure
**Goal**: Initialize the feature environment and install necessary dependencies for event sourcing and recurrence.

- [x] T001 Install dependencies (`rrule`, `uuid`, `clock`, `json_annotation`) and dev_dependencies (`build_runner`, `json_serializable`, `drift_dev`) in `pubspec.yaml`
- [x] T002 Create feature directory structure in `lib/features/ledger/` (data, domain, presentation)
- [x] T003 Create `core/database` migration placeholder for Drift schema updates in `lib/core/data/database/app_database.dart`

## Phase 2: Foundational (Domain & Data Layer)
**Goal**: Implement the core Event Store, Event definitions, and base Projection logic. This blocks all user stories.
**Independent Test Criteria**: Unit tests verify that `LedgerEvent` objects can be serialized/deserialized and stored/retrieved from SQLite with strictly ordered IDs and deterministic replay.

### 2.1 Event Model (The Source of Truth)
- [x] T004 [P] Define `LedgerEvent` sealed class and subclasses (`TransactionPosted`, `TransactionReversed`, `TransactionScheduled`, `TransactionPendingAdded`) in `lib/features/ledger/domain/events/ledger_event.dart`
- [x] T005 [P] Implement JSON serialization for all event types in `lib/features/ledger/domain/events/ledger_event.g.dart` (via build_runner)
- [x] T006 Define `ledger_events` Drift table schema in `lib/core/data/database/tables.dart` (ensure no float types for money; use Int/BigInt)
- [x] T007 Implement `EventsDao` with `appendEvent()` and `getStream()` methods in `lib/core/data/database/daos/events_dao.dart`
- [x] T042 Create strict ordering and idempotency unit tests for `EventsDao`: verify duplicate EventIDs are rejected and streams are strictly ordered by sequence number in `test/unit/core/data/database/daos/events_dao_test.dart`

### 2.2 Read Model (Projections)
- [x] T008 [P] Define `accounts_view` Drift table schema in `lib/core/data/database/tables.dart` including `credit_limit` (nullable), `type` (asset/liability), `posted_balance`, and `available_balance` (Use IntColumn for all money fields)
- [x] T009 [P] Refactor existing `Transactions` table into `transactions_view` Drift table schema including `status` (posted/pending/scheduled) in `lib/core/data/database/tables.dart` (Migrate `amount` to IntColumn)
- [x] T010 Implement `TransactionsDao` for querying projections in `lib/core/data/database/daos/transactions_dao.dart`
- [ ] T011 Create `LedgerRepository` interface in `lib/features/ledger/domain/repositories/ledger_repository.dart`
- [ ] T012 Implement `LedgerRepositoryImpl` handling atomic "Write Event + Update Projection" transaction in `lib/features/ledger/data/repositories/ledger_repository_impl.dart`
- [ ] T036 [P] Implement `CalculateAccountBalanceUseCase` domain logic covering posted vs available balance using pending status in `lib/features/ledger/domain/usecases/calculate_account_balance_usecase.dart`

## Phase 3: User Story 1 - Post Transaction (Income/Expense) (P1)
- [x] T013 [US1] Implement `PostTransactionUseCase` (command -> event generation) and wire into `LedgerService` in `lib/features/ledger/domain/usecases/post_transaction_usecase.dart`
- [x] T014 [US1] Create unit test for `PostTransactionUseCase` logic in `test/unit/features/ledger/domain/usecases/post_transaction_usecase_test.dart`
- [x] T015 [US1] Expose `accountBalanceProvider` and `recentTransactionsProvider` in `lib/features/ledger/presentation/providers/ledger_providers.dart`
- [x] T016 [US1] Update `TransactionFormScreen` to call `LedgerService.postTransaction` instead of legacy repository and remove unused legacy CRUD logic in `lib/features/ledger/presentation/screens/transaction_form_screen.dart`
- [x] T037 [US1] Create unit tests for liability scenarios (expense increases owed, payment decreases owed) in `test/unit/features/ledger/domain/liability_logic_test.dart`
- [x] T038 [US1] Implement `AccountSummaryCard` to display Owed/Available Credit for liabilities and Balance/Available for assets in `lib/features/ledger/presentation/widgets/account_summary_card.dart`

## Phase 4: User Story 2 & 3 - Edit/Delete via Reversal (P1)
- [x] T017 [US2] Implement `ReverseTransactionUseCase` (voiding logic) and wire into `LedgerService` in `lib/features/ledger/domain/usecases/reverse_transaction_usecase.dart`
- [x] T018 [US2] Implement `CorrectTransactionUseCase` (reverse + new post) and wire into `LedgerService` in `lib/features/ledger/domain/usecases/correct_transaction_usecase.dart`
- [x] T019 [US2] Create unit tests for reversal/correction use cases in `test/unit/features/ledger/domain/usecases/reversal_usecase_test.dart` (Verify net-zero impact with strict precision)
- [x] T020 [US2] Update `TransactionDetailScreen` to show void status and history in `lib/features/ledger/presentation/screens/transaction_detail_screen.dart`
- [x] T021 [US3] Connect "Delete" UI action to `reverseTransaction` in `lib/features/ledger/presentation/screens/transaction_detail_screen.dart`

## Phase 5: User Story 4 - Transfers (P2)
- [x] T022 [US4] Update `LedgerEvent` payload to support multiple legs list in `lib/features/ledger/domain/events/ledger_event.dart`
- [x] T023 [US4] Implement `PostTransferUseCase` logic and wire into `LedgerService` in `lib/features/ledger/domain/usecases/post_transfer_usecase.dart`
- [x] T024 [US4] Update `transactions_view` projection logic to handle multi-leg splitting (if needed) or linking in `lib/features/ledger/data/repositories/ledger_repository_impl.dart`
- [x] T025 [US4] Create unit test for transfer atomicity in `test/unit/features/ledger/domain/ledger_transfer_test.dart`

## Phase 6: User Story 5 - Recurring Bills (P3)
- [x] T026 [US5] Define `recurring_series` Drift table in `lib/core/data/database/tables.dart`
- [x] T027 [US5] Implement `ProjectRecurringEventsUseCase` to calculate future instances using `rrule` in `lib/features/ledger/domain/usecases/project_recurring_events_usecase.dart`
- [x] T028 [US5] Implement `scheduled_transactions_view` projection logic in `lib/features/ledger/data/repositories/recurring_repository_impl.dart`
- [x] T029 [US5] Expose `scheduledTransactionsProvider` in `lib/features/ledger/presentation/providers/ledger_providers.dart`
- [x] T039 [US5] Implement `LedgerService.convertScheduledToPosted` logic (emit TransactionPosted with ref to scheduled instance) in `lib/features/ledger/domain/services/ledger_service.dart`

## Phase 7: User Story 6 - Category Management (P3)
- [x] T030 [US6] Define `categories` table with `is_archived` and `archived_at` fields in `lib/core/data/database/tables.dart`
- [x] T031 [US6] Implement `CategoryRepository` methods for soft-delete/archive in `lib/core/data/repositories/category_repository.dart`
- [x] T032 [US6] Verify Reporting queries join on `category_id` in `lib/core/data/database/daos/reports_dao.dart`
- [ ] T040 [US6] Add UNIQUE partial index on `(type, lower(name))` WHERE `is_archived = 0` to `categories` table via Drift migration (Deferred)
- [ ] T041 [US6] Create integration test to verify duplicate active category creation fails, while archived duplicates are allowed in `test/integration/features/settings/category_constraint_test.dart`

## Phase 8: Polish & Cross-Cutting
- [x] T033 Implement `rebuildProjections()` method in `LedgerRepository` (truncate views -> replay all events) in `lib/features/ledger/data/repositories/ledger_repository_impl.dart`
- [ ] T034 Add integration test for full replay capability in `test/integration/features/ledger/replay_test.dart`
- [ ] T035 Verify NFR-001 (<100ms latency) with a benchmark test in `test/performance/ledger_benchmark_test.dart`

## Dependencies
1. **Phase 1 & 2** are blocking for ALL other phases.
2. **Phase 3 (US1)** is blocking for US2, US3, US4.
3. **Phase 4, 5, 6, 7** can be executed relatively in parallel after Phase 3.

## Implementation Strategy
- **MVP (Core)**: Phases 1, 2, 3. This gives a working "Append-Only" ledger for simple expenses.
- **Enhanced**: Phases 4, 5. Adds the critical "Reversal" logic and Transfers.
- **Complete**: Phases 6, 7. Adds advanced scheduling and organization.
