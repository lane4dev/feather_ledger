# Research: Core MVP

**Feature**: `001-core-mvp`
**Date**: 2026-01-18

## 1. Database & Persistence
**Requirement**: Local persistence, offline-first.
**Options**:
-   **A. Drift (SQLite)**: Strongly typed, reactive, compile-time checks. Excellent Riverpod integration.
-   **B. Hive**: NoSQL, fast, pure Dart. Less structured query capability.
-   **C. Isar**: Successor to Hive, highly performant.
**Decision**: **Option A (Drift)**.
**Rationale**: The "Running Balance" and "Reports" features require aggregation queries (SUM, GROUP BY date/category) which are native and efficient in SQL. Drift provides type-safe SQL which matches the "High Code Quality" constitution mandate.

## 2. State Management & Architecture
**Requirement**: MVVM, Riverpod.
**Pattern**:
-   **Data Layer**: Drift Database -> DAOs -> Repositories.
-   **Domain Layer**: Pure Dart entities (mapped from Drift classes).
-   **Presentation Layer**:
    -   `AsyncNotifier` providers for managing UI state.
    -   Controllers for complex user actions.
**Decision**: Use `riverpod_generator` for all providers to ensure syntax consistency and type safety.

## 3. Visualization Components
**Requirement**: Heatmap and Donut Chart.

### 3.1 Heatmap
**Options**:
-   **A. flutter_heatmap_calendar**: dedicated package, matches "GitHub contributions" style.
-   **B. Custom GridView**: Complete control, high effort.
**Decision**: **Option A (flutter_heatmap_calendar)**.
**Rationale**: Fits the "calendar style intensity" requirement out of the box. customizable enough for MVP.

### 3.2 Donut Chart
**Options**:
-   **A. fl_chart**: Industry standard for Flutter charts. Highly customizable.
-   **B. graphic**: Grammar of graphics library (Wilkinson).
**Decision**: **Option A (fl_chart)**.
**Rationale**: specific support for Pie/Donut charts with robust animation and touch interaction support.

## 4. Internationalization (i18n)
**Requirement**: EN + zh-CN, instant switch.
**Decision**: Standard `flutter_localizations` with `.arb` files.
**Rationale**: Native Flutter support, easiest to maintain.
