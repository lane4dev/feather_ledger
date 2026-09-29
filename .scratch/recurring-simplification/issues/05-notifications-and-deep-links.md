# 基于稳定 UUID 的本地通知调度与失效降级

Type: grilling
Label: wayfinder:grilling
Status: resolved
Triage: ready-for-human
Blocked by: 01, 03, 04

## Question

在通知 payload 绑定稳定实例 UUID、非当前币种完全静默且废除 `ScheduledBillRedirects` 与精简删除记录表后，本地通知的调度、更新、点击跳转及失效提示应如何设计？

## Context

Chart 阶段已锁定：
- 通知直接携带稳定实例 UUID（不再依赖 `${seriesId}_${ms}`），废除 `ScheduledBillRedirects` 与专门的精简删除记录留存表。
- 非当前币种完全静默（不调度/不触发通知）。

本票需要确认的边界：
1. **通知调度预算与时机**：只针对当前币种下、未来前瞻窗口内处于 `scheduled` 状态的实例调度本地提醒（或仅限非 `autoPost` 的提醒 / 还是 `autoPost` 也允许提前/当天通知？）；物化、单期改期、跳过、入账、更新规则与切换币种时如何同步取消/重建通知。
2. **通知点击（Deep Link）状态分支**：
   - 实例仍待入账（`scheduled`）→ 直接打开该实例详情（或待入账操作页）；
   - 实例已入账（`posted`）→ 按 `sourceBillId` 或实例关联交易跳转最新交易详情，若该交易已被冲正删除则提示「交易已删除」；
   - 实例已跳过（`skipped`）或 UUID 在库中找不到（随规则删除/计划删除）→ 统一轻提示「该账单已跳过或已不存在」，不做跳转重定向。
3. **自动入账订阅是否需要通知**：开启 `autoPost` 的订阅本身会在启动时自动入账，是否默认不调度“待手动记入提醒”（避免“一边自动入账、一边又发通知叫用户去记”的矛盾），还是作为可选提醒？

## Comments

- 用户确认（Round 1）：
  - `Q1`：维持当前设计，在新建/编辑页面中保留通知设置入口；如果用户设置了通知，按照用户的设定提醒（即 `autoPost` 规则也可自由配置提前提醒，默认无提醒时自然不调度）。
  - `Q2`：确认。
  - `Q3`：确认。

## Answer

1. **可选提醒覆盖所有排期规则**：新建与编辑表单继续为 `planned` 与 `repeating`（无论是否开启 `autoPost`）统一保留通知提前量设置入口（默认不设即不提醒；用户设置了则按设定触发）。
2. **基于稳定 UUID 的调度与对账（废除 `ScheduledBillRedirects`）**：
   - 保留 `watchScheduled()` 响应式全量对账（`_reconcile`）以及核心约束（仅当前币种、账户未归档、iOS 64 条配额内取最近 `limit = 60` 条未来待入账实例；`skipped` 状态不调度未来通知）。
   - `upcomingReminders` 与 `_reconcile` 的触发时间及排序统一按 **`effectiveDate - Duration(minutes: reminderMinutes)`** 计算，确保单期改期 `dateOverride` 后通知时间自动同步。
   - 通知 payload 与系统通知哈希 `_stableId(bill.id)` 直接绑定实例稳定 UUID，彻底删除 `ScheduledBillRedirects` 表与 16 跳重定向链。
3. **点击与快捷动作（Deep Link）降级分支**：
   - **`scheduled`**：支持通知快捷动作「记入 / 跳过」（保留冷启动动作优先于自动入账的 deferral 保护）；点击主体跳 `/ledger` 并打开 `PendingBillSheet`。
   - **`failed`**：点击通知或快捷动作时打开 `PendingBillSheet` 展示错误并支持重试「记入」或「跳过本期」。
   - **`posted`**：经 `getTransactionBySourceBill(bill.id)` 跳转当前有效交易详情（含更正后最新交易）；若该交易已被冲正删除则轻提示「这笔交易已删除」。
   - **`skipped`**：直接跳转到 `/ledger` 并打开 `PendingBillSheet` 展示「已跳过」状态与「恢复为待入账」主按钮，方便用户一键恢复。
   - **库中查无此 UUID**（规则已停止被清理、计划已删除、或改日期/频率重新生成了未来实例）：统一轻提示「该账单已不存在」，不做重定向或删除存根查询。
