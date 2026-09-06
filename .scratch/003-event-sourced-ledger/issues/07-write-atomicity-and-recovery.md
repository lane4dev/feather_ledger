# 07 · 写入原子性与投影恢复

Type: grilling
Status: resolved 2026-09-06（由 spec 采纳）

## Answer

推荐立场经用户确认全量提升为正式决策，固化于 [spec.md](../spec.md) §命令模型：append 事件+投影更新同一 db.transaction；不引入 outbox/异步投影；恢复统一走 rebuild；命令返回 Result<T>（core/result）；投影器按 last_updated_event_id 游标「已应用则跳」实现幂等。
Blocked by: 06

## Question

「写事件 + 更新投影」是否放进同一个数据库事务？投影更新失败如何恢复？

**背景**：现状零 `db.transaction`——投影器流程是 append 事件 → upsert 交易行 → append 冗余 AccountUpdated → 重写账户行，四个独立 await，中途崩溃即存储与投影永久发散（无重放可用，风险 #7 实锤）。`accounts_view.last_updated_event_id` 游标已存在但被塞 0。

**需要裁决**：
1. 同事务 vs 分离：确认采用 `db.transaction` 包裹「append 事件 + 跑投影器更新读模型」（本地 SQLite 单文件，同事务成本近零，Drift watch 流也能看到一致快照）。有没有理由不这么做？
2. 事务边界与流语义：投影器在事务内写多张表，Drift 的 stream watch 在事务提交后才通知——确认无「半状态」泄漏路径。
3. 恢复策略：若同事务已保证原子性，唯一不一致来源只剩「投影代码 bug / 手改数据库」→ 恢复 = projection rebuild（票11 的机制）。确认不引入 outbox / 后台投影 worker（单机用不上，复杂度不划算）。
4. 事务失败的用户侧表现：命令返回什么（Result 类型？`core/result/` 目录已在目标结构里）——抛异常 vs Result<T>，错误如何回传 ViewModel。
5. 投影器幂等：同事件重放两次必须无害（upsert 语义天然幂等？余额加减不是！）——投影器内部用什么机制保证可重放（先查游标再应用？）。

**涉及风险**：#7（projection 与 event store 不一致，主责）。

**代码指针**：`lib/features/ledger/data/event_handlers/ledger_transaction_event_handler.dart`（顺序 await 链）、`lib/core/data/database/app_database.dart`（无事务包裹）；wayfinder.md「Event Store 目标」第 4/5 问。

**推荐立场**：同事务（append + project 一个 `db.transaction`）；不引入 outbox/异步投影；恢复统一走 rebuild（票11）；命令返回 `Result<T>`（`core/result/`）；投影器以 `last_updated_event_id` 游标做「已应用则跳过」实现幂等，余额更新改为「读事件流内余额 → 写绝对值」或「游标内加减 + rebuild 校验」——具体形态在票内定。
