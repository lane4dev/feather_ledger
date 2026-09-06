# Wayfinder Map: CQRS + Event Sourcing 迁移决策图

（wayfinder:map · local-markdown tracker · effort 目录 `.scratch/003-event-sourced-ledger/`）

## Destination

一张决策完备的 map：将 feather_ledger 从当前半迁移状态（事件存储已存在，但写路径分裂、投影可被绕过、生产无法反序列化事件）迁移到 `specs/003-event-sourced-ledger/mattpocock/wayfinder.md` 所定义的 CQRS + Event Sourcing 目标架构所需的**全部架构决策**解决完毕——14 张决策票全部 resolved，迁移路线清晰到可以直接进入 speckit 的 spec → tasks → implement 流程。本 effort 只做决策，不改业务代码。

## Notes

- **需求来源**：`specs/003-event-sourced-ledger/mattpocock/wayfinder.md`（原始需求：目标目录结构、目标账务模型、12 项财务风险清单、12 步迁移优先级）。工程规范以 `.specify/memory/constitution.md` 为准。
- **代码库现状**：见 AGENTS.md「Event-sourced ledger model」一节。关键现状：事件 JSON 工厂仅测试注册（生产 `LedgerEvent.fromJson` 抛错）；`PostTransferCommand` / `ReverseTransactionCommand` 绕过投影器（转账不进读模型、UI 删除不更新投影）；无 `db.transaction` 包裹多步写入；seeder 与账户命令直写投影（`lastUpdatedEventId: 0`）。
- **工作方式**：所有票均为 HITL grilling 票——工作 session 先认领（`Status: claimed`），调用 Skill 工具加载 `mattpocock-skills:grilling` 与 `mattpocock-skills:domain-modeling`，从票内推荐立场出发向用户提问，用户拍板后把答案写入 `## Answer`、置 `Status: resolved`、回填本 map 的 Decisions so far。
- **既定约束（charting 阶段已定，票内不再重议）**：
  - 金额一律 int minor units（分），禁 double/float——原则已定，开放问题只剩 VO 形态与币种归属（票01）。
  - 开发数据可丢弃：无真实用户数据，不写数据迁移器；Event Store 设计保留「从投影回填事件」的口子（票06）。
  - 目标目录结构照单全收（wayfinder.md 的 lib/ 结构图是固定事实）：ledger 核心域、reports 只读投影、settings 其余部分纯 CRUD。
  - 循环/定期规则保持纯 CRUD，不事件化；projection rebuild 明确豁免 `recurring_series` / `scheduled_transactions_view`（票11 落实）。
  - 迁移姿态：边走边删——每个纵向切片落地时删除被取代的旧路径，任何时刻代码库只有一套逻辑系统；「无双轨」写入各切片验收标准（票14 汇总）。
- **12 项财务风险 → 票映射**（每项须在对应票给出规避决策，票14 逐一核销）：
  1. 金额 double/float → 票01
  2. 收入/支出/转账三套底层模型 → 票02
  3. 转账计入收支统计 → 票05、票10
  4. 信用卡还款重复计支出 → 票05
  5. 删除交易断审计链 → 票04
  6. 改历史后月度快照不更新 → 票12
  7. projection 与 event store 不一致 → 票07、票11
  8. 分类硬删除丢历史名称 → 票09、票10
  9. 未来日期交易余额定义不清 → 票10
  10. 多币种余额错误合并 → 票01、票10
  11. UI 直接修改 read model → 票10
  12. 余额多处重复计算 → 票10

## Decisions so far

- [01 Money VO 与币种](issues/01-money-vo-and-currency.md)：Money = (int minorUnits, currencyCode)；账户级币种；写时复制；单币种校验
- [02 Posting 模型](issues/02-posting-model.md)：Transaction+Postings 单模型；debit/credit 方向 + 正数金额
- [03 聚合边界](issues/03-aggregate-boundaries.md)：三独立聚合，无 Ledger 聚合，streamId=聚合根 id
- [04 修改与删除](issues/04-modify-delete-semantics.md)：修改=Reversed+Recorded 配对；删除=Reversed(userDeleted)；已冲正禁改
- [05 转账与还款](issues/05-transfer-and-repayment.md)：双腿净额零；kind==transfer 唯一排除口径；还款=转账
- [06 Event Store](issues/06-event-store-schema-and-write-protocol.md)：信封定稿（砍 correlationId/causationId/metadata/eventVersion）；commandId 幂等；unique(streamId, streamVersion)
- [07 写入原子性](issues/07-write-atomicity-and-recovery.md)：事件+投影同事务；Result 返回；游标幂等；恢复=rebuild
- [08 schema 演进](issues/08-event-schema-evolution.md)：payload 内嵌 schemaVersion；读取时 upcast；未知事件硬失败
- [09 事件目录](issues/09-event-catalog-and-naming.md)：9 事件终稿 + 生产工厂注册；Corrected/Scheduled/PendingAdded/MonthClosed 等不设
- [10 投影与余额](issues/10-phase1-projections-and-balance-semantics.md)：4 张 MVP 视图；余额含未来交易、唯一计算点；分类写时快照
- [11 Rebuild](issues/11-rebuild-mechanism.md)：手动+schema 强制；CRUD 表豁免；golden 等价进 CI；seeder 走事件
- [12 月度快照](issues/12-monthly-balance-snapshots.md)：增量维护+自受影响月级联重算；空月物化；unique 四元组
- [13 月结](issues/13-month-close-policy.md)：(b) isClosed 恒 false 占位，无月结事件，不拦截历史修改
- [14 路线汇总](issues/14-route-consolidation-and-handoff.md)：被 spec 的分阶段路线（P1–P10）与风险核销表取代

**map 已关闭（2026-09-06）**：14 张票的推荐立场经用户确认全量提升为决策，固化为 [spec.md](spec.md)（Status: ready-for-agent）。目的地达成——后续进入 speckit 的 tasks / implement 流程。

## Not yet specified

（无——原两处雾区已收敛：第二阶段报表投影固化为 spec Non-goals 的第二阶段范围；core/event_sourcing 抽象深度由 spec 附注定调——ledger 专用最小实现，core 放信封类型 + EventStore 接口 + append 协议，Drift 实现在 ledger data 层。）

## Out of scope

- 信用卡完整建模（账单周期、还款日、额度管理）——仅保留防堵死约束（票01/02/05/10 内处理），实现留给未来 effort。
- 预算功能——完全排除，无防堵死需求。
- 多币种实现（汇率、换算）——仅防堵死（票01/10），实现排除。
- 同步/备份——完全排除。
- 循环/定期规则事件化——`RecurringSeries` 保持纯 CRUD，rebuild 豁免；若未来要事件化需重开 effort。
- 现有 db.sqlite 开发数据的迁移——数据可丢弃，不做。
