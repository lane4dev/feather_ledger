# 04 · 修改与删除语义

Type: grilling
Status: resolved 2026-09-06（由 spec 采纳）

## Answer

推荐立场经用户确认全量提升为正式决策，固化于 [spec.md](../spec.md) §事件模型：修改=TransactionReversed(reason: correction)+TransactionRecorded 配对（一命令两事件一事务）；UI 删除=单独 TransactionReversed(reason: userDeleted)；读模型 isReversed 软删除呈现；不设 TransactionCorrected；已冲正交易禁止再次修改/删除。
Blocked by: 02

## Question

交易的修改与删除在事件层如何表达？

**背景**：现状分裂——`CorrectTransactionCommand` 做 reverse+replace（但 reversal 走投影器、新 posting 绕过，两条腿投影行为不一致）；`LedgerService.deleteTransaction` → `ReverseTransactionCommand` 只 append 事件不更新投影（已知 bug：读模型不删行、余额不减）；`transactions_view.isReversed` 软删除已存在。wayfinder.md 问：`TransactionCorrected` 单事件 vs `TransactionReversed + TransactionRecorded` 事件对。

**需要裁决**：
1. 修改 = `TransactionCorrected`（单事件携带全量新值 + 指向原交易）还是 `TransactionReversed + TransactionRecorded`（配对事件）？权衡：审计可读性（corrected 一目了然）vs 事件语义纯度（reversed+recorded 重放逻辑零特判）、报表归因（修正后交易算原日期还是修正日期）、快照重建的级联范围（票12 直接受影响）。
2. UI「删除」映射什么：`TransactionReversed`（审计链完整，风险 #5 的正解）vs 真·删除事件（禁）？reverse 后读模型如何呈现（不显示但可追溯）。
3. 冲正后重放语义：`TransactionReversed` 必须能定位原交易的所有 posting 并抵消；corrected 路径的事件携带什么（全量 posting 还是 diff）。
4. 修正已冲正的交易：允许吗（推荐禁止——先 reverse 后 record 新的）。

**涉及风险**：#5（删除断审计链）、#6 的上游。

**代码指针**：`lib/features/ledger/domain/commands/correct_transaction_command.dart`、`reverse_transaction_command.dart`、`lib/features/ledger/domain/services/ledger_service.dart`（deleteTransaction）；wayfinder.md「目标账务模型」第 5/6 问。

**推荐立场**：修改 = `TransactionReversed(reason: correction) + TransactionRecorded` 配对事件（重放零特判、快照级联天然正确），UI 删除 = 单独 `TransactionReversed(reason: userDeleted)`；读模型以 isReversed 软删除呈现；修正已冲正交易禁止，只能对有效交易发起新修正。
