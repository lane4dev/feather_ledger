# 简化后的周期与计划领域模型和实例主键设计

Type: grilling
Label: wayfinder:grilling
Status: resolved
Triage: ready-for-human

## Question

在废除 `${seriesId}_${ms}` 拼接主键、`ScheduledBillRedirects` 表及三套批次/资格字段后，收敛后的 `RecurringSeries` 与 `ScheduledTransactionsView` 数据模型、稳定 UUID 主键以及 `(series_id, occurrence_key)` 幂等键应如何精确设计？

## Context

Chart 阶段已锁定方向：
- 模式收敛为 3 种：即时记账（默认）、一次性计划（`planned`）、周期账单（`repeating`，带显式 `autoPost` 开关）；在表单记住用户上次是否开启自动入账。
- 单期覆盖支持 **金额、日期、备注**；账户、分类仍归属于规则。
- 废除 `ScheduledBillRedirects`、`AutomaticPostingBatches`、`AutomaticPostingBatchMembers`、`RestoreConfirmationBatches`。

本票需要锁定模型层的精确契约（决定下游物化、编辑、自动入账与迁移设计）：
1. **系列模型字段**：`RecurringSeries` 需要保留哪些字段，裁撤哪些字段（如 `mode` 枚举取值、`autoPost` 布尔、是否保留 `enabled/status` 停用态，以及记住上次开关选择的本地偏好如何命名与生效）。
2. **`occurrence_key` 语义**：当实例主键为独立 UUID 时，`(series_id, occurrence_key)` 唯一约束应以什么作为 `occurrence_key`（例如「按规则排出的原始日历日 `YYYY-MM-DD`」还是「第 N 期序号」），以确保：
   - 重复执行物化绝对幂等；
   - 单期被跳过（`skipped`）或被单期改期到其他日期后，原排期位置不会在下次物化时重复长出一笔；
   - 一次性计划（`planned`）的 `occurrence_key` 如何取值。
3. **单期备注覆盖**：实例表增加可空 `memo` 覆盖列（还是直接从系列拷贝并在单期修改时更新实例 `memo`），读取时怎么合并展示（null 回退系列备注 vs 显式空串清空备注）。
4. **已入账交易的来源关联**：删除复杂批次关联后，已入账交易（`TransactionRecorded` / `transactions_view`）上的 `sourceBillId` 如何简化并指向稳定实例 UUID。

## Comments

- 用户确认（Q1）：`RecurringSeries.mode` 收敛为 `planned` 与 `repeating`（取消独立 `subscription` 枚举值，由 `autoPost: bool` 表达是否自动入账）；`planned` 恒为 `autoPost = false`，不允许开启自动入账。
- 用户确认（Q2）：`occurrence_key` 采用按规则排出的原始逻辑排期日 `YYYY-MM-DD`（`planned` 固定为 `'single'`），单期改期只改覆盖日期、不改 `occurrence_key`。
- 用户确认（Q3）：实例表采用显式可空覆盖列（`amountOverrideMinor`、`dateOverride`、`memoOverride`），`null` 表示继承规则与原始排期。
- 用户确认（Q4）：记住上次自动入账选择作为纯本地偏好（不进备份，默认 `false`）；`sourceScheduledBillId` 指向新实例稳定 UUID；确认裁撤 4 张冗余表与 `autoPostEligible` 永久锁字段。

## Answer

1. **模式与周期规则模型（`RecurringSeries` + UI `TransactionFormMode`）**：
   - 表单入口收敛为 3 种模式：`defaultMode`（即时记账）、`planned`（一次性未来计划，UI 始终保持「计划」标签）、`repeating`（周期账单）；**`planned` 与 `repeating` 均提供「到期自动入账」开关**。
   - `RecurringSeries.mode` 收敛为两值：`planned`（一次性计划）与 `repeating`（周期规则），均由 `autoPost: bool` 决定是否到期自动入账；取消独立 `subscription` 领域枚举（旧库 `subscription` 迁移为 `repeating` + `autoPost = true`）。
   - 新建 `planned` 与 `repeating` 时，「到期自动入账」开关**各自独立**读取纯本地 UI 偏好 `lastPlannedAutoPost: bool` 与 `lastRepeatingAutoPost: bool`（均默认 `false`，不写入 `.flbackup` 备份，不影响已有规则）。

> **[2026-11-23 规格调整对齐]**：`planned` 允许开启 `autoPost`（UI 标签仍保持「计划」），且 `planned` 与 `repeating` 各自独立记忆上次 `autoPost` 开关状态。
2. **实例身份与幂等键（`ScheduledTransactionsView`）**：
   - 主键 `id` 改为独立稳定 **UUID**，彻底废除 `${seriesId}_${ms}` 日期拼接主键。
   - 增加唯一约束 `UNIQUE(series_id, occurrence_key)`：
     - `repeating` 的 `occurrence_key` 为按规则排出的原始逻辑排期日 `YYYY-MM-DD`（如 `'2026-11-15'`）；
     - `planned` 的 `occurrence_key` 固定为 `'single'`。
   - 单期改期或跳过只更新该行字段与状态，不修改 `occurrence_key`，从结构上杜绝重复物化并彻底消灭 `ScheduledBillRedirects`。
3. **单期覆盖字段设计**：
   - `ScheduledTransactionsView` 保留规则排定日 `scheduledDate`（非空），并设置三列显式可空覆盖字段：`amountOverrideMinor`（`int?`）、`dateOverride`（`DateTime?`）、`memoOverride`（`String?`）。
   - 任一覆盖列为 `null` 时继承系列模板（`series.amountMinor`、`scheduledDate`、`series.description`）；非 `null`（包括 `memoOverride == ''`）时优先采用覆盖值，从而保证后续「更新规则」不会静默冲掉用户已调过的单期覆盖。
   - 账户（`accountId`）与分类（`categoryId`）始终归属系列规则，不支持单期覆盖。
4. **来源关联与表/字段裁撤清单**：
   - 已入账交易继续复用 `TransactionRecorded.sourceScheduledBillId` 指向新实例的稳定 UUID。
   - 明确从领域模型与持久化表结构中裁撤：`ScheduledBillRedirects`、`AutomaticPostingBatches`、`AutomaticPostingBatchMembers`、`RestoreConfirmationBatches` 共 4 张表，以及 `ScheduledTransactionsView.autoPostEligible` 永久手动锁字段。
