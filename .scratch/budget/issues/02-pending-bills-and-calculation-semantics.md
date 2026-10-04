# 待入账周期账单、历史基准与固定/弹性计算口径

Type: grilling
Label: wayfinder:grilling
Status: resolved
Triage: ready-for-human

## Question

待入账周期账单（`scheduled_transactions_view`）、固定周期 vs 弹性支出拆解、历史参考基准（上月/近 3 月均值）以及跨月达标/超支公式应如何精确定义？

## Context

Chart 阶段与定位升级已锚定：
- `Actual` 严格与 `ReportsDao` 一致：仅统计 `currentCurrency`、`includeInTotals == true` 且未删除账户下，已入账、未冲销的 `TransactionKind.expense`（不含 `transfer`、`openingBalance`、`balanceAdjustment`）。
- 预算 UI 采用**双段进度 + 预计剩余**：`Actual` 保持已入账口径不变，同时展示待入账占用（`Pending`）以及 `Budget - Actual`（当前剩余）与 `Budget - Actual - Pending`（预计剩余）。
- 复盘需要：
  - 编辑预算时提供「上月实际」「近 3 月均值」「本月已排期固定周期底线」；
  - 复盘摘要与下钻列表需要自动区分「固定周期/计划支出（依托 `sourceScheduledBillId` 与待入账）」与「弹性日常消费」。
- 已知现有周期模型现状（见 `.scratch/recurring-simplification/spec.md` 与 `lib/core/data/database/tables.dart`）：
  - `ScheduledTransactionsView.status` 有 `'scheduled' | 'posted' | 'skipped' | 'failed'`；
  - 实例有效日期为 `dateOverride ?? scheduledDate`，有效金额为 `amountOverrideMinor ?? series.amountMinor`；
  - `ProjectRecurringEventsCommand` 对未来只物化有限窗口（90 天内最多 3 期 / 保底 1 期）。

本票需要锁定以下计算口径：
1. **纳入 `Pending` 的实例状态与跨月逾期归属**：
   - `failed`（自动入账失败等待用户重试的待办）是否计入 `Pending`？
   - 按 `effectiveDate = dateOverride ?? scheduledDate` 归属月份 `[monthStart, nextMonthStart)`；上月逾期至今仍为 `scheduled` / `failed` 的账单，保留在「原排期月」还是并入「当前自然月」？
2. **未来月份超出物化窗口的规则**：
   - 用户切换查看 4 个月后的未来月份时，远期周期尚未全量物化进 `scheduled_transactions_view`。预算页对远期月份只读取已物化实例（并提示未完全物化），还是在查询侧临时推演？
3. **固定周期/计划 vs 弹性消费（Committed vs Discretionary）拆分口径**：
   - 已入账交易中 `sourceScheduledBillId != null`（即由 `planned` 或 `repeating` 账单转正的交易）计为「固定/计划支出」，其余普通记账计为「弹性日常支出」；
   - 如果用户创建了一条带 `sourceScheduledBillId` 的交易后又对其做了**更正（`TransactionReversed(correction)` + 新 `TransactionRecorded`）**，或者原周期系列已被停止/删除（`sourceScheduledBillId` 仍在交易行上），该笔交易是否仍归入固定/计划支出？（注：查 `transactions_view.sourceScheduledBillId` 即可验证保留行为）。
   - 编辑预算时展示的「本月已排期周期底线」= 当月该分类已入账 `sourceScheduledBillId != null` + 当月待入账 `Pending` 之和，还是仅指 `Pending`？
4. **「近 3 月均值」与「达标率 / 总预算汇总」公式**：
   - 以所查看月份 `M` 为基准，「近 3 月均值」是否固定取 `[M-3, M-2, M-1]` 三个已完整结束的相邻自然月实际支出的算术平均（即使其中某月支出为 0 也除以 3，还是只对有数据的月份平均）？
   - 总览栏 `Totals.Actual` / `Totals.Pending` 是否包含「未设预算但有消费的分类」（与 Excel `Totals` 一致）？
   - 分母为 `0`（总预算为 0 或未设预算分类有消费）时，百分比、进度条与「达标分类数」怎么算（未设预算有消费的分类算不算“未达标”或单独统计）？

## Answer

经两轮决策，本票锁定以下待入账周期账单、历史基准与固定/弹性计算口径：

1. **`Pending`（待入账占额）口径与月份归属**：
   - **状态范围**：纳入 `ScheduledTransactionsView.status IN ('scheduled', 'failed')`（`posted` 已计入 `Actual`，`skipped` 已取消）。
   - **账户与币种过滤**：同 `Actual` 口径一致，通过 `RecurringSeries.accountId` 关联 `AccountsView`，仅统计当前全局展示币种（`Current currency`）且 `includeInTotals == true` 账户下的支出类排期实例。
   - **月份归属**：严格按 `effectiveDate = dateOverride ?? scheduledDate` 落在目标月 `[monthStart, nextMonthStart)` 内统计；跨月逾期未入账的 `scheduled` / `failed` 实例留在原排期月（供历史月复盘可见），不自动顺延叠加到当前月 `Pending`。
   - **远期物化窗口**：预算查询统一只读已物化表 `scheduled_transactions_view`（与 `/ledger` 保持单一数据源，不在预算查询侧另行推演 RRULE）；当查看超出 `ProjectRecurringEventsCommand` 已物化覆盖范围的远期月份时，展示轻提示说明仅统计已排期部分。

2. **固定周期/计划（Committed）vs 弹性消费（Discretionary）拆分**：
   - **已入账拆解**：`transactions_view.sourceScheduledBillId != null`（包含经 `CorrectTransactionCommand` 更正后继承该引用、或原 `RecurringSeries` 已被删除/停用的交易）归入 **Committed Actual**；`sourceScheduledBillId == null` 归入 **Discretionary Actual**。
   - **本月已排期周期底线（Committed Baseline）**：定义为当月该分类的 **`Committed Actual + Pending`** 之和（确保月初待扣与月末已扣时的刚性底线口径稳定不归零）。

3. **「近 3 月均值（3-Month Avg）」历史基准口径**：
   - 以所查看月份 `M` 为基准，取此前连续 3 个自然月 `[M-3, M-2, M-1]` 的 `Actual` 算术平均（总和 ÷ 3，含期间 0 元消费月份）。
   - **冷启动兜底**：若当前币种 & `includeInTotals == true` 账户下最早一笔已入账交易所在月份晚于 `M-3`，则仅从「最早有账月份」起算至 `M-1` 求算术平均并标注实际参与月数；若 `M-1` 及之前全无历史记录，则显示 `—`。

4. **总览汇总（Totals）、达标判定与除零兜底**：
   - **Totals 汇总范围**：顶部 `Totals.Actual` 与 `Totals.Pending` 纳入当前币种下**全部支出分类**（含未设预算但有发生额的分类，与 Excel `Totals` 口径一致），并在旁注中拆明「其中未设预算支出」金额，避免口径误解或遗漏大额无预算消费。
   - **分类执行三态（针对已设预算分类）**：
     - `Actual <= Budget` 且 `Actual + Pending <= Budget` → **达标（In Budget）**；
     - `Actual <= Budget` 且 `Actual + Pending > Budget` → **达标但有预计超支风险（At Risk）**；
     - `Actual > Budget` → **已超支（Over Budget）**。
     - 达标判定公式为 `Actual <= Budget`（前两态均属实际达标）。
   - **达标率分母与除零兜底**：达标分类数（`X / Y`）**仅以「已设预算分类」为分母**；「未设预算但有发生额/待入账」的分类不计入达标率分母，而是单独计数提醒。任意分母为 `0`（总预算为 0 或单类未设预算）的百分比/进度条一律显示 `—`。
