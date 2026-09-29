# 二元编辑作用域与「跳过 / 停用」交互边界

Type: grilling
Label: wayfinder:grilling
Status: resolved
Triage: ready-for-human
Blocked by: 01, 02

## Question

在「编辑仅分本期 vs 更新规则」且「周期/订阅单期不提供删除、仅允许跳过」的约束下，两类操作的精确行为、单期冲突处理以及改规则对现有未入账实例的影响应如何定义？

## Context

Chart 阶段已锁定：
- **编辑**二元收敛：「仅此一期」vs「更新规则（应用到所有尚未入账的未来期次）」；已入账交易永远不动，不再拆出 `thisAndFollowing` 系列，不再有 `all` 回溯修改历史。
- **删除/跳过**规则：对周期和订阅单期账单，**不提供删除功能，仅允许「跳过」**；整体停止针对周期规则本身。

本票需要敲定的核心细节：
1. **一次性计划（`planned`）与周期账单的操作差异**：
   - 一次性计划只有 1 条实例，是否保留直接「删除该计划」（物理删除规则与实例），而不提供“跳过”或作用域弹窗？
   - 周期账单（`repeating`）详情页的溢出菜单/按钮如何呈现「跳过本期」与「停止/删除此周期规则」两个入口（明确不给单期“删除”字样）。
2. **「仅此一期」编辑细节**：
   - 单期改期（`scheduledAt`）时，如果目标日期与同系列另一条活跃或已跳过期次撞期，是允许各自独立存在（因为主键已是 UUID + `occurrence_key`！），还是提示/限制同日冲突？
   - 单期修改字段（金额、日期、备注）后，在界面上是否需要标记“已单期调整”，以及自动入账规则对已单期调整过的过期期次如何处理（例如改到未来继续自动，改到过去直接保持手动）。
3. **「更新规则」对未来未入账实例的刷新策略**：
   - 只改金额、分类、账户、备注、是否自动入账时：原地更新系列，未覆盖的未入账实例直接继承新规则（已手工改过金额/备注的单期实例是保留单期覆盖还是被规则刷新？）。
   - 如果用户修改了**开始日期 / 重复频率**（例如每月 10 号改到 15 号）：如何干净地重建尚未入账的未来实例，且不引入 `ScheduledBillRedirects` 或跨周期锚点映射表？
4. **「停止/删除规则」后的遗留语义**：
   - 停止规则时，未入账的未来/逾期实例一律清理（或保留已到期的手动实例？），已入账交易与系列名字/来源关系如何处理（物理删规则 vs 软停用 `isActive = false`）。

## Comments

- 用户确认：Q1=`a`（`repeating` 溢出菜单平铺「跳过本期」与「停止周期规则」，取消删除作用域弹窗；`planned` 仅直接编辑与「删除计划」）；Q2=`a, 是`（单期改期允许同日并存；覆盖与 `autoPost` 联动；改规则专属字段时禁用「仅修改本期」并提示只能「更新周期规则」）；Q3=`1 选 (b), 2 确认`（允许在更新规则时修改重复频率与 `autoPost` 开关）；Q4=`a`（软停用 `RecurringSeries.isActive = false` + 删除未入账 `scheduled`/`failed` 实例）。

## Answer

1. **一次性计划（`planned`）与周期账单（`repeating`）的操作边界**：
   - **`planned`（一次性计划）**：新建与编辑页均支持配置 `autoPost` 开关（交互对齐 `repeating`，UI 标签保持「计划」）；编辑时直接更新该计划及唯一实例（不弹作用域框）；溢出菜单只提供「**删除计划**」（二次确认后物理删除该 `RecurringSeries` 与对应实例），不提供「跳过」。
   - **`repeating`（周期账单）**：溢出菜单直接平铺「**跳过本期**」（将实例置为 `skipped`）与「**停止周期规则**」两个独立动作，各自走独立二次确认，**彻底取消删除作用域弹窗**，单期绝不提供“删除”入口或字样。
   - **UI 显示已跳过与失败账单，并支持恢复 `skipped`**：
     - 账本页按天时间轴内联展示 `scheduled`、`failed` 与 `skipped` 行；`skipped` 行采用弱化样式 + **删除线** + 「已跳过」Badge（不计入当日小计与月度合计；当天只有 `skipped` 行时日期分组照常显示）。
     - 月份选择器红点（`pendingBillMonths`）仅统计 `scheduled` 与 `failed`，不因仅有 `skipped` 而标记月份。
     - 点开 `skipped` 账单详情弹窗仅提供「**恢复为待入账**」主操作（隐藏记入/编辑/跳过）；所属账户已归档或已删除时禁止恢复；若恢复的 `skipped` 实例属于 `autoPost == true` 规则且已到期（`effectiveDate <= now`），恢复时**自动置 `manualOnly = true`**（改期到未来则清除）。

> **[2026-11-23 规格调整对齐]**：补充 `planned` 编辑态 `autoPost` 开关、UI 内联展示 `skipped`（删除线）与 `failed` 账单及 `skipped -> scheduled` 恢复边界。
2. **「仅修改本期（`thisOnly`）」与二元作用域交互**：
   - 作用域枚举收敛为二元：`thisOnly` | `updateRule`（删除旧 `thisAndFollowing` 与 `all`）。
   - **单期改期允许同日并存**：依托 UUID + `UNIQUE(series_id, occurrence_key)`，同一系列两期实际日期落在同一天时不再报 `scheduledDateTaken` 冲突。
   - **单期覆盖与界面展示**：单期修改写入 `amountOverrideMinor` / `dateOverride` / `memoOverride`，账本列表直接展示生效值（不增加额外的“已单期调整”角标）。若系列开启 `autoPost` 且该期覆盖后仍处于未来日期，到期后按覆盖后的金额/备注/日期自动入账。
   - **规则专属字段限制**：当用户在编辑页改动了规则专属字段（分类、账户、`autoPost` 开关、重复频率）时，保存作用域弹窗禁用「仅修改本期」并提示仅能选择「更新周期规则」。
3. **「更新规则（`updateRule`）」编辑范围与刷新策略**：
   - 编辑页支持修改全部规则模板字段：金额、基准日期、分类、账户、备注、提醒、**`autoPost` 开关**与**重复频率（每日/每周/每月/每年）**。
   - **未改变基准日期与重复周期时**（即 `date` 与 `frequency`/`interval`/`weekdays` 均未变）：原地更新 `RecurringSeries`；尚未入账实例中对应覆盖列为 `null` 者自动继承新规则，用户之前单期手工调整过的非 `null` 覆盖列继续保留；已 `posted`/`skipped` 历史行不动（`countLimit >= K + 1` 中 `K` 计 `posted + skipped`）。
   - **改变了基准日期或重复周期时**（`date` 或 `frequency`/`interval`/`weekdays` 任一改变）：更新系列新规则（`series.startDate` 设为本次编辑日期），**不保留 `skipped` 历史、仅保留 `posted` 行**——删除该系列下所有 `scheduled`、`failed` 与 `skipped` 行，再按新规则从新日期起重新物化（`countLimit >= K + 1` 中 `K` 仅计 `posted`；若新排期与 `posted` 撞期则跳过该日不重复物化）。
4. **「停止周期规则」持久化语义**：
   - 采用**软停用**：新增 `RecurringSeries.isActive: bool`（默认 `true`），停止时置为 `false`，并**删除该系列下所有 `scheduled`、`failed` 与 `skipped` 实例**。
   - 物理保留 `RecurringSeries` 与全部历史 `posted` 实例，确保 `sourceScheduledBillId` 溯源与外键永不断链；物化查询仅扫描 `isActive == true` 的规则。
