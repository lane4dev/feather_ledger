<!--
SYNC IMPACT REPORT
Version Change: 0.0.0 -> 1.0.0
Status: Initial Ratification

Modified Principles:
- N/A (Initial creation)

Added Sections:
- I. Strict MVVM Architecture
- II. State Management with Riverpod
- III. Material 3 Minimalist Design
- IV. Internationalization (i18n) First
- V. High Code Quality & Maintainability
- VI. Comprehensive Testing

Templates Requiring Updates:
- .specify/templates/plan-template.md (✅ Verified)
- .specify/templates/spec-template.md (✅ Verified)
- .specify/templates/tasks-template.md (✅ Verified)

Follow-up TODOs:
- Review analysis_options.yaml for stricter lint rules.
-->

# Feather Ledger Constitution

## Core Principles

### I. Strict MVVM Architecture
The application MUST adhere to the Model-View-ViewModel (MVVM) architectural pattern to ensure separation of concerns.
- **Model**: Data classes and business logic repositories. Must not depend on Flutter UI.
- **View**: Flutter Widgets. Responsible strictly for rendering and user interaction. MUST NOT contain business logic.
- **ViewModel**: Managed by Riverpod providers. Mediates between View and Model. Exposes UI state and handles user intents.

### II. State Management with Riverpod
Riverpod is the exclusive state management solution.
- **Providers**: Use `riverpod_generator` and annotation syntax (`@riverpod`) where possible for type safety and boilerplate reduction.
- **Immutability**: State classes MUST be immutable (use `freezed` or `equatable`).
- **Access**: Views consume state via `ref.watch`. Logic updates state via `ref.read` in callbacks or internal provider logic.

### III. Material 3 Minimalist Design
The UI/UX MUST follow Material 3 guidelines with a focus on minimalism, consistency, and performance.

- **Theme**: `useMaterial3: true` is mandatory.
- **Aesthetic**: Clean layouts, consistent spacing, and standard M3 components. Avoid custom widgets where standard ones suffice.
- **Performance**: Avoid expensive builds in `build()` methods. Optimize list rendering (lazy loading).

- **Design System Governance (project-level hard rules)**:
  - **Single source of truth**:
    - Feature UI MUST use `Theme.of(context).colorScheme` and `Theme.of(context).textTheme`.
    - Feature UI MUST NOT hardcode palette or typography primitives (e.g., `Colors.*`, `Color(0x...)`, ad-hoc `TextStyle(...)` overrides).
  - **Tokens (non-Material primitives)**:
    - Spacing / radius / (optional) shadows MUST be defined as `ThemeExtension`s and attached to `ThemeData.extensions`.
    - ThemeExtensions MUST implement `copyWith` and `lerp` to support smooth theme transitions.
  - **Component boundaries (single entry points)**:
    - Feature UI MUST use DS wrappers as the only styling entry points:
      - Buttons → `AppButton`
      - Form fields → `AppTextField` / `AppFormField`
      - Surfaces/Cards → `AppCard`
    - DS wrappers MUST remain thin and M3-aligned (i.e., they standardize tokens/variants, not reinvent widgets).
  - **Prohibited patterns (in feature UI only)**:
    - In `lib/features/**/ui/**`, the following are FORBIDDEN:
      - `Colors.` / `Color(0x`
      - `TextStyle(` / direct `fontSize`/`FontWeight` overrides
      - `EdgeInsets(` / `Radius.circular(`
    - These primitives MAY be used inside the DS implementation layer (e.g., `lib/app/design_system/**`) when defining standardized variants/tokens.
  - **Exceptions**:
    - Any exception MUST be implemented as a named DS variant and reviewed via PR (no ad-hoc per-screen overrides).

### IV. Internationalization (i18n) First
The application MUST be multi-lingual from the start.
- **Languages**: Default to English (en). Mandatory support for Simplified Chinese (zh).
- **Implementation**: Hardcoded strings in UI are strictly FORBIDDEN. Use `flutter_localizations` and `.arb` files for all user-facing text.

### V. High Code Quality & Maintainability
Codebase MUST remain clean, readable, and scalable.

- **Linting baseline (flutter_lints)**:
  - The project MUST use `package:flutter_lints` as the baseline recommended lint set.
  - `pubspec.yaml` MUST include `flutter_lints` under `dev_dependencies`.
  - A root-level `analysis_options.yaml` MUST exist and include:
    - `include: package:flutter_lints/flutter.yaml`

- **Static analysis gate**:
  - `flutter analyze` MUST succeed on a clean checkout.
  - Analyzer errors are blocking. Warnings SHOULD be treated as blockers unless explicitly approved.
  - Analyzer behavior MUST be controlled only via `analysis_options.yaml` and scoped ignore comments in code (no hidden, tool-specific side channels).

- **Suppressions policy**:
  - Suppressing a lint MUST be local and justified:
    - Use `// ignore:` or `// ignore_for_file:` with a brief rationale comment.
  - Blanket disabling of lints is FORBIDDEN unless documented and reviewed.
  - Generated code MAY use file-level ignores where appropriate, but MUST NOT leak ignores into handwritten feature code.

- **Typing**:
  - No implicit `dynamic`. Strong typing is enforced.

- **Comments**:
  - Focus on "Why", not "What". Self-documenting code is preferred.

### VI. Comprehensive Testing
Quality is non-negotiable.
- **Unit Tests**: Required for all Repositories, Services, and ViewModels (Business Logic).
- **Widget Tests**: Required for reusable UI components and critical screens.
- **Coverage**: New features MUST include accompanying tests.

## Governance

This Constitution acts as the supreme source of truth for engineering decisions within the Feather Ledger project.

1.  **Amendments**: Changes to this document require a Pull Request with explicit rationale and team approval.
2.  **Compliance**: All code reviews MUST verify adherence to these principles. Violations are blocking issues.
3.  **Versioning**: This document follows Semantic Versioning. Major changes (architecture shifts) increment MAJOR, new principles increment MINOR.

**Version**: 1.0.0 | **Ratified**: 2026-01-17 | **Last Amended**: 2026-01-17
