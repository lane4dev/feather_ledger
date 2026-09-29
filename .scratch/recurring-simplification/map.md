# 周期与订阅模型瘦身方案决策地图

Label: wayfinder:map

## Destination

产出并锁定一套与个人记账实际复杂度相匹配的周期/订阅瘦身版规格（[spec.md](spec.md)）及数据模型、迁移边界方案，同时完成 `CONTEXT.md` 领域术语收敛与必要的 ADR 沉淀；本阶段不直接修改业务代码。

## Notes

- 范围覆盖三块耦合痛点：① 周期实例身份与编辑模型；② 自动入账与资格状态机；③ 物化窗口与通知生命周期；以及面向真实用户账本的平滑数据库迁移和 `CONTEXT.md` 术语重整。
- 每次会话应结合 `wayfinder`、`grilling`、`domain-modeling` 技能，并对照 `.specify/memory/constitution.md`、`CONTEXT.md` 及 `docs/adr/`。
- 允许推翻并简化 `.scratch/multi-currency/spec.md` 中过度复杂的边缘条文，但需保留既有 `RecurringSeries`、待入账实例和已入账交易的平滑迁移路径。
- 锚定方向（Chart 阶段已与用户锁定，各子票据不得违背以下前提）：
  - **实例身份**：`ScheduledTransactionsView` 改用独立稳定 UUID 主键 + `(series_id, occurrence_key)` 唯一约束；废除 `${seriesId}_${ms}` 拼接 ID 与 `ScheduledBillRedirects` 表。单期覆盖支持 **金额、日期、备注**（分类、账户跟随规则）。
  - **编辑与删除收敛**：编辑仅保留「仅此一期」与「更新规则（仅影响未入账未来期次）」，已入账交易永远不动，不再拆出新系列、不再有 `all` 回溯平移。对周期/订阅单期账单**不提供删除功能，仅允许「跳过」**；整体停止则针对规则本身。
  - **Entry mode 与自动入账**：收敛为 3 种模式——即时记账（默认）、一次性计划（`planned`，支持显式 `autoPost` 开关，UI 始终保持「计划」标签）、周期账单（`repeating`，带显式「到期自动入账」开关），新建时两类模式**各自独立记住**上次开关选择（`lastPlannedAutoPost` / `lastRepeatingAutoPost`）；创建或开启 `autoPost` 且起点在过去时不设保护，保存后即对当前币种当场自动补账。**取消**设置页 3 个默认关闭的全局开关、`enabledSince` / `currencyActiveSince` / `lastSeenWallClock`、`auto_post_eligible` 永久锁与 `AutomaticPostingBatches` 批次表。
  - **多币种与恢复水线**：取消 `RestoreConfirmationBatches` 多批次状态机，改为基于恢复点水线的轻量防误扣保护（恢复点之前已到期的降级为手动待入账）。非当前币种下周期与订阅完全静默（不自动入账、不发通知），直到用户切回该币种后弹出提醒交由用户手动处理或自动补记。
  - **物化、跳过恢复与通知**：未来仍采用有限前瞻窗口（90 天最多 3 期 / 保底 1 期），**历史欠账改回从 `startDate` 起全量补齐所有缺失发生日**（不设截断上限；开启 `autoPost` 自动转正入账，关闭 `autoPost` 生成待入账实例），保留 `skipped` 消耗 `countLimit` 不顺延；UI 界面内联展示 `skipped`（弱化样式 + **删除线** + 「已跳过」Badge，仅含 `skipped` 月份不亮提示点）与 `failed` 状态账单并允许将 `skipped` 恢复为待入账（恢复已到期 `autoPost` 实例自动置 `manualOnly = true`；停用规则直接删除 `skipped`；改基准日期或重复周期时仅保留 `posted`）；通知直接绑定稳定 UUID，废除通知重定向与精简删除记录表，点击 `skipped` 通知直达恢复弹窗，查无 UUID 才提示已不存在。

## Decisions so far

<!-- 索引：每关闭一张决策票据追加一行要点与链接；细节保留在各自票据中 -->

- [简化后的周期与计划领域模型和实例主键设计](issues/01-domain-model-and-identity.md)：`mode` 收敛为 `planned`/`repeating`，**两者均支持 `autoPost` 开关**（`lastPlannedAutoPost` / `lastRepeatingAutoPost` 各自独立记忆，不进备份，`planned` 保持「计划」标签）；实例改用稳定 UUID + `UNIQUE(series_id, occurrence_key)`（`YYYY-MM-DD` / `'single'`）与三列可空覆盖字段；裁撤 4 张冗余表与 `autoPostEligible`。
- [有限前瞻物化窗口与周期生命周期边界](issues/02-materialization-window-and-lifecycle.md)：未来 90 天最多 3 期（保底 1 期，去 3 年展开）；**历史缺失期次改回从 `startDate` 起全量补齐（取消 30 天 / 3 期截断且无硬上限）**，按 `autoPost` 自动入账或生成待入账，Banner 仅统计非自动入账待核对项；`skipped` 消耗 `countLimit` 不顺延；账户归档保留已到期一次性待办并删除原规则（同步修正 `CONTEXT.md`）。
- [极简编辑与跳过/删除语义设计](issues/03-edit-and-skip-semantics.md)：`planned` 支持 `autoPost` 开关与直接编辑/删除；`repeating` 菜单平铺「跳过本期」与「停止规则（`isActive = false` + 清 `scheduled`/`failed`/`skipped`）」；**UI 内联展示 `skipped`（弱化删除线）与 `failed` 账单，允许将 `skipped` 恢复为 `scheduled`（已到期 `autoPost` 恢复置 `manualOnly = true`，归档/已删账户禁止恢复）**；编辑收敛为 `thisOnly` vs `updateRule`（改规则专属字段禁用 `thisOnly`），改日期/周期时仅留 `posted` 并清理 `skipped`。
- [极简自动入账、多币种静默切回与恢复水线机制](issues/04-auto-post-currency-and-restore.md)：用单一 `manualOnly` 布尔列取代恢复/资格状态机与 3 个全局开关；取消创建/开启 `autoPost` 的过去期次拦截，保存后即对当前币种当场自动补账并弹泛化汇总 SnackBar；仅保留 `.flbackup` 恢复全币种 `markPreRestoreManualOnly()` 水线防误扣；切回币种时仅对积压 `autoPost && !manualOnly` 弹窗二选一（全补记/转手动）；失败保留 `failed` 渲染并支持重试。
- [基于稳定 UUID 的本地通知调度与失效降级](issues/05-notifications-and-deep-links.md)：`planned` 与 `repeating`（含 `autoPost`）保留可选提醒入口；调度按 `effectiveDate - reminderMinutes` 与实例稳定 UUID 全量对账，彻底废除 `ScheduledBillRedirects`；Deep Link 直查 UUID 状态（`scheduled`/`failed`/`skipped` 均直达 `PendingBillSheet` 相应态、`posted` 跳交易、查无 UUID 提示「该账单已不存在」）。
- [领域术语收敛（CONTEXT.md）与架构决策记录（ADR）](issues/06-glossary-and-adr-alignment.md)：对齐 `CONTEXT.md`（删除 `Bill eligibility`，重写 `Manual-only bill`、`Entry mode`、`Automatic posting`，微调 `Recurring series`、`Source bill`，修正 `Archive`）；同步 `docs/adr/0005-scheduled-bill-identity-and-two-scope-editing.md`；汇编交付最终规格 [spec.md](spec.md)。

## Not yet specified

无（2026-11-23 三项调整涉及的全部 8 个边界决策 Q1–Q8 已通过 `/grill-with-docs` 两轮评审完全收敛，并同步锁定 `CONTEXT.md`、`docs/adr/0005-...md`、`spec.md`、`issues/01..06` 与 `tasks/01..06`）。

## Out of scope

- 在本方案探索阶段直接修改生产 Dart 代码、Drift 表或运行迁移代码。
- 恢复 Google Calendar 式的 `thisAndFollowing` 拆表、`all` 历史平移或单期改账户/改分类能力。
- 保留 3 套默认关闭的全局自动入账开关、毫秒级激活边界历史、`auto_post_eligible` 永久手动锁以及多批次恢复确认状态机。
- 跨币种汇率换算、跨币种转账以及改动核心事件溯源账本（`ledger_events`）的不可变记账语义。
