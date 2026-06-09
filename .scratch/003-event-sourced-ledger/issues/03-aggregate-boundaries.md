# 03 · Aggregate 边界与聚合设计

Type: grilling
Status: resolved 2026-09-06（由 spec 采纳）

## Answer

推荐立场经用户确认全量提升为正式决策，固化于 [spec.md](../spec.md) §领域模型：三个独立 Aggregate（Transaction 含 postings、Account、Category）；无 Ledger 聚合（余额纯投影派生）；跨账户一致性靠同事务写入；命令侧校验放领域服务；streamId=聚合根 id。账户/分类生命周期事件化，settings 其余部分纯 CRUD。
Blocked by: 02

## Question

`Transaction`、`Account`、`Category` 是否各自为 Aggregate？是否需要独立的 `Ledger` Aggregate 或 Domain Service？

**背景**：现状无任何聚合抽象——命令直接构造事件、直接 append，无聚合根、无一致性边界、无不变量集中地。目标结构提供 `features/ledger/domain/aggregates/` 目录。

**需要裁决**：
1. Aggregate 划分：Transaction（含 postings，跨账户！）、Account、Category 各自独立聚合？Transaction 跨越多个 Account 的余额，复式记账通常把「账户余额」视为派生而非聚合内状态——余额只活在投影里（wayfinder.md 原则 5 已倾向此），Transaction 聚合校验的边界是什么？
2. 是否需要 Ledger Aggregate：一个「总账」聚合管理所有交易（强一致但单流瓶颈）vs Transaction 各自聚合 + Account 余额纯投影。本地单机无并发写者，吞吐不是约束，但事件流结构（streamId 怎么定）由此决定。
3. 命令侧校验归属：账户是否存在、币种是否一致、金额上限等校验放在聚合内、领域服务，还是命令处理器？
4. streamId 语义：per-transaction stream、per-account stream、还是单一 global stream？（影响 票06 的表结构与并发控制。）
5. wayfinder.md 内部张力需裁决：它说「settings 纯 CRUD」，又把 AccountCreated/CategoryArchived 列入初始事件集。裁决：账户/分类生命周期必须事件化（否则 categories_view 无法 rebuild，见 票11），settings 的其余部分（主题、语言、偏好）纯 CRUD——「settings 纯 CRUD」指 feature 归属而非账户分类的存储模型。

**代码指针**：`lib/features/ledger/domain/commands/`（现有 8 命令直写模式）、`lib/core/domain/events/`；wayfinder.md「目标账务模型」第 2/3 问。

**推荐立场**：三个独立 Aggregate（Transaction、Account、Category），无 Ledger 聚合——账户余额是投影派生数据（唯计算点在 票10 落实），跨账户一致性靠「同事务写事件+投影」（票07）而非聚合边界；命令侧校验放领域服务；streamId = 聚合根 id（transactionId / accountId / categoryId）。
