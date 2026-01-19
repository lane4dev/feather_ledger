---
description: "Task list for Feather Ledger Core MVP"
---

# Tasks: Feather Ledger - Core MVP

**Input**: Design documents from `specs/001-core-mvp/`
**Prerequisites**: plan.md, spec.md, data-model.md, research.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure.

- [x] T001 Create project structure (`lib/app`, `lib/core`, `lib/features`) per plan.md
- [x] T002 Add dependencies (`flutter_riverpod`, `drift`, `go_router`, etc.) to `pubspec.yaml`
- [x] T003 [P] Configure linting rules in `analysis_options.yaml`
- [x] T004 [P] Setup localization (`l10n.yaml` and `lib/app/l10n/app_en.arb`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T005 Create Material 3 Theme definition in `lib/app/theme/app_theme.dart`
- [x] T006 Define Drift Tables (`Accounts`, `Categories`, `Transactions`) in `lib/core/database/tables.dart`
- [x] T007 Initialize Drift Database connection in `lib/core/database/app_database.dart`
- [x] T008 [P] Setup `GoRouter` with Bottom Navigation Shell in `lib/app/router/app_router.dart`
- [x] T009 Setup `main.dart` with `ProviderScope`, `MaterialApp`, and `AppLocalizations`

**Checkpoint**: Foundation ready - Database is schema-ready, App runs with Shell (Bottom Nav), Theme is active.

---

## Phase 3: User Story 1 - Ledger Management (Priority: P1) 🎯 MVP

**Goal**: View transactions, add new records, and see running balance.

**Independent Test**: Launch app, see empty ledger, add transaction, see it appear in list with updated balance.

### Implementation for User Story 1

- [x] T010 [P] [US1] Create Domain Entities (`Transaction`, `Category`, `Account`) in `lib/features/ledger/domain/entities/ledger_entities.dart`
- [x] T011 [P] [US1] Create `TransactionDao` with CRUD operations in `lib/core/database/daos/transaction_dao.dart`
- [x] T012 [US1] Create `LedgerRepository` implementation in `lib/features/ledger/data/repositories/ledger_repository.dart`
- [x] T013 [US1] Create `LedgerService` (Business Logic) in `lib/features/ledger/domain/services/ledger_service.dart`
- [x] T014 [US1] Implement Riverpod Providers (List, Balance) in `lib/features/ledger/presentation/providers/ledger_providers.dart`
- [x] T015 [US1] Create `TransactionFormScreen` (Add/Edit) in `lib/features/ledger/presentation/screens/transaction_form_screen.dart`
- [x] T016 [US1] Create `LedgerScreen` (List + Month Filter) in `lib/features/ledger/presentation/screens/ledger_screen.dart`

**Checkpoint**: User Story 1 (Core MVP) fully functional. Can Add/View/Edit transactions.

---

## Phase 4: User Story 2 - Visual Reports (Priority: P2)

**Goal**: View Spending/Income Heatmap and Donut Charts.

**Independent Test**: Navigate to Reports tab, see charts reflecting the data entered in US1.

### Implementation for User Story 2

- [x] T017 [US2] Add Aggregation Queries (Heatmap, Category Totals) to `TransactionDao` in `lib/core/database/daos/transaction_dao.dart`
- [x] T018 [US2] Create `ReportsRepository` implementation in `lib/features/reports/data/repositories/reports_repository.dart`
- [x] T019 [US2] Create Reports Providers (Chart Data) in `lib/features/reports/presentation/providers/reports_providers.dart`
- [x] T020 [US2] Implement `ReportsScreen` with `flutter_heatmap_calendar` and `fl_chart` in `lib/features/reports/presentation/screens/reports_screen.dart`

**Checkpoint**: User Stories 1 & 2 functional. Reports visualize the Ledger data.

---

## Phase 5: User Story 3 - Settings & Localization (Priority: P3)

**Goal**: Change Language, Theme, and Currency.

**Independent Test**: Toggle Language/Theme in Settings, verify app updates immediately.

### Implementation for User Story 3

- [x] T021 [P] [US3] Create `SettingsRepository` (SharedPreferences wrapper) in `lib/features/settings/data/repositories/settings_repository.dart`
- [x] T022 [US3] Create Settings Providers (ThemeMode, Locale, Currency) in `lib/features/settings/presentation/providers/settings_providers.dart`
- [x] T023 [US3] Implement `SettingsScreen` UI in `lib/features/settings/presentation/screens/settings_screen.dart`
- [x] T024 [US3] Integrate Settings Providers into `main.dart` (Theme/Locale) and `LedgerScreen` (Currency)

**Checkpoint**: App is fully customizable and localized.

---

## Phase 6: User Story 4 - Accounts & Budgets (Priority: P4 - Stretch)

**Goal**: Manage multiple accounts (Cash, Bank).

**Independent Test**: Create new Account, assign transaction to it.

### Implementation for User Story 4

- [x] T025 [P] [US4] Create `AccountDao` in `lib/core/database/daos/account_dao.dart`
- [x] T026 [US4] Create `AccountRepository` in `lib/features/settings/data/repositories/account_repository.dart`
- [x] T027 [US4] Implement `AccountListScreen` and `AccountFormScreen` in `lib/features/settings/presentation/screens/account_management_screen.dart`

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final verification and cleanup.

- [x] T028 Verify Offline Persistence (Restart app and check data)
- [x] T029 Run `flutter analyze` and fix linting issues
- [x] T030 Run `flutter test` (if unit tests added)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundational (Phase 2)**: Blocks all User Stories.
- **User Stories (Phase 3+)**: US1 is the base. US2 & US3 depend on Foundational but can be largely parallelized after US1 data structures are settled.

### User Story Dependencies

- **US1 (Ledger)**: Core Data Creator. Must be first to have meaningful data for other stories.
- **US2 (Reports)**: Read-only consumer of US1 data.
- **US3 (Settings)**: Cross-cutting, affects UI of US1/US2.

### Implementation Strategy

1. **MVP Base**: Complete Phase 1 & 2.
2. **Core Loop**: Complete US1. **Validate**: Can I track my spending?
3. **Insights**: Complete US2. **Validate**: Can I see where money goes?
4. **Personalization**: Complete US3. **Validate**: Is it usable in my language/theme?
5. **Bonus**: Complete US4 if time permits.