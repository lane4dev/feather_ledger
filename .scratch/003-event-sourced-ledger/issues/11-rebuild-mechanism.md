# 11 · Rebuild 机制与投影正确性

Type: grilling
Status: resolved 2026-09-06（由 spec 采纳）

## Answer

推荐立场经用户确认全量提升为正式决策，固化于 [spec.md](../spec.md) §投影模型·§测试策略：rebuild=手动入口（设置→开发者项）+ Drift schema 升级强制触发；流程=单一事务内清空事件化投影→按 GSN 重放→重写游标与 projection_version；CRUD 表（recurring_series、scheduled_transactions_view）与偏好豁免；golden 等价（增量==重放）与不变量断言进 CI；seeder 改走标准写入路径（append 事件）。
Blocked by: 06, 10

## Question

投影如何从事件重建？重建期间 UX 与数据安全如何保障？投影正确性如何测试？

**背景**：现状无任何重放能力（工厂只测试注册），投影发散即永久发散。票07 已定「同事务写入」消除常规不一致，rebuild 是兜底：投影代码 bug、手动改库、以及 schema 迁移后的强制重建。`accounts_view.last_updated_event_id` 游标已在。

**需要裁决**：
1. Rebuild 触发方式：仅开发/调试入口（设置里隐藏项）vs 启动时校验 GSN 与游标自动触发 vs 手动命令。schema 迁移后是否强制 rebuild（Drift schemaVersion 升级时）。
2. Rebuild 流程：事务内 drop + 重建 vs 新表 swap？重建期间 UI watch 流的反应（禁 UI 蒙层？）。事件量大时本地 SQLite 的耗时上限（个人记账万级事件 < 1s，可同步做）。
3. **CRUD 表豁免（charting 既定约束落实）**：rebuild 只重建事件化投影（accounts_view / transactions_view / transaction_postings_view / categories_view + 票12 快照表）；`recurring_series`、`scheduled_transactions_view`、`categories` 若保留 CRUD 直写则豁免——注意：categories_view 若事件化，旧 categories 表的 CRUD 写路径与 rebuild 的边界必须在票内写死，否则双写复活。
4. projection_version 的使用时机（与 票10 的设计对齐）：rebuild 完成时写入版本，启动校验版本不匹配 → 提示 rebuild。
5. 正确性测试策略（wayfinder.md 问「如何测试 projection 的正确性」）：不变量断言（Σpostings = Σ账户余额变动；转账净额零）+ 「增量投影 == 全量重放」的黄金测试——测试基建形态（golden replay harness）。
6. seeder 的最终形态：seed 直接写事件流（AccountCreated + OpeningBalanceSet + CategoryCreated…）还是仍直写投影（豁免 rebuild）？——倾向前者，seed 数据从此可重放。

**涉及风险**：#7（与 票07 共担）。

**代码指针**：`lib/core/data/database/daos/events_dao.dart`（getStream/getMaxEventId 已存在但空置）、`lib/app/bootstrap/seeder.dart`（直写投影反例）；wayfinder.md「Projection 目标」第 3-6 问。

**推荐立场**：rebuild = 手动入口（设置 → 开发者项）+ schema 迁移强制触发；流程 = 事务内清空事件化投影表 → 按序重放全部事件 → 重算游标与 projection_version；CRUD 表豁免并在代码注释标明；测试 = 不变量断言 + 增量/重放等价黄金测试进 CI；seeder 改为 append 事件（走同一条写入路径，顺路修复「seed 无事件」）。
