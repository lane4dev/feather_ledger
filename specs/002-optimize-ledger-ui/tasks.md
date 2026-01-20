# Tasks: Optimize Ledger UI

**Branch**: `002-optimize-ledger-ui` | **Spec**: [specs/002-optimize-ledger-ui/spec.md](specs/002-optimize-ledger-ui/spec.md)
**Plan**: [specs/002-optimize-ledger-ui/plan.md](specs/002-optimize-ledger-ui/plan.md)

## Implementation Strategy

-   **Incremental Refactoring**: We will modify `LedgerScreen` in place but build new sub-components (`LedgerHeader`, `TransactionTile`, etc.) first to minimize breakage.
-   **No New Deps**: We will implement a custom "pulse" animation for the skeleton loader to avoid adding the `shimmer` package if not already present, ensuring 0 new dependencies.
-   **Sliver-First**: The core layout relies on `SliverMainAxisGroup` (Flutter 3.13+). Ensure your Flutter environment is up to date.

## Phase 1: Setup & Data Layer
*Goal: Prepare the theme tokens and data grouping logic required for the UI.*

- [X] T001 Define Ledger-specific theme tokens (colors, spacing, text styles) in `lib/features/ledger/presentation/theme/ledger_theme.dart` (or similar file)
- [X] T002 Implement `dailyTransactionsProvider` logic to group transactions by date in `lib/features/ledger/presentation/providers/ledger_providers.dart`
- [X] T003 [P] Create placeholder widget files (`ledger_header.dart`, `ledger_timeline.dart`, `transaction_tile.dart`) to unblock parallel work

## Phase 2: Foundational Components (Blocking)
*Goal: Build the atomic UI components that will be assembled into the main screen.*

- [X] T004 [US2] Implement `TransactionTile` with new visual hierarchy (Amount > Title > Meta) in `lib/features/ledger/presentation/widgets/transaction_tile.dart`
  - hierarchy: Amount (primary) > Title (secondary) > Meta (tertiary)
  - Meta supports 1–2 lines (icons + subtle dot/tag slots); defines truncation/wrapping rules for long text
  - low-contrast separators (avoid heavy dividers)
  - lightweight trailing icon slot (visual-only; must not introduce new behavior)
- [X] T005 [US2] Implement `TimeAnchor` widget (Day/Weekday stack) with fixed width in `lib/features/ledger/presentation/widgets/time_anchor.dart`
- [X] T006 [US1] Implement `LedgerHeader` (Month Switcher + Balance) with `collapsed` vs `expanded` layout logic in `lib/features/ledger/presentation/widgets/ledger_header.dart`

## Phase 3: User Story 1 - Header & Page Structure
*Goal: Establish the new `CustomScrollView` layout and collapsible header behavior.*

- [X] T007 [US1] Refactor `LedgerScreen` to use `CustomScrollView` and `SliverAppBar` in `lib/features/ledger/presentation/screens/ledger_screen.dart`
- [X] T008 [US1] Integrate `LedgerHeader` into the `SliverAppBar` using `FlexibleSpaceBar` or similar mechanism in `lib/features/ledger/presentation/screens/ledger_screen.dart`
- [X] T008A [US1][US2] Implement the “Left Column Alignment Contract”:
  - reserve `col.anchor` width in `LedgerHeader` (same as `TimeAnchor` column)
  - ensure the pinned `TimeAnchor` is always positioned below the header (expanded/collapsed)
  - prevent overlap and visible jitter during header expand/collapse
  (apply in `ledger_header.dart`, `ledger_screen.dart`, and `ledger_timeline.dart` as needed)
- [X] T009 [US1] Verify Month Switcher navigation updates `selectedDateProvider` and resets scroll position
- [X] T009A [US1] Implement month label tap → month/year picker (dialog or bottom sheet) and update `selectedDateProvider` accordingly; after month load completes, reset list scroll to top and refresh anchor context


## Phase 4: User Story 2 - Timeline & Anchor
*Goal: Implement the sticky time anchor and grouped transaction list.*

- [X] T010 [US2] Implement `LedgerTimeline` widget using `SliverMainAxisGroup` and `SliverPersistentHeader` for groups in `lib/features/ledger/presentation/widgets/ledger_timeline.dart`
- [X] T011 [US2] Connect `LedgerTimeline` to `dailyTransactionsProvider` in `lib/features/ledger/presentation/widgets/ledger_timeline.dart`
- [X] T012 [US2] Ensure `TimeAnchor` pins correctly under the App Bar and is pushed up by the next group
- [X] T012A [US2] Confirm anchor semantics match the spec’s Anchor Switching Rule (first visible transaction item’s group key) and document any boundary behavior (e.g., when group header is partially visible) in code comments near the anchor implementation


## Phase 5: User Story 3 - Feedback States
*Goal: Consistent Empty, Error, and Loading (Skeleton) states.*

- [X] T013 [US3] Implement `LedgerSkeleton` with custom pulse animation (no external pkg) in `lib/features/ledger/presentation/widgets/ledger_skeleton.dart`
- [X] T014 [US3] Implement `LedgerEmpty` state (styled "No Transactions") in `lib/features/ledger/presentation/widgets/ledger_empty.dart` (or inline if simple)
- [X] T015 [US3] Update `LedgerScreen` to show Skeleton/Empty/Error states based on AsyncValue in `lib/features/ledger/presentation/screens/ledger_screen.dart`, ensuring Month Switcher remains usable in all states

## Phase 6: User Story 4 - Add & Detail
*Goal: Restyle secondary surfaces to match the new premium aesthetic.*

- [X] T016 [US4] Restyle `TransactionFormScreen` (inputs, spacing, buttons) to match new tokens in `lib/features/ledger/presentation/screens/transaction_form_screen.dart`
- [X] T017 [US4] Implement `TransactionDetailSheet` (read-only bottom sheet) in `lib/features/ledger/presentation/screens/transaction_detail_sheet.dart`
- [X] T018 [US4] Wire up `TransactionTile` tap event to open `TransactionDetailSheet` in `lib/features/ledger/presentation/widgets/transaction_tile.dart`

## Phase 7: Polish & Validation
*Goal: Final testing and accessibility checks.*

- [X] T019 Ensure text scaling works for `TimeAnchor` (wrap/scale) and `LedgerHeader`
- [X] T020 Verify localization (EN/ZH) layout stability (no overflows)
  - long titles/notes
  - very large amounts
  - month label formats
  - no overflow/overlap that blocks interaction
- [X] T021 [Test] Create Golden tests for `LedgerScreen` (Loaded, Empty, Skeleton) in `test/ui/features/ledger/ledger_screen_golden_test.dart`


## Dependencies

1.  **T001 (Tokens)** blocks visual implementation of **T004–T015**
2.  **T002 (Provider)** blocks **T011 (Timeline Wiring)**
3.  **T004, T005, T006 (Components)** block **T007, T010 (Screens/Timeline)**
4.  **T008A (Alignment Contract)** should be completed before validating **T012/T012A** (anchor positioning & jitter)
5.  **T009A (Month Picker)** depends on **T006 (LedgerHeader)** and should be verified alongside **T009**
6.  **T022 (Anchor Switching Widget Test)** depends on **T010–T012A**

## Parallel Execution Opportunities

- **UI Components**: T004 (`TransactionTile`), T005 (`TimeAnchor`), and T006 (`LedgerHeader`) can be built in parallel once T001 (Tokens) is done.
- **Timeline vs. Feedback Views**: Phase 5 (Skeleton/Empty/Error) can be built in parallel with Phase 3 or 4.
- **Tests**: Golden tests (T021) can start once Phase 3 renders the new header; anchor switching widget test (T022) can start once Phase 4 implements grouping and pinned anchor behavior.
