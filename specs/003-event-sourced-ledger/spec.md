# Feature Specification: Event-Sourced Ledger Core

**Feature Branch**: `003-event-sourced-ledger`
**Created**: 2026-01-25
**Status**: Draft  
**Input**: User description: (See original prompt)

## Clarifications

### Session 2026-01-25
- Q: Should manual entry of "pending" transactions be supported in the UI, or just in the architecture? → A: Architecture Support Only: Define TransactionPendingAdded event and AvailableBalance logic, but do not build UI to create them manually.
- Q: How should events be ordered to ensure deterministic replay? → A: Global Sequence Number: Every event gets a unique, auto-incrementing integer ID at persistence time.
- Q: Where should the projections (Read Models) be stored for UI queries? → A: Separate Table (SQL): Maintain normalized SQL tables for transactions and accounts, updated by projection logic.
- Q: What is the database strategy for the Event Log and Projections? → A: Event Log + Projections in same SQLite: Use the existing Drift/SQLite setup but add a ledger_events table for the source of truth.
- Q: How should a user-driven "Account Balance Change" (reconciliation) be handled? → A: Implicit (Auto-calculate): User enters a target balance; system calculates the difference from the current projection and emits a BalanceAdjustmentApplied event.
- Q: How should projections be kept up-to-date with the event log? → A: Event-driven (on-demand): Projections are persisted; new events update the projection tables in the same transaction.

## User Scenarios & Testing *(mandatory)*
### User Story 1 - Post Transaction (Income/Expense) (Priority: P1)

As a user, I want to record an income or expense so that my account balance reflects the real-world activity.

**Why this priority**: Fundamental capability of the ledger.

**Independent Test**: Verify that adding a transaction emits a `TransactionPosted` event and updates the `PostedBalanceProjection`.

**Acceptance Scenarios**:
1. **Given** an asset account with balance $100, **When** I post a $50 expense, **Then** a `TransactionPosted` event is appended, and the account balance becomes $50.
2. **Given** a liability (credit card) account with owed balance $100, **When** I post a $50 expense, **Then** a `TransactionPosted` event is appended, and the owed balance becomes $150.
3. **Given** an asset account with balance $10, **When** I post a $50 expense, **Then** the transaction is accepted (allowing negative balance), and the balance becomes -$40.

---

### User Story 2 - Edit Transaction via Reversal (Priority: P1)

As a user, I want to correct a mistake in a past transaction so that my ledger is accurate, without losing the history of the error.

**Why this priority**: Core requirement for the "Reversal-Only" architecture; ensures auditability.

**Independent Test**: Edit a transaction and verify the event log contains the original, a `TransactionReversed` event, and a new `TransactionPosted` event.

**Acceptance Scenarios**:
1. **Given** a transaction T1 exists, **When** I edit the amount from $50 to $60, **Then** the system emits `TransactionReversed(target=T1)` AND `TransactionPosted(newDetails=$60)`.
2. **Given** the timeline view, **Then** the UI shows the corrected transaction (and optionally groups/hides the reversed pair), but the balance reflects only the net effect of the new transaction.

---

### User Story 3 - Delete Transaction via Reversal (Priority: P1)

As a user, I want to remove an erroneous transaction so that it no longer affects my balance.

**Why this priority**: Essential CRUD operation handled via the new event-sourcing paradigm.

**Independent Test**: Delete a transaction and verify the event log contains a `TransactionReversed` event and the balance reverts to the pre-transaction state.

**Acceptance Scenarios**:
1. **Given** a transaction T1 exists, **When** I delete it, **Then** the system emits `TransactionReversed(target=T1)` only.
2. **Given** a deleted transaction, **Then** it is marked as "voided" in the UI (or hidden) and does not contribute to the `PostedBalanceProjection`.

---

### User Story 4 - Transfers (Priority: P2)

As a user, I want to move money between accounts so that both balances are updated correctly.

**Why this priority**: Common financial activity requiring atomicity across two accounts.

**Independent Test**: Create a transfer and verify `TransactionPosted` contains two legs (outflow and inflow).

**Acceptance Scenarios**:
1. **Given** Account A ($100) and Account B ($0), **When** I transfer $50 from A to B, **Then** a single `TransactionPosted` event is recorded with two legs: Leg 1 (A, -$50), Leg 2 (B, +$50).
2. **Given** a transfer exists, **When** I delete it, **Then** a `TransactionReversed` event is emitted, reversing impacts on BOTH Account A and Account B.

---

### User Story 5 - Recurring Bills & Scheduling (Priority: P3)

As a user, I want to schedule future transactions so that I can forecast my cash flow.

**Why this priority**: Adds forward-looking value to the ledger.

**Independent Test**: Create a recurring series and verify `TransactionScheduled` events are projected for future dates.

**Acceptance Scenarios**:
1. **Given** a recurring monthly bill, **When** I view next month, **Then** I see `TransactionScheduled` instances.
2. **Given** a scheduled instance, **When** I mark it as paid, **Then** a `TransactionPosted` event is emitted (converting scheduled to posted).
3. **Given** a recurring series, **When** I skip one occurrence, **Then** a `RecurringOccurrenceSkipped` event is recorded, and that specific instance disappears from the timeline.

---

### User Story 6 - Category Management (Priority: P3)

As a user, I want to organize my transactions by category and maintain historical accuracy even if I change my category structure.

**Why this priority**: Reporting accuracy.

**Independent Test**: Archive a category and verify old transactions still reference it in reports.

**Acceptance Scenarios**:
1. **Given** a category "Food" with transactions, **When** I archive "Food", **Then** the transactions remain linked to the "Food" category ID.
2. **Given** "Food" is archived, **When** I create a new "Food" category, **Then** it gets a new ID, preventing mix-ups with the old category in reports (unless explicitly merged, but default is separate).

---

### Edge Cases

- **Negative Balance**: Asset accounts ALLOW negative balances (e.g., overdraft).
- **Available Credit Unknown**: If a credit card has no `creditLimit` set, the "Available Credit" field displays as "Unknown" or hidden, rather than $0 or infinite.
- **Replay Error**: If the event log is corrupted (checksum fail), the system must halt projection rebuilding and alert (theoretical, low level).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST persist all domain changes as an append-only stream of immutable events (Event Store).
- **FR-002**: System MUST support `TransactionPosted`, `TransactionPendingAdded`, `TransactionScheduled`, and `TransactionReversed` event types (Note: `TransactionPendingAdded` is architecture-only; no manual UI entry).
- **FR-003**: System MUST enforce "Reversal-Only" editing: editing/deleting a transaction emits a `TransactionReversed` event (referencing the target event ID) rather than mutating the original record.
- **FR-004**: System MUST project `PostedBalanceProjection` for Asset accounts as `opening + sum(posted inflows - posted outflows)`.
- **FR-005**: System MUST project `PostedBalanceProjection` for Liability accounts (Credit Cards) as `opening owed + sum(posted charges - posted payments)` (Positive value = Debt).
- **FR-006**: System MUST calculate `AvailableBalance` for Asset accounts: `postedBalance ± pending legs`.
- **FR-007**: System MUST calculate `AvailableCredit` for Liability accounts: `creditLimit - (posted owed + pending charges)` if limit exists; otherwise "Unknown".
- **FR-008**: System MUST support Transfers as a single `TransactionPosted` event containing two balanced legs (fromAccount, toAccount).
- **FR-009**: System MUST support Recurring Series using RRULE + EXDATE semantics, projecting future occurrences as `TransactionScheduled`.
- **FR-010**: System MUST NOT aggregate reports by Category Name; MUST aggregate by Category ID to support renaming/archiving correctly.
- **FR-011**: System MUST allow negative balances on Asset accounts (Option 1).
- **FR-012**: System MUST be able to completely rebuild all Projections (Read Models) by replaying the Event Log from genesis.

### Non-Functional Requirements

- **NFR-001**: Event persistence and projection update MUST complete in <100ms for single events to maintain UI responsiveness.
- **NFR-002**: System MUST support full projection rebuild from the event log for recovery purposes.
- **NFR-003**: All monetary calculations MUST use decimal/fixed-point arithmetic to prevent rounding errors.

### Key Entities

- **LedgerEvent**: The source of truth. Fields: `id`, `sequenceNumber` (global monotonic int), `type`, `occurredAt`, `effectiveAt`, `payload` (JSON), `correlationId`.
- **Transaction (Read Model)**: A projection of a transaction, containing its current state (derived from Posted/Reversed events).
- **Account (Read Model)**: Contains `postedBalance`, `availableBalance`, `type` (Asset/Liability).
- **RecurringSeries**: Defines rules for generating scheduled transactions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: **Auditability**: 100% of balance changes can be traced back to a specific sequence of events; no "ghost" changes.
- **SC-002**: **Replayability**: The system can rebuild the entire read-model storage from the Event Log in under 5 seconds for 10,000 events.
- **SC-003**: **Data Integrity**: Reversing a transaction results in a net-zero impact on the account balance with 0.00 deviation.
- **SC-004**: **User Trust**: Users can view "voided" or "corrected" transactions in history if they choose, verifying that the app didn't just "delete" data silently.