# 12 · 月度账户余额快照

Type: grilling
Status: resolved 2026-09-06（由 spec 采纳）

## Answer

推荐立场经用户确认全量提升为正式决策，固化于 [spec.md](../spec.md) §快照模型：unique(accountId, currencyCode, year, month)；投影器每次余额事件写入时增量维护受影响月；opening=上月 closing（首月锚 OpeningBalanceSet）；级联重建=自受影响月起至最新物化月全部重算；**空月物化为连续快照行**（票内二选一取物化，查找逻辑最简）；eventSequenceFrom/To 记录覆盖区间；MonthlySummary 退役。
Blocked by: 10

## Question

`monthly_account_balance_snapshots` 的设计与「改历史后受影响月份的级联重建」机制。

**背景**：wayfinder.md 给出建议字段全表（id、accountId、currencyCode、year、month、openingBalanceMinor、closingBalanceMinor、incomeMinor、expenseMinor、transferInMinor、transferOutMinor、netChangeMinor、transactionCount、eventSequenceFrom/To、projectionVersion、isClosed、createdAt/updatedAt/rebuiltAt）。快照是纯派生数据（既定原则），不是事实来源。

**需要裁决**：
1. 唯一约束：unique(accountId, currencyCode, year, month)——确认（多币种下同账户不同币种各自一行还是拒绝混币？与 票01 单币种断言衔接）。
2. opening/closing 计算：opening = 上月 closing（首月 = 事件流首笔前的余额，即 OpeningBalanceSet）；closing = opening + 本月净变动。快照由谁生成：事件写入时增量维护 vs 查询时惰性生成 vs rebuild 时批量——增量维护才能覆盖「用户翻看任意历史月」。
3. **级联重建（风险 #6 正解）**：修改/冲正历史交易（票04 的 reverse+record 配对）后，该月及之后所有月份的快照如何失效重算——全部重算（个人记账事件量小，粗暴但正确）vs 精确受影响区间（自交易日期起）。快照的 eventSequenceFrom/To 记录覆盖区间，重建时校验。
4. isClosed 一阶段是否实现 → 直接交给 票13（月结策略），本票只留字段。
5. 未来月份/无交易月份：是否物化空快照（连续月份完整性 vs 只记有交易的月）——影响「上月 closing = 本月 opening」的查找逻辑。
6. 快照与 MonthlySummary（现状 double 元实体）的关系：MonthlySummary 作为查询时聚合是否就此退役，被快照 + 区间查询取代。

**涉及风险**：#6（改历史快照不更新，主责）。

**代码指针**：`lib/features/ledger/domain/value_objects/monthly_summary.dart`、`lib/features/ledger/domain/queries/watch_monthly_summary_query.dart`；wayfinder.md「每月余额快照目标」全节（字段清单在彼处，勿在此复制）。

**推荐立场**：唯一约束确认；快照由投影器在每次事件写入时增量维护（当月 upsert，首月锚 OpeningBalanceSet）；改历史触发「自受影响月起全部重算」（正确性优先于性能，个人量级毫秒级）；空月份不物化、查找 opening 用「≤ 该月最近快照 + 事件区间补算」……若补算复杂则物化空月——票内二选一拍板；MonthlySummary 退役改读快照。
