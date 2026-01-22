# feather_ledger Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-01-21

## Active Technologies
- **Framework**: Dart 3.x / Flutter 3.x (Latest Stable)
- **Architecture**: Strict MVVM (@.specify/memory/constitution.md)
- **State Management**: `flutter_riverpod` + `riverpod_generator`
- **Persistence**: `drift` (SQLite), `shared_preferences`
- **Navigation**: `go_router`
- **UI Components**: Material 3, `flutter_heatmap_calendar`, `fl_chart`
- **Localization**: `flutter_localizations`, `intl`

## Project Structure

High-level structure based on @specs/001-core-mvp/plan.md and @specs/002-optimize-ledger-ui/plan.md.

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
│   ├── ledger/                # Ledger: List, CRUD, Header
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/      # Screens, Widgets (TimeAnchor, TransactionTile), Providers
│   ├── reports/               # Reports: Heatmap, Donut Charts
│   └── settings/              # Settings: Theme, Locale, Currency
└── main.dart                  # Entry point
```

## Commands

### Setup & Build
- `flutter pub get`: Install dependencies
- `dart run build_runner build -d`: Generate code (Riverpod, Drift, Freezed)
- `flutter run`: Launch application

### Quality Assurance
- `flutter test`: Run unit and widget tests
- `flutter analyze`: Check for linting errors. 

## Code Style & Constitution

All development MUST adhere to the **Feather Ledger Constitution** defined in @.specify/memory/constitution.md.

1.  **Strict MVVM**: Logic in Riverpod Providers, UI in Widgets.
2.  **Riverpod Only**: Exclusive state management.
3.  **Material 3**: Use `Theme.of(context)`, no hardcoded colors/styles in features.
4.  **I18n First**: No hardcoded strings; use `.arb` files.
5.  **Testing**: Unit tests for logic, Widget tests for UI components.

## Recent Changes

### 002-optimize-ledger-ui (Current Focus)
**Specs**: @specs/002-optimize-ledger-ui/spec.md | **Plan**: @specs/002-optimize-ledger-ui/plan.md
- **Goal**: Visual overhaul of Ledger page to "Google Tasks" premium aesthetic.
- **Key Features**: Collapsing header, sticky "Time Anchor" (Day/Date), Skeleton loading, standardized "TransactionTile".
- **Status**: Implementation phase.

### 001-core-mvp (Foundation)
**Specs**: @specs/001-core-mvp/spec.md | **Plan**: @specs/001-core-mvp/plan.md
- **Goal**: Bottom nav, Transaction CRUD, Monthly Reports (Heatmap/Donut), Settings (Theme/Lang).
- **Status**: Core architecture and basic functionality established.

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->

**Mandatory: `flutter analyze` must be run after every code adjustment to ensure no syntax or linting errors are introduced.**
