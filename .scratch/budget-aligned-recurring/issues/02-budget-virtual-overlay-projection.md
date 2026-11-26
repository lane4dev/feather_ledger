# 02: 预算双层 Overlay 虚拟投影与移除降级提示

Triage: ready-for-agent

**Blocked by:** 01 · 本地日历日展开内核、Schema 升级与自然月物理物化

关联规格见 [spec.md](../spec.md)。

**What to build:** 让预算模块（Track / Plan / Review）与记账表单实时预算提示基于 `RecurrenceExpander` 实现「活跃支出周期系列按需展开 + 物理实例行 Overlay 叠加」，确保当月高频支出与未来任意月份的固定支出（Committed spend）、待入账占用（Pending bill exposure）和预计剩余 100% 精确，并彻底移除高频与远期的“仅含已物化排期”降级提示。

## 验收标准

- [ ] 预算月度查询在 Track 与 Plan 模式（`targetYm >= nowYm`）下，读取当前币种、`includeInTotals == true`、未删除且未归档账户下的活跃支出周期系列，调用 `RecurrenceExpander` 展开落在 `targetYm` 且 `scheduledDate >= materializeFrom` 的全部期次，并与物理实例行按 `(seriesId, occurrenceKey)` 叠加合并：
  - 命中 `posted` 物理行时不重复计入待入账占用（仅保留在 `committedActualMinor`）；
  - 命中 `skipped` 物理行时从待入账占用中剔除；
  - 命中 `scheduled / failed` 物理行时，若 `dateOverride` 移至其他月份则从本月剔除，否则采用 `amountOverrideMinor ?? series.amountMinor` 与 `memoOverride ?? series.description`；
  - 未命中物理行（例如超出物理窗口的未来月份）时生成带 `(seriesId, occurrenceKey, isVirtual: true)` 标识的虚拟待入账项计入 `pendingMinor` 与分类贡献列表；
  - 并入物理表中因 `dateOverride` 从其他月份挪入 `targetYm` 的 `scheduled / failed` 支出行及遗留的非活跃/归档账户逾期一次性计划单，确保跨月改期总额守恒。
- [ ] Review 历史月（`targetYm < nowYm`）不执行虚拟展开，仅统计物理表中遗留的未处理 `scheduled / failed` 支出行以驱动 `hasLeftoverPendingInReview` 提示。
- [ ] 记账表单实时预算提示（`watchCategoryBudgetHint`）复用同一 Overlay 逻辑，使当月高频与未来月份的预算余量与超支风险提示与预算页完全一致。
- [ ] 移除预算摘要实体与界面中的 `hasHighFrequencyPending`、`isFarFutureMaterializedOnly` 降级标记及相关提示渲染（包括首页、复盘页与分类详情页）。
- [ ] 通过 `LedgerServiceHarness`（`RecurringService` + `BudgetService`）端到端验证当月 `DAILY/WEEKLY` 完整占用、远期 M+6 与跨年 Plan 基线、有限次分期到期归零、入账转移守恒、跳过剔除、跨月 `dateOverride` 守恒及 Review 不虚增；更新预算 UI 组件测试确认降级提示已消失。
- [ ] `flutter analyze` 无新增错误或警告，相关预算与表单测试全部通过。
