# Implementation Plan: Event-Sourced Ledger Core

**Branch**: `003-event-sourced-ledger` | **Date**: 2026-01-25 | **Spec**: [specs/003-event-sourced-ledger/spec.md](specs/003-event-sourced-ledger/spec.md)
**Input**: Feature specification from `specs/003-event-sourced-ledger/spec.md`

## Summary

Refactor the core ledger domain to use an **Event Sourcing** architecture. This ensures every balance change is traceable to an immutable event, supporting complex features like "Reversal-Only" editing, time-travel debugging, and robust audit trails. The implementation remains local-first (SQLite) but separates "Write Model" (Events) from "Read Model" (Projections).

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x (Latest Stable)
**Primary Dependencies**:
- `flutter_riverpod` (State Management)
- `drift`, `sqlite3_flutter_libs` (Persistence: Events & Projections)
- `rrule` (Recurring transaction logic)
- `uuid` (Event & Transaction IDs)
- `clock` (Testable time)
**Storage**: SQLite (Single DB file containing both `ledger_events` and projection tables).
**Testing**:
- `flutter_test` (Unit tests for reducers/projections).
- `integration_test` (Drift DAO & Migration tests).
- `golden_toolkit` (UI Golden tests).
**Target Platform**: Android (primary), iOS.
**Project Type**: Mobile Application.
**Performance Goals**: <100ms for event write + projection update; <5s to rebuild 10k events from scratch.
**Constraints**: 100% Offline, Strict MVVM, Reversal-Only edits.
**Scale/Scope**: Refactoring core Data/Domain layers; impacting Ledger & Reports features.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Strict MVVM Architecture**: ✅ Plan decouples Domain (Events/Reducers) from UI (ViewModels).
- **II. State Management with Riverpod**: ✅ Providers will expose Read Models (e.g., `accountBalanceProvider`); Events dispatched via Services.
- **III. Material 3 Minimalist Design**: ✅ UI changes limited to integrating new data sources; existing M3 style preserved.
- **IV. Internationalization (i18n) First**: ✅ N/A for core logic, but UI updates must respect locale.
- **V. High Code Quality & Maintainability**: ✅ Event Sourcing improves long-term maintainability and debuggability.
- **VI. Comprehensive Testing**: ✅ Critical for this refactor. Unit tests for event reducers are mandatory.

## Project Structure

### Documentation (this feature)

```text
specs/003-event-sourced-ledger/
├── plan.md              # This file
├── research.md          # Tech stack decisions (Drift, RRULE)
├── data-model.md        # Event schemas & Projection definitions
├── quickstart.md        # Migration & Usage guide
└── tasks.md             # Execution tasks
```

### Source Code (repository root)

```text
lib/
├── features/
│   ├── ledger/
│   │   ├── data/
│   │   │   ├── daos/                  # EventsDao, TransactionsDao
│   │   │   ├── models/                # Drift Tables (Events, Projections)
│   │   │   └── repositories/          # LedgerRepositoryImpl
│   │   ├── domain/
│   │   │   ├── events/                # LedgerEvent (Sealed Class), EventType
│   │   │   ├── models/                # Transaction, Account (Read Models)
│   │   │   └── services/              # LedgerService (Command Handler)
│   │   └── presentation/              # Updated Providers & ViewModels
│   └── reports/                       # Updates to consume new Read Models
└── core/
    └── database/                      # Drift Database Schema updates
```

**Structure Decision**: Modular Feature-based Architecture. The "Ledger" feature will encapsulate the new Event Sourcing logic. `core/database` will manage the shared SQLite connection and migrations.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Event Sourcing | Strict Auditability & "Reversal-Only" requirement | CRUD (Mutating state) loses history and makes "undo/correct" logic brittle and prone to "ghost" errors. |
