# 01: 本地日历日展开内核、Schema 升级与自然月物理物化

Triage: ready-for-agent
Status: resolved

**Blocked by:** None (can start immediately)

关联规格见 [spec.md](../spec.md)。

**What to build:** 为周期系列建立统一的本地日历日展开内核，完成 CRUD 豁免表的增量升级，并将物理物化升级为「当月完整 + 未来 2 个完整自然月月末对齐、取消高频 3 期截断、单系列单事务批量写入、读路径无 N+1」的新策略，同时打通 `RecurringService` 与 `BudgetService` 共用内存数据库和固定时钟的端到端测试底座。

## 验收标准

- [x] 新增纯领域展开器 `RecurrenceExpander`，严格以本地日历日 `(year, month, day)` 推演 `DAILY / WEEKLY / MONTHLY / YEARLY`、自定义 `interval`、`BYDAY`、`endDate` 与 `countLimit - completedCountOffset`，产出保留原始本地时刻的排期日期与本地 `YYYY-MM-DD` 逻辑 `occurrenceKey`（`planned` 固定 `'single'`），消除 UTC 跨零点漂移、夏令时偏移与 `rrule` 文本/离散列双写割裂。
- [x] 完成 `AppDatabase` 增量 `schemaVersion` 升级（不提升 `ledgerProjectionVersion`，不触碰或重建事件溯源表）：`recurring_series` 新增 `materialize_from`（现有行回填 `start_date`）与 `completed_count_offset`（默认 `0`）；`scheduled_transactions_view` 中既有 `repeating` 行的 `occurrence_key` 按 `scheduled_date.toLocal()` 迁为本地日历日（冲突时按 `posted > failed > scheduled > skipped` 保留最高优先级）。
- [x] 物理物化窗口改为对齐本地自然月月末 `endOfMonth(nowYm + 2)`（覆盖当月完整与未来 2 个完整自然月），取消窗口内 `maxKeep = 3` 截断，完整物化每日/每周/每月全部期次（保留单系列单次前瞻安全阀 120 条）；对在窗口内无发生项的稀疏规则（如年付或远期起点）保底物化最近 1 期（`minKeep = 1`）；`planned` 系列保持按自身日期幂等生成唯一 `'single'` 行。
- [x] 物理物化改为每条系列单次数据库事务 + 批量 `insertOrIgnore` 写入；`RecurringRepository` 读路径直接复用 SQL `JOIN` 的系列、账户与分类字段，消除按系列逐条查询的 N+1 开销，并提供按未结清/月份范围筛选的查询能力。
- [x] 扩展 `LedgerServiceHarness`，支持注入 `FixedClock` 并暴露共用同一内存数据库的真实 `BudgetService`；端到端验证自然月月末对齐（例如 11 月 26 日完整覆盖至次年 2 月底）、高频完整物化、本地凌晨 00:30 跨 UTC 零点与跨时区重跑幂等、以及 `RecurringReminders` 在取消 3 期上限后仍严守 60 条系统通知上限。
- [x] `flutter analyze` 无新增错误或警告，相关单元、迁移与提醒测试全部通过。
