# 02 · Posting 模型：Transaction + Postings 单一账务模型

Type: grilling
Status: resolved 2026-09-06（由 spec 采纳）

## Answer

推荐立场经用户确认全量提升为正式决策，固化于 [spec.md](../spec.md) §领域模型：Transaction+Postings 单一模型；posting 用 debit/credit 显式方向（个人记账语义：credit=余额增、debit=余额减）+ 正数 amountMinor；收入/支出=单腿+kind 标注（不引入虚位账户但不堵死）；转账=方向相反金额相等双腿；Transaction 保留显式 kind 枚举。

## Question

底层账务模型是否采用「一笔 Transaction 携带多个 Posting」的单一模型（接近复式记账），收入/支出/转账/信用卡消费/还款全部是它的 UI 表现？

**背景**：现状是「半多腿」——事件层 `TransactionPosted` 已是 `List<TransactionLeg>`（accountId + 有符号 amount 分 + role outflow/inflow），但投影器只读 `legs.first`（单腿假设）；读模型 `transactions_view` 是共享 `transactionId` 的 per-leg 行。UI 有收入/支出两种表单类型，转账走 `PostTransferCommand`（双腿、绕过投影器）。

**需要裁决**：
1. 方向表达：有符号 amount（正=入账、负=出账）vs 显式 debit/credit 方向字段 + 正数金额。两者对报表、不变量校验、可读性的影响。
2. Posting 字段定稿：accountId、amountMinor、currencyCode、direction/signed、categoryId（可选）、memo（可选）——以 wayfinder.md 清单为准还需增删什么（例如 posting 级 isReversed？不需要——冲正在 Transaction 级）。
3. 模型不变量：转账双腿净额为零；收入/支出是「一条腿指账户、一条腿指向虚位账户（income/expense counteraccount）」还是「单腿 + TransactionKind 标注」？这决定收支统计口径在哪算。
4. Transaction 级字段：transactionId、occurredAt（交易日）、description、kind（income/expense/transfer？）是否保留显式 kind，还是纯由 posting 形态推导？
5. UI 的五种形态（收入/支出/转账/信用卡消费/信用卡还款）各自映射到什么 posting 组合。

**涉及风险**：#2（三套底层模型）、#3 的基础。

**代码指针**：`lib/features/ledger/domain/events/transaction_event.dart`（TransactionLeg）、`lib/features/ledger/data/event_handlers/ledger_transaction_event_handler.dart`（legs.first 假设）、`lib/core/data/database/tables.dart`（TransactionsView per-leg 行）；wayfinder.md「目标账务模型」全节。

**推荐立场**：采用 Transaction + Postings 单一模型；posting 用 debit/credit 显式方向 + 正数 amountMinor（转账=一借一贷净额零，不变量在聚合内校验）；Transaction 保留显式 kind 枚举（UI 语义需要，报表排除 transfer 用它）；收入/支出为单腿 posting + kind 标注，不引入虚位账户（个人记账引入 counteraccount 收益不抵复杂度，但字段设计不得堵死未来引入）；信用卡消费=支出 posting，还款=双腿转账（票05 细化）。
