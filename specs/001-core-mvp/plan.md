# Implementation Plan: Core MVP

**Branch**: `001-core-mvp` | **Date**: 2026-01-18 | **Spec**: [specs/001-core-mvp/spec.md](./spec.md)
**Input**: Feature specification from `specs/001-core-mvp/spec.md`

## Summary

Implement the Core MVP of Feather Ledger, a local-first Flutter personal finance app. This includes the bottom navigation shell, Ledger feature (transaction CRUD + monthly grouping), Reports feature (Heatmap + Donut charts), and Settings (Theme/Locale). The app will be built using strict MVVM architecture with Riverpod for state management and Drift (SQLite) for persistence.

## Technical Context

**Language/Version**: Dart 3.x / Flutter (Latest Stable)
**Primary Dependencies**:
-   `flutter_riverpod`, `riverpod_generator` (State Management)
-   `drift`, `sqlite3_flutter_libs` (Persistence)
-   `go_router` (Navigation)
-   `flutter_localizations` (i18n)
-   `fl_chart` (Donut Charts)
-   `flutter_heatmap_calendar` (Heatmap)
-   `shared_preferences` (Settings)
**Storage**: SQLite (via Drift) for business data; SharedPreferences for user settings.
**Testing**: `flutter_test` (Unit/Widget), `integration_test`.
**Target Platform**: Android (Primary), iOS.
**Project Type**: Mobile Application.
**Performance Goals**: 60fps scrolling, <2s cold start.
**Constraints**: 100% Offline, Material 3 Design System.
**Scale/Scope**: ~10 screens, ~2000 LOC est.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

-   **MVVM**: Enforced via directory structure (data/domain/presentation).
-   **Riverpod**: Exclusive state manager.
-   **Material 3**: Enforced via `ThemeData(useMaterial3: true)` and strict widget usage.
-   **i18n**: Configured from day one.
-   **Linting**: `flutter_lints` enabled.

## Project Structure

### Documentation (this feature)

```text
specs/001-core-mvp/
├── plan.md              # This file
├── research.md          # Tech stack decisions
├── data-model.md        # Drift schema and entity definitions
├── quickstart.md        # Run/Test instructions
└── tasks.md             # Execution tasks
```

### Source Code (repository root)

```text
lib/
├── app/                       # App-wide configuration
│   ├── config/                # Environment config
│   ├── l10n/                  # Localization .arb files
│   ├── router/                # GoRouter definition
│   └── theme/                 # Material 3 Theme definition
├── core/                      # Shared utilities
│   ├── database/              # Drift Database & DAOs
│   └── utils/                 # Extensions, Formatters
├── features/
│   ├── ledger/                # Feature: Ledger List & CRUD
│   │   ├── data/              # Repositories & DTOs
│   │   ├── domain/            # Entities & UseCases
│   │   └── presentation/      # Widgets & Riverpod Providers
│   ├── reports/               # Feature: Visual Reports
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── settings/              # Feature: Settings & Preferences
│       ├── data/
│       └── presentation/
└── main.dart                  # Entry point
```

**Structure Decision**: Modular Feature-based Architecture. Each feature (Ledger, Reports, Settings) encapsulates its own Data/Domain/Presentation layers, promoting separation of concerns and scalability. `Core` contains shared infrastructure like the Database.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | | |