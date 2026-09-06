# 06 · Event Store 表结构与写入协议

Type: grilling
Status: resolved 2026-09-06（由 spec 采纳）

## Answer

推荐立场经用户确认全量提升为正式决策，固化于 [spec.md](../spec.md) §事件模型：信封=eventId、streamId、aggregateType、eventType（类名稳定串）、streamVersion、GSN（autoincrement）、payloadJson（内含 schemaVersion）、occurredAt、recordedAt、commandId；砍 correlationId/causationId/metadata/eventVersion；unique(streamId, streamVersion)；commandId 查重幂等（双击防重）；生产 bootstrap 集中注册工厂；投影记录来源 GSN 保留回填口子。

## Question

Drift 中事件存储表如何建？事件写入/读取协议如何定？

**背景**：现状 `LedgerEvents` 表：autoincrement id（GSN）、eventId、type（`runtimeType.toString()`——重命名即断）、occurredAt/recordedAt、payload JSON、correlationId/metadata（空置）。事件工厂只在测试注册，生产 `LedgerEvent.fromJson` 抛 `UnsupportedError`。correlationId/metadata 完全没消费方。

**需要裁决**：
1. wayfinder.md 列的 envelope 字段逐项裁定进/出一阶段：eventId、streamId、aggregateId、aggregateType、eventType、eventVersion、streamVersion、globalSequenceNumber、payloadJson、metadataJson、occurredAt、recordedAt、commandId/correlationId/causationId、schemaVersion。本地单机应用里哪些是真需求、哪些是面向分布式场景的过度设计？
2. 事件类型标识：`runtimeType.toString()` 换成稳定的显式 eventType 字符串（如 `'transaction.recorded'`）+ 生产启动时工厂注册——确认注册点（main bootstrap）。
3. streamVersion 并发控制：单机单写者（UI isolate + 后台 DB isolate）下要不要 unique(streamId, streamVersion) 约束做乐观并发？本地是否仍需要 commandId 幂等（防重复点击双击提交）？
4. Drift 建表细节：索引（streamId 查询、GSN 有序扫）、GSN 生成方式（autoincrement 保持现状？）。
5. 保留「从投影回填事件」的口子（charting 约束）：设计上如何不堵死（不强制外键投影→事件，但投影记录 source GSN）。

**代码指针**：`lib/core/data/database/tables.dart`（LedgerEvents）、`lib/core/data/database/daos/events_dao.dart`、`lib/core/data/repositories/event_repository.dart`、`lib/core/domain/events/ledger_event.dart`（_factories 注册表）；wayfinder.md「Event Store 目标」全节。

**推荐立场**：一阶段 envelope = eventId、streamId（=聚合根 id）、aggregateType、eventType（稳定字符串）、streamVersion、globalSequenceNumber（autoincrement）、payloadJson、occurredAt、recordedAt、schemaVersion（预留）。commandId 幂等要（双击防重：提交前查 commandId 是否已处理）；correlationId/causationId/metadataJson/eventVersion 砍（out of scope：同步/分布式是未来 effort）；unique(streamId, streamVersion) 约束加上（成本近零，写坏数据早失败）。
