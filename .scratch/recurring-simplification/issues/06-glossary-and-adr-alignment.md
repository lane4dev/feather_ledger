# 领域术语收敛（CONTEXT.md）与架构决策记录（ADR）

Type: grilling
Label: wayfinder:grilling
Status: resolved
Triage: ready-for-human
Blocked by: 01, 02, 03, 04, 05

## Question

基于最终锁定的瘦身模型，`CONTEXT.md` 中的哪些周期/订阅领域术语需要退场、合并或重写，以及哪些不可逆且带有显著权衡的架构决策需要沉淀为 `docs/adr/`？

## Context

当前 `CONTEXT.md` 受早期复杂方案影响，同时承载了 *Recurring series*、*Automatic posting*、*Bill eligibility*、*Source bill*、*Manual-only bill*、*Entry mode* 等概念，且部分描述（如 `Bill eligibility`、`Manual-only bill` 永久锁）已准备在本方案中裁撤。

本票在前序所有技术与产品决策均关闭后执行：
1. 逐条核对 `CONTEXT.md` 受影响的术语定义，移除实现细节（如不再提及具体类 `AutomaticPostingPolicy`）并退场已不存在的概念（如 *Bill eligibility*、*Manual-only bill* 永久锁）。
2. 明确是否保留“订阅只是 UI 标签”的既有原则，或调整 *Entry mode* 词条以匹配最终确认的 3 种模式 + 自动入账开关。
3. 评审并确定是否新增 ADR（例如记录「为什么用稳定 UUID + `(series_id, occurrence_key)` 取代日期拼接 ID，并放弃全历史作用域拆分与多批次资格状态机」）。

## Comments

- 用户确认（Round 1）：`Q1: 确认; Q2: a;`（推进完成 `spec.md`、`CONTEXT.md` 与 `docs/adr/0005-...md` 收口）。

## Answer

1. **`CONTEXT.md` 术语收敛（7 项调整，不新增多余概念）**：
   - 删除 `Bill eligibility`（语义合并进 `Automatic posting` 与 `Manual-only bill`，移除对 `AutomaticPostingPolicy` 与旧水线的引用）。
   - 重写 `Manual-only bill`：不再是不可解除的永久锁，用户显式单期改期到未来日期时解除。
   - 重写 `Entry mode`：收敛为 `default`、`planned`、`repeating` 三种，说明 `autoPost` 为 `repeating` 上的属性。
   - 重写 `Automatic posting`：去除了旧资格状态机术语，表述为「当前币种 + 开启 `autoPost` + 非 `manual-only`」时的自动记账行为。
   - 微调 `Recurring series`：保留「订阅（subscription）仅作开启自动入账时的 UI 标签」，补充 `planned` 与停用不删历史已入账记录的边界。
   - 修正 `Archive`：与 `account_lifecycle_command.dart` 实际行为及 Ticket 02 对齐（归档将已到期未处理账单保留为一次性 `planned` 待办，删除原周期规则与未来待入账实例，恢复账户不再复活）。
   - 微调 `Source bill`：补充「规则被停止或删除」时关联仍保留。
2. **新增 `docs/adr/0005-scheduled-bill-identity-and-two-scope-editing.md`**：
   - 记录采用稳定 UUID 主键 + `UNIQUE(series_id, occurrence_key)`、两档编辑作用域（`thisOnly` 覆盖 vs `updateRule` 仅影响未入账未来期次）与放弃 Calendar 拆分模型的决策及取舍。
3. **交付收口**：产出 `.scratch/recurring-simplification/spec.md`（包含领域模型、规则明细、v14 → v15 平滑迁移与旧表清理、以及对 `.scratch/multi-currency/spec.md` 的取代矩阵），并完成 `map.md` 收口。
