# Quickstart: Optimize Ledger UI

**Branch**: `002-optimize-ledger-ui`

## Prerequisites
-   Flutter 3.x+ installed.
-   Dependencies: `flutter_riverpod`, `intl`, `go_router` (already in project).

## Running the Feature
1.  **Checkout**: `git checkout 002-optimize-ledger-ui`
2.  **Run**: `flutter run`
3.  **Navigate**: The app opens to the Home page. The "Ledger" tab is the primary focus.

## Key Components to Verify
1.  **Header**: Scroll down. Does the "Month/Balance" header collapse smoothly?
2.  **Anchor**: Look at the left column. As you scroll past days, does the date (e.g., "20") stick until the day ends?
3.  **Add**: Tap FAB (+). Does the form look consistent with the new style?

## Troubleshooting
-   **Jittery Anchor**: Ensure you are in Release mode or Profile mode. Debug mode has overhead.
-   **Missing Icons**: Ensure `MaterialIcons` font is loaded (standard in Flutter).
