# Feature Specification: Core MVP (Ledger, Reports, Settings)

**Feature Branch**: `001-core-mvp`
**Created**: 2026-01-17
**Status**: Draft
**Input**: User description: "开发一个简洁的移动端记账应用： 1. 三个底部页面：账本、报表、更多 2. 账本：按月份查看；展示当月余额；流水明细；新增记录按钮 3. 报表：按月份统计的收入/支出热力图；按类型统计的收入/支出环形图 4. 更多：设置（语言/货币/主题）、账户管理、预算 5. 默认英文，同时支持中文 6. 交互与视觉参考 Google Tasks 的简洁风格"

## Scope & Release Gates

## Clarifications

### Session 2026-01-18
- Q: How should the monthly balance be calculated? → A: Running Balance: Show the cumulative ending balance of all accounts as of the end of that month.
- Q: Should categories be hierarchical or flat? → A: Flat List: Categories are a single list.
- Q: Should the MVP allow editing or deleting existing records? → A: Full CRUD: Support viewing, adding, editing, and deleting transactions.
- Q: How is Heatmap intensity calculated? → A: User choice (Frequency, Volume, or Net) via Settings.
- Q: How should Income vs Expense charts be displayed? → A: Simultaneous: Show both Income and Expense charts on the same page.

### MVP In Scope (MUST ship)
- **S-MVP-01**: Bottom navigation with 3 tabs (Ledger / Reports / More).
- **S-MVP-02**: Ledger: month switch + list + full CRUD for transactions + monthly summary (Running Balance).
- **S-MVP-03**: Reports: heatmap (user-configurable) + simultaneous Income & Expense donut charts (selected month).
- **S-MVP-04**: Settings: language (EN/zh-CN) + theme + currency + heatmap calculation preference.
- **S-MVP-05**: Local persistence + works fully offline.

### Out of Scope (WON'T ship in MVP)
- **S-OOS-01**: Login / cloud sync / multi-device sync.
- **S-OOS-02**: Import/export (CSV/Excel/Bank statement).
- **S-OOS-03**: Transfers between accounts.
- **S-OOS-04**: Multi-currency conversion and exchange rates.
- **S-OOS-05**: Notifications / budget alerts (push/local).

### Stretch (MAY ship if time allows, not required)
- **S-ST-01**: Accounts management (create/edit/delete) with initial balance.
- **S-ST-02**: Budgets (monthly total) or category budgets.

### Release Gate (Definition of Done for this feature)

MVP is considered "done" when:
- All P1 + P2 + P3 acceptance scenarios pass (P4 is optional).
- No [NEEDS CLARIFICATION] markers remain in this spec.

## User Scenarios & Testing

### User Story 1 - Ledger Management (Priority: P1)

As a user, I want to view my monthly transactions and add new ones so that I can track my spending immediately.

**Why this priority**: Core value proposition. Without adding/viewing transactions, the app is useless.

**Independent Test**: Can be tested by launching the app, seeing an empty state, adding a record, and seeing it appear in the list with the updated balance.

**Acceptance Scenarios**:

1.  **Given** the app is launched, **When** I land on the "Ledger" tab, **Then** I see the current month's transactions grouped by date and a summary showing total income, total expense, and the running balance (cumulative) as of the month's end.
2.  **Given** I am on the Ledger tab, **When** I tap the "Add Record" button, **Then** a form appears allowing me to input amount, category, and date.
3.  **Given** I have added a transaction, **When** I save it, **Then** the list updates immediately and the running balance reflects the change.
4.  **Given** I have existing transactions, **When** I select one to edit, **Then** I can modify its details and the changes are persisted.
5.  **Given** I have existing transactions, **When** I delete one, **Then** it is removed from the list and the running balance is updated.
6.  **Given** I have transactions from multiple months, **When** I switch the month view, **Then** only transactions for that specific month are shown, but the balance shown is the running total up to that month.

---

### User Story 2 - Visual Reports (Priority: P2)

As a user, I want to see visual breakdowns of my finances so that I can understand spending patterns.

**Why this priority**: Provides high-level insight, differentiating the app from a simple list.

**Independent Test**: Can be tested by adding mock data and verifying the charts render correctly on the "Reports" tab.

**Acceptance Scenarios**:

1.  **Given** I have transaction data, **When** I navigate to the "Reports" tab, **Then** I see a Heatmap of daily activity for the selected month.
2.  **Given** I have expense/income data, **When** I look at the breakdown section, **Then** I see two separate Donut charts (Income and Expense) displayed simultaneously.
3.  **Given** I change the month filter in Reports, **When** the view updates, **Then** the Heatmap and both Donut charts reflect data only for that month.

---

### User Story 3 - Settings & Localization (Priority: P3)

As a user, I want to customize the app's language, currency, and theme so that it fits my personal preferences.

**Why this priority**: Accessibility (i18n) and personalization are explicit requirements for launch.

**Independent Test**: Can be tested by toggling settings and verifying the UI updates without restart.

**Acceptance Scenarios**:

1.  **Given** the app defaults to English, **When** I go to "More" > "Settings" and switch Language to Chinese, **Then** all app text updates to Chinese immediately.
2.  **Given** I am in Settings, **When** I change the default Currency, **Then** all monetary values in Ledger and Reports display the new symbol.
3.  **Given** I am in Settings, **When** I toggle the Theme (e.g., Dark Mode), **Then** the app colors adjust according to Material 3 standards.

---

### User Story 4 - Accounts & Budgets (Priority: P4)

As a user, I want to manage multiple asset accounts and set budgets so that I can control my financial health.

**Why this priority**: Enhances the "Ledger" feature but not strictly blocking for the very first "enter expense" use case.

**Independent Test**: Can be tested by creating a new account and assigning a transaction to it.

**Acceptance Scenarios**:

1.  **Given** I am on the "More" tab, **When** I tap "Account Management", **Then** I can add, edit, or delete asset accounts (e.g., Cash, Bank).
2.  **Given** I have multiple accounts, **When** I add a transaction, **Then** I can select which account it belongs to.
3.  **Given** I am on the "More" tab, **When** I tap "Budget", **Then** I can set a monthly spending limit for specific categories.

### Edge Cases

- **Empty State**: How does the Ledger/Report look with 0 transactions? (Should show friendly "No data" placeholders).
- **Large Values**: What happens if an amount is 999,999,999.99? (Should truncate or scale font).
- **Date Boundaries**: Transactions exactly at 00:00:00 on the 1st of the month.
- **Offline**: App must work 100% offline (implied by local mobile app nature).

## Requirements

### Functional Requirements

- **FR-001**: System MUST provide a bottom navigation bar with 3 tabs: Ledger (Home), Reports, More.
- **FR-002**: System MUST default to English locale but support switching to Simplified Chinese.
- **FR-003**: System MUST persist all data locally on the device (SQLite/Isar/Hive implies persistence).
- **FR-004**: Ledger view MUST group transactions by date (descending) and show daily totals.
- **FR-005**: Ledger view MUST display total Income, Expense, and Running Balance (cumulative total) for the selected month.
- **FR-006**: System MUST support full CRUD (Create, Read, Update, Delete) for transaction records.
- **FR-007**: Reports view MUST include an "Income/Expense Heatmap" with configurable intensity logic (Frequency, Volume, or Net).
- **FR-008**: Reports view MUST include two simultaneous "Category Donut Charts" (one for Income, one for Expense).
- **FR-009**: Settings MUST allow toggling between Light and Dark themes, and configuring the Heatmap calculation mode.
- **FR-010**: System MUST allow creating custom flat-list categories (no hierarchy) or using default ones.
- **FR-011**: Interaction design MUST follow "Google Tasks" minimalism (Floating Action Button for add, clean lists, bottom sheet forms).

### Key Entities

- **Transaction**: ID, Amount, Type (Income/Expense), CategoryID, AccountID, Date, Note.
- **Category**: ID, Name, Icon, Type, Color.
- **Account**: ID, Name, InitialBalance, CurrencySymbol.
- **Budget**: ID, CategoryID, AmountLimit, Period (Month).
- **Settings**: Language, ThemeMode, DefaultCurrency.

## Success Criteria

### Measurable Outcomes

- **SC-001**: App launch to interactive state takes < 2 seconds on mid-range devices.
- **SC-002**: Adding a transaction requires <= 3 taps from the home screen.
- **SC-003**: Language switch is applied instantly (< 500ms) without app restart.
- **SC-004**: Scroll performance maintains 60fps (or device max) with 1000+ transaction records.
- **SC-005**: Users can successfully identify their highest spending category in < 5 seconds via the Reports tab.

## Design System

### Intent

- The app must present a consistent, minimal, "Google Tasks-like" visual experience across Ledger / Reports / More, so users don't feel each screen is "a different app."
- A centralized design system reduces long-term maintenance cost by preventing per-screen styling drift, and ensures future features remain visually coherent.

### Product Constraints

- **DS-001** (Consistency): All user-facing screens MUST follow a single coherent visual language (spacing rhythm, typography hierarchy, surface treatment, iconography style).
- **DS-002** (Themeability): The app MUST support at least Light and Dark appearance modes (optionally also "Follow System"), and the appearance MUST apply consistently across all screens.
- **DS-003** (Global application): When the user changes appearance settings, the entire app MUST update without requiring an app restart, and MUST not cause broken layouts or unreadable text.
- **DS-004** (Centralized styling rules): Visual styling primitives (color, typography, spacing, corner radius, elevation/shadow) MUST be defined centrally and reused. Feature screens MUST NOT introduce "ad-hoc" one-off styles that create long-term inconsistency.
- **DS-005** (Component coherence): Core interactive components (buttons, inputs, cards/surfaces) MUST have consistent behavior and visuals across the app, including at minimum: default, pressed, disabled, and error states.
- **DS-006** (Accessibility): The design MUST remain usable under common accessibility settings (e.g., larger text sizes), and MUST maintain readable contrast and tap-friendly interactions.

### Acceptance Criteria

- **AC-DS-01**: A reviewer can navigate all MVP screens and confirm they share consistent spacing, typography hierarchy, and component styling (no screen feels "custom themed").
- **AC-DS-02**: Switching appearance mode updates all visible screens immediately, with no illegible text, broken spacing, or clipped components.
- **AC-DS-03**: Common controls (primary buttons, form fields, cards) look and behave consistently across Ledger / Reports / More, including error/disabled states.

## Build & Release

### Intent

- The team needs a safe way to test changes and share builds with QA/users without impacting the production app.
- Build variants reduce release risk by enabling parallel installation, clear identification, and repeatable packaging for testing and store distribution.

### Product Requirements

- **BR-001** (Two variants): The app MUST provide two build variants: Development and Production.
- **BR-002** (Clear identification): The Development build MUST be clearly distinguishable from Production at install-time and on the device (e.g., app name and/or visual indicator), so testers never confuse them.
- **BR-003** (Parallel install): Development and Production builds MUST be able to coexist on the same device without overwriting each other.
- **BR-004** (Data separation expectation): User data created in Development MUST NOT appear in Production unintentionally (to avoid test data polluting real usage), unless explicitly designed otherwise.
- **BR-005** (Repeatability & documentation): The repository MUST contain documentation describing a repeatable procedure to produce each variant for testers/reviewers, including prerequisites and a verification checklist.
- **BR-006** (Release readiness): Production builds MUST be suitable for store release (no obvious dev-only identifiers, no debug-only behavior visible to end users).

### Acceptance Criteria

- **AC-BR-01**: Both variants can be installed simultaneously on the same device and launch independently.
- **AC-BR-02**: The Development build is visibly labeled/distinguishable, preventing accidental use as Production.
- **AC-BR-03**: Creating sample transactions in Development does not affect what is shown in Production.
- **AC-BR-04**: A new contributor can follow the documentation to produce both variants and confirm they meet the above checks.
