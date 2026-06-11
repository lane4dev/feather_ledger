# Implementation Plan: Event-Sourced Ledger Core

> ⚠️ **迁移前文档（过期标记，T001）**：本 plan 生成于事件化迁移之前，以下内容已被已确认规格 [spec.md](spec.md)（2026-09-06 同步）取代，**不可作为实现依据**：
> - **Project Structure** 的目录结构（`features/ledger/data/daos`、`models` 等；现行结构为 `lib/core/data/database/` + `lib/features/ledger/`，目标结构见 spec.md「Background」引用的 wayfinder lib/ 结构图）。
> - **Testing** 一节的 `golden_toolkit` 与 integration_test 假设；现行测试策略见 tasks.md「测试策略」（全部逻辑测试经领域服务 + 内存 Drift）。
> - 对旧 Draft spec 的引用（Draft 已被本目录 spec.md 取代）。
>
> 仍然有效的内容：技术栈选型（Dart/Flutter、Drift/SQLite、Riverpod、rrule、uuid、clock、本地优先）、性能目标与 Constitution 检查。实施依据一律为 [spec.md](spec.md) + [tasks.md](tasks.md)。

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
