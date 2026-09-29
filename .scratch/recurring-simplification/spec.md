# 周期与订阅模型瘦身版规格与迁移方案

> 本规格由 `.scratch/recurring-simplification/map.md` 全部 6 张决策票据（01–06）及边界核对（Round 1–2）收口产物汇总而成，目标是将周期/计划/订阅与提醒机制收敛到与个人记账（Accounted For）实际复杂度匹配的极简边界，开发期直接按目标 UUID 模型洁净重构 CRUD 周期表（严守事件溯源核心账本不受损）。
>
> 对齐资产：`CONTEXT.md`、`docs/adr/0005-scheduled-bill-identity-and-two-scope-editing.md`。

---

## 1. 设计原则与整体取舍

1. **只保留个人记账真实需要的两层抽象**：一条规则（`RecurringSeries`）+ 一批物化出来的待处理/历史账单实例（`ScheduledTransactionsView`）。
2. **禁止时间驱动的组合状态机**：彻底废除 3 套全局开关、毫秒级资格历史（`enabledSince` / `currencyActiveSince` / `lastSeenWallClock`）、`auto_post_eligible` 永久锁、多批次确认表（`AutomaticPostingBatches` / `AutomaticPostingBatchMembers` / `RestoreConfirmationBatches`）以及通知重定向链（`ScheduledBillRedirects`）。
3. **禁止 Google Calendar 式全历史拆分**：不因改一期或改未来规则而拆出碎片化子系列，也不改写已入账交易的分类/金额/日期历史。
4. **CRUD 豁免表边界不变**：`RecurringSeries` 与 `ScheduledTransactionsView` 依然是直写的 CRUD 豁免表，不进入事件存储重建；只有转正入账后的真实交易写入 `ledger_events`（`TransactionRecorded` 携带 `sourceScheduledBillId` 指向实例稳定 UUID）。
5. **开发期直接按目标模型落地**：应用尚在开发中，不对旧版（v14 及更早）周期表做历史数据搬迁或旧 `${seriesId}_${ms}` 兼容兜底；但升级时严守事件溯源红线（绝不删除或重建 `ledger_events` 与四张事件溯源投影视图）。

---

## 2. 领域模型与数据库 Schema（v15）

### 2.1 枚举与表单入口

- **`TransactionFormMode`（UI 创建入口，3 档）**：
  - `defaultMode`：即时记账（不建周期/计划规则）。
  - `planned`：一次性未来计划（无重复频率，允许开启/关闭 `autoPost` 开关）。
  - `repeating`：周期账单（含重复频率、`autoPost` 开关）。
- **`RecurringSeriesMode`（持久化枚举，2 档）**：
  - `planned (0)`：一次性计划（支持 `autoPost: bool`，决定到期是否自动入账；UI 始终保持「计划」标签，不改称「订阅」）。
  - `repeating (1)`：周期规则（`autoPost: bool` 决定是否到期自动入账；「订阅」仅作开启 `autoPost` 时的 UI 标签，不再作为独立领域枚举）。
  - **表单各自独立记住上次选择**：两个纯本地 UI 偏好 `lastPlannedAutoPost: bool` 与 `lastRepeatingAutoPost: bool`（均默认 `false`，**不写入 `.flbackup` 备份**），分别作用于新建 `planned` 与 `repeating` 时的初始开关状态。
- **`RecurringEditScope`（编辑作用域，2 档）**：
  - `thisOnly`：仅修改这一期（写单期覆盖列）。
  - `updateRule`：更新规则（仅影响未入账未来期次，不动已入账历史；仅在修改基准日期或重复周期时一并清除历史 `skipped`）。
- **`ScheduledTransactionStatus`（实例状态，4 档）**：
  - `scheduled` | `posted` | `skipped` | `failed`。

### 2.2 `RecurringSeries` 表（v15 变更）

保留既有核心字段（`id`, `rrule`, `startDate`, `endDate`, `countLimit`, `amountMinor`, `description`, `categoryId`, `accountId`, `type`, `autoPost`, `mode`, `reminderMinutes`），新增：

- `isActive: bool`（`DEFAULT true`）：软停用标记；停止周期规则时置为 `false`（并删除其尚未入账 `scheduled`、`failed` 与已跳过 `skipped` 实例），物理保留系列记录与历史 `posted` 行以维持 `sourceScheduledBillId` 与外键不断链。

### 2.3 `ScheduledTransactionsView` 表（v15 重构）

| 列名 | 类型 / 约束 | 语义说明 |
| :--- | :--- | :--- |
| `id` | `TEXT PRIMARY KEY` | 独立稳定 **UUID**（彻底替代 `${seriesId}_${ms}`） |
| `series_id` | `TEXT NOT NULL REFERENCES recurring_series(id)` | 所属规则 ID |
| `occurrence_key` | `TEXT NOT NULL` | `repeating` 取规则排出的逻辑排期日 `YYYY-MM-DD`；`planned` 固定 `'single'`。**单期改期与跳过均不改变该列** |
| `scheduled_date` | `DATETIME NOT NULL` | 规则原始排定日期 |
| `amount_override_minor` | `INTEGER NULL` | 单期金额覆盖（`null` 表示继承 `series.amountMinor`） |
| `date_override` | `DATETIME NULL` | 单期日期覆盖（`null` 表示继承 `scheduledDate`） |
| `memo_override` | `TEXT NULL` | 单期备注覆盖（`null` 表示继承 `series.description`；显式 `''` 视为覆盖为空） |
| `manual_only` | `BOOLEAN NOT NULL DEFAULT 0` | 仅手动入账标记（替代原 `auto_post_eligible` 永久锁） |
| `status` | `TEXT NOT NULL` | `'scheduled'` \| `'posted'` \| `'skipped'` \| `'failed'` |
| `transaction_id` | `TEXT NULL` | 转正后的原始交易 ID |
| 唯一索引 | `UNIQUE(series_id, occurrence_key)` | 结构性保证物化幂等、杜绝单期改期或跳过后重复生成 |

**派生生效属性（领域实体计算属性）**：
- `effectiveDate` = `dateOverride ?? scheduledDate`
- `effectiveAmountMinor` = `amountOverrideMinor ?? series.amountMinor`
- `effectiveDescription` = `memoOverride ?? series.description`
- **不可单期覆盖字段**：`accountId`、`categoryId` 始终归属 `RecurringSeries`。

### 2.4 裁撤的表与状态（v15 移除）

- 物理删除 4 张 CRUD 冗余表：
  - `AutomaticPostingBatches`
  - `AutomaticPostingBatchMembers`
  - `RestoreConfirmationBatches`
  - `ScheduledBillRedirects`
- 删除 `ScheduledTransactionsView.autoPostEligible` 列（逻辑迁移至反向语义 `manualOnly`）。
- 删除设置页 3 个本地自动入账全局开关、`enabledSince`、`currencyActiveSince`、`lastSeenWallClock` 偏好键，以及设置页恢复确认批次弹窗、`AutomaticPostingPolicy` 毫秒资格边界与进度弹窗。

---

## 3. 核心行为规格

### 3.1 有限前瞻物化窗口与历史截断

1. **未来前瞻窗口（`repeating` 且 `isActive == true` 且账户未归档）**：
   - 以今天为起点向后 **90 天**内，每条活跃规则最多保留 **`3` 期**未来 `scheduled` 实例；
   - **保底 `1` 期**未来实例（仅用于兜住如每年一次等超过 90 天的低频规则，取消 3 年长距离前瞻）。
   - `planned` 规则直接按自身 `scheduledDate` 物化唯一 `'single'` 实例，不受 90 天窗口约束。
2. **历史缺失期次全量补齐与会话级 UI 提醒**：
   - 物化器回溯早于今天的未物化历史期次时，**从 `series.startDate` 起补齐所有缺失的历史期次实例**，取消「仅回溯最近 30 天内、且单条规则最多补生成最近 3 期」的截断限制且不设人工硬截断上限；已在数据库中的历史 `scheduled`/`posted`/`skipped`/`failed` 行保持幂等不重复生成。
   - **按规则 `autoPost` 分流处理**：
     - 若规则开启了自动入账（`autoPost == true`，且未被标为 `manualOnly`、当前币种、规则活跃、账户未归档）：先物化缺失实例，再由自动入账流自动生成对应的已入账交易记录（`TransactionRecorded`）；
     - 若规则关闭了自动入账（`autoPost == false` 或已标 `manualOnly == true`）：仅生成 `scheduled` 待入账交易记录留待用户手动处理。
   - 物化命令返回 `newlyMaterializedOverdueCount`，**仅统计本次新补齐且不会自动入账、需用户手动核对的过期实例**（即 `autoPost == false` 或 `manualOnly == true`，避免与启动自动入账 SnackBar 自相矛盾）。当 `newlyMaterializedOverdueCount > 0` 时，账本页顶部显示一条**纯会话级、可手动关闭的非阻塞 Banner**（提示「本次新补齐了 N 笔已到期账单，请核对处理」，不新增表或持久化字段）。
3. **有限次数与跳过**：
   - 取消 `extraCount` 末尾顺延补期逻辑；每次 `skipped` 直接消耗 `countLimit` 的 1 次计数。
   - 全部期次进入终态或超过 `endDate` 后，物理保留规则与历史实例行，物化器自然不再生成。
4. **账户归档联动**（与 `account_lifecycle_command.dart` 现行实现及修正后的 `CONTEXT.md` 一致）：
   - 账户归档时，仅将已到期未处理（`scheduled`/`failed`）的账单保留为一次性 `planned` 待办，原周期规则与未到期未来实例删除；恢复归档账户不复活已删除规则。

### 3.2 二元编辑与「跳过 / 停止规则」边界

1. **`planned`（一次性计划）**：
   - 新建与编辑页均支持配置 `autoPost` 开关（交互逻辑对齐 `repeating`，UI 标签始终保持「计划」）；编辑直接更新规则与 `'single'` 实例，不弹作用域弹窗。
   - 详情页溢出菜单只提供「**删除计划**」（二次确认后物理删除该规则与实例），不提供「跳过」。
2. **`repeating`（周期账单）与已跳过账单展示/恢复**：
   - 详情页溢出菜单直接平铺「**跳过本期**」（置为 `skipped`）与「**停止周期规则**」（软停用 `isActive = false` 并删除该系列下所有 `scheduled`、`failed` 与 `skipped` 实例，仅保留 `posted` 历史），各自独立二次确认；**彻底取消删除作用域弹窗，单期不提供“删除”入口或字样**。
   - **UI 显示已跳过与失败账单，并支持恢复 `skipped`**：
     - 账本页按天时间轴内联展示 `scheduled`、`failed` 与 `skipped` 行；其中 `skipped` 行采用弱化透明度 + **删除线** + 「已跳过」Badge，不计入当日收支小计与月度合计。若某天仅有 `skipped` 行，日期分组头部照常显示。
     - 月份选择器上的待办提示标记点（`pendingBillMonths`）仅统计 `scheduled` 与 `failed`，**不标记仅含 `skipped` 的月份**。
     - 点开 `skipped` 账单的详情弹窗（`PendingBillSheet`）时，仅提供主操作「**恢复为待入账**」（隐藏「记入 / 编辑 / 跳过」）；恢复后回到 `scheduled` 态即可执行常规操作。
     - **恢复边界**：所属账户已归档或已删除时禁止恢复（返回对应 `LedgerErrorCode`）；若恢复的 `skipped` 实例属于 `autoPost == true` 规则且当时已到期（`effectiveDate <= now`），恢复时**自动置 `manualOnly = true`**（停留在待入账列表等用户手动处理，若之后单期改期至未来则清除 `manualOnly`）。
3. **编辑二元作用域（`thisOnly` vs `updateRule`）**：
   - **仅修改本期（`thisOnly`）**：仅对本次编辑中**确实改变**（相对当前规则模板或继承值）的字段写入 `amountOverrideMinor` / `dateOverride` / `memoOverride`，未改动字段保持 `NULL` 以继续继承后续 `updateRule` 改动（若规则备注非空而用户在单期将其清空，则写入 `''` 表示显式覆盖为空）；不改 `occurrence_key` 与 UUID；**允许单期改期与同系列其他期次落在同一天**（不再因同日抛 `scheduledDateTaken`）；不展示额外角标。若系列开启 `autoPost` 且修改后 `effectiveDate > today`，清除 `manualOnly` 并按覆盖后的金额/备注/日期到期自动入账；若被编辑账单原为 `failed`，保存后重置为 `scheduled`。
   - **规则专属字段保护**：用户在编辑页改动了**分类、账户、`autoPost` 开关或重复规则（`CustomRecurrence`）**中的任意一项时，保存作用域弹窗禁用「仅修改本期」，提示仅可选择「更新周期规则」。
   - **更新规则（`updateRule`）**：复用 `CustomRecurrenceDialog` 支持修改全部模板字段（金额、基准日期、分类、账户、备注、提醒、**`autoPost` 开关**与完整 `CustomRecurrence` 规则：频率 / 间隔 / 星期 / 结束日期或次数上限）。保存后将该系列下覆盖范围内的 `failed` 实例一并复位为 `scheduled`（保持既有 `manualOnly` 值不变）。
     - **未改变基准日期与重复周期时**（即 `date` 与 `frequency`/`interval`/`weekdays` 均未变，含仅调金额/模板/开关或 `endDate`/`countLimit`）：原地更新 `RecurringSeries`；尚未入账实例中覆盖列为 `null` 的字段继承新规则，非 `null` 单期覆盖列继续保留；已 `posted`/`skipped` 历史不动。**次数上限下限校验**：统计 `K = posted + skipped`，要求 `countLimit >= K + 1`。
     - **改变了基准日期或重复周期时**（`date` 或 `frequency`/`interval`/`weekdays` 任一变化）：`series.startDate` 更新为本次编辑的日期，**不保留 `skipped` 历史、仅保留 `posted` 行**——事务内删除该系列全部 `scheduled`、`failed` 与 `skipped` 行，再按新规则从新 `startDate` 起重新物化；若新算出的某个 `occurrence_key` 恰好与已有 `posted` 历史行撞期，则保留历史行并跳过该日不再重复物化。**次数上限下限校验**：因 `skipped` 将被清除，`K` 仅统计 `posted` 行数，要求 `countLimit >= K + 1`。
   - **编辑形态锁定**：在 `RecurringBillFormScreen` 中保持 `planned` 与 `repeating` 各自形态锁定，不提供互转入口。

### 3.3 极简自动入账、多币种静默切回与恢复水线

1. **当前币种常规启动与保存后即时自动入账**：
   - 当前币种下，满足 `series.isActive && series.autoPost && !manualOnly && (status == scheduled) && effectiveDate <= now`（且账户未归档）的实例（涵盖 `planned` 与 `repeating`，以及本次物化补齐的所有缺失历史 `autoPost` 实例），在启动首帧后异步分片自动入账（每 20 笔让出一次事件循环，保留冷启动通知动作优先于自动入账的 deferral 机制）。
   - **保存后即时自动入账**：在表单新建或通过 `updateRule` 开启 `autoPost = true`（涵盖 `planned` 与 `repeating`）且存在已到期实例时，保存并完成物化后**当场对当前币种该规则执行 `catchUpAutoPosted`** 并弹出入账汇总 SnackBar（非当前币种保持静默，待切回币种时弹出补记提示）。
   - 当次自动入账成功 `N >= 1` 笔时，弹出轻量 SnackBar 提示（兼容计划与订阅的泛化文案，例如「已自动记入 N 笔计划或订阅账单」）。
   - 单笔入账失败时置为 `ScheduledTransactionStatus.failed`（不阻塞其余实例；不新增 `failure_reason` 存储列），在账本列表保留展示并置顶警示，用户点开 `PendingBillSheet` 可重试「记入」或「跳过本期」（`ConvertScheduledToPostedCommand` 与 `skipIfScheduled` 均同时接受 `scheduled` 与 `failed`，重试失败时直接弹出具体 `LedgerErrorCode` 本地化文案）。
2. **创建与开启 `autoPost` 不设过去期次拦截保护**：
   - 取消创建时及 `updateRule` 开启 `autoPost` 时的过去期次 `manualOnly` 拦截：只要创建了 `autoPost = true` 规则（`planned` 或 `repeating`）或通过 `updateRule` 将 `autoPost` 从 `false` 改为 `true` 且起点包含过去/当前日期，物化出的全部缺失期次保持 `manualOnly = false`，对当前币种当场并全部自动生成已入账交易（非当前币种切回时入积压弹窗）。
   - 防误扣保护仅保留给备份恢复水线（下条 `markPreRestoreManualOnly`）与从 `skipped` 恢复已到期 `autoPost` 实例的场景。
3. **备份恢复（`.flbackup`）全币种水线保护**：
   - **承重启动顺序**：`applyPendingRestore` → `rebuild (if stale)` → `materialize()` → **`markPreRestoreManualOnly()`（检测到 `readRestoreBarrier` 时执行）** → `catchUpAutoPosted()`。
   - `markPreRestoreManualOnly()` **不区分当前币种、面向全币种**将库内所有 `status == scheduled && effectiveDate <= restoreTime` 的实例一次性标为 `manualOnly = true`（确保即便稍后切换其他币种，恢复前到期的多币种账单也不会自动入账或进入一键补记）。
   - 若当前币种存在被拦截的恢复前到期实例，账本页顶部展示一条会话级可关闭 Banner 提示核对。
   - 用户后续若显式把某笔 `manualOnly` 实例单期改期到未来（`effectiveDate > today`），清除 `manualOnly` 恢复自动资格。
4. **多币种静默与切回提醒**：
   - 非当前币种完全静默：不自动入账、不弹窗、不调度通知提醒。
   - 用户将当前币种切换为 `C` 时，查询 `currency == C && status == scheduled && effectiveDate <= now && !manualOnly && series.autoPost == true` 的积压实例：
     - 仅在存在积压项时弹出轻量确认弹窗，提供二选一：**「一键全部自动补记」**（立即转正入账）或**「转为待手动处理」**（将这些积压项标为 `manualOnly = true` 留在待入账列表逐条处理；切回后新到期的未来期次照常自动入账）。
     - 普通 `autoPost == false` 手动账单与 `manualOnly == true` 的恢复前旧账单不进弹窗。

### 3.4 基于稳定 UUID 的本地通知调度与失效降级

1. **可选提醒覆盖所有排期规则**：`planned` 与 `repeating`（含 `autoPost == true`）在新建与编辑页保留提醒设置入口，默认不设即不调度；用户设置了则按设定触发。
2. **调度与全量对账**：
   - 保留 `watchScheduled()` 响应式全量对账（`_reconcile`）、当前币种过滤、账户未归档过滤以及 iOS 64 条配额内 `limit = 60` 上限。
   - 触发时间与排序一律改读 **`effectiveDate - Duration(minutes: reminderMinutes)`**，使单期改期后通知时间同步更新。
   - 通知 payload 与系统通知哈希 `_stableId(bill.id)` 直接绑定实例稳定 UUID。
3. **点击与快捷动作（Deep Link）**：
   - **`scheduled`**：支持快捷动作「记入 / 跳过」（含冷启动 deferral 保护）；点击主体跳转 `/ledger` 并打开 `PendingBillSheet`。
   - **`failed`**：打开 `PendingBillSheet` 展示错误并支持重试「记入」或「跳过本期」。
   - **`posted`**：直接通过 `getTransactionBySourceBill(bill.id)` 查找当前有效交易（含更正后的最新交易）并打开 `TransactionDetailSheet`；若该交易已冲正删除，轻提示「这笔交易已删除」。
   - **`skipped`**：直接跳转到 `/ledger` 并打开 `PendingBillSheet` 展示「已跳过」状态与「恢复为待入账」主按钮，方便用户一键恢复。
   - **库中查无此 UUID**（规则停止被清理、计划已删除、或改日期/频率重建了未来实例）：统一轻提示「该账单已不存在」。

---

## 4. 数据库 Schema 升级边界（v14 → v15）与旧规格取代清单

### 4.1 `AppDatabase` v14 → v15 升级策略（开发期洁净重构）

> 注意：`RecurringSeries` 与 `ScheduledTransactionsView` 为 CRUD 豁免表，**不触发**也不依赖 `LedgerRebuildService.isStale()`；`onUpgrade` 绝不可删除/重建事件溯源视图表（`AccountsView`, `TransactionsView`, `TransactionPostingsView`, `CategoriesView`）。

因应用处于开发阶段，不需要对旧版周期表做逐行数据搬迁或兼容兜底（不保留 `'pending'` 旧状态兼容与 `bill.transactionId` 旧行兜底，所有实例一律使用 UUID v4）：

1. **重建 CRUD 豁免周期表（`onUpgrade` `from < 15`）**：
   - 先 `DROP TABLE IF EXISTS` 清理 4 张废表（`automatic_posting_batch_members`, `automatic_posting_batches`, `restore_confirmation_batches`, `scheduled_bill_redirects`）与旧的 `scheduled_transactions_view`、`recurring_series`；
   - 再通过 `Migrator.createTable` 重建瘦身后的 `recurringSeries`（含 `isActive`、2 档 `mode`）与 `scheduledTransactionsView`（UUID 主键 + `UNIQUE(series_id, occurrence_key)` + 3 列单期覆盖 + `manual_only`）。
   - 严守红线：上述清理仅限 CRUD 豁免周期表，绝不触碰 `ledger_events` 与 4 张事件溯源投影视图。
2. **恢复 `.flbackup` 兼容边界**：
   - 沿用单向版本号策略（仅拒绝比当前 `schemaVersion` 更新的备份）。
   - 恢复旧版本（如 v14）备份时，`AppDatabase` 的 `onUpgrade` 清理并重建周期表，紧接着 `main.dart` 启动链上的 `materialize()` → `markPreRestoreManualOnly()` 接管水线（若未来正式发布后需要保留已有周期数据，再在该基线版本之上通过常规 `onUpgrade` 演进）。
   - 备份恢复不导入本机偏好 `lastPlannedAutoPost` 与 `lastRepeatingAutoPost`（本地偏好保持本机隔离）。

### 4.2 `.scratch/multi-currency/spec.md` 被取代/裁剪条款对照

| 原 `multi-currency/spec.md` 条文范围 | 原复杂要求 | 本瘦身方案处置 |
| :--- | :--- | :--- |
| **US28–US31**（4 模式与 3 套默认关闭全局开关） | 4 种录入模式；3 个独立本机全局开关 | **取代**：收敛为 3 模式（`default`/`planned`/`repeating`）+ 系列级 `autoPost` + `lastPlannedAutoPost` / `lastRepeatingAutoPost` 各自独立本地记忆 |
| **US32–US36, US39–US41**（毫秒级边界与永久锁） | `enabledSince`/`currencyActiveSince`/`lastSeenWallClock`、`autoPostEligible` 永久锁 | **废弃**：由单列 `manualOnly` + 切币种弹窗 + 改期至未来自动清除 `manualOnly` 取代 |
| **US44–US55**（无限历史欠账补齐与多批次进度状态机） | 无限历史枚举、`AutomaticPostingBatches`、进度条弹窗、中断恢复批 | **部分恢复并简化**：恢复历史缺失期次全量补齐（取消 30 天最多 3 期截断），开启 `autoPost` 自动转正入账、关闭 `autoPost` 生成待入账；继续废弃 `AutomaticPostingBatches`、进度条弹窗与未来 3 年展开（未来仍限 90 天最多 3 期 / 保底 1 期） |
| **US56–US67**（多批次恢复确认屏障与竞态重确认） | `RestoreConfirmationBatches`、`backupExportedAt` 窗口重确认弹窗 | **废弃**：替换为 `materialize()` 后的全币种 `markPreRestoreManualOnly()` 一次性水线打标 + 会话级 Banner |
| **US68–US73**（16 跳通知重定向与精简删除存根） | `ScheduledBillRedirects`、保留删后存根、跨币种保留并打开旧通知 | **简化**：稳定 UUID 直连 + `effectiveDate` 对账；非当前币种静默且切离取消；`skipped`/缺失统一轻提示 |
| **US75–US83**（`thisAndFollowing`/`all` 拆分与删后补期） | 同频跨周期锚点映射、保留删后末尾 `extraCount` 顺延 | **废弃**：二元作用域 `thisOnly` vs `updateRule`；单期不允许删只允许跳过；跳过消耗 `countLimit` 不补期 |
| **Out of Scope**（不支持修改重复频率） | 首版不允许修改重复频率 | **放开**：`updateRule` 支持修改重复频率并安全重建未入账未来实例 |
