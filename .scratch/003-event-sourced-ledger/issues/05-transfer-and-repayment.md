# 05 · 转账与信用卡还款语义

Type: grilling
Status: resolved 2026-09-06（由 spec 采纳）

## Answer

推荐立场经用户确认全量提升为正式决策，固化于 [spec.md](../spec.md) §领域模型·硬性约束：转账=kind=transfer 双腿净额零；统计排除唯一口径为 Transaction.kind==transfer；还款=储蓄→信用卡转账（不设还款专用事件）；信用卡余额负数表示欠款；同账户转账与跨币种转账均拒绝。
Blocked by: 02

## Question

转账与信用卡还款如何建模，确保不污染收支统计？

**背景**：现状 `PostTransferCommand` 构造双腿 `TransactionPosted` 直接 append，绕过投影器——转账根本不进读模型、不动余额（已知 bug）。月度统计在 `WatchMonthlySummaryQuery` / `transactions_view` 上按金额符号求和，若转账入表会被计入收支。

**需要裁决**：
1. 转账 = 双腿 `TransactionRecorded`（出账户 debit posting + 入账户 credit posting，净额零）：确认采用，并定读模型如何呈现（两行 per-leg 行带 transfer 标注？还是聚合显示为一行？）。
2. 收支统计排除机制：靠 Transaction.kind == transfer 排除，还是靠「posting 不携带收支分类」排除，还是两者（口径唯一化，谁权威）？
3. 信用卡还款：定调为「储蓄账户 → 信用卡账户的转账」，因此天然不计支出（风险 #4 的正解）。信用卡消费 = 普通支出（挂在信用卡账户上）。确认这个最小模型，不引入账单周期（out of scope）。
4. 信用卡账户的余额语义：信用卡账户余额为负（欠款）还是正（额度占用）？影响「净资产」类聚合（留给 票10 余额语义，但方向在此定）。
5. 同账户转账：允许吗（等价于无操作/校准）？

**涉及风险**：#3（转账污染统计）、#4（还款重复计支出）。

**代码指针**：`lib/features/ledger/domain/commands/post_transfer_command.dart`、`lib/features/ledger/domain/queries/watch_monthly_summary_query.dart`、`lib/features/ledger/presentation/screens/transaction_form_screen.dart`（现有类型切换）；wayfinder.md「特别需要避免」第 3/4 条。

**推荐立场**：转账 = kind=transfer 的双腿净额零 TransactionRecorded；统计排除以 Transaction.kind 为唯一权威口径（posting 不带收支分类的转账天然不计）；还款 = 储蓄→信用卡转账，不引入还款专用事件；信用卡余额记为负欠款；同账户转账禁止（校验在领域服务）。
