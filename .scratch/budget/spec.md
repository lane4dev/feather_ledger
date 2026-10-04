# 月度预算与复盘功能规格说明书（Budget & Review）

> **状态**：设计已锁定（Wayfinder 探索阶段收官文档）  
> **目标目录**：`lib/features/budget/`（遵循 `lib/features/ledger/` 垂直切片架构）  
> **关联决策**：[CONTEXT.md](../../CONTEXT.md)（`### Budget & Review`）、[ADR-0006](../../docs/adr/0006-budget-stepped-timeline-and-crud-exemption.md)、[UI 交互原型](prototype-budget-ui.html)

---

## 1. 目标与产品定位

以 `.scratch/.ref/Monthly budget.xlsx` 的分类限额汇总为数学基线，将 `/budget`（底部导航第二 Tab）建设为围绕 **「规划（Plan with evidence）→ 跟踪（Track）→ 复盘（Review）」** 闭环的个人支出预算核心驾驶舱：

1. **规划**：设定/调整预算时旁路提供历史与固定基线参考（上月实际、近 3 月均值、当月固定支出底线）。
2. **跟踪**：按当前币种实时追踪已入账实际支出（`Actual`）与待入账周期/计划账单占用（`Pending`），并在 `TransactionFormScreen` 记账时提供非阻塞的即时预算余量提示。
3. **复盘**：支持历史月份及当月复盘视图，自动拆解「固定支出（Committed）」与「弹性支出（Discretionary）」，识别超支/结余 TOP 归因、未设预算大额支出与异常波动，提供近 6 个月趋势对比，并支持月度与分类维度的持久化 `Review Note`。

### 1.1 明确边界（Out of Scope）

- 不含**收入预算表**或独立的全局总支出/预期收入心理上限参考线；总预算永远等于各支出分类预算自底向上之和。
- 顶部不展示账户「期初/期末余额」与「储蓄变化率」。
- 不支持跨月结余滚存（Rollover）、本地推送提醒（如 80%/100%）、账户/标签维度预算、跨币种汇率合并。
- 不在 `/ledger` 账本首页头部嵌入预算卡片或桌面小组件；记账联动仅限于 `TransactionFormScreen` 只读提示条。
- `/budget` 与 `/ledger/reports` 各自独立：`/budget` 负责支出预算规划与复盘，`/ledger/reports` 保留收支构成饼图与日净流量热图，不做强耦合互跳或文案复用。

---

## 2. 领域模型与不变量

### 2.1 统一语言（参见 `CONTEXT.md`）

严格避免复用已被 `Entry mode` 占用的 `planned` 一词，也不在查询模型中使用易与持久投影表 `MonthlyAccountBalanceSnapshots` 混淆的 `Snapshot` 命名；预算体系统一使用：
- **Category budget**：`(currencyCode, categoryId)` 在某自然月的正整数支出上限（遵循 `ADR-0004` 两位小数最小单位 `amountMinor > 0`；清空即解除设定 `unset`，绝不存 0）。
- **Budget timeline**：按 `effectiveYm = year * 100 + month` 递增的阶跃规则序列。
- **Committed spend**：当月带 `sourceScheduledBillId` 的已入账支出 + 跟踪视图下的 `Pending` 账单。
- **Discretionary spend**：当月不带 `sourceScheduledBillId` 的普通支出。
- **Pending bill exposure**：当月及未来月状态为 `scheduled` 或 `failed` 且关联账户 `includeInTotals == true && deleted == false` 的支出账单。
- **Budget variance**：统一定义为 `Budget - Actual`（正数为结余/余量，负数为超支）；扣除 `Pending` 后的剩余命名为 `projectedRemainingMinor`（UI 文案「预计剩余」）。
- **Review note**：按 `(currencyCode, ym, categoryKey)` 存储的纯文本复盘备忘（`<= 500` 字，`categoryKey = ''` 表示月度级）。

### 2.2 跨月规则与编辑作用域

1. **阶跃继承**：对于 `(currencyCode, categoryId, M)`，生效规则取所有 `effectiveYm <= M` 中的最大 `effectiveYm` 行；若该行 `amountMinor == null`（`unset` 哨兵）或无任何行，视为**未设预算**。
2. **两个编辑/清除作用域**（`BudgetEditScope`）：
   - `thisMonthOnly`：仅改变 `M`，若 `M+1` 当前尚无显式断点，必须在同一事务内先将 `M+1` 锚定为编辑前 `M` 的生效状态（`amountMinor` 或 `null`），再写入 `M`。
   - `thisAndFollowing`：写入 `M` 并删除所有 `effectiveYm > M` 的未来断点。
3. **智能默认与安全边界**：
   - 仅当用户在**当前月或未来月**对某分类满足 **「当前生效预算为 `null` 且不存在任何 `effectiveYm > M` 的显式未来断点」** 时，才跳过作用域弹窗直接按 `thisAndFollowing` 生效；若未来已存在任何显式断点（哪怕当前月未设预算），仍必须弹出作用域选择并明确提示覆盖后续规则；其余更新或清除均弹窗选择作用域。
   - **全时间轴可编辑**：过去、当前、未来月份均可编辑，但历史月编辑时给出轻量引导提示“历史月已结束，建议调整当前或未来月份以指导后续执行”。
4. **分类归档截断**：
   - 归档分类（`CategoriesView.archived == true`）**禁止**为任何月份新设或恢复预算（包括 `M <= archiveYm`），仅保留历史月份只读展示与旧 `Review Note` 查看；系统内置分类（`systemCode != null`）及非 `expense` 分类一律排除在预算之外。
   - 归档判定以 `CategoriesView.archivedAt.toLocal()` 所在自然月 `archiveYm` 为准：**归档当月（`M <= archiveYm`）保留既有预算，次月起（`M > archiveYm`）自动截断停止延续**（纯读时截断，不主动删改归档前留下的 `budget_rules` 行）。

### 2.3 计算口径与冷启动规则

1. **币种与账户过滤**：
   - 预算主屏严格使用全局 `ledgerCurrencyProvider`（`Current currency`）；多币种规则彼此独立（`TransactionFormScreen` 提示条则遵循表单打开时锁定的 `formState.currencyCode`）。
   - `Actual` 仅统计 `transactions_view` 中满足以下条件的分录金额绝对值之和：`currencyCode == targetCurrency`、`kind == expense`、`isReversed == false`、`account.includeInTotals == true && account.deleted == false`（保留 `archived == true` 历史账户，排除 `transfer`、`openingBalance`、`balanceAdjustment`，与 `ReportsDao` 100% 对齐）。
2. **`Pending` 账单口径**：
   - 取 `scheduled_transactions_view` join `recurring_series` 与 `accounts_view`：`type == expense`、`currencyCode == targetCurrency`、`account.includeInTotals == true && account.deleted == false`、`status IN ('scheduled', 'failed')`。
   - 金额取 **`coalesce(scheduled.amountOverrideMinor, recurringSeries.amountMinor)`**，生效日期取 **`coalesce(scheduled.dateOverride, scheduled.scheduledDate)`**；严格按生效日期所在自然月 `[monthStart, nextMonthStart)` 归属，**不跨月顺延**到当前月。
   - 当月与未来月均**只读取已物化实例行**（与 `/ledger` 待入账列表保持单一数据源；`ProjectRecurringEventsCommand` 对 `repeating` 系列在未来 90 天最多物化 `maxKeep = 3` 期、`minKeep = 1` 期），不对日/周高频系列或远期月在查询侧另写 RRULE 推演，而在存在未完全物化系列或远期月时展示轻提示「仅含已物化排期」。
3. **固定（Committed）vs 弹性（Discretionary）**：
   - 已入账固定支出 = 当月 `Actual` 中 `sourceScheduledBillId != null` 的交易金额之和；已入账弹性支出 = `sourceScheduledBillId == null` 的支出。
   - 当月固定基线（Committed Baseline）= 已入账固定支出 + 当月 `Pending` 账单之和。
4. **近 3 月均值（3-Month Average）**：
   - 对目标月 `M`，统计前三个完整自然月 `[M-3, M-2, M-1]` 的实际支出算术平均。
   - 冷启动修正：若当前币种最早一笔支出交易所在月 `earliestTxYm` 晚于 `M-3`，分母按 `[max(M-3, earliestTxYm) .. M-1]` 的实际月数计算；若 `M <= earliestTxYm`（无前置历史月），则不显示均值或显示 `—`。
5. **总计（Totals）与达标率（Compliance）**：
   - **总预算（`totalBudget`）** = 当月所有有效设定预算（含归档当月仍有效的分类）的 `budgetMinor` 之和。
   - **主执行口径（消除「100% 达标却超支」冲突）**：主进度条、执行率及 `projectedRemainingMinor`（预计剩余）**仅汇总当月已设预算分类**的 `Budget`、`Actual` 与 `Pending`，使其与达标率 `X / Y` 完全同分母自洽。
   - **全盘实际总支出旁注**：单独汇总当月当前币种下**全部支出分类**（含未设预算分类）的 `Actual` / `Pending`，在总览卡片底部明确一行展示「本月全部实耗 X（其中未设预算 Y）」，既保留 Excel Totals 全盘防漏视角，又不污染已设预算分类的执行率。
   - **达标判定**：`Actual <= Budget` 即为达标（`In Budget`）；若 `Actual <= Budget` 但 `Actual + Pending > Budget`，叠加预警标签 `At Risk（含待入账将超支）`。
   - **达标率**：`达标分类数 / 当月已设预算分类总数`；分母为 0 时显示 `—`（不展示 0% 或 100%）。

### 2.4 自适应模式、归因与趋势

1. **三态自适应视图**（对比设备当前自然月 `nowYm`）：
   - `M > nowYm`：**规划模式（Plan）** — 聚焦总预算 vs 固定待入账基线，展示「剩余可自由支配额度」。
   - `M == nowYm`：**跟踪模式（Track）** — 聚焦实时 `Actual + Pending` 双段进度与预计剩余，右上角提供「复盘预览」轻量开关。
   - `M < nowYm`：**复盘模式（Review）** — 严格以 `Actual` 计算达标与归因（忽略未转正的 `Pending`，若有遗留未转正过期账单仅展示轻量提示），默认展开复盘归因卡与近 6 月趋势。
2. **复盘归因引擎**：
   - **超支 TOP 3**（`Actual > Budget`，按 `Actual - Budget` 降序）与 **结余 TOP 3**（`Actual <= Budget`，按 `Budget - Actual` 降序）分栏展示。
   - **未设预算大额提醒**：对未设预算但支出占当月全部分类总实际支出 `>= 5%` 的分类，最多取 TOP 3 在归因区提醒（支持一键跳转设预算）。
   - **异常波动标记（纯比例双门槛）**：某分类当月 `Actual` 相对其近 3 月均值环比增长 `>= +25%` 且占当月总支出 `>= 5%`（或超预算）时，标记「偏高 +X%」警示胶囊。
   - **TOP 3 贡献交易**：分类下钻内按单笔支出金额降序取前 3 笔，标明 `固定`（带 `sourceScheduledBillId`）或 `弹性`。
3. **排序规则**：
   - Track / Plan 模式：已设预算分类按风险等级优先（已超支 > 含待入账超支 > 其余按执行率降序）；
   - Review 模式：已设预算分类按超支金额/实际消耗降序；
   - 未设预算但有发生额或待入账：紧随已设预算分组之后，按 `Actual + Pending` 降序；
   - 其余活跃无发生分类：收拢于最底部默认折叠区「其余分类（点击设预算 · N）」。
4. **近 6 个月趋势**：
   - 滑动窗口 `[M-5 .. M]`；未设预算的月份在预算折线上留空断线（不填 0），有 `Review Note` 的月份在节点渲染小圆点指示。

---

## 3. 持久化、查询与备份架构

### 3.1 数据库表结构（`AppDatabase` `schemaVersion: 15 -> 16`）

1. **CRUD 豁免表 `BudgetRules`**（不入 `ledger_events`，`LedgerRebuildService` 永不清空）：
   - `currencyCode` (`TEXT`)
   - `categoryId` (`TEXT`)
   - `effectiveYm` (`INTEGER`, `year * 100 + month`)
   - `amountMinor` (`INTEGER`, nullable — `NULL` 表示该月起显式取消预算)
   - `updatedAt` (`DATETIME`)
   - 主键：`{currencyCode, categoryId, effectiveYm}`
2. **CRUD 豁免表 `BudgetReviewNotes`**：
   - `currencyCode` (`TEXT`)
   - `ym` (`INTEGER`)
   - `categoryKey` (`TEXT`, 默认 `''` 表示月度总复盘备忘，规避 SQLite 复合主键/唯一约束对 `NULL` 不去重)
   - `note` (`TEXT`, 非空且 trim 后长度 `1..500`，清空即硬删行)
   - `updatedAt` (`DATETIME`)
   - 主键：`{currencyCode, ym, categoryKey}`
3. **既有派生投影表增强 `CategoriesView`**：
   - 新增可空列 `archivedAt` (`DATETIME`, nullable)。
   - `AppDatabase.onUpgrade` 执行 `addColumn(categoriesView, categoriesView.archivedAt)`（严格遵循 `AGENTS.md`，禁止 `deleteTable/createTable`）。
   - 提升 `ledgerProjectionVersion`（`7 -> 8`）：老用户升级首次启动由 `LedgerRebuildService` 从事件存储自动重放，`LedgerProjectorImpl._applyCategoryArchived` 从 `EventEnvelope.recordedAt` 写入 `archivedAt`（读取 `archiveYm` 时必须调用 `.toLocal()` 与交易本地自然月对齐），实现自愈。

### 3.2 事务写入与冗余节点裁剪

- 所有写操作在 `db.transaction(...)` 中执行：
  1. 若目标分类存在且未归档（`category.archived == false && category.systemCode == null`），否则拒写 `LedgerErrorCode.categoryArchived` / `categoryNotFound`；若分类非 `expense` 拒写 `LedgerErrorCode.categoryTypeMismatch`；若预算金额 `<= 0` 拒写 `LedgerErrorCode.invalidAmount`。
  2. `thisMonthOnly`：先查询 `M+1` 生效值（不含 `M` 即将写入的新值，即当前 `M+1` 已有的显式行或继承自 `<= M` 的旧值）；若 `M+1` 无显式行则先插入 `(currencyCode, categoryId, M+1, priorState)`，再 upsert `M`。
  3. `thisAndFollowing`：删除所有 `effectiveYm > M` 的行，再 upsert `M`。
  4. **冗余断点升序裁剪不变量**：写入后必须**按 `effectiveYm` 升序依次检查 `M` 及其紧邻后继断点 `M_next`**（因为若 `M` 因与前驱状态相同而被删除，紧邻的 `M_next` 会立刻暴露给前驱并同样变成冗余；若全时间线最前方出现无前驱的 `null` 哨兵行也一并删除），逐一清理冗余断点。
- `Review Note` 校验：长度 `> 500` 拒写（新增 `LedgerErrorCode.budgetNoteTooLong`）；分类备忘若目标分类已归档拒写 `LedgerErrorCode.categoryArchived`（保留已有旧备忘只读）；空白字符串则执行删除。

### 3.3 `BudgetDao` 三流分离

为避免编辑单条备注或打开记账页时整页大查询抖动，拆分 3 个响应式读取接口：
1. **`watchMonthBudgetSummary`**：联合查询截至目标月 `M` 的规则、近 6 月 `[M-5..M]` 支出汇总（严格使用本地 `DateTime(y, m, 1)` 至 `DateTime(y, m+1, 1)` 半开区间，对齐 `ReportsDao` 规避 SQLite UTC 偏移，并显式过滤 `systemCode == null` 与 `accountsView.includeInTotals == true & deleted == false`）、目标月归档状态与 `Review Note` 状态。
2. **`watchMonthPendingExpenses`**：流式监听目标月 `Pending` 支出账单明细及按分类合计（含 `amountOverrideMinor` 与 `dateOverride` 解析）。
3. **`watchCategoryBudgetHint`**：专供 `TransactionFormScreen` 的单分类超轻量流，按 `formState.currencyCode ?? ledgerCurrency`、`targetYm = ym(form.date)` 与 `selectedCategoryId` 返回该月该分类 `budgetMinor?`、`actualMinor`、`pendingMinor`（含归档截断判定），具体预览扣减规则见 §5.6。

### 3.4 备份与恢复

- `.flbackup` 沿用 `VACUUM INTO` 快照打包 `db.sqlite`，无需改造备份容器格式。
- `BackupService` 版本闸门保持单向向后兼容（仅拒绝更新的 `schemaVersion > current`），旧 v15 `.flbackup` 恢复后经 `onUpgrade` + `LedgerRebuildService` 自动平滑迁移至 v16（无预算数据为空，历史交易自动重算且 `archivedAt` 自动回填）。

---

## 4. 错误码与本地化契约

### 4.1 `LedgerErrorCode` 扩展（`lib/core/domain/result/result.dart`）

复用现有 `invalidAmount`、`categoryNotFound`、`categoryArchived`、`categoryTypeMismatch`，新增封闭成员：
- `budgetNoteTooLong`（复盘备忘超过 500 字上限）

### 4.2 四语言 ARB 同步（`app_en.arb`、`app_zh.arb`、`app_zh_Hans.arb`、`app_zh_Hant.arb`）

每次新增错误码或 UI 词条必须同步四份 ARB 并运行 `flutter gen-l10n`：
- 错误码键：`errorBudgetNoteTooLong`；
- 核心词条域：模式名称（规划/跟踪/复盘预览/复盘）、总预算/实耗/待入账/预计剩余/达标率、固定支出/弹性支出/固定基线、上月实际/近 3 月均值/已设固定、作用域选项（仅本月/本月及以后）、空态与冷启动引导、4 态记账预算提示条、Review Note 占位与字数限制提示。

---

## 5. UI 与交互规范（对齐方案 A 原型）

完整交互与视觉参考 [prototype-budget-ui.html](prototype-budget-ui.html)，严格遵守 `AppTheme`、`AppSpacing`、`AppSemanticColors`、`AppMetrics`（`cardRadius = 20`, `sheetRadius = 28`, `controlRadius = 14`）、`tabularFigures` 与 `LucideIcons.*`（禁止 emoji）：

1. **顶部导航与空态**：
   - AppBar 居中复用 `< YYYY年MM月 ▾ >`（`FeatherMonthPicker`）；当月右侧提供「复盘预览」切换按钮与 `+` 补设入口。
   - **空态**：当前币种下尚无任何已设预算分类时，顶部总览卡全量置零并引导「点下方任意分类开始设置预算」，「已设预算」分组隐藏，其余活跃分类按「有发生额 → 底部折叠其余分类」自然呈现；若当前币种下无活跃账户，提示前往管理账户创建账户。
2. **总览卡 + 归因卡 + 6 月趋势**：
   - 单页叙事流（无边框 `AppCard`）：`BudgetOverviewCard` 顶部主指标与双段进度条（实色 `Actual` + 斜纹 `Pending`）严格仅汇总已设预算分类（与达标率同分母）；卡片底部单行旁注「本月全部实耗 X（含未设预算 Y）」，并在存在高频/远期排期或历史遗留待办时附轻提示；
   - 复盘归因卡（历史月默认展开，当月通过「复盘预览」展开）：超支 TOP 3 vs 结余 TOP 3 双栏对比、未设预算大额提示、月度 Review Note 入口；
   - 近 6 月柱线趋势图（`fl_chart`）：预算虚线留空无预算月份，X 轴下方绘制 Review Note 圆点。
3. **三段分组分类列表**：
   - ① 已设预算（含历史月已归档但当月仍有效分类）→ ② 未设预算但有发生额/待入账 → ③ 底部默认折叠「其余分类（点击设预算 · N）」。
4. **高屏占比分类下钻 Modal BottomSheet（~88%）**：
   - 头部显示分类图标、名称、归档/风险标签与「调预算」按钮；
   - 依次展示：近 6 个月预算线 vs 实际柱图（含近 3 月均值虚线）→ 固定 vs 弹性 vs 待入账构成条 → TOP 3 贡献流水（带 `固定/弹性` 标签；**已入账交易可点击直接 push `/ledger/edit` 纠偏**，`Pending` 行可只读展示或跳转 `/ledger/edit-bill`）→ 分类 Review Note 编辑区（已归档分类只读展示）。
5. **预算编辑 Modal BottomSheet**：
   - 顶部一键填入参考芯片（`上月实际`、`近 3 月均值`、`固定底线`），`LedgerAmountInput` 金额输入、作用域切换（仅当无未来断点且首次设定时隐藏，否则显式提供 `仅本月 / 本月及以后`）、清除预算按钮。
   - **`amountMinor == null`（空值或输入 `0`）时禁用「保存」按钮**，并在输入 `0` 时下方提示“预算需大于 0；如需取消请点击「取消预算」”。
6. **`TransactionFormScreen` 记账即时预算提示条**：
   - 仅 `type == expense` 且选中分类时内嵌于分类/金额区下方（查询币种取表单锁定的 `formState.currencyCode`）；绝不阻塞保存。
   - **完整状态矩阵**：
     - 所选账户 `includeInTotals == false` → 展示提示「该账户不计入预算统计」，不做余量加减预览；
     - `original != null`（编辑既有交易）→ 仅当 `original.type == expense && original.category?.id == selectedCategoryId && ym(original.date) == ym(form.date) && original.account.includeInTotals` 时，才从基线 `Actual` 中先扣减 `original.amount`；改月、改分类或原账户不计入合计均不扣减；
     - `mode == TransactionFormMode.planned` → 在当前/未来月按增加 `Pending` 计算「预计剩余」；若日期落在历史月（`ym(form.date) < nowYm`），提示「历史月计划账单不计入已完结复盘」；
     - `defaultMode` / `repeating` → 按增加 `Actual` 预览（余量充足 / 含待入账预警 / 已超支 / 未设预算 4 态）。

---

## 6. 架构分层（`lib/features/budget/`）

严格对齐 `lib/features/ledger/`：
```
lib/features/budget/
├── data/
│   └── repositories/budget_repository_impl.dart
├── domain/
│   ├── entities/          # BudgetRule, BudgetReviewNote, CategoryBudgetSummary, MonthBudgetSummary, BudgetAttribution, CategoryBudgetHint
│   ├── value_objects/     # YearMonth, BudgetEditScope, BudgetMode, BudgetVariance, BudgetTrendPoint
│   ├── repositories/      # BudgetRepository 接口
│   ├── commands/          # SetCategoryBudgetCommand, ClearCategoryBudgetCommand, SaveReviewNoteCommand
│   ├── queries/           # WatchMonthBudgetQuery, WatchCategoryDrilldownQuery, WatchTransactionBudgetHintQuery
│   └── services/          # BudgetService (Result<T> + guard)
└── presentation/
    ├── models/            # BudgetOverviewUiModel, BudgetCategoryRowUiModel, BudgetDrilldownUiModel, BudgetHintUiModel
    ├── mappers/           # BudgetUiMapper（所有 formatMinor / abs / 百分比格式转换集中在此）
    ├── view_model/        # BudgetViewModel (keepAlive / family per YearMonth), BudgetEditViewModel
    └── widgets/ & screens/# BudgetScreen, BudgetOverviewCard, BudgetAttributionCard, BudgetTrendChart, BudgetCategorySection, BudgetDrilldownSheet, BudgetEditSheet, TransactionBudgetHintBanner
```

---

## 7. 验收门槛

1. `flutter analyze` 零新增 warning/error；
2. 跨月阶跃继承（`thisMonthOnly` 锚定 `M+1`、`thisAndFollowing` 清未来断点、冗余裁剪、首次直达未来生效）、`CategoriesView.archivedAt` 截断与 `LedgerRebuildService` 自愈全部有单元测试钉住；
3. `Actual`、`Pending`、固定/弹性拆分、冷启动 3 月均值、分母为 0 达标率（`—`）、异常波动双门槛、纯文本 500 字 Review Note 校验均有单元测试钉住；
4. `BudgetScreen` 三态视图切换、底部折叠未设分类、分类下钻 Sheet、`TransactionFormScreen` 4 态提示条与 `.flbackup` v15→v16 升级均有组件/集成测试通过。
