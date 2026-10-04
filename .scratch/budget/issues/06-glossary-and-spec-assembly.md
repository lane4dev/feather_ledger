# 领域术语对齐、SPEC 汇编与实施拆解

Type: grilling
Label: wayfinder:grilling
Status: resolved
Triage: ready-for-human
Blocked by: 01, 02, 03, 04, 05

## Question

在前面五张决策票据收敛后，如何更新 `CONTEXT.md` 的预算与复盘领域术语、判断是否沉淀 ADR，并汇编输出完整的 `.scratch/budget/spec.md` 与面向 `lib/features/budget/`（含 `TransactionFormScreen` 只读提示）的实施任务拆解？

## Context

依据 `AGENTS.md` 与 `domain-modeling` 技能：
- `CONTEXT.md` 必须只包含无实现细节的统一语言词汇，明确区分 `Entry mode: planned` 与预算术语（如 `Budget`、`Budget allocation`、`Budget variance`、`Committed spend`、`Discretionary spend`、`Review note` 等）。
- 仅当决策同时满足「难以逆转、无上下文会困惑、真实权衡取舍」三条件时才新建 `docs/adr/`。
- 实施拆解必须严格对齐 `lib/features/ledger/` 参考切片（`data/` + `domain/` + `presentation/`，MVVM + Riverpod `@riverpod` + `Result<T>` / `Failure` + `LedgerErrorCode` + 四语言 ARB + `unit`/`ui` 测试），确保不引入跨特征脏耦合（`TransactionFormScreen` 通过只读 provider 或共享查询接口消费预算剩余，不直接依赖 `Budget` 写命令）。

本票最终交付物（均在 `.scratch/budget/` 与领域文档内，不改生产代码）：
1. 更新 `CONTEXT.md` 新增/对齐预算与复盘词条（经用户确认）；
2. 判定并按需新增预算相关 ADR（若不满足三条件则跳过）；
3. 汇编 `.scratch/budget/spec.md`；
4. 产出 `.scratch/budget/tasks.md` 供后续独立实施会话直接执行。

## Answer

已完成全部收官产出与对齐：

1. **统一语言（[CONTEXT.md](../../CONTEXT.md)）**：在文末新增 `### Budget & Review` 段落，定义 7 个标准领域词条：`Category budget`、`Budget timeline`、`Committed spend`、`Discretionary spend`、`Pending bill exposure`、`Budget variance`、`Review note`，显式禁止与 `Entry mode: planned` 冲突的旧称。
2. **架构决策记录（[ADR-0006](../../docs/adr/0006-budget-stepped-timeline-and-crud-exemption.md)）**：沉淀 `0006-budget-stepped-timeline-and-crud-exemption.md`，记录阶跃时间线（`effectiveYm` + 可空取消哨兵 + `CategoriesView.archivedAt` 读时截断）与 CRUD 豁免表（隔离 `ledger_events` 与 `LedgerRebuildService`）的权衡边界。
3. **最终规格与任务清单**：汇编生成 [.scratch/budget/spec.md](../spec.md) 与分 5 个增量验证阶段拆解的 [.scratch/budget/tasks.md](../tasks.md)，并收拢所有原本处于「未明区域」的空状态、`/budget` vs `/ledger/reports` 边界与验收门槛。
