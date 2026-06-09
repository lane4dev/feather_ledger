# 01 · Money 值对象与币种归属

Type: grilling
Status: resolved 2026-09-06（由 spec 采纳）

## Answer

推荐立场经用户确认全量提升为正式决策，固化于 [spec.md](../spec.md) §领域模型：Money = 不可变 (int minorUnits, currencyCode) VO；账户级币种（创建时取全局默认）；posting 写时从账户复制币种；写入路径单币种断言；余额聚合按 (accountId, currencyCode) 分组；double 元实体全部退役。

## Question

金额与币种如何在领域层表达？

**背景**：现行代码金额单位混乱——DB 与事件用有符号 int 分，部分实体（`ScheduledTransactionEntity`、`RecurringTransactionSeriesEntity`、`MonthlySummary`）用 double 元，`(amount * 100).round()` 散落在命令/查询里。币种目前只是全局显示设置（`currency_provider` / `PreferencesRepository` 的 `currency_code`），不参与任何账务逻辑。

**需要裁决**：
1. Money VO 的形态：`(int minorUnits, String currencyCode)` 组合类，还是裸 int + 事件/投影各自携带币种列？
2. 币种归属层级：全局单币种（现状）vs 账户级 currencyCode vs 交易级？多币种实现被排除在本 effort 外，但 posting.currencyCode 字段必须现在就位以防堵死。
3. posting.currencyCode 的真相来源：写入时从账户快照复制，还是运行时外键式引用？
4. 多币种余额合并的规避：投影层按 currencyCode 分组聚合的约束在哪落实（与 票10 衔接）。
5. 现有 double 元实体的清算：`MonthlySummary` / `ScheduledTransactionEntity` 等在新架构里统一为分。

**涉及风险**：#1（double/float）、#10（多币种错误合并）。

**代码指针**：`lib/features/ledger/domain/entities/ledger_entities.dart`、`lib/features/ledger/domain/value_objects/monthly_summary.dart`、`lib/core/presentation/providers/currency_provider.dart`、`lib/app/config/app_currencies.dart`；wayfinder.md「迁移原则」第 8 条与 posting 字段清单。

**推荐立场**：Money = 不可变 `(int minorUnits, String currencyCode)` VO，`core/money/` 落位；账户级 currencyCode（创建时从全局设置固化默认值，可改）；posting 写入时从账户复制币种；写入协议层（票06）执行单币种断言——同币种校验失败即拒绝入账。所有领域实体一律 int 分，double 元实体随切片替换。
