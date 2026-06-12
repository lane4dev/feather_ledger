# Feather Ledger — Agent Instructions

## Project context

- Personal bookkeeping app (记账): accounts, income/expense transactions, recurring schedules, monthly reports. Bilingual (en / zh_Hans / zh_Hant), Material 3.
- Flutter/Dart using strict MVVM, Riverpod (codegen), Drift/SQLite, GoRouter, ARB-based localization, fl_chart for reports.
- The authoritative engineering principles are in `.specify/memory/constitution.md`; read and follow them before changing code.
- Feature specifications and plans live under `specs/`. The current event-sourcing work is `specs/003-event-sourced-ledger/`.

## Architecture overview

Strict layering, mirrored per feature:

```
lib/app/        bootstrap (seeder), config (currencies/languages/app info), GoRouter, theme, l10n
lib/core/       shared kernel: database + DAOs + repo impls (data), entities/enums/events/repo
                interfaces (domain), global providers — theme/locale/currency/balance
                visibility/categories/accounts (presentation)
lib/features/   ledger, reports, settings — each split into data / domain / presentation
lib/shared/     cross-feature widgets and extensions
```

Within a feature:

- `domain/commands/` — write use cases. Emit domain events, persisted via `DriftEventStore.append` and projected by `LedgerProjectorImpl` in the same database transaction.
- `domain/queries/` — read use cases streaming Drift views.
- `domain/services/` — facades composing commands + queries (`LedgerService`, `AccountService`); the entry point the UI consumes.
- `domain/repositories/` (interfaces) ↔ `data/repositories/` (impls), wired by Riverpod providers.
- CQRS by naming convention: each command/query is a plain class with `execute()`, constructor-injected deps, and a hand-written `@riverpod` provider in the same file. No command bus.
- Presentation: widgets → view model (`@riverpod` notifier) → service → command/query. Widgets hold no business logic.

## Event-sourced ledger model

- `ledger_events` is the write model: JSON payload per event (embedded `schemaVersion`), autoincrement id = global sequence number (GSN), `unique(streamId, streamVersion)`, commandId dedup. Nine event types: `TransactionRecorded`, `TransactionReversed` (userDeleted | correction), `AccountCreated/Renamed/Archived`, `CategoryCreated/Renamed/Archived`, `OpeningBalanceSet`. Event factories are registered in production at bootstrap (`register_ledger_events.dart`); upcasting reads through the registry.
- Read models are Drift tables projected at write time: `accounts_view` (single `balanceMinor` + archived + `lastUpdatedEventId` cursor), `transactions_view` (one row per transaction, kind, isReversed, write-time category snapshots) + `transaction_postings_view` (posting-level rows), `categories_view`, `monthly_account_balance_snapshots`. `recurring_series` and `scheduled_transactions_view` are CRUD-exempt (never touched by rebuild).
- `LedgerProjectorImpl` is the only projection writer and the only balance calculation point; every append drives it inside the same database transaction. Snapshot maintenance lives in `MonthlySnapshotProjectorImpl` (per-account recompute from the anchor month).
- `LedgerRebuildService` rebuilds the five event-sourced views from the event store in one transaction (startup runs it when a view's projectionVersion is stale; settings page has a long-press developer entry). Unknown event types hard-fail with the event id.
- Corrections are `TransactionReversed(correction)` + `TransactionRecorded` pairs in one command/one transaction; UI delete is `TransactionReversed(userDeleted)`. Reversed rows are hidden from the read model; the audit chain stays in the event store.

## Money convention (important)

DB rows and events use signed int minor units (expense negative, income positive), end to end — including scheduled/recurring entities (`amountMinor`). The only double bridge is `Money.fromDouble` at the presentation input boundary; formatting goes through `formatMinor`.

## App flow

- `main.dart`: manual `ProviderContainer` → open `db.sqlite` (background isolate) → `seedDatabase` (event-sourced: AccountCreated/OpeningBalanceSet/CategoryCreated × N incl. 2 built-in system categories; names localized at seed time; idempotent on empty event store) → rebuild-if-stale check → `runApp`.
- Router: `StatefulShellRoute` with 3 tabs — `/ledger`, `/reports`, `/more`. `/ledger/add` and `/ledger/edit` push on the root navigator. `/accounts_management` and `/categories_management` are top-level routes opened from the transaction form's pickers.
- Ledger state: `LedgerViewModel` (keepAlive notifier) holds selected month, snapshot-sourced monthly totals, scheduled transactions, per-account balances; the transaction list watches the `ledgerMonthlyTransactionsProvider(month)` family directly (mapped via `TransactionUiMapper`, grouped by day).
- Preferences via SharedPreferences (`PreferencesRepository`): theme mode, locale, currency, balance visibility.

## Testing layout

- `test/unit/` mirrors `lib/` (DAOs, repositories, commands, services); `test/ui/` for widget behavior; `test/support/` has fakes, mocks, fixtures.
- Event serialization tests go through the production registry (`registerLedgerEvents()`); there is no test-only factory registration.

## Required practices

- Keep presentation widgets free of business logic; use Riverpod providers for state and coordination.
- Do not hardcode user-facing strings, colors, or feature-local typography. Use localization and `Theme.of(context)`.
- Maintain unit tests for logic and widget tests for UI behavior.
- After every code adjustment, run `flutter analyze` and report any failures.

## Useful commands

- `flutter pub get`
- `dart run build_runner build -d` (regenerates Riverpod/Drift/json_serializable `.g.dart` files after changing annotated code)
- `flutter test`
- `flutter analyze`
