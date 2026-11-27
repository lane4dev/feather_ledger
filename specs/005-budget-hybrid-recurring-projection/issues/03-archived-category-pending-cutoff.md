# 03: 归档分类与系统分类的预算待入账统一截断

**What to build:** 在预算待入账读取入口（`BudgetDao`）中为物理待入账与虚拟补齐统一关联分类元数据，过滤掉系统分类（`systemCode != null`），并对已归档分类实施与预算时间轴一致的本地月截断：归档当月（`M <= archiveYm`）保留其待入账敞口，从归档次月起（`M > archiveYm`）将该分类的**物理待入账与虚拟待入账一并从预算统计与单分类提示条中排除**；同时监听分类表变更，确保归档或恢复分类时预算待入账流实时刷新。

**Blocked by:** None (can start immediately)

**Status:** resolved

## 修改范围与涉及页面
- **修改范围**：预算待入账数据加载与流监听（`BudgetDao` 物理查询、虚拟补齐查询及 `watchMonthPendingExpenses` 变更监听表集合）以及对应预算集成测试。
- **涉及页面**：预算首页（`/budget` 总览与分类列表）、预算分类详情页（贡献列表）与记账表单实时预算提示条。

## 必须遵循的设计规范
- 遵循 **ADR-0006**（分类归档月份按事件时间的本地月 `archiveYm` 判定）、**ADR-0008**（`M > archiveYm` 时物理与虚拟待入账一并排除）与 **CONTEXT.md**（*Pending bill exposure* 与 *Archive* 语义）。
- 仅收口预算读侧口径，不改变 `CategoryArchived` 领域事件语义，也不修改数据库表结构。

## 必须保留的现有功能或交互行为
- 归档分类不会自动停用其关联的周期规则，也不会删除已物化的物理待入账行。
- 分类归档当月（`M <= archiveYm`）的有效预算、物理待入账与虚拟待入账全部保留。
- 归档分类下已实际入账的历史/当月交易（`Actual`）继续如实计入全月总支出与历史回顾，不受影响。
- 账户过滤口径保持不变（物理与虚拟均要求 `includeInTotals == true && deleted == false`，虚拟补齐额外要求 `archived == false`）。

## Acceptance criteria
- [ ] 当支出分类在 `M` 月归档且名下仍有未停用的活跃周期规则时：查 `M` 月预算，其物理与虚拟待入账正常计入；查 `M + 1` 月及更远月份时，其**物理待入账与虚拟待入账均从总览 `allExpensePendingMinor`、分类行、贡献列表与单分类记账提示条中排除**。
- [ ] 系统分类（`systemCode != null`）不进入预算物理或虚拟待入账统计。
- [ ] 在监听 `watchMonthBudget` 期间归档或恢复该分类时，预算待入账流实时发出更新后的正确结果，无需重新订阅。

## Answer

Resolved by `ad0be8b fix(budget): cut archived and system categories out of pending exposure`. `_countsTowardBudgetPending` filters both physical and virtual pending rows by category metadata (system categories excluded; archived category keeps month M and drops from M+1). `watchMonthPendingExpenses` now watches `categoriesView`. DAO tests cover the boundary, system categories, and archive/restore stream re-emission.
