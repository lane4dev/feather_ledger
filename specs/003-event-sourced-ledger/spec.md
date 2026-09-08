# Spec：CQRS + Event Sourcing 架构迁移（003-event-sourced-ledger）

Status: ready-for-agent
Tracker: local-markdown（`.scratch/003-event-sourced-ledger/`）
决策来源：wayfinder map（`.scratch/003-event-sourced-ledger/map.md`）——14 张决策票的推荐立场经用户 2026-09-06 确认，全量提升为正式决策。本 spec 不引入任何 map 之外的新架构。

> **实施引用基线（T001）**：本文件为已确认规格的 specs 目录同步副本，取代本目录原 Draft 规格（其 `BalanceAdjustmentApplied`、`TransactionPendingAdded`、pending 余额等决策均已被否决）。与 `plan.md`、`data-model.md`、`contracts/` 冲突时，一律以本文件为准。

## Background / 背景与问题陈述

feather_ledger 的账务层处于半迁移状态：事件存储（`ledger_events`）已存在，但只有部分写路径经过它，且投影可被绕过。对用户而言，这意味着账目会**悄悄出错**：

- 删除一笔交易后，余额与交易列表不更新（`ReverseTransactionCommand` 只 append 事件不跑投影）。
- 转账根本不入账（`PostTransferCommand` 绕过投影器，读模型无此交易、余额不动）。
- 事件 JSON 工厂只在测试中注册，生产环境无法反序列化事件——事件存储实际是只写不读的死数据。
- 事件追加与投影更新是连续独立 await，无事务包裹，中途崩溃即永久发散；且无重放重建能力。
- 金额单位混乱：DB/事件用 int 分，部分实体用 double 元，换算散落各处。
- 余额有三处独立计算（投影器增量、DAO「回滚未来」算法、账户服务补账），口径互不一致。

本 spec 定义迁移到完整 CQRS + Event Sourcing 架构的决策与验收。目标目录结构以 `specs/003-event-sourced-ledger/mattpocock/wayfinder.md` 的 lib/ 结构图为准（既定事实）：ledger 为核心领域，reports 只读投影，settings 承载账户/分类管理 UI 及纯 CRUD 偏好。

## Goals / 目标

- Event Store 是唯一事实来源；全部投影与月度快照均为可重建的派生数据。
- 单一账务模型：Transaction + Postings，收入/支出/转账/信用卡消费/还款全部是它的形态。
- 全系统金额一律 int minor units（分），禁止 double/float。
- 消除 wayfinder map 记录的 12 项财务风险（见「风险与缓解」核销表）。
- 迁移按可验收的纵向切片推进，每片落地即删除被取代的旧路径——任何时刻代码库只有一套逻辑系统。

## Non-goals / 非目标

- 信用卡完整建模（账单周期、还款日、额度管理）；信用卡仅作为账户类型 + 转账语义的还款。
- 预算功能。
- 多币种换算（汇率、净资产合并折算）；仅保留防堵死约束。
- 同步 / 备份 / 多设备。
- 循环/定期规则事件化：`recurring_series` 与 `scheduled_transactions_view` 保持纯 CRUD，rebuild 豁免；「转正」走新写入路径发 `TransactionRecorded`。
- 严格月结：不设 `MonthClosed` / `MonthReopened` 事件，修改历史不拦截（升级路径见快照模型）。
- `TransactionCorrected` 单事件（采用 Reversed+Recorded 配对，见事件模型）。
- outbox / 异步投影 worker / 后台投影进程。
- 数据迁移工具：无真实用户数据，开发库可丢弃（见数据迁移策略）。
- 第二阶段报表投影（monthly_category_summaries、monthly_cashflow_view、account_balance_history_view）：本 spec 止于「报表读现有投影视图 + 月度快照」。

## User Stories / 用户故事

1. 作为记账人，我想记录一笔支出，所以账户余额立即正确扣减且事件流留有审计记录。
2. 作为记账人，我想记录一笔收入，所以月度收入统计与余额同步增加。
3. 作为记账人，我想在账户间转账，所以两个账户余额各自变动而收支统计不被污染。
4. 作为记账人，我想用信用卡消费，所以它像普通支出一样记账并挂在信用卡账户上。
5. 作为记账人，我想偿还信用卡，所以还款表现为储蓄→信用卡转账、不被重复计为支出。
6. 作为记账人，我想修改历史交易，所以修改以「冲正+重记」落地、原记录仍可追溯。
7. 作为记账人，我想删除交易，所以列表不再显示它但事件审计链完整保留。
8. 作为记账人，我想查看账户当前余额，所以它包含所有已入账交易（含未来日期）且口径唯一。
9. 作为记账人，我想查看月度报表，所以收入/支出/分类占比来自与余额同源的投影数据。
10. 作为记账人，我想归档不用的分类，所以历史交易仍显示归档时的分类名称与图标。
11. 作为记账人，我想归档账户，所以它不再出现在选择器中但历史与余额保留。
12. 作为记账人，我想切换显示币种，所以它只影响格式化而不参与任何账务计算。
13. 作为记账人，我想快速连点保存，所以重复提交被幂等去重、只产生一笔交易。
14. 作为记账人，我想在空月份查看快照，所以该月快照存在且净变动为零。
15. 作为记账人，我想修改上月交易，所以该月及之后月份的快照自动重算。
16. 作为记账人，我想修改已冲正的交易被拒绝，所以账目不会出现二次抵消。
17. 作为记账人，我想同账户转账被拒绝，所以不产生无意义账目。
18. 作为记账人，我想跨币种账户间转账被拒绝，所以余额不会被错误合并。
19. 作为记账人，我想首次安装即有默认分类与账户，所以种子数据经事件流写入、可重放。
20. 作为记账人，我想把定期交易转正，所以它产生真实交易且定期状态同步更新。
21. 作为开发者，我想投影损坏后一键重建，所以事件化投影可从事件流全量重放恢复。
22. 作为开发者，我想 schema 升级后自动强制重建，所以新投影代码立即生效。
23. 作为开发者，我想 rebuild 遇到未知事件类型时硬失败，所以账目不会无声漂移。
24. 作为开发者，我想用等价测试证明「增量投影 == 全量重放」，所以投影正确性持续受验证。
25. 作为开发者，我想命令返回 Result 而非裸异常，所以 UI 能统一呈现失败原因。
26. 作为开发者，我想金额全部为 int 分，所以不存在浮点累计误差。
27. 作为开发者，我想余额只有一个计算点，所以任何统计口径都不会与账面余额冲突。
28. 作为开发者，我想每片迁移落地即删旧路径，所以代码库任何时刻无双轨逻辑。

## Domain Model / 领域模型

### Money 值对象

- 不可变值对象 `Money(int minorUnits, String currencyCode)`，置于 core 层 money 模块。
- 金额**一律** int minor units（分）；领域实体、事件、投影、快照、UI 模型全部如此。现存 double 元实体（MonthlySummary、ScheduledTransactionEntity、RecurringTransactionSeriesEntity）随对应阶段退役。
- 币种不一致的 Money 运算抛错；显示货币是格式化偏好，不参与账务。

### Posting 与 Transaction

- **单一模型**：`Transaction`（transactionId、occurredAt 交易日、description、kind、notes?）携带 1..n 个 `Posting`（accountId、direction、amountMinor 正整数、currencyCode、categoryId?、memo?）。
- `kind ∈ {income, expense, transfer}`，Transaction 级显式字段。
- **direction 语义（个人记账语义，非严格会计复式语义，全系统唯此一处定义）**：`credit` = 该账户余额增加 amountMinor；`debit` = 该账户余额减少 amountMinor。
- 形态映射：收入 = kind income + 单 credit posting；支出 = kind expense + 单 debit posting；转账 = kind transfer + 一 debit 一 credit（金额相等、账户不同、币种相同）→ 净额恒零。不引入虚位账户（contra account），但字段结构不堵死未来引入。
- 信用卡：消费 = 支出 posting 挂信用卡账户；还款 = 储蓄→信用卡的转账。信用卡余额为负数表示欠款。

### 聚合边界

- 三个独立 Aggregate：**Transaction**（含 postings，不变量：postings 非空；income/expense 恰好 1 个 posting；transfer 恰好 2 个方向相反、金额相等、账户互异、币种相同的 posting；amountMinor > 0）、**Account**、**Category**。
- 不设 Ledger 聚合：账户余额不是聚合状态，是投影派生数据。
- streamId = 聚合根 id（transactionId / accountId / categoryId）。
- 命令侧校验（账户存在、币种一致、未归档、转账两账户互异）放领域服务；跨账户一致性靠同事务写入（见命令模型），不靠聚合边界。

### 账户与分类

- Account：accountId、name、type（cash/bank/credit/other）、currencyCode（创建时从全局设置取默认，可改）、archived。
- Category：categoryId、name、iconKey、colorInt、type（income/expense）、systemCode?（两个内置系统调整分类保留固定 id 与 systemCode）、archived。
- 软删除统一为**归档**（Archived），不硬删除：账户与分类皆然。

### 硬性约束（红线，实现与评审一律以此为准）

| 约束 | 规则 |
|---|---|
| 金额 | int minor units；Money VO 或裸 int；禁止 double/float 参与任何账务计算 |
| 转账 | kind=transfer 双腿净额恒零；收支统计排除口径**唯一**为 kind==transfer |
| 信用卡 | 消费=支出；还款=转账；绝无「还款再计一笔支出」的路径 |
| 软删除 | 交易=冲正（isReversed）；账户/分类=归档；无任何硬删除路径 |
| 多币种 | 每笔交易单币种（校验强制）；余额聚合按 (accountId, currencyCode) 分组，永不错币种合并；posting 币种写入时从账户复制 |

## Event Model / 事件模型

### 事件目录（终稿）

| 事件 | payload 要点 |
|---|---|
| `AccountCreated` | accountId, name, type, currencyCode（不含初始余额） |
| `AccountRenamed` | accountId, name |
| `AccountArchived` | accountId |
| `CategoryCreated` | categoryId, name, iconKey, colorInt, type |
| `CategoryRenamed` | categoryId, name |
| `CategoryArchived` | categoryId |
| `TransactionRecorded` | transactionId, occurredAt, kind, description, notes?, postings[{accountId, direction, amountMinor, currencyCode, categoryId?, memo?}] |
| `TransactionReversed` | originalTransactionId, reason(userDeleted \| correction) |
| `OpeningBalanceSet` | accountId, amountMinor, currencyCode |

**不设**：TransactionCorrected、TransactionScheduled、TransactionPendingAdded、AccountUpdated（由 Renamed 取代）、AccountDeleted（由 Archived 取代）、MonthClosed / MonthReopened、MonthlyBalanceSnapshotGenerated、ProjectionRebuilt（快照是派生数据、rebuild 是运维操作，均不进事件存储）。

- 修改 = `TransactionReversed(reason: correction) + TransactionRecorded` 配对事件（一个命令、一个数据库事务内产生两条）；UI 删除 = 单独 `TransactionReversed(reason: userDeleted)`。
- 已冲正的交易禁止再次修改/删除；只能对有效交易发起。

### 事件信封（envelope）

- 字段：eventId（uuid）、streamId（=聚合根 id）、aggregateType、eventType（**Dart 类名作为稳定字符串**，不用 runtimeType 反射）、streamVersion、globalSequenceNumber（表 autoincrement，即 GSN）、payloadJson（内含 schemaVersion）、occurredAt、recordedAt、commandId。
- **砍掉**：correlationId、causationId、metadata、eventVersion（同步/分布式场景是未来 effort，不预建）。
- 约束：`unique(streamId, streamVersion)`（乐观并发，写坏数据早失败）；索引支持按 streamId 查询与按 GSN 顺序扫描。
- 幂等：命令执行前以 commandId 查事件表，命中即短路返回成功，不产生第二笔。
- **生产工厂注册**：应用 bootstrap 集中注册全部事件工厂（修复「仅测试注册」缺陷）；eventType → 工厂的注册表是唯一分发点。
- 防堵死口子（数据迁移用）：投影行记录来源 GSN，不设投影→事件外键；合成事件可安全追加。

### schema 演进

- `schemaVersion: int` 内嵌于 payload，默认 1。
- 读取时 upcast：upcaster 注册表 keyed by (eventType, version)，投影器只见到最新结构。
- 首次发布前 v1 payload 可随意修改（开发数据可丢弃）；发布后演进纪律生效并写入 constitution（见路线收尾阶段）。
- rebuild 遇到未知 eventType：**硬失败**并报告事件 id（宁可失败不可无声漂移）。

## Command Model / 命令模型

沿既有 CQRS 命名约定：命令为带 `execute()` 的普通类 + 同文件 `@riverpod` provider，无 command bus；UI → ViewModel → 领域服务（LedgerService / AccountService）→ 命令。

| 命令 | 产生事件 | 说明 |
|---|---|---|
| CreateAccount | AccountCreated (+ OpeningBalanceSet 若初始余额 ≠ 0) | 币种默认取全局设置 |
| RenameAccount | AccountRenamed | |
| ArchiveAccount | AccountArchived | 归档后校验拒绝新记账 |
| CreateCategory / RenameCategory / ArchiveCategory | 对应事件 | 系统分类不可归档 |
| RecordTransaction | TransactionRecorded | 领域服务做全部前置校验 |
| ReverseTransaction | TransactionReversed | UI 删除入口 |
| CorrectTransaction | TransactionReversed(correction) + TransactionRecorded | 一命令两事件一事务 |
| ConvertScheduledToPosted | TransactionRecorded | 定期转正；同时改 scheduled 状态（CRUD 表） |

- 账户余额调整（用户直接改余额）：通过 RecordTransaction 挂内置系统调整分类实现，不再走独立补账命令。
- **原子性**：append 事件 + 投影更新在**同一个数据库事务**内；事务失败整体回滚，命令返回失败。
- **恢复策略**：不引入 outbox / 异步投影。同事务已消除常规不一致；投影代码 bug 或手工改库的恢复 = projection rebuild（见投影模型）。
- 命令返回 `Result<T>`（core 层 result 模块，失败携带用户可读错误码）；ViewModel 不捕获裸异常。
- 幂等：全部写命令携带 commandId（uuid），append 前按 commandId 查重。

## Projection Model / 投影模型

### 一阶段视图（MVP 四张）

| 视图 | 要点 |
|---|---|
| `accounts_view` | accountId, name, type, currencyCode, balanceMinor（**单一余额**，availableBalance 砍掉）, archived, last_updated_event_id（游标）, projection_version |
| `transactions_view` | transactionId, occurredAt, kind, description, isReversed, categoryName/categoryIcon **写时快照**（历史保真，不 join 存活）, source GSN |
| `transaction_postings_view` | posting 级行：transactionId, accountId, direction, amountMinor, currencyCode, categoryId?, memo? |
| `categories_view` | categoryId, name, iconKey, colorInt, type, archived, systemCode? |

### 投影器规则

- 每个事件类型一个 apply 分支：AccountCreated → 插入账户行（余额 0）；OpeningBalanceSet → 余额**置为绝对值**（仅开户时合法）；TransactionRecorded → 插交易行（含分类快照）+ posting 行 + 各账户余额增量 + 当月快照 upsert；TransactionReversed → 交易行置 isReversed + 余额反向增量 + 快照级联；Renamed/Archived → 更新对应视图。
- **幂等**：按 `last_updated_event_id` 游标「已应用则跳」；事件按 GSN 顺序应用。
- **余额唯计算点**：账户余额只在投影器内变动；`getRunningBalance` 的「回滚未来」算法**删除**。**当前余额 = 全部未冲正 posting 的增量之和（含未来 occurredAt 交易）**——「记了就算」。
- UI（ViewModel/Widget）只 watch 投影 provider，写一律走命令。现有「直写投影表」的定期交易命令保留为例外（其表为 CRUD 豁免表），转正走命令。
- projection_version：每张视图记录投影器代码版本，rebuild 完成时写入；启动时可校验提示。
- **rebuild 规则**：手动入口（设置→开发者项）+ Drift schema 升级时强制触发。流程 = 单一事务内：清空**事件化**投影与快照 → 按 GSN 顺序重放全部事件 → 重写游标与 projection_version。**豁免表**：`recurring_series`、`scheduled_transactions_view`、SharedPreferences 偏好——rebuild 一律不动。
- 每张视图分组聚合遵守 (accountId, currencyCode)，多币种余额不合并。

### 非事件化数据清单（不进 Event Sourcing）

| 数据 | 存储 | rebuild 行为 |
|---|---|---|
| 主题/语言/显示币种/余额可见性 | SharedPreferences（现状保留） | 不涉及 |
| 循环规则与定期实例（recurring_series / scheduled_transactions_view） | Drift CRUD | 豁免 |
| 应用静态配置（币种表、语言表、分类默认 token） | 代码内 | 不涉及 |
| 关于页版本信息 | package_info | 不涉及 |

账户与分类的生命周期**是**事件化的（settings 只是 UI 归属地）。

## Snapshot Model / 月度快照模型

`monthly_account_balance_snapshots`：id、accountId、currencyCode、year、month、openingBalanceMinor、closingBalanceMinor、incomeMinor、expenseMinor、transferInMinor、transferOutMinor、netChangeMinor、transactionCount、eventSequenceFrom、eventSequenceTo、projectionVersion、isClosed（**保留恒 false**，月结不启用）、createdAt、updatedAt、rebuiltAt。

- 唯一约束 `unique(accountId, currencyCode, year, month)`。
- **生成**：投影器在每次余额相关事件写入时增量维护——受影响月 upsert；月度收支按 kind 归集（transfer 计 transferIn/Out，不计 income/expense）。
- **opening/closing**：opening = 上月 closing；该账户首月锚定 OpeningBalanceSet（无则 0）。closing = opening + netChange。
- **空月物化**：自账户首笔事件所在月至当前月逐月物化（含无交易月，净变动 0）——opening 查找恒为「上一行 closing」，无需区间补算。
- **级联重建**：任何改变历史月净额的写入（冲正、修改后新交易的日期）触发**自受影响月（含原交易月与新交易月的较早者）起至最新已物化月**的全部重算。正确性优先于性能（个人记账量级毫秒级）。
- MonthlySummary（double 元实体）退役，月度汇总一律读快照。
- isClosed 升级路径（多设备同步时代再启用 MonthClosed/Reopened 事件与写拦截）记录为可能性，**非承诺**。

## Data Migration / 数据迁移策略

- **全新开始**：无真实用户数据（charting 既定事实）。schema 版本升级 + **破坏性迁移**：清空重建全部表 + 重跑种子。不编写投影→事件回填工具。
- **防堵死口子保留**：事件信封含 commandId 列、投影行记录来源 GSN、无投影→事件外键——未来需要时可追加「从投影合成事件」的一次性工具，本 spec 不实现。
- **种子数据走事件**：首启时事件表为空 → 经标准写入路径 append：AccountCreated(Cash) + AccountCreated(Bank) + OpeningBalanceSet(Bank, 100000) + CategoryCreated × N（含两个内置系统调整分类，固定 id 与 systemCode 保留；名称按种子时本地化，现状行为不变）。幂等：以事件表空为条件。

## Testing Strategy / 测试策略

- **单一接缝（既定决策）**：全部逻辑测试经领域服务（LedgerService / AccountService）对内存 Drift 数据库执行，断言三类外部可观察输出——**事件流**（审计链是外部契约）、**投影表**、**月度快照**。命令/投影器/Event Store 不单独开接缝。先例：现有 ledger_service_test、ledger_transfer_test、liability_logic_test（其手工注册事件工厂的模式在工厂生产注册落地后自然消亡）。
- 好测试只断言外部行为：给命令 → 查事件/投影/快照；不断言私有内部、不 mock 被测系统内部协作。
- **golden 等价测试（CI 必跑）**：随机/枚举操作序列 → 「增量投影结果」与「清空重放结果」逐字段相等。
- **不变量断言**：任意事件流重放后 Σ posting 增量 = Σ 账户余额变动；转账净额恒零；已冲正交易不计入统计但事件保留；每月 opening = 上月 closing。
- **风险回归测试**：每项财务红线（见风险表）至少一条 G/W/T 测试钉死。
- Widget 测试保持只测投影驱动的 UI 行为（现有 test/ui 模式）。

## Rollout Plan / 分阶段路线

每阶段独立提交、无数据迁移（破坏性重建即可）、完成即删旧路径（无双轨验收写入每阶段）。全部阶段完成后 `flutter analyze` 零告警、测试全绿。

**P1 核心基建（Money / Result / clock）**
范围：core 层 money、result、clock 模块。纯新增，无行为变化。
- GIVEN 币种不同的两个 Money WHEN 相加 THEN 抛币种不一致错误
- GIVEN 任意失败命令 WHEN 返回 THEN Result.failure 携带错误码，无裸异常逃逸

**P2 Event Store 落位**
范围：新事件表 + envelope + 工厂生产注册 + 幂等 + unique(streamId, streamVersion)。旧账务路径本阶段不变。
- GIVEN 生产启动完成 WHEN 任一注册事件序列化往返 THEN 语义相等（工厂在 bootstrap 注册）
- GIVEN 同 commandId 命令提交两次 THEN 事件表只多一条……即：只产生一笔事件，第二次幂等短路
- GIVEN 同 streamId 相同 streamVersion 的两个事件 WHEN 写入 THEN 第二个因唯一约束失败
- GIVEN 事件 append 完成 THEN eventType 为类名稳定串、payload 含 schemaVersion=1、GSN 单调递增

**P3 账户与分类事件化 + 种子走事件**
范围：Account/Category 全部事件、accounts_view/categories_view 投影维护、seeder 改走标准写入路径；删除账户/分类 CRUD 直写与 AccountUpdated 噪音路径。
- GIVEN 空库首启 WHEN 种子执行 THEN 事件表含 AccountCreated×2 + OpeningBalanceSet + CategoryCreated×N，且两视图由投影生成
- GIVEN 已有账户 WHEN 更名/归档 THEN 对应事件 + 视图更新；归档账户被记账校验拒绝
- GIVEN 系统分类 WHEN 尝试归档 THEN 拒绝

**P4 支出与收入闭环**
范围：RecordTransaction（expense/income）、transactions_view + transaction_postings_view 投影、余额投影、表单与列表切到新路径；**删除** PostTransactionCommand 旧路径、getRunningBalance、double 元 MonthlySummary 的生产用法。
- GIVEN 记录支出 10.50 WHEN 提交 THEN TransactionRecorded(debit, 1050) 入库；交易行 + posting 行 + 余额 −1050 + 当月快照 expense +1050
- GIVEN 未来日期支出 WHEN 提交 THEN 当前余额包含该笔（语义钉死）
- GIVEN 记录收入 WHEN 提交 THEN credit posting、余额与月度收入增加
- GIVEN 双击保存 WHEN 第二次到达 THEN 幂等短路仅一笔
- GIVEN 已归档分类的旧交易 WHEN 列表渲染 THEN 显示写时快照的分类名/图标
- GIVEN 全库 WHEN 审计 THEN 无旧支出写入路径、无 getRunningBalance（无双轨）

**P5 转账与还款**
范围：kind=transfer 双腿校验、统计排除、信用卡还款语义；删除 PostTransferCommand 绕过路径。
- GIVEN A→B 转账 100 WHEN 提交 THEN A debit 10000 + B credit 10000，两余额正确变动，月度 income/expense 不变
- GIVEN 储蓄→信用卡还款 WHEN 提交 THEN 不计入支出统计
- GIVEN 同账户或跨币种转账 WHEN 校验 THEN 拒绝
- GIVEN 月度统计 THEN kind==transfer 是唯一排除口径，无第二处判断

**P6 修改与删除**
范围：ReverseTransaction / CorrectTransaction、isReversed 呈现、审计链；删除 ReverseTransactionCommand 旧不投影路径。
- GIVEN 修改历史交易 WHEN 提交 THEN 事件表新增 Reversed(correction)+Recorded 配对，余额/列表/受影响月快照全部更新
- GIVEN 删除交易 WHEN 提交 THEN Reversed(userDeleted)，列表隐藏（isReversed），事件流保留完整原交易
- GIVEN 已冲正交易 WHEN 再次修改/删除 THEN 拒绝
- GIVEN 含冲正的事件流 WHEN 重放 THEN 冲正与原交易相互抵消，余额正确

**P7 月度快照**
范围：快照表、增量维护、级联重算、MonthlySummary 退役。
- GIVEN 修改上月交易 WHEN 提交 THEN 该月及之后全部快照重算，eventSequenceFrom/To 更新
- GIVEN 无交易月 WHEN 查询 THEN 快照存在且净变动为 0
- GIVEN 首月 WHEN 读取 THEN opening = OpeningBalanceSet 金额
- GIVEN 月度汇总 WHEN UI 读取 THEN 来自快照，代码库无 double 元汇总实体

**P8 Rebuild 机制**
范围：手动入口 + schema 升级强制触发 + golden 等价测试进 CI + 不变量断言。
- GIVEN 任意事件流 WHEN 手动 rebuild THEN 事件化投影与快照清空重放后与重建前逐字段一致；recurring/scheduled/偏好原样保留
- GIVEN schema 升级 WHEN 启动 THEN 强制 rebuild 后应用正常
- GIVEN 未知 eventType WHEN rebuild THEN 硬失败并报告事件 id
- GIVEN 增量写入 N 笔 vs 全量重放 WHEN 对比 THEN 投影与快照等价

**P9 报表切换**
范围：reports 数据源切到快照 + 现有投影视图；heatmap/饼图行为不变。
- GIVEN 月度报表 WHEN 读取 THEN 数据来自快照/投影，收支数字与账面余额同源
- GIVEN 含转账的月份 WHEN 查看分类占比 THEN 转账不计入

**P10 收尾核销**
范围：旧代码删除清单核销、12 风险核销、schema 演进纪律写入 constitution（或 ADR）、AGENTS.md 现状段落更新。
- GIVEN 全库 WHEN 审计 THEN 无 double 货币字段、无双轨写路径、余额单计算点、事件工厂生产注册
- GIVEN 风险表 WHEN 核销 THEN 12 项全绿且各有测试钉死

## Acceptance Criteria / 全局验收

- 事件流是唯一事实来源：删除全部派生表后 rebuild，一切视图/快照/余额恢复原值。
- 账务不变量恒成立：Σ posting 增量 = Σ 余额变动；转账净额零；每月 opening = 上月 closing；当前余额含未来交易。
- 12 项财务风险全部消除且各有回归测试（映射见下表）。
- 生产路径无 double 金额、无双轨写路径、余额单计算点。
- `flutter analyze` 零告警、`flutter test` 全绿（含 golden 等价与不变量测试）。

## Risks and Mitigations / 风险与缓解（12 项核销表）

| # | 风险 | 规避决策（本 spec） | 验收处 |
|---|---|---|---|
| 1 | 金额 double/float | Money VO + 全库 int 分，P1/P10 审计 | P1、P10 |
| 2 | 收入/支出/转账三套模型 | 单一 Transaction+Postings | P4、P5 |
| 3 | 转账污染收支统计 | kind==transfer 唯一排除口径 | P5 |
| 4 | 信用卡还款重复计支出 | 还款=转账语义 | P5 |
| 5 | 删除交易断审计链 | TransactionReversed 软删除，事件永久保留 | P6 |
| 6 | 改历史快照不更新 | 自受影响月级联重算 | P7 |
| 7 | 投影与事件存储不一致 | 同事务写入 + rebuild + golden 等价 | P2/P6、P8 |
| 8 | 分类硬删除失真 | 归档 + 交易行写时快照 | P3、P4 |
| 9 | 未来交易余额定义不清 | 定义：当前余额含未来交易，单计算点 | P4 |
| 10 | 多币种错误合并 | 每笔交易单币种校验 + (account, currency) 分组 | P4/P5 |
| 11 | UI 直改 read model | UI 只 watch 投影、写只走命令；直写反例清除 | P4、P10 |
| 12 | 余额多处重复计算 | 投影器唯一计算点，getRunningBalance 删除 | P4 |

## Further Notes / 附注

- **经用户确认提升为决策的争议项**（复核入口）：修改=Reversed+Recorded 配对（否决单事件 Corrected）；当前余额含未来交易；不设 MonthClosed 事件、isClosed 恒 false 占位；posting 用 debit/credit 显式方向（个人记账语义，非严格会计语义）；信封砍 correlationId/causationId/metadata/eventVersion；空月物化为连续快照；账户仅 postedBalance 单一余额。
- 第二阶段报表投影（monthly_category_summaries 等）与 `core/event_sourcing` 通用化抽象是未来独立 effort 的候选，本 spec 只落 ledger 专用最小实现（信封类型 + EventStore 接口 + append 协议在 core，Drift 实现在 ledger data 层）。
- 原 wayfinder 票 14 计划的独立 route.md 由本 spec 的「分阶段路线」取代，不再单独产出。
