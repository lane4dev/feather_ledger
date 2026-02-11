# Research: Event-Sourced Ledger Core

**Feature Branch**: `003-event-sourced-ledger` | **Date**: 2026-01-25

## 1. Event Sourcing Implementation in SQLite/Drift

**Decision**: Store events in a `ledger_events` table and maintain "Read Models" (Projections) in standard normalized tables (`transactions`, `accounts`, `balances`).

**Rationale**:
- **Query Performance**: UI needs to query "transactions for this month" or "current balance" instantly. Replaying events on every read is too slow.
- **Complexity**: Full ES (Event Store) databases are overkill for a local-first mobile app. Using SQLite for both events and projections allows **atomic transactions** (write event + update projection in one go), eliminating "eventual consistency" complexity.
- **Maintainability**: Drift provides excellent type-safe Dart bindings for SQLite, making schema management and queries robust.

**Alternatives Considered**:
- *Pure Event Replay*: Rebuild state in-memory on app launch. Rejected due to startup latency risk as data grows.
- *JSON Document Store*: Store projections as JSON blobs. Rejected because we need relational queries (e.g., "sum amount where category=X").

## 2. Event Serialization

**Decision**: Use `json_serializable` (via `freezed`) to serialize event payloads to a JSON Text column in SQLite.

**Rationale**:
- **Flexibility**: Event schemas evolve. Storing payload as JSON allows storing diverse event types in a single table without sparse columns.
- **Tooling**: Existing project uses `json_serializable`.
- **Searchability**: We don't need to SQL-query inside the event payload often; we query the Projections.

## 3. Recurring Transactions (RRULE)

**Decision**: Use `rrule` package for recurrence logic.

**Rationale**:
- **Standard**: RFC 5545 is the gold standard for recurrence.
- **Capability**: Handles complex rules (e.g., "last Friday of the month").
- **Projection**: We will project "Scheduled Transactions" into a read-model table for a rolling window (e.g., next 2 years), allowing the UI to query them like normal transactions.

## 4. Sequence Generation

**Decision**: Use SQLite's `AUTOINCREMENT` integer primary key as the Global Sequence Number.

**Rationale**:
- **Ordering**: Provides a strict, gap-free (mostly), monotonic ordering for deterministic replay.
- **Simplicity**: Native to SQLite.
- **Conflict**: Since it's local-first (single writer), concurrency conflicts on sequence numbers are non-existent.

## 5. Decimal Arithmetic

**Decision**: Use integer "minor units" (cents) for storage and `decimal` package for in-memory calculations if needed, or simple integer math.

**Rationale**:
- **Precision**: Floating point math is dangerous for finance.
- **Storage**: Integers are efficient and exact in SQLite.
- **Convention**: standard practice ($10.00 -> 1000).
