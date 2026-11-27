# ADR-0008: 周期性记账的混合投影架构（自然月近期物化 + 预算读时虚拟补齐）

> **状态**：Proposed（已对齐当前实现现状，待评审固化）  
> **日期**：2026-11-26（2026-11-27 对齐现状修订）  
> **关联文档**：`CONTEXT.md`、`docs/adr/0005-scheduled-bill-identity-and-two-scope-editing.md`、`docs/adr/0006-budget-stepped-timeline-and-crud-exemption.md`、`docs/adr/0007-clear-category-budget-and-notes-atomically.md`

## 1. 背景与问题（Context）

当前周期性记账（`recurring_series`）由 `ProjectRecurringEventsCommand` 采用**三阶段自然月对齐的物理物化**策略（已废弃早期 `maxKeep = 3` 的固定期数截断），仅面向 `isActive == true` 且关联账户 `!archived && !deleted` 的系列，按本地日历日批量幂等写入 `scheduled_transactions_view`：

- **Phase 0（休眠重启历史回填）**：回填 `[max(materializeFrom, startOfMonth(nowYm - 11)), now]`（最多 12 个自然月）内缺失的历史期次，单系列硬上限 `maxBackfillPerSeries = 100`（最近优先）。
- **Phase 1（自然月对齐前瞻窗口）**：完整物化 `(now, endOfMonth(nowYm + 1)]`（当月 + 未来 1 个完整自然月，共 2 个自然月），无 `maxKeep = 3` 截断，单系列设 `maxUpcomingSafetyValve = 120` 条前瞻安全阀。
- **Phase 2（低频保底）**：若 `(now, horizonEnd]` 内无任何待入账 `scheduled` 实例，继续向后探测并保底物化最近 `minKeep = 1` 期（如年付规则或远期起点）。`planned` 系列幂等插入 `occurrence_key = 'single'`。

该物化策略已解决**当月（`Track`）及次月（`nowYm + 1`）**的高频周期账单覆盖问题，但与 **预算页（`/budget`）的远期规划（`Plan`）** 之间仍存在结构性张力：

1. **超出物理窗口的远期规划断崖归零**：当用户切换到 `targetYm > nowYm + 1` 的远期月份进行预算规划时，物理表尚未物化对应期次（仅低频规则可能有一条 `minKeep = 1` 保底），导致远期月份的 `Pending` 与固定支出基线失真。
2. **无法靠无限扩大物理物化窗口解决**：若将物理前瞻窗口拉长至 12–24 个月，高频（每日/每周）规则会向 SQLite 写入数百上千条冗余行，增加写路径与账本查询负担，且仍无法覆盖窗口之外的任意规划月。
3. **避免 UI 妥协与双口径漂移**：预算首页、分类详情页与记账表单实时预算提示条必须保持 100% 同口径，避免退回到「仅统计已生成的周期账单」等降级免责提示（旧版 `hasHighFrequencyPending` / `isFarFutureMaterializedOnly` 标记已移除）。

## 2. 架构决策（Decision）

采用 **混合投影方案（Hybrid Projection：自然月近期物理物化 + 预算读时虚拟补齐 + 按需落库）**：

1. **层一：写入与账本侧维持自然月对齐物化**：
   - `ProjectRecurringEventsCommand` 维持 `defaultMonthsAhead = 1`（当月 + 未来 1 个完整自然月）、`maxUpcomingSafetyValve = 120`、`minKeep = 1` 及 Phase 0 历史回填上限（12 个月 / 100 条）；SQLite 保持有界，`/ledger` 待入账与本地通知窗口（60 条上限）保持可控。
2. **共享 `RecurrenceExpander` 作为唯一真相源（Single Source of Truth）**：
   - 重复规则的本地日历日推演逻辑统一收口于纯 Dart 领域引擎 `RecurrenceExpander`（`lib/core/domain/recurrence/recurrence_expander.dart`，配合 `RecurrenceRuleSpec`），同时被 `ProjectRecurringEventsCommand`（写入物化）、`EnsureOccurrenceMaterializedCommand`（按需落库）和预算读路径调用，杜绝多套实现导致的口径漂移与时区/DST 漂移。
3. **层二：预算读侧执行虚拟补齐（Overlay）**：
   - 对目标自然月 `M`（仅限 `Track` 当月与 `Plan` 未来月，即 `M >= nowYm`），预算待入账读取合并两路数据：
     - **已物化未入账部分**：读取 `scheduled_transactions_view` 中 `status IN ('scheduled', 'failed')` 且生效日期 `coalesce(dateOverride, scheduledDate)` 落入 `M` 的物理实例（含 `amountOverrideMinor` 与 `memoOverride`）。
     - **虚拟补齐部分**：对活跃支出系列（`isActive == true`、`type == expense`、同币种、关联账户 `includeInTotals && !deleted && !archived`），通过 `RecurrenceExpander.expandForMonth` 展开落入 `M` 的理论期次，剔除已有物理行覆盖的 `(seriesId, occurrenceKey)` 后，按 `recurringSeries.amountMinor` 合成虚拟待入账项计入 `Pending` 与贡献列表。
4. **按需落库（Materialize-on-Write）衔接交互**：
   - 区别于「只读摘要行」方案，远期虚拟待入账项在预算分类详情页中允许用户直接点击操作；点击时通过 `RecurringService.ensureMaterialized`（`EnsureOccurrenceMaterializedCommand`）在单事务内按 `(seriesId, occurrenceKey)` 幂等落库为标准 `scheduled` UUID 行（`INSERT OR IGNORE`），随后无缝复用既有 `PendingBillSheet` 执行记入、单期编辑或跳过（ADR-0005）。

## 3. 核心去重与边界不变量（Invariants）

实现与后续演进必须严格满足以下 6 条不变量：

1. **唯一去重键为 `(seriesId, occurrenceKey)`（严禁使用 `effectiveDate` 或 UTC 时间戳）**
   - 遵循 ADR-0005：`repeating` 系列的 `occurrenceKey` 为规则推导的本地日历日 `YYYY-MM-DD`，`planned` 系列固定为 `'single'`（`kPlannedOccurrenceKey`）。
   - 收集去重集合时，必须涵盖该系列所有已物化状态：`scheduled`、`failed`、`skipped`、`posted`（无论其 `dateOverride` 是否已改期至其他月份）。
   - 任何理论展开期次只要 `(seriesId, occurrenceKey)` 命中已物化集合，虚拟补齐必须跳过。
2. **单期改期（`dateOverride`）跨月不重不漏**
   - 例：原定 `11/28`（`occurrenceKey = '2026-11-28'`）的一期被用户改期到 `12/01`。
   - 查 `11月` 时：`(seriesId, '2026-11-28')` 命中去重集合，虚拟补齐跳过，且其实例 `effectiveDate = 12/01` 不在 11 月，故 11 月不计入。
   - 查 `12月` 时：物理查询按 `effectiveDate = 12/01` 计入该改期实例；同时 `12月` 原本的理论期次（如 `'2026-12-01'`）仍按各自原始 `occurrenceKey` 独立判定，互不干扰。
3. **跳过（`skipped`）与提前入账（`posted`）绝不复活**
   - 因为 `skipped` 与 `posted` 均在 `(seriesId, occurrenceKey)` 去重集合中，用户跳过的期次或提前入账的期次不会被虚拟补齐重新算回 `Pending`。
4. **严格遵守系列终止、下界与过滤条件**
   - 虚拟展开仅面向 `type == expense`、`isActive == true`、`currencyCode == targetCurrency`、关联账户满足 `includeInTotals == true && deleted == false && archived == false` 的系列；且须尊重 `materializeFrom` 下界（低于 `effectiveMaterializeFrom` 的期次不虚拟补齐）。
   - 遵守 `endDate` 与全生命周期 `countLimit`：展开时以 `remainingCountLimit = countLimit - completedCountOffset` 从 `startDate` 锚点推进，确保总期数绝不超过 `countLimit`。
   - **归档分类截断（需持续核查）**：系统分类（`systemCode != null`）及已归档且 `M > archiveYm` 的分类不参与预算统计与单分类提示中的有效预算计算；需确保虚拟待入账在总览 `allExpensePendingMinor` 与单分类提示中同样遵循归档截断口径。
5. **历史月（`Review` 模式）隔离**
   - 当 `M < nowYm` 时，`WatchMonthBudgetQuery` 与 `WatchTransactionBudgetHintQuery` 显式传入 `includeVirtual = false`，**跳过虚拟补齐**；`BudgetCalculator` 在 `Review` 模式下以 `Actual` 计算，将 `pendingMinor` 置为 0（仅保留物理遗留待入账提示标志 `hasLeftoverPendingInReview`）。
6. **远期展开性能护栏（待补强）**
   - 为防止高频规则（如 `DAILY`）在用户切换到极远未来月时因 `rrule.getInstances` 从 `startDate` 线性步进而拖慢查询，需评估并补齐预算虚拟补齐的最大前瞻范围护栏（如 `M <= nowYm + 24` 个月）或步进快进优化。

## 4. 模块与分层现状（Touchpoints）

| 层级 | 模块 / 文件 | 现状与职责 |
| :---- | :---- | :---- |
| **Domain（共享）** | `lib/core/domain/recurrence/recurrence_expander.dart` | **已落地**：`RecurrenceExpander` + `RecurrenceRuleSpec`，提供本地日历日 `expandInRange` / `expandForMonth` / `firstOccurrenceAfter`，供物理物化、预算虚拟补齐与按需落库共用。 |
| **Domain（Ledger）** | `lib/features/ledger/domain/commands/ensure_occurrence_materialized_command.dart` | **已落地**：按需落库命令（Materialize-on-Write），校验系列/账户有效性与规则合法性后，单事务 `INSERT OR IGNORE` 落库标准 `scheduled` UUID 行。 |
| **Data（DAO）** | `lib/core/data/database/daos/budget_dao.dart` | **已落地**：`_loadPendingExpenseBills` 承担物理行 + 虚拟 Overlay 合并逻辑，被 `watchMonthPendingExpenses` 与 `watchCategoryBudgetHint` 共同复用。*(后续可选重构：将内存 Overlay 逻辑抽离为纯 Domain 服务 `BudgetPendingProjector`，降低 DAO 层业务耦合。)* |
| **Domain（Budget）** | `lib/features/budget/domain/queries/watch_month_budget_query.dart`<br>`lib/features/budget/domain/queries/watch_transaction_budget_hint_query.dart`<br>`lib/features/budget/domain/services/budget_calculator.dart` | **已落地**：由查询层按 `month >= nowYm` 决定 `includeVirtual`；`BudgetCalculator.compute` 统一聚合实账与待入账（含虚拟项）。 |
| **Presentation** | `lib/features/budget/presentation/screens/budget_category_detail_screen.dart` 等 | **已落地**：已移除旧版降级免责提示；分类详情页展示虚拟待入账项，点击时经 `BudgetViewModel.materializeVirtualPendingBill` 按需落库并打开 `PendingBillSheet`。 |

## 5. 权衡与备选方案（Alternatives Considered）

- **早期固定期数物化（`maxKeep = 3`）**：无法支撑日/周频次的当月完整跟踪与次月预算规划，已废弃。
- **仅靠扩大自然月物理物化窗口（无虚拟补齐）**：将窗口扩至 12–24 个月可保持纯 SQL 聚合，但每日账单会向 SQLite 写入数百条冗余行，且超出窗口后仍为 0，性价比低于「近 2 月物理物化 + 远期虚拟补齐」的混合方案。
- **纯虚拟 RRULE + Exception 表（重构整个账本周期模块）**：改造成本高，需推翻现有 `scheduled_transactions_view` 与通知/入账链路；当前混合方案结合 Materialize-on-Write，在不破坏既有 UUID 模型（ADR-0005）的前提下获得了同等的远期规划准确度与交互能力。

## 6. 单元测试与验收清单（Test Checklist）

以下场景为混合投影架构的核心验收基线（主体已覆盖于 `budget_virtual_overlay_test.dart` 与 `virtual_bill_materialize_test.dart`）：

1. **当月及近月高频全量覆盖**：`DAILY` / `WEEKLY` 系列在 `Track` 当月及 `nowYm + 1` 物理物化窗口内总额准确且不重复。
2. **超出物理窗口的远期规划补齐**：查询 `nowYm + 2` 及更远月份（0 期物理物化）时，虚拟补齐按月完整展开，固定支出基线准确。
3. **跳过不复活**：物理行状态为 `skipped` 时，对应 `(seriesId, occurrenceKey)` 不得被虚拟补齐重新计入 `Pending`。
4. **提前入账不重复**：物理行已转为 `posted` 进入 `Actual` 时，不得再被虚拟补齐计入 `Pending`。
5. **单期改期跨月（`dateOverride`）**：原定 `M` 月末的一期改期至 `M + 1` 月初，验证 `M` 月少 1 期、`M + 1` 月多 1 期，总额守恒且不与目标月原规则期次冲突。
6. **单期改额（`amountOverrideMinor`）**：已物化期次覆写金额后，验证该期取覆写额、其余物理/虚拟期次仍取规则原额。
7. **终止条件与下界生效**：验证 `endDate`、`countLimit`（含 `completedCountOffset`）与 `materializeFrom` 均在虚拟补齐中严格生效。
8. **过滤与归档截断**：验证 `isActive == false` 系列、`includeInTotals == false` 或 `archived == true` 账户、以及 `M > archiveYm` 归档分类不参与预算虚拟补齐。
9. **历史月隔离与三端口径一致**：验证 `M < nowYm` 不触发虚拟补齐；验证 `BudgetScreen`、`BudgetCategoryDetailScreen` 与 `TransactionFormScreen` 提示条三处 `预计剩余` 完全一致。
10. **按需落库（Materialize-on-Write）与远期性能护栏**：验证点击远期虚拟账单可幂等落库并进入编辑/跳过流程；验证极端高频规则查看远期月份时受前瞻上限或步进优化保护，无明显卡顿。