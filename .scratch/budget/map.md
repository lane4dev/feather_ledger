# 月度预算与复盘功能决策地图（Budget & Review）

Label: wayfinder:map

## Destination

产出并锁定一套**以复盘为核心、贯穿「规划（Plan with evidence）→ 跟踪（Track）→ 复盘（Review）」闭环**的月度分类支出预算完整规格（[spec.md](spec.md)）、领域/持久化/交互决策、`CONTEXT.md` 术语更新及实施任务清单，为后续在 `lib/features/budget/`（含 `TransactionFormScreen` 轻量只读提示联动）的落地提供清晰蓝图；本探索地图阶段不直接修改生产代码。

## Notes

- **产品定位升级**：预算不仅是对照 `.scratch/.ref/Monthly budget.xlsx` 的单月限额表，而是应用的核心驾驶舱——既在日常消费时给出即时反馈，更侧重月末与跨月的偏差归因、固定 vs 弹性支出拆解、历史趋势识别与下月调参。
- **参考基线**：保留 `.scratch/.ref/Monthly budget.xlsx` 的核心数学语义（分类预算额度、实际支出汇总、`Diff = Budget - Actual`、总预算自底向上汇总）。
- **已锚定边界（Chart 阶段与定位升级评审锁定）**：
  - **仅支出预算（无收入计划与全局总上限锚点）**：只对支出分类设定预算额度，总预算 = 各分类预算之和。
  - **纯预算执行与复盘总览**：顶部不展示账户「期初/期末余额」或「储蓄变化率」，聚焦预算与实际/待入账对比及复盘指标。
  - **规划（Plan with evidence）**：设定/编辑预算时旁路展示「上月实际」「近 3 月均值」「本月已排期周期账单底线」。
  - **跟踪（Track）**：
    - `Actual` 严格与 `ReportsDao` 一致（仅统计当前币种、`includeInTotals == true` 未删除账户下已入账未冲销的 `expense`，排除 `transfer`、`openingBalance`、`balanceAdjustment`）；
    - 以双段进度 + 扣除待入账后的预计剩余纳入待入账周期账单；
    - **记账表单即时只读提示**：在 `TransactionFormScreen` 选择支出分类并输入金额时，展示本月该分类预算剩余与记账后预估剩余。
  - **复盘（Review）**：
    - 历史月展示复盘摘要（达标分类数、TOP 超支/结余归因、主要贡献流水、相对近 3 月均值波动）；
    - 结合 `sourceScheduledBillId` 与待入账记录，自动区分「固定周期/计划支出」与「弹性日常消费」；
    - 总览与分类下钻支持跨月（近 6 个月）预算 vs 实际趋势对比；
    - 支持轻量 **Review Note**（月度/分类偏离原因备忘），随 `.flbackup` 持久化。
  - **跨月、多币种与持久化分层**：预算延续生效且保留历史；严格按 `Current currency` 隔离；采用 **CRUD 豁免表**（不进 `ledger_events`），随 `db.sqlite` 纳入 `.flbackup`。
  - **分类展示与归档**：分组展示「已设预算」「未设预算但有发生额/待入账」「其余活跃分类（可折叠补设）」；已归档分类禁止新设预算，历史月份通过快照保留。
- **领域术语警示（`domain-modeling`）**：`CONTEXT.md` 中 `planned` 已被占用为 **Entry mode**（一次性计划账单 / 计划）。预算规格与 UI 文案**不得**沿用 Excel 的 `Planned` 命名预算额度，需统一采用无歧义术语（如 **Budget / 预算额度**、**Committed spend**、**Discretionary spend**、**Review note** 等）。
- **每次会话必读**：`wayfinder`、`grilling`、`domain-modeling` 技能；对照 `.specify/memory/constitution.md`、`AGENTS.md`、`CONTEXT.md`、`docs/adr/`（尤其是 ADR-0003、ADR-0004、ADR-0005）。

## Decisions so far

<!-- 索引：每关闭一张决策票据追加一行要点与链接；细节保留在各自票据中 -->

- [跨月预算规则与编辑语义](issues/01-temporal-budget-rule-and-editing.md): 采用按 `(currencyCode, categoryId)` 的分段生效时间线（`effectiveYearMonth <= M`，值域 `{>0, unset}`），支持「仅本月 / 本月及以后（覆盖未来断点）」双作用域与智能默认；全时间轴可编（历史月主引导调后续月）；分类归档以其操作所在自然月为界，次月起停止延续。
- [待入账周期账单、历史基准与固定/弹性计算口径](issues/02-pending-bills-and-calculation-semantics.md): `Pending` 纳 `scheduled`/`failed`（`includeInTotals == true`、按 `effectiveDate` 归原排期月、远期只读已物化表）；`Committed` = `sourceScheduledBillId != null + Pending`；近 3 月均值取 `[M-3, M-2, M-1]` 算术平均（冷启动自最早有账月起）；`Totals` 纳全部分类支出并旁注未设预算部分；达标判 `Actual <= Budget`（另标 At Risk）且仅以已设预算分类为分母，零分母显示 `—`。
- [月度复盘视角、偏差归因与 Review Note 机制](issues/03-review-attribution-and-notes.md): 按时间轴自适应「规划/跟踪(+轻切复盘)/复盘」；历史复盘严格计 `Actual` 并提示遗留待办；分栏超支/结余 Top 3 + 占比 `>=5%` 未设预算预警 + 带标签 Top 3 贡献流水；纯比例双门槛（`+25%` 且占比 `>=5%` 或超支）标异常波动；滑动近 6 月趋势无预算留断点；支持月度+分类双维度纯文本 `Review Note`。
- [预算持久化表结构、查询聚合与备份边界](issues/04-persistence-schema-and-backup.md): 新增 `BudgetRules`（复合主键 `(currencyCode, categoryId, effectiveYm)` + 可空 `amountMinor`）与 `BudgetReviewNotes`（`categoryKey = ''` 防 NULL 重复）两张 CRUD 豁免表，并在 `CategoriesView` 增 `archivedAt` 随投影重建自愈回填；写入单事务维护时间线与冗余裁剪；`BudgetDao` 三流分离隔离记账轻量提示；`AppDatabase` 升 v16 保持 `.flbackup` 向后兼容。
- [预算主屏、复盘视图与记账提示原型](issues/05-budget-screen-ui-and-drilldown.md): 确认方案 A 单页叙事流（对齐 `AppTheme` 无边框 `AppCard` + 语义色 + `tabular-nums` + 矢量图标）；点击分类弹 88% 高屏占比 BottomSheet 下钻（无额外全屏路由）；主列表三段分组且最底部默认折叠「其余分类（点击设预算）」；`TransactionFormScreen` 内嵌 4 态非阻塞即时提示条。原型资产：`prototype-budget-ui.html`。
- [领域术语对齐、SPEC 汇编与实施拆解](issues/06-glossary-and-spec-assembly.md): 在 `CONTEXT.md` 新增 7 个 `Budget & Review` 标准术语，新建 `docs/adr/0006-budget-stepped-timeline-and-crud-exemption.md`，并汇编完整规格 [spec.md](spec.md) 与 5 阶段实施清单 [tasks.md](tasks.md)（含空态冷启动、与 `/ledger/reports` 独立边界及测试验收门槛）。

## Not yet specified

（无 —— 全部决策已收敛至 [spec.md](spec.md) 与 [tasks.md](tasks.md)，可正式转入实施阶段。）

## Out of scope

- 在本方案地图阶段直接编写或修改生产 Dart 代码、Drift 表或运行迁移脚本。
- **收入预算表**，以及独立的「月度预期收入 / 总支出心理上限」全局参考线。
- 顶部独立的 **月度期初/期末账户余额** 与 **储蓄增减率** 对比卡片。
- **跨月预算结转**（Rollover / 未花完额度滚存到下月）。
- **本地推送超支预警通知**（如 80%/100% 提醒）。
- **账户级 / 标签级预算** 与 **跨币种汇率合并预算**。
- 在 `/ledger` 账本首页头部嵌入预算卡片或系统桌面小组件（日常记账联动仅限于 `TransactionFormScreen` 内的只读预算提示）。
