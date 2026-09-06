# 10 · 一阶段投影集与余额语义

Type: grilling
Status: resolved 2026-09-06（由 spec 采纳）

## Answer

推荐立场经用户确认全量提升为正式决策，固化于 [spec.md](../spec.md) §投影模型：MVP 四视图=accounts_view、transactions_view、transaction_postings_view、categories_view；**当前余额=全部未冲正 posting 增量之和（含未来日期交易）**；余额唯一计算点在投影器，getRunningBalance 删除；分类归档+交易行写时快照（名/图标）；转账按 kind 单行呈现；账户仅 postedBalance 单一余额（availableBalance 砍）；UI 只读投影；projection_version 记录投影器版本。
Blocked by: 01, 02

## Question

第一阶段投影集定稿 + 「当前余额」的唯一定义。

**背景**：现状三处算余额——投影器增量加减、`TransactionsDao.getRunningBalance`（总余额减去未来日期交易的「回滚未来」算法，存在恰因「未来交易是否计入当前余额」从未定义）、`AccountService.updateAccount` 的 reconcile 差额补账。`getRunningBalance` 就是风险 #12 的实锤。

**需要裁决**：
1. 一阶段必须实现的投影（wayfinder.md MVP 集）：accounts_view、transactions_view、transaction_postings_view（新表——现在 postings 与 transactions 混在同一 per-leg 行表里）、categories_view。逐一确认形态与字段。
2. **当前余额定义（风险 #9 的正解）**：账户余额 = 截至今天的已入账交易净额？还是含未来日期的已入账交易？定调后 `getRunningBalance` 的「回滚未来」算法去留自明。UI 的「本月收支」是否同样口径。
3. 余额唯计算点（风险 #12）：余额只在投影器内计算，`accounts_view.posted_balance` 是唯一真源；删除 `getRunningBalance`，reporting 一律读快照或聚合查询。确认。
4. categories_view 与历史保真（风险 #8）：分类软删除（Archived 不删除）+ transactions_view 冗余存 category 名/图标（写时快照），还是读时 join categories_view？转账/还款如何呈现（kind 标注行 vs per-leg 两行）。
5. 多币种分组约束（风险 #10，与 票01 衔接）：余额聚合按 (accountId, currencyCode) 分组，一阶段单币种断言写在哪。
6. UI 只读投影（风险 #11）：确认所有 ViewModel/Widget 只 watch 投影表，写一律走命令。现状 ledger list 直接 watch Drift view provider（已符合），但 `InsertOrUpdateScheduledTransactionCommand` 直写投影表是反例——转正走新写入路径（map 既定约束）。
7. projection_version 字段设计（每张投影表记录投影器代码版本，rebuild 时校验）。

**代码指针**：`lib/core/data/database/daos/transaction_dao.dart`（getRunningBalance）、`lib/features/ledger/data/event_handlers/ledger_transaction_event_handler.dart`、`lib/features/settings/domain/services/account_service.dart`（reconcile 补账）、`lib/core/data/database/tables.dart`；wayfinder.md「Projection 目标」全节。

**推荐立场**：4 张 MVP 投影齐上；**当前余额 = 含未来日期的已入账净额**（个人记账「记了就算」最直观，月度快照/报表按日期切窗自然隔离未来交易），删 getRunningBalance；余额唯一在投影器；分类归档 + 写时冗余名称进 transactions_view（历史保真不依赖 join 存活）；转账按 kind 聚合显示一行、postings 明细在详情层展开；projection_version = 简单 int，票11 使用。
