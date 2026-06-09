# 09 · 事件目录与命名定稿

Type: grilling
Status: resolved 2026-09-06（由 spec 采纳）

## Answer

推荐立场经用户确认全量提升为正式决策，固化于 [spec.md](../spec.md) §事件模型：终稿目录 9 事件=AccountCreated/Renamed/Archived + CategoryCreated/Renamed/Archived + TransactionRecorded/Reversed + OpeningBalanceSet（AccountCreated 不含初始余额）；不设 TransactionCorrected、TransactionScheduled、TransactionPendingAdded、AccountUpdated、MonthClosed/Reopened、MonthlyBalanceSnapshotGenerated、ProjectionRebuilt；eventType=Dart 类名稳定串；工厂生产 bootstrap 注册；废弃事件随迁移删除。
Blocked by: 02, 04, 12, 13

## Question

全量事件清单最终定稿：每个事件的名称、payload 字段、进/出目录裁决，以及生产工厂注册机制。

**背景**：这是收敛票——上游票（posting 形态 02、修改/删除语义 04、快照设计 12、月结策略 13）落地后，事件集才无歧义。现状事件命名混乱：`TransactionPosted` vs 目标 `TransactionRecorded`；`TransactionScheduled` / `TransactionPendingAdded` 空置无人生产；`AccountUpdated` 语义含糊（被投影器当审计噪音冗余 append）。

**需要裁决**：
1. 初始集确认（wayfinder.md 已列）：AccountCreated、AccountRenamed、AccountArchived、CategoryCreated、CategoryRenamed、CategoryArchived、TransactionRecorded、TransactionReversed——逐一确认 payload 字段（对齐 票02 的 posting 结构、票01 的 Money VO）。
2. 候选集裁决（每项独立进/出）：TransactionCorrected（取决于 票04）、OpeningBalanceSet（账户初始余额是事件还是 AccountCreated 内嵌字段？现状是内嵌 initialBalance）、MonthClosed / MonthReopened（取决于 票13）、MonthlyBalanceSnapshotGenerated（快照生成是事件吗？取决于 票12——快照是派生数据，倾向不设事件，除非月结需要）、ProjectionRebuilt（rebuild 是运维操作不是业务事实，倾向砍）。
3. 事件命名规范：过去式动词 + 领域名词（`TransactionRecorded`）；eventType 稳定字符串格式（`transaction.recorded` vs `TransactionRecorded`——与 票06 的注册机制对齐）。
4. 归属包：账户/分类事件放 `features/ledger/domain/events/`（跨 feature 共享）还是各自 feature？账务事件与纯 ledger 事件的边界。
5. 生产工厂注册点：main bootstrap 处集中注册全部事件（修复「测试才注册」bug 的最终方案）。
6. 现有废弃事件（TransactionScheduled、TransactionPendingAdded、AccountUpdated 的冗余 append 路径）随迁移删除——列入 票14 的切片清单。

**代码指针**：`lib/core/domain/events/account_event.dart`、`lib/features/ledger/domain/events/transaction_event.dart`；wayfinder.md「Event Store 目标」初始事件清单。

**推荐立场**：目录 = 8 个初始事件 + OpeningBalanceSet（初始余额显式成事件，可审计「开户入金」）+ TransactionCorrected 不设（票04 推荐 reverse+record 配对）；MonthClosed/Reopened 视 票13 结论；MonthlyBalanceSnapshotGenerated、ProjectionRebuilt 砍（派生/运维不进事件存储）；eventType 用 `TransactionRecorded` 类名直接作稳定字符串（Dart 类名即契约，注册表 keyed by 它）。
