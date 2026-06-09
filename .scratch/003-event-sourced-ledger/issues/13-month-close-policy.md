# 13 · 月结策略

Type: grilling
Status: resolved 2026-09-06（由 spec 采纳）

## Answer

选定方案 (b)，固化于 [spec.md](../spec.md) §快照模型：快照保留 isClosed 字段恒 false 占位；不设 MonthClosed/MonthReopened 事件；修改历史不拦截；「多设备同步时代再升级为 (c)」记录为可能性而非承诺。
Blocked by: 12

## Question

个人记账 App 需要严格月结吗？`MonthClosed` / `MonthReopened` 事件与 `isClosed` 字段一阶段要不要？

**背景**：wayfinder.md 自问「个人记账 App 是否需要严格月结」。严格月结（会计实务）= 关账后禁止修改历史，改动须先重开。现有 UI 无任何月结概念，用户（个人）随时可能修正上月账目。

**需要裁决**：
1. 一阶段是否实现 isClosed / MonthClosed / MonthReopened：三选一——(a) 完全不做（字段都不留）；(b) 快照留 isClosed 字段恒 false，事件不留（结构占位、语义未启用）；(c) 完整实现（关账拦截写命令 + 重开事件）。
2. 若不实现：UI 修改历史交易的体验保持现状（无拦截）；快照的「该月已定稿」概念何时需要（多设备同步时代？——同步已 out of scope，这可能是「永远不需要」的信号）。
3. 若实现（b 或 c）：关账的粒度（按账户 vs 按月全局）；MonthClosed 事件对 rebuild 的影响（重放到 MonthClosed 时历史事件还能改吗——事件存储不可变，月结是「写命令的守卫」而非「事件的封锁」，这个语义要在票内说清）。
4. 与 票09 的接口：MonthClosed/MonthReopened 进不进事件目录由此票定论。

**代码指针**：wayfinder.md「每月余额快照目标」第 4/5/6 问；无现有月结代码。

**推荐立场**：(b)——快照留 isClosed 恒 false 占位（字段成本零、堵死避免），MonthClosed/MonthReopened 事件不设；修改历史不拦截（个人记账 + 数据可丢弃阶段，严格月结是团队会计的刚需，单人场景拦截只会烦人）；把「若未来做多设备同步则升级为 (c)」记为升级路径而非承诺。
