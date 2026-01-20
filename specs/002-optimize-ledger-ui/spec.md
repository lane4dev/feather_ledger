# Feature Specification: Optimize Ledger UI

**Feature Branch**: `002-optimize-ledger-ui`  
**Created**: 2026-01-19
**Status**: Draft  
**Input**: User description: """在 001-core-mvp 已实现的基础上，对 **账本** 页面做深度 UI/视觉优化（功能不变、数据不变）： 

目标： 
- 视觉风格更接近 Google Tasks：专业、高级、更轻、更干净、更一致的排版与层级 
- 信息结构更清晰：月份/余额/明细的层级、留白、字号、对齐一致 
- 列表可读性更好：金额/分类/备注/时间的视觉优先级明确 
- 空态/加载态/错误态统一（文案与组件一致） 

范围（In scope）： 
- 账本页（包含：月份切换区域、余额摘要区域、流水列表、FAB 新建入口、筛选/搜索入口如已存在） 
- 账本页相关的通用 UI 组件（如 TransactionTile、SummaryCard、SectionHeader 等） 
- 主题与样式（仅限与账本页相关的 tokens：颜色、字号、间距、圆角、阴影/高度等） 

非目标（Out of scope / 禁止改动）： 
- 不改动 Domain 业务规则、余额算法、数据筛选规则 
- 不改动 Data 层 schema / repository 行为（除非纯 UI 需要新增字段展示，但必须保持向后兼容） 
- 不新增“新功能”（比如预算提醒/统计口径变化）——本次只做 UI/UX 优化 

验收标准： 
- 交互流程与 001 保持一致（新增、编辑、删除、切换月份等行为不变） 
- 在同样数据下，页面信息层级更清晰，且 i18n（英文/中文）布局不崩 
- 关键状态具备 golden 截图基准：空态/有数据/长列表/超长备注/大金额/中文 
- Through basic无障碍检查：文字对比度、点击区域、字体缩放不炸"""

## Clarifications

### Session 2026-01-20
- Q: Header Collapse Behavior → A: Mandatory: The header MUST collapse into a compact form (e.g., showing only Month/Balance) upon scrolling.
- Q: Amount Visual Styling → A: Color + Sign: Expense in Red (with `-`), Income in Green (with `+`).
- Q: Transaction Detail View → A: Read-only Detail: Open a bottom sheet or new screen showing all transaction fields in a premium layout.
- Q: Left-side Time Anchor Format → A: Day Number + Weekday: e.g., "20 / Mon" (Vertical stack).
- Q: Loading State Presentation → A: Skeleton: Show shimmering placeholders for the header, time anchor, and list items.

## Context

The Ledger page already exists in `001-core-mvp` and is functionally usable.  
This feature improves **visual hierarchy**, **readability**, and **scroll interaction polish** while keeping business rules unchanged.

## Goals

1. Make the Ledger page feel **clean, minimal, premium**, with consistent spacing/typography.
2. Improve scanability of transactions via clear hierarchy:
   **Amount (primary, Color + Sign) > Title (secondary) > Meta (tertiary)**.
3. Introduce a **left-side Time Anchor** that stays visible during scroll and updates predictably by group.
4. Ensure Month Switcher + Balance Summary coexist with the list & anchor without overlap/jitter.
5. Ensure Empty/Loading/Error states look consistent and professional.

## Non-Goals (Strict)

- No changes to **domain rules** (balance calculation, sorting, filtering semantics).
- No changes to **data schema / repository behavior**.
- No new end-user features (e.g., budget logic changes, new transaction types, new CRUD capabilities that don’t already exist in 001).

## References

- Visual reference for list style & scroll feel:  
  `specs/002-optimize-ledger-ui/assets/ledger_list_reference.png`

## Assumptions

- Default grouping granularity for the Time Anchor is **By Day** (e.g., 2026-01-19).  
  If the product prefers “By Time-of-day”, document and update this spec before planning.
- Month switching is already supported in 001 (or has an equivalent navigation pattern).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ledger Page Header feels clear and stays out of the way (Priority: P1)

As a user, I want to view my monthly ledger with a clean, minimal, premium and hierarchical layout resembling Google Tasks, so that I can immediately grasp the current month, balance, and list structure without visual clutter.

**Why this priority**: The header sets the page’s information hierarchy and strongly affects perceived quality.

**Independent Test**: Open Ledger page; verify header clarity in EN/ZH and under large text settings.

**Acceptance Scenarios**:
1. **Given** the Ledger page is open, **Then** Month Switcher and Balance Summary are visually separated yet cohesive (spacing/typography does the separation, not heavy dividers).
2. **Given** I scroll the transaction list, **Then** the header MUST collapse into a compact form (showing only Month and Balance), and the transaction content remains stable (no jumping).
3. **Given** I switch month (previous/next or picker), **Then** the list scroll position resets to the top of the list region and the time anchor context updates to match the newly loaded month.
4. **Given** EN/ZH locale and large font scaling, **Then** month label and balance remain readable without overlapping the left anchor column.

---

### User Story 2 - Transaction list is scannable with a stable Time Anchor (Priority: P1)

As a user, I want to scan transactions quickly using a clear visual hierarchy and a pinned left-side Time Anchor, so I always know which time group I’m looking at while scrolling.

**Why this priority**: The transaction list is the core surface of the Ledger.

**Independent Test**: Render short/long lists with extreme data; scroll through groups and verify anchor stability.

**Acceptance Scenarios**:
1. **Given** a transaction item, **Then** Amount is the most prominent element (distinguished by color and +/- sign); Title is secondary; Meta (category/account/tags/time) is tertiary and does not compete visually.
2. **Given** I scroll within a time group, **Then** the left Time Anchor remains visible and continues to represent the current group using the **DD / Day** format (e.g., "20 / Mon").
3. **Given** I scroll into the next group, **Then** the Time Anchor updates only when the “active group” changes, and does not flicker/jitter.
4. **Given** the header is expanded or collapsed, **Then** the Time Anchor never overlaps the header and stays aligned with the list content column.
5. **Given** EN/ZH locale, **Then** Time Anchor formatting and layout remain stable.
6. **Given** a transaction item is tapped, **Then** a **Read-only Detail** view opens (e.g., as a Bottom Sheet) showing all transaction fields in a premium layout consistent with the redesigned style.

**Anchor Switching Rule**:
- The active Time Anchor is defined by the group key of the **first visible transaction item** in the viewport.
- The anchor switches only when that first visible item belongs to a different group.

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


---

### User Story 3 - Empty/Loading/Error states feel consistent (Priority: P2)

As a user, I want the Ledger page to look reliable and polished in empty/loading/error conditions, so the app feels trustworthy.

**Why this priority**: Edge states strongly impact perceived quality.

**Independent Test**: Force empty month / loading delay / error; verify visuals and primary actions remain usable.

**Acceptance Scenarios**:
1. **Given** a month has no transactions, **Then** the page shows a dedicated empty state while Month Switcher remains usable.
2. **Given** data is loading, **Then** the page shows **Skeleton placeholders** (shimmering boxes) for the header, time anchor, and list items to provide a smooth, premium loading experience.
3. **Given** a load error occurs, **Then** the page shows a clear error message and a retry affordance, without breaking layout.

---

### User Story 4 - Add Transaction & Read-only Detail (Priority: P2)

As a user, I want to add new transactions or view existing ones with a clean, minimal, and premium form/view that matches the Ledger page style, so that my experience remains cohesive.

**Why this priority**: The Add and Detail views are secondary surfaces that complete the user journey.

**Scope note**: These views are **UI-only**. The underlying behavior and validation semantics MUST remain the same as `001-core-mvp`. Edit/Delete remains out of scope.

**Independent Test**: Open Add from the Ledger FAB and tap a transaction for Detail; verify visual hierarchy and localization in EN/ZH.

**Acceptance Scenarios**:
1. **Given** I am on the Ledger page, **When** I tap the FAB, **Then** the Add Transaction screen opens using the same typography/spacing/surface style as the Ledger redesign.
2. **Given** the Add screen or Detail view is open, **Then** the primary focus is on the most important information (Amount), and secondary details are visually de-emphasized.
3. **Given** I use EN/ZH locale and large text scaling, **Then** labels and values remain readable without overflow that blocks interaction.
4. **Given** I save from the Add screen, **Then** I return to Ledger and the new item appears in the correct group per the existing grouping rule.

---

### User Story 5 - Edit & Delete Transaction (Deferred / Out of scope)

As a user, I want to edit or delete an existing transaction, so that I can correct mistakes and keep my ledger accurate.

**Why this matters**: Edit/Delete completes the CRUD loop and is critical for long-term trust in a finance app.

**Status**: Deferred. `001-core-mvp` does not include Edit/Delete. This story is documented for future work and MUST NOT be implemented as part of this UI-optimization feature.

**Acceptance Scenarios (for a future feature spec)**:
1. **Given** I open an existing transaction, **Then** I can edit its fields and save changes without breaking list grouping and time anchor stability.
2. **Given** I delete a transaction, **Then** the list updates correctly and the current time anchor remains stable when groups disappear.
3. **Given** EN/ZH locale and large text scaling, **Then** Edit/Delete labels, dialogs, and messages remain readable and accessible.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Ledger page UI changes must not alter 001 business behavior (sorting/filtering/balance semantics).
- **FR-002**: Month Switcher must support previous/next and direct jump to an arbitrary month/year.
- **FR-003**: On month change completion, the transaction list position resets to the top of the list region.
- **FR-004**: Balance Summary displays a clear hierarchy: primary balance + optional secondary breakdown (income/expense).
- **FR-005**: Transaction list items follow the visual hierarchy: Amount (Red with '-' for expenses, Green with '+' for income) > Title > Meta.
- **FR-006**: A left-side Time Anchor stays visible during scroll and follows the Anchor Switching Rule, formatted as **DD / Day**.
- **FR-007**: Header and Time Anchor must never overlap; main content column alignment remains consistent.
- FR-008**: Empty/Loading/Error states are visually consistent with the redesigned Ledger page; **Loading state MUST use skeleton placeholders** for header, anchor, and list items.
- **FR-009**: EN/ZH localization and large text scaling must not cause overflow/overlap that breaks usability.
- **FR-010**: The design uses a consistent local token set for spacing/typography/radii for the Ledger page (token definitions in plan.md).
- **FR-011**: The Add Transaction flow MUST remain behaviorally identical to 001; only UI styling and layout hierarchy may change.
- **FR-012**: This feature MUST NOT add new Edit/Delete entry points or behaviors (since they do not exist in 001).
- **FR-013**: The header MUST collapse into a compact form (showing only Month/Balance) upon scrolling.
- **FR-014**: Tapping a transaction item MUST open a **Read-only Detail** view showing all fields in a premium layout.

### Key Entities

- **Time Anchor Key**: grouping key derived from `occurredAt` (default: By Day).
- **Header Region**: Month Switcher + Balance Summary.
- **Transaction Tile**: a single transaction row in the list.

---

## Success Criteria *(mandatory)*

- **SC-001**: No functional regression: month switching and CRUD flows that exist in 001 remain usable and unchanged in behavior.
- **SC-002**: Readability: in a mixed dataset (long notes, large amounts), users can visually identify amount and title without confusion.
- **SC-003**: Stability: Time Anchor does not flicker/jitter when slowly scrolling between groups.
- **SC-004**: Robustness: EN/ZH and large text scaling do not create overlapping UI that blocks interaction.
- **SC-005**: Consistency: empty/loading/error states look coherent and keep month navigation accessible.
- **SC-006**: No scope creep: Add remains functional and unchanged in behavior; Edit/Delete are not introduced in 002.
