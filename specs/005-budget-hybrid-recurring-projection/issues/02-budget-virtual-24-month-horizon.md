# 02: 预算虚拟补齐 24 个月前瞻上限护栏

**What to build:** 在预算月度查询（`WatchMonthBudgetQuery`）与记账表单实时预算提示查询（`WatchTransactionBudgetHintQuery`）中统一收敛虚拟补齐启用窗口为 `nowYm <= targetYm <= nowYm + 24`（仅在 Track 当月与未来 24 个自然月内的 Plan 模式启用虚拟补齐）；超出 `nowYm + 24` 时读侧静默跳过虚拟补齐，仅保留已存在的物理待入账，确保预算首页、分类详情页与记账表单提示条三端在边界月份 100% 同口径。

**Blocked by:** None (can start immediately)

**Status:** resolved

## 修改范围与涉及页面
- **修改范围**：预算月度查询（`WatchMonthBudgetQuery`）、记账表单预算提示查询（`WatchTransactionBudgetHintQuery`）及对应的查询/服务层测试。
- **涉及页面**：预算首页（`/budget`）、预算分类详情页与记账表单实时预算提示条的数据边界；**不修改**月份选择器交互范围、不新增 UI 免责提示文案。

## 必须遵循的设计规范
- 遵循 **ADR-0008** 与 **CONTEXT.md**（*Pending bill exposure*）：前瞻上限为当前月起未来 24 个自然月（含 `nowYm + 24`），超出后静默跳过虚拟补齐，不引入 UI 妥协文案。
- 严格通过注入的 `DomainClock` 计算 `nowYm` 与前瞻上限，禁止直接读取系统时钟。

## 必须保留的现有功能或交互行为
- 历史月（`Review` 模式，`targetYm < nowYm`）继续关闭虚拟补齐，严格以实际支出（Actual）评估预算达标。
- 当月（`Track`）与 `nowYm + 1 .. nowYm + 24` 的 `Plan` 模式完整展示物理与虚拟待入账，并保持点击远期虚拟账单触发按需落库（Materialize-on-Write）的交互不变。
- 预算月份选择器仍允许用户自由切换任意远期月份，预算时间轴（*Budget timeline*）规则读取不受前瞻上限影响。
- 在 `targetYm > nowYm + 24` 的月份中，若已存在物理物化的待入账行（例如远期低频规则的 `minKeep = 1` 保底行），仍正常计入预算待入账。

## Acceptance criteria
- [ ] 查询 `targetYm == nowYm + 24` 时，预算总览、分类详情贡献列表与记账表单实时提示条均完整包含活跃周期规则的虚拟待入账。
- [ ] 查询 `targetYm == nowYm + 25` 时，预算总览、分类详情贡献列表与记账表单实时提示条均静默跳过虚拟补齐（但保留已存在的物理待入账行），且三端 `projectedRemaining` 数值 100% 一致。
- [ ] 查询 `targetYm < nowYm`（`Review` 模式）继续跳过虚拟补齐，无任何回归。

## Answer

Resolved by `5360f12 feat(budget): cap virtual pending overlay at a 24-month horizon`. One shared predicate `budgetIncludesVirtualPending` now gates both `WatchMonthBudgetQuery` and `WatchTransactionBudgetHintQuery` to `nowYm <= M <= nowYm + 24`; queries read the clock once. 10 deterministic FixedClock tests cover now/-1/+1/+24/+25 and physical retention past the horizon.
