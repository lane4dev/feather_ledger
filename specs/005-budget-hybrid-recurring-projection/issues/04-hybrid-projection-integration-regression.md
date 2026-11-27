# 04: 混合投影全链路集成验收与回归检查

**What to build:** 在最高服务层接缝（`BudgetService` + `RecurringService` + 注入 `FixedClock` 的内存数据库）上补齐本次混合投影收口的组合边界集成验收测试——串联覆盖多年前历史起点高频规则快进、新建历史周期账单（`materializeFrom = today` 与近过去补齐）、`nowYm + 24` / `+25` 前瞻边界、归档分类 `M` / `M + 1` 物理与虚拟双排除、6 个月趋势图非目标月隔离以及远期虚拟账单按需落库——并完成全量测试与静态分析回归检查。

**Blocked by:** 01, 02, 03

**Status:** ready-for-agent

## 修改范围与涉及页面
- **修改范围**：预算与周期高层集成测试套件（基于现有 `LedgerServiceHarness` 接缝）；无新增功能代码、无架构搬迁重构（不抽离 `BudgetPendingProjector`）。
- **涉及页面**：验证预算首页、分类详情页与记账表单实时提示条三端数据源 100% 一致，无 UI 视觉变更。

## 必须遵循的设计规范
- 遵循 **ADR-0005 / 0006 / 0007 / 0008** 与 **CONTEXT.md** 统一术语。
- 遵循高层接缝测试原则：仅断言外部可观察的预算总览、分类贡献、提示条与落库实体，不耦合内部 SQL 或私有方法；使用 `FixedClock` 保证 100% 确定性。

## 必须保留的现有功能或交互行为
- 6 个月趋势图（`BudgetTrendPoint`）维持仅在 `m == targetYm` 填入 `pendingMinor`，其余 5 个月保持为 `0`。
- 单期改期跨月（`dateOverride`）、单期改额（`amountOverrideMinor`）、跳过不复活（`skipped`）、提前入账不重复（`posted`）与远期虚拟账单按需落库（Materialize-on-Write）等既有行为全部无回归。
- 历史周期账单继续维持现有 `DistantPastStartGuard`（2 个月阈值确认弹窗 + `materializeFrom` + `< today` 标 `manualOnly`），不做历史端虚拟补齐。

## Acceptance criteria
- [ ] 组合集成测试覆盖并全部通过：
  - 新建多年前起点 `DAILY` / `WEEKLY` 规则并选择「仅从今天起生成」（`materializeFrom = today`）时，当月 `Track` 不将早于 `today` 的期次虚拟补齐进来，`nowYm + 24` 完整计入且相位对齐 `startDate`，`nowYm + 25` 静默截断虚拟补齐；
  - 新建近过去周期账单（补齐 `manualOnly` 物理逾期行）时，当月 `Track` 准确计入且不与虚拟期重复，上月 `Review` 不计入 `pendingMinor`；
  - 归档分类在 `M` 月保留并在 `M + 1` 月同时排除物理与虚拟待入账，且总览、分类明细与记账提示条三端 `projectedRemaining` 完全一致；
  - 6 个月趋势图在 `Plan` 模式下非目标月份的 `pendingMinor` 恒为 `0`；
  - 远期虚拟账单（如 `nowYm + 6`）按需落库后进入编辑/跳过流程保持幂等且预算实时刷新。
- [ ] 全量 `ledger` 与 `budget` 单元测试（`flutter test`）全部通过。
- [ ] `dart analyze` 无新增 warning 或 error。
