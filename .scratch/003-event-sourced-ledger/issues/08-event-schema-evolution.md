# 08 · 事件 schema 演进策略

Type: grilling
Status: resolved 2026-09-06（由 spec 采纳）

## Answer

推荐立场经用户确认全量提升为正式决策，固化于 [spec.md](../spec.md) §事件模型：payload 内嵌 schemaVersion（默认 1）；读取时 upcast（upcaster 注册表 keyed by eventType+version，投影器只见最新结构）；首次发布前 v1 可随意改，发布后纪律写入 constitution；rebuild 遇未知 eventType 硬失败并报告事件 id。
Blocked by: 06

## Question

事件 payload 的 schema 版本升级策略是什么？

**背景**：事件是永久事实，比代码活得久——改 payload 结构（加字段、拆字段、改语义）时历史事件不能失效。现状 `schemaVersion` 概念完全缺失；数据虽可丢弃（charting 决策），但那是「本次迁移免费」，发布后第一版起就有真实历史了。

**需要裁决**：
1. 版本号挂在哪：每事件 payload 内嵌 `schemaVersion`（事件级）vs 事件类型级注册表 vs 全局 app schemaVersion。Drift 的 `schemaVersion = 2+` 迁移与事件 payload 版本是什么关系（表结构迁移 ≠ 事件语义迁移，两者要分开表述）。
2. 升级机制：读取时 upcast（旧事件读入内存转成新结构再投影）vs 写入时永不改旧事件 + 投影器支持多版本。推荐哪种、注册表长什么样（upcaster per event type per version）？
3. 本次迁移的起点纪律：v1 事件集（票09 定稿）发布前可以随意改 payload（数据可丢弃）；发布后规则即生效——这条纪律写进 map 还是 constitution？
4. 未知事件类型：rebuild 时遇到不认识的 eventType（降级安装）——报错拒绝 vs 跳过并记录？

**代码指针**：`lib/core/domain/events/ledger_event.dart`（fromJson 分发）、`lib/core/data/database/app_database.dart`（schemaVersion 1）；wayfinder.md「Event Store 目标」第 6 问。

**推荐立场**：事件级 payload 内嵌 `schemaVersion: int`（默认 1）；读取时 upcast（upcaster 注册表 keyed by eventType+version，投影器只见最新结构）；本次迁移期间 v1 随便改、首次发布后规则生效并写入 constitution/ADR；未知事件类型在 rebuild 时报错拒绝（静默跳过会导致账目无声漂移，个人记账宁可失败）。
