# 05: 远过去起点保存确认与历史回填护栏

Triage: ready-for-agent

**Blocked by:** 04 · 规则编辑完整性、事务原子性与账户归档修正

关联规格见 [spec.md](../spec.md)。

**What to build:** 当用户新建周期系列或通过 `updateRule` 修改排期起点且起始日期早于两个月前时，保存前弹出简洁的两选项确认对话框（默认「仅从今天起生成」，或由用户自定义补齐最近 N 天为手动待入账），杜绝录老合约/老分期或误选年份导致的账单轰炸与余额双重扣款；并对两个月内早于今天的近过去期次加设自动入账保护。

## 验收标准

- [ ] 新建 `repeating` 系列或 `updateRule` 变更基础排期时，若目标 `startDate` 严格早于当前本地日期减去 2 个自然月，保存前弹出简洁确认对话框，仅提供两个选项（绝不提供一键自动扣过去 1–2 年）：
  1. **「仅从今天起生成（推荐）」**：保留所选 `startDate` 作为排期与 `countLimit` 锚点，将 `materializeFrom` 设为今日零点（`startOfDay(now)`），不物化今天之前的历史期次；
  2. **「补齐最近 N 天待入账（手动核对）」**：默认 `N = 30`，允许用户编辑为 `1..365` 之间的正整数（且受单系列 100 条硬上限保护），确认后将 `materializeFrom` 设为 `max(startDate, startOfDay(now - N days))`，并将所有严格早于 `startOfDay(now)` 的补齐历史期次统一标为 `manualOnly = true`；
  - 取消弹窗则中止保存，不写任何数据。
- [ ] 当新建或改排期的 `startDate` 位于过去 2 个月以内且早于今天时，不弹远过去确认框，`materializeFrom = startDate`，但所有严格早于 `startOfDay(now)` 的历史期次均标为 `manualOnly = true` 不静默自动入账；当日已到期（`startOfDay(now) <= effectiveDate <= now`）且开启 `autoPost` 的期次仍正常在保存时自动入账并携带 `sourceScheduledBillId`。
- [ ] 确认对话框文案、自定义天数输入校验提示及选项说明完整覆盖 `en`、`zh`、`zh_Hans`、`zh_Hant` 四份 ARB 文件（`zh` 镜像简体），并运行 `flutter gen-l10n`。
- [ ] 通过 `LedgerServiceHarness` 端到端验证：2 年前起算的 36 期月度分期选「仅从今天起生成」后，历史 24 期不物化、未来 12 期在 `BudgetService` Plan 中准确展示且第 13 期归零；选「补齐最近 45 天」仅补齐近 45 天内期次且全标 `manualOnly = true`（即使 `autoPost = true` 也不静默扣款）；补充交易表单与周期账单编辑表单组件测试验证弹窗出现条件、自定义天数输入与取消中止。
- [ ] `flutter analyze` 无新增错误或警告，全部相关单测与组件测试通过。
