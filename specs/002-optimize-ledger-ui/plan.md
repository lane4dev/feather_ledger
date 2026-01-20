# Implementation Plan: Optimize Ledger UI

**Branch**: `002-optimize-ledger-ui` | **Date**: 2026-01-20 | **Spec**: [specs/002-optimize-ledger-ui/spec.md](specs/002-optimize-ledger-ui/spec.md)
**Input**: Feature specification from `specs/002-optimize-ledger-ui/spec.md`

## Summary

This plan outlines the visual overhaul of the Ledger page to achieve a "clean, minimal, premium" aesthetic resembling Google Tasks. The core changes involve a complex scrolling layout with a collapsing header and a stable, pinned left-side "Time Anchor". The implementation will strictly adhere to existing business logic (MVVM/Riverpod) while refactoring the UI layer into modular, performant components.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x (Latest Stable)
**Primary Dependencies**: `flutter_riverpod`, `go_router`, `intl`
**Storage**: N/A (UI only; uses existing Repository)
**Testing**: `flutter_test` (Widget Tests), `golden_toolkit` (for visual regression)
**Target Platform**: Android (primary), iOS
**Project Type**: Mobile Application
**Performance Goals**: 60fps scrolling with complex list items; <16ms frame time during header collapse/expand.
**Constraints**: No new external packages unless absolutely necessary. Strict Material 3 usage.
**Scale/Scope**: Refactoring ~2 main screens and ~5 sub-components.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Strict MVVM Architecture**: ✅ Plan keeps logic in ViewModels (Providers), UI in Widgets.
- **II. State Management with Riverpod**: ✅ Uses existing and new Riverpod providers.
- **III. Material 3 Minimalist Design**: ✅ Core goal of this feature.
- **IV. Internationalization (i18n) First**: ✅ EN/ZH support mandated.
- **V. High Code Quality & Maintainability**: ✅ Component-based refactoring.
- **VI. Comprehensive Testing**: ✅ Widget tests and Golden tests planned.

## 4.1 Plan Overview

### Goals
- Transform `LedgerScreen` into a premium, timeline-based view.
- Implement a collapsing header (Month Switcher + Balance).
- Implement a sticky "Time Anchor" (Day/Date) on the left.
- Unify Empty/Loading (Skeleton)/Error states.
- Restyle `TransactionFormScreen` to match the new aesthetic.

### 001 Baseline & Reuse
- **Existing**: `LedgerScreen`, `TransactionFormScreen`, `LedgerService`, `LedgerRepository`.
- **Reuse**:
    - `ledgerSummaryProvider` & `ledgerTransactionsProvider` (Data layer unchanged).
    - `selectedDateProvider` (Logic unchanged).
    - `TransactionType` enum & entities.
- **Refactor**:
    - `LedgerScreen` → Break into `LedgerHeader`, `LedgerTimeline`, `TransactionTile`.
    - `TransactionFormScreen` → Apply new `AppTheme` tokens and layout adjustments.

### Risks & Mitigation
- **Risk**: Time Anchor "jitter" when scrolling.
    - **Mitigation**: Use `SliverPersistentHeader` or a verified `ScrollController` listener with a debounced state update, or a custom `RenderObject` if standard widgets fail (unlikely). Recommended: `SliverPersistentHeader` for grouped headers + `CustomScrollView`.
- **Risk**: Header overlapping content.
    - **Mitigation**: Strict use of `Slivers` and `SliverOverlapInjector` (if needed) or explicit padding logic.
- **Risk**: ZH text overflow in narrow columns (Time Anchor).
    - **Mitigation**: `FittedBox` or strictly defined constraints with text scaling support.
- **Risk**: Performance with large lists.
    - **Mitigation**: `SliverList` with `builder` delegate (lazy rendering).

## 4.2 UI Structure & Component Map

### `LedgerPage` (Scaffold)
- **TopAppBar**: Minimal, possibly transparent or merged with Header.
- **Body**: `CustomScrollView`
    - `SliverAppBar` (Floating/Pinned/Snap): Contains `LedgerHeader`.
    - `SliverPadding` (Top spacing).
    - `SliverMainAxisGroup` (Flutter 3.13+) or Multi-Sliver approach for grouped transactions.

### Components
1.  **`LedgerHeader`** (Collapsing)
    -   **`MonthSwitcher`**: Row with `IconButton` (left/right) and `InkWell` (center date).
        -   Tap month label opens a month/year picker (dialog/bottom sheet); selecting a month updates selected month state.
    -   **`BalanceSummary`**:
        -   Expanded: Large Balance + Income/Expense Row.
        -   Collapsed: Small Balance next to Month.
2.  **`LedgerTimeline`** (The List)
    -   **`TimeAnchor`**: The left column widget (e.g., "20 / Mon").
    -   **`TransactionGroup`**: A grouping of transactions for a single day.
    -   **`TransactionTile`**:
        -   **Left**: Time Anchor Placeholder (invisible/spacer to align content).
        -   **Center**: Title (Text), Meta (Category icon + name + tags + low-contrast separators).
        -   **Right**: Amount (Colored + Sign).
3.  **`TransactionForm`** (Restyled)
    -   Standardized inputs using `AppTextField` (conceptually) or styled `TextFormField`.
4.  **`FeedbackViews`**
    -   `LedgerSkeleton`: Shimmer effect for the entire structure.
    -   `LedgerEmpty`: Styled "No transactions" view.
    -   `LedgerError`: Retryable error view.

### `TimeAnchor` (Pinned Group Header) – Component Contract

**Visual format**: vertical stack (example: `20` on line 1, `Mon` on line 2)

**Layout rules**
- Render as a two-line vertical column:
  - Top: day-of-month text (`text.anchor_day`)
  - Bottom: weekday short label (`text.anchor_wday`)
- Center-align both lines within the anchor column width (`col.anchor`)
- Avoid shrinking text to fit (do not rely on `FittedBox` to scale down text)
  - Prefer: wrapping, increasing header height, or allowing `col.anchor` to expand within a defined max range

**Localization**
- Use locale-aware weekday formatting (EN: `Mon`; ZH: localized short weekday)
- Ensure the weekday label remains short; if necessary, define a locale-specific abbreviation strategy

**Semantics (A11y)**
- Treat the pinned TimeAnchor as a section header:
  - `Semantics(header: true, label: "<Localized full date>")`
- The visual “20 / Mon” is a styling choice; the semantic label should be the full, localized date

**Pinned behavior**
- Implement the group anchor using `SliverPersistentHeader(pinned: true, ...)` so it remains visible until pushed by the next group.

## 4.3 Visual System (Ledger-local Tokens)

These tokens apply specifically to the Ledger feature to ensure the "premium" feel.

| Token | Value (Reference) | Usage |
| :--- | :--- | :--- |
| `gap.xs` | 4dp | Tight grouping (e.g., amount sign vs number) |
| `gap.sm` | 8dp | Standard internal padding |
| `gap.md` | 16dp | Section padding, tile padding |
| `gap.lg` | 24dp | Major layout separation |
| `col.anchor` | 72dp | Fixed width for Time Anchor column |
| `text.balance` | `headlineMedium` | Primary balance (Expanded) |
| `text.anchor_day` | `titleLarge` | Day number (e.g., "20") |
| `text.anchor_wday`| `bodySmall` | Weekday (e.g., "Mon") |
| `radius.card` | 16dp | Summary card / Form containers |

**Typography**:
-   **Amount**: `titleMedium` (Bold, Monospace optional).
-   **Title**: `bodyLarge` (Medium weight).
-   **Meta**: `bodySmall` (Muted color).

**Colors (ColorScheme roles)**:
-   **Income**: `primary` or `tertiary` (Green-aligned in theme).
-   **Expense**: `error` (Red-aligned).
-   **Anchor Text**: `onSurfaceVariant` (Muted).
-   **Background**: `surface` / `surfaceContainer` (Subtle banding if needed).

**Time Anchor Visual Format**

- The Time Anchor displays **two lines in a vertical stack**:
  - Line 1: **day-of-month** (e.g., `20`)
  - Line 2: **weekday short label** (e.g., `Mon`)
- The two lines are **center-aligned within the anchor column** and remain readable at common text scales.
- The weekday label is **localized** (e.g., EN: `Mon`, `Tue`; ZH: localized weekday short form).
- The Time Anchor must not visually compete with transaction content:
  - it uses a muted emphasis compared to the transaction Amount/Title hierarchy.
- The vertical “`20 / Mon`” format must remain stable under:
  - EN/ZH locale
  - long lists and slow scrolling
  - header expanded/collapsed states (no overlap with header; no layout jumps)


## 4.4 Scroll & Layout Strategy

### Comparison
-   **Option A (Sticky Headers)**: Use `CustomScrollView` with `SliverMainAxisGroup` (if available) or `sticky_headers` package.
    -   *Pros*: Native "sticky" feel, simplest implementation of "Anchor stays visible".
    -   *Cons*: `sticky_headers` might be an external dep. Flutter's native `SliverPersistentHeader` is powerful but verbose for many small groups.
-   **Option B (Recommended): Native Slivers with Pinned Headers**
    -   Use a `CustomScrollView`.
    -   Each Day Group is a `SliverMainAxisGroup` (Flutter 3.13+) containing:
        -   `SliverPersistentHeader` (Pinned): Displays the `TimeAnchor`.
        -   `SliverList`: Displays the transactions for that day.
    -   *Why Recommended*: Native, performant, handles "pushing" the previous anchor up naturally. Zero 3rd-party dependencies.
    -   *Header Collapse*: Use `SliverAppBar` with `floating: true, pinned: true, snap: false`.

### Anchor Logic (Option B details)
-   The `SliverPersistentHeader` for "Jan 20" will stick to the top (under the `SliverAppBar`) until the "Jan 20" list scrolls off, at which point "Jan 19" header pushes it out.
-   **Alignment**: The `TimeAnchor` widget inside the header must visually align with the "Left Column" of the list.
-   **Header Sync**: The `SliverAppBar` handles the Month/Balance collapse automatically via `FlexibleSpaceBar`.

## 4.5 State Management (Riverpod)

### ViewModels
1.  **`ledgerStateProvider`**: (Existing `selectedDateProvider` + `ledgerTransactionsProvider`)
    -   Needs a *Selector* or *Provider* that groups transactions by date: `dailyTransactionsProvider`.
    -   Returns: `Map<DateTime, List<Transaction>>` (Sorted Descending).
2.  **`ledgerUiStateProvider`** (New):
    -   Manage pure UI state if complex (e.g., "isFilterOpen"). For now, mostly handled by Widget state (scroll position).

### Data Flow
-   `ref.watch(dailyTransactionsProvider)` -> Builds the `CustomScrollView` -> Iterates Map Keys -> Creates `SliverMainAxisGroup` per day.
-   **Month Change**: Updates `selectedDateProvider` -> Triggers fetch -> AsyncValue loads -> UI shows Skeleton -> UI shows new list.
-   **Scroll-to-top**: On `selectedDate` change, use `ScrollController.animateTo(0)`.

## 4.6 Accessibility (A11y)

-   **Time Anchor**: Should ideally be excluded from semantics if the List Items contain the date, OR implemented as a Section Heading.
    -   *Decision*: `TimeAnchor` is a Section Header. `Semantics(header: true, label: "January 20")`.
-   **TransactionTile**: `ListTile` semantics. "Groceries, $50 expense, Jan 20".
-   **Touch Targets**: Minimum 48x48dp for Month arrows and Transaction taps.
-   **Text Scale**: Ensure `TimeAnchor` column width (`72dp`) expands or text wraps if user sets huge font size. (Use `Flexible` inside the header row).

## 4.7 Testing Strategy

### Golden Tests (`test/goldens`)
1.  **`ledger_loaded_golden`**: Full populated list, expanded header.
2.  **`ledger_scrolled_golden`**: Collapsed header, pinned anchor visible.
3.  **`ledger_empty_golden`**: "No transactions".
4.  **`ledger_skeleton_golden`**: Shimmer state.
5.  **`ledger_zh_golden`**: Chinese text validation.

### Widget Tests (`test/widgets`)
-   **Group Logic**: Verify `dailyTransactionsProvider` correctly groups items.
-   **Navigation**: Verify tapping "Next Month" calls `setMonth` and resets scroll.
-   **Interaction**: Verify tapping a tile triggers navigation to Detail (mocked).

## 4.8 File Changes

### New Files (Create)
-   `lib/features/ledger/presentation/widgets/ledger_header.dart` (Header + MonthSwitcher + Balance)
-   `lib/features/ledger/presentation/widgets/ledger_timeline.dart` (The ScrollView + Group logic)
-   `lib/features/ledger/presentation/widgets/transaction_tile.dart` (The premium list item)
-   `lib/features/ledger/presentation/widgets/time_anchor.dart` (The sticky date widget)
-   `lib/features/ledger/presentation/widgets/ledger_skeleton.dart` (Loading state)
-   `lib/features/ledger/presentation/screens/transaction_detail_sheet.dart` (Read-only bottom sheet)

### Modified Files
-   `lib/features/ledger/presentation/screens/ledger_screen.dart` (Refactor to use new structure)
-   `lib/features/ledger/presentation/screens/transaction_form_screen.dart` (Restyle)
-   `lib/features/ledger/presentation/providers/ledger_providers.dart` (Add grouped data provider)

## Phase 0: Research & Preparation
*(Already largely covered by local investigation, but formalizing)*
-   **Task**: Validate `SliverMainAxisGroup` availability (Flutter 3.13+). *Confirmed: Feather Ledger uses Latest Stable.*
-   **Task**: Define exact color palette mapping from Material 3 roles.

## Phase 1: Design & Contracts
-   **Data Model**: No changes to DB. Grouping logic is pure Domain/Presentation mapping.
-   **Contracts**: N/A (Local DB).

## Phase 2: Implementation Tasks
(To be generated by `/speckit.tasks`)
