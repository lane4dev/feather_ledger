# Feather Ledger — Agent Instructions

## Project context

- Flutter/Dart application using strict MVVM, Riverpod, Drift/SQLite, GoRouter, Material 3, and ARB-based localization.
- The authoritative engineering principles are in `.specify/memory/constitution.md`; read and follow them before changing code.
- Feature specifications and plans live under `specs/`. The current event-sourcing work is `specs/003-event-sourced-ledger/`.

## Required practices

- Keep presentation widgets free of business logic; use Riverpod providers for state and coordination.
- Do not hardcode user-facing strings, colors, or feature-local typography. Use localization and `Theme.of(context)`.
- Maintain unit tests for logic and widget tests for UI behavior.
- After every code adjustment, run `flutter analyze` and report any failures.

## Useful commands

- `flutter pub get`
- `dart run build_runner build -d`
- `flutter test`
- `flutter analyze`
