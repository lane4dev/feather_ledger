# Research & Findings: Optimize Ledger UI

**Branch**: `002-optimize-ledger-ui`
**Date**: 2026-01-20

## 1. Scroll & Layout Architecture

**Decision**: Use `CustomScrollView` with `SliverMainAxisGroup` (Flutter 3.13+) and `SliverPersistentHeader`.

**Rationale**:
-   **Native Sticky Headers**: `SliverPersistentHeader` provides the exact "pinned" behavior required for the Time Anchor without external packages.
-   **Performance**: `SliverList` ensures lazy rendering of large transaction lists.
-   **Collapsing Header**: `SliverAppBar` integrates seamlessly into `CustomScrollView` for the main page header.
-   **Grouping**: `SliverMainAxisGroup` allows treating a Header + List as a single scrollable unit, perfect for "Day" groupings.

**Alternatives Considered**:
-   *sticky_headers package*: Rejected to avoid external dependencies.
-   *Overlay approach*: Too complex to synchronize manually with scroll position; prone to jitter.

## 2. Time Anchor "Jitter" Mitigation

**Decision**: The "Jitter" risk is mitigates by using the native `pinned: true` property of `SliverPersistentHeader`.

**Mechanism**:
-   As the user scrolls, the header for "Day X" stays pinned at the top of the viewport (under the app bar).
-   When the bottom of "Day X" group reaches the header, it naturally pushes the header out of view (standard Sliver behavior).
-   This avoids manual calculation of "first visible item" in Dart code, pushing that logic to the highly optimized Flutter engine.

## 3. Component Modularization

**Decision**: Break `LedgerScreen` into distinct widgets (`LedgerHeader`, `LedgerTimeline`, `TransactionTile`).

**Rationale**:
-   **Maintainability**: The existing `LedgerScreen` was becoming a monolith.
-   **Reusability**: `TransactionTile` might be used in search results or other future views.
-   **Testability**: Smaller widgets are easier to test in isolation (Widget Tests).

## 4. Skeleton Loading Strategy

**Decision**: Implement a custom `LedgerSkeleton` widget using standard `Shimmer` effects (or a manual gradient animation if `shimmer` package is avoided, but `shimmer` is standard). *Correction*: To strictly stick to "No new packages", we will implement a simple linear gradient animation using `SingleTickerProviderStateMixin` or just static gray placeholders if animation is too heavy.

**Refinement**: We will use a simple "pulsing" opacity animation or static gray boxes to simulate loading, keeping dependencies zero.

## 5. Localization & Text Scaling

**Decision**:
-   **Time Anchor**: Fixed width (`72dp`) but allow text to wrap or scale down slightly (`FittedBox`) if system font size is huge.
-   **Amount**: Prioritize visibility. If space is tight, truncate the *Title*, never the *Amount*.

## 6. Data Grouping Logic

**Decision**: Implement `groupedTransactionsProvider` in the Presentation layer.

**Rationale**:
-   The Data layer returns a raw list sorted by date.
-   Grouping by "Day" is a UI-specific concern (how it's displayed).
-   This keeps the Domain layer pure.
