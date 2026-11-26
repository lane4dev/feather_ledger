# Accounted For —— Agent 指南

## 项目背景

- 个人记账应用：账户、收入/支出交易、周期计划、月度报表。三语（en / zh_Hans / zh_Hant），Material 3。
- Flutter/Dart，严格 MVVM、Riverpod（codegen）、Drift/SQLite、GoRouter、基于 ARB 的本地化、报表用 fl_chart。
- 权威工程原则见 `.specify/memory/constitution.md`，改代码前必须先阅读并遵守。
- 特性规格与计划位于 `specs/`。当前的事件溯源工作见 `specs/003-event-sourced-ledger/`。
- `CONTEXT.md`（仓库根目录）是统一语言（ubiquitous language）——命名新概念或新类型前先读它。已决策记录在 `docs/adr/`（0001：聚合根跑在写路径上；0002：posting context 是独立接缝；0003：余额用途无分类；0004：账本最小金额单位；0005：预约账单 UUID 身份与二元作用域编辑；0006：预算阶梯时间轴与 CRUD 豁免边界）；审计与研究在 `docs/reports/` 和 `docs/research/`。

## 架构定位

- **特性优先（Feature First）**：`lib/features/{ledger,reports,settings}` 是垂直切片，各自拥有
  `domain/` / `presentation/`（有独立持久化时再加 `data/` —— settings 没有）。
  `lib/core`（共享内核）与 `lib/shared` 只放被一个以上特性需要的东西。
  禁止新增技术分层目录（`lib/models/`、`lib/services/`）。目前有三个单消费者文件停在共享层，它们是
  已知例外而非先例：`shared/presentation/widgets/sliver_clip_rect.dart`（仅 ledger）、
  `core/presentation/providers/balance_visibility_provider.dart`（仅 ledger）、
  `core/domain/clock/clock.dart`（`FixedClock` 仅测试使用）。
- **DDD**：`domain/` 拥有实体、值对象、聚合（聚合根自己校验不变量 ——
  `Transaction.validate()` 位于 `features/ledger/domain/model/transaction.dart`）、命令/查询以及仓储
  **接口**；`data/` 拥有持久化。
- **CQRS + 事件溯源**：写入是命令，把事件追加进 `ledger_events`（唯一事实来源）；读取消费投影；下游
  一切皆可从事件重建。没有命令总线。

## 架构总览

严格分层；ledger 是参考切片，另外两个切片应向它收敛：

```
lib/app/        引导 (bootstrap)、配置 (currencies/languages/app info)、GoRouter、主题、l10n、
                design_system (AppButton/AppCard/AppTextField 包装)
lib/core/       共享内核：数据库 + DAO + 仓储实现 (data)；实体/枚举/event_sourcing/money/clock/
                constants/result/仓储接口 (domain)；全局 provider —— 主题/语言/币种/余额可见性/
                分类/账户 (presentation)
lib/features/   ledger、reports、settings —— 各自拆分为 data / domain / presentation
lib/shared/     跨特性的组件与扩展
```

`lib/app/design_system/` 是共享组件的样式入口；`lib/shared/presentation/widgets/` 放跨特性的**行为型**
组件（`feather_divider`、`feather_month_picker`）。凡涉及令牌（token）的一律优先用设计系统。

特性内部：

- `domain/commands/` —— 写用例。发出领域事件，经 `DriftEventStore.append` 持久化，并由 `LedgerProjectorImpl` 在同一个数据库事务内投影。**例外**：周期链路与预算链路的写命令直接写 CRUD 豁免表、不发事件、因此也没有 `commandId`（只有将待入账转为真实交易的 `ConvertScheduledToPostedCommand` 发事件并消费 `commandId`）。
- `domain/queries/` —— 读用例，流式读取 Drift 视图。
- `domain/services/` —— 组合命令 + 查询的门面（`LedgerService`、`AccountService`、`CategoryService`、`RecurringService`、`BackupService`、`TransactionExportService`）；UI 消费的入口。ledger 还有 `PostingContextResolver`（`domain/services/posting_context.dart`），即每个写入方都要经过的接缝：在构建聚合前校验账户/分类（ADR-0002）。
- `domain/model/` —— 聚合根及其组成部分（`Transaction`、`Posting`）；另有 `domain/value_objects/`（含 `TransactionFilter`）、`domain/entities/`、`domain/export/`（`transaction_csv.dart`，纯函数）、`domain/projections/`（投影器接口，实现放在 `data/projections/`）。
- `domain/repositories/`（接口）↔ `data/repositories/`（实现），由 Riverpod provider 接线。
- CQRS 靠命名约定：每个命令/查询都是普通类，带 `execute()`、构造器注入依赖，并在同文件内手写 `@riverpod` provider。没有命令总线。
- 表现层：组件 → 视图模型（`@riverpod` notifier）→ service → 命令/查询。组件内不放业务逻辑。**这是 ledger 的形态；另外两个切片目前并不对称**（见下）。

### 各切片成熟度（描述代码现状，不是目标）

- **ledger** —— 完整切片：视图模型（`LedgerViewModel`、`RecurringViewModel`、`SearchViewModel`）→ service → 命令/查询。
- **settings** —— 只有 `domain/` + `presentation/`，**没有视图模型层**：表单直接调 service，并在组件内
  现场生成命令 ID（备份/恢复的对话框也是直接调 `BackupService`）。为 settings 加 UI 时，优先引入 notifier
  而不是继续把组件养大。它还有一处跨特性依赖，用于长按重建入口
  （`settings_screen.dart` → `features/ledger/data/projections/ledger_rebuild_service.dart`）
  —— 除 `main.dart` 这一组合根之外，唯一被认可的跨特性 data 层依赖。
- **reports** —— 没有 `commands/`、`queries/` 或 `services/`；provider 直接读
  `data/repositories/reports_repository.dart`。排序 / Top-5 截断 / 「其他」分桶聚合**曾经**在
  `report_breakdown_view.dart` 组件内做，现已收到 `ReportBreakdownMapper`
  （`presentation/models/`）—— 那个桶是一次求和，图表原本在做金额算术来给自己写标签。
- **reports 的分类合计是量值，不是净值**：`watchCategoryBreakdown` 按 kind 过滤后按分类聚合，
  每个 posting 取 `postingSignedImpact(...).abs()`。饼图答的是「这一类花了多少」，不是「净流向了哪边」，
  而且饼图根本画不了负扇区。**这里曾经存带符号的影响**，于是支出报表按降序排负数 ⇒ 最小的排最前、
  Top-5 截错了那一头；现在合计恒为正，降序即「最大的在前」。热度图不同：它按天展示**净**流量，
  依然带符号。
- 新特性一律照 **ledger** 的形态来。

## 领域模型

- `Transaction` 是聚合根（`features/ledger/domain/model/transaction.dart`）—— 一笔资金流动，拥有它的
  若干 `Posting`（分录）。五种 kind：`income`、`expense`、`transfer`（用户可选的三种），加
  `openingBalance`、`balanceAdjustment`（账本自己造的两条余额用途，见 ADR-0003，**没有分类**）。
  `TransactionKind` 的声明顺序被 Drift 按 ordinal 持久化，新值只能往后追加。分录金额**永远为正**，
  符号由 `PostingDirection` 承载（credit 使账户余额增加，debit 使其减少 —— 个人记账语义，仅定义在
  `core/domain/enums.dart`）。
- 聚合根有两扇门（ADR-0001）：面向意图的构造器（`Transaction.income` / `.expense` / `.transfer`）供
  写入方使用，`rehydrate` 供重放使用。**写入方一旦动用 `rehydrate`，就是在宣告它要绕过校验。**
  这条规则有**一处刻意的例外**：`Transaction.openingBalance()` / `.balanceAdjustment()` 是意图构造器，
  内部却经 `rehydrate` 装配 —— 因为它们的意图只是「一个账户 + 一个带符号金额」，而把符号翻译成
  `PostingDirection` 正是 `rehydrate` 那扇门（它接受已成形 posting）在做的转译。所以这两个构造器
  **不自带校验**，调用方必须自己 `validateOrThrow()`（`RecordTransactionCommand._executeBalancePurpose`
  确实调了）。要新加这类"只是装配"的构造器，先回来看这一段。
- `validate()` 校验形状：分录非空、金额为正、income/expense 恰好一条方向匹配的分录**且必须带分类**、
  transfer 是两条金额相等方向相反的分录且落在**不同**账户、**同一**币种上、两种余额用途恰好一条分录
  **且必须不带分类**（`requiresCategory` 是这条判据的唯一出处）。`validateOrThrow()` 把
  `TransactionViolation` 转成 `CommandRejected`；违规到 `LedgerErrorCode` 的映射与违规定义放在一起。
  每个写入方都在构建事件之前校验，投影器在 rehydrate 时再校验一次，以捕获损坏的事件流。
- 关于分录**所引用之物**的事实 —— 账户存在且未归档、分类同理、分类 kind 与交易一致 —— 无法放进聚合根
  （需要查库）。它们藏在 `PostingContextResolver` 之后（ADR-0002）：每个写入方都调用它，且它返回取到的
  实体而不只是结论。
- 没有专门的转账模型：信用卡还款就是一笔 savings→credit 的 transfer。周期系列不能是 transfer
  （只有一个账户 = 没有第二条腿），因此 `RecurringSeriesKind` 被收窄为 income|expense。
- `Money`（`core/domain/money/money.dart`）是「金额 + 币种」的值对象；`AccountBalance`
  （`features/ledger/domain/value_objects/account_balance.dart`）是以最小单位表示的投影余额。
  关于账户本身的规则放在 `AccountEntity`（`core/domain/entities/account.dart`）上 —— 例如
  `wouldOverdraft(amountMinor)`，其中信用账户被豁免。

## 事件溯源账本模型

- `ledger_events` 是写模型：每个事件一个 JSON payload（内嵌 `schemaVersion`），自增 id 即全局序列号（GSN），`unique(streamId, streamVersion)`，commandId 去重 —— 最后一项是在 append 时由代码校验（插入前查询）实现的，并非唯一索引。十种事件类型：`TransactionRecorded`、`TransactionReversed`（userDeleted | correction）、`AccountCreated/Renamed/Archived/TotalsInclusionChanged`、`CategoryCreated/Renamed/Archived`、`OpeningBalanceSet`。事件工厂在生产环境于 bootstrap 时注册（`register_ledger_events.dart`）；upcasting 走注册表读取，未注册的 `eventType` 也由注册表拒绝（持有信封的调用方会把事件 id 传进去，让报错点名到具体事件）。
- 读模型是写入时投影出来的 Drift 表：`accounts_view`（单个 `balanceMinor` + archived + `includeInTotals` + `lastUpdatedEventId` 游标）、`transactions_view`（一笔交易一行，含 kind、isReversed、写入时的分类快照）+ `transaction_postings_view`（分录级行）、`categories_view`、`monthly_account_balance_snapshots`。`recurring_series` 与 `scheduled_transactions_view` 豁免于 CRUD 之外（重建永不触碰）。
- **账户有两个互不相干的关闭开关，方向相反**：`archived` 把它拿出**选择器**、但留在**合计**里（`AccountArchived`）；`includeInTotals` 让它留在**一切显示的地方**、只拿出**合计**（`AccountTotalsInclusionChanged`）。术语见 `CONTEXT.md` 的 Ledger totals。
  - **排除是读时行为，不落进任何投影。** 快照行按账户存，这个开关不改变任何一行的内容，只改变**哪些行进合计**，所以投影器不因它而动（与 `AccountArchived` 一致，都不刷新快照），开关因此瞬时生效且可逆。四个合计点各自读它：`WatchMonthlySnapshotQuery`（头部三个数字里的余额与收支两半）、`reports_dao` 的三个查询（各自 `innerJoin accounts_view`——用 join 而不是事后过滤，是因为 `watch()` 只对语句里出现过的表重新发信号，否则切换开关后图表会一直停在旧数字上）、`ledger_day_group.dart`（每天的收支小计）。
  - **`accountListProvider` 永不过滤。** 它返回全部账户（含被排除合计的与已归档的），因为账户管理与建账时的币种候选都需要完整集合；账本范围本身由**设置里的当前币种**决定（见「应用流程」），不再从账户集合推导 —— 在这里过滤不会、也不应影响账本币种。
  - 被排除账户的交易**仍然出现在账本列表里**，只是不进当天小计——所以一天的行加起来可能不等于那天的合计。这是刻意的：规则只有一条，代价是看得到的东西不一定算得进旁边的数字。
- `LedgerProjectorImpl` 是唯一的投影写入方；每次 append 都在同一个数据库事务里驱动它。余额计算全部位于投影路径内部，由两个协作者分担：投影器维护 `accounts_view.balanceMinor`，`MonthlySnapshotProjectorImpl` 从锚点月份起按账户重算各月收入/支出/转账与期初、期末余额。投影路径之外任何地方都不重算余额。
- `LedgerRebuildService` 在一个事务内从事件存储重建五个事件溯源视图（启动时若某视图的 projectionVersion 过期就执行；设置页有长按开发者入口）。过期判定只覆盖带 `projectionVersion` 列的四个视图 —— `transaction_postings_view` 没有该列，它的过期只能经由 `transactions_view` 间接发现。未知事件类型硬失败，并报出事件 id。
- 更正 = `TransactionReversed(correction)` + `TransactionRecorded`，成对出现在一个命令/一个事务里；UI 删除是 `TransactionReversed(userDeleted)`。被冲销的行对读模型隐藏；审计链留在事件存储中。
- **期初余额与余额调整是两种 transaction kind，没有分类**（ADR-0003，`openingBalance` / `balanceAdjustment`）。
  `AccountService.createAccount` 只发 `AccountCreated`，账户永远从 0 开始；非零起始余额接着以一条
  `TransactionRecorded` 落账，`kind: openingBalance`、**不带分类**、`commandId` 用 `'$commandId-opening'`
  派生以便整对重试去重。「改余额」走同一个形状，`kind: balanceAdjustment`。两者都
  **出现在账本里**（用户能看到那笔钱从哪来），但**不进收入/支出、不进分类合计、不进热度图**，
  当天小计也不算它们 —— 余额动、统计不动。这不是靠"隐藏的分类"做到的，是**没有分类**：所以
  「账本里看得见、编辑页选不到」「用户自建同名分类」这两类问题不存在了。
  投影侧的关键在 `MonthlySnapshotProjectorImpl`：`net` 在 kind 分桶**之前**累加（余额），
  switch 只决定进哪个桶（统计）—— 写反了会让快照的期末余额和 `accounts_view` 对不上。
  老记录（重构前是挂在两个固定系统分类下的普通收支）由 `projectedTransactionKind` 在**投影时**重新解释，
  事件本身不动，详见那里的注释与 `balance_purpose_migration_test.dart`。`OpeningBalanceSet` 仍无生产者，
  但事件类型、注册表与投影分支**全部保留**（旧事件流仍需重放）。

## 周期与预约交易

这是账本中与预算一起**刻意不做**事件溯源的 CRUD 豁免部分（ADR-0005 / ADR-0006），也是重建存在豁免名单的原因。

- **表结构与身份（ADR-0005，v17）**：`recurring_series` 存规则（`mode`：`planned | repeating`、`frequency`、`interval`、`start_date`、`materialize_from`、`end_date`、`count_limit`、`completed_count_offset`、`rrule`、`auto_post`、`reminder_minutes`、`is_active`）；`scheduled_transactions_view` 存物理实例，主键是独立 **UUID**，配 `UNIQUE(series_id, occurrence_key)`，带 `status`（`scheduled | posted | skipped | failed`）、`manual_only` 及稀疏覆盖列（`amount_override_minor`、`date_override`、`memo_override`）。`occurrence_key` 对 `repeating` 为规则推导的**本地日历日 `YYYY-MM-DD`**（绝非 UTC），对 `planned` 固定为 `'single'`（`kPlannedOccurrenceKey`）。两张表均为 CRUD 豁免表，升级 schema（如 v17 新增 `materialize_from` / `completed_count_offset` 并迁移本地 `occurrence_key`）**不升 `ledgerProjectionVersion`**，重建永不触碰。
- **统一本地日历日展开内核（`RecurrenceExpander`）**：位于 `features/ledger/domain/recurrence/recurrence_expander.dart`（纯领域、无 DB/时钟副作用），同时被物理物化与预算虚拟投影共享：
  - `startDate` 与 `endDate` 按本地 `(year, month, day)` 交给 RRULE 推进，`BYDAY` 按本地星期语义解释，再拼回规则本地时刻生成 `scheduledDate` 与本地 `YYYY-MM-DD` `occurrenceKey`。
  - `endDate` 闭区间截断；`countLimit` 始终代表全生命周期总次数，展开时以 `countLimit - completedCountOffset` 推进剩余期次；`materializeFrom` 是允许物理物化与预算虚拟投影的下界日期，而 `startDate` 始终保留为排期与 `countLimit` 锚点。
- **层一：自然月对齐的物理物化（`ProjectRecurringEventsCommand`）**：仅面向 `isActive == true` 且关联账户 `!archived && !deleted` 的系列，每个系列在单次数据库事务内批量 `INSERT OR IGNORE`：
  - **Phase 0（休眠重启历史回填上限）**：回填 `[max(materializeFrom, startOfMonth(nowYm - 11)), now]`（最多 12 个自然月）内缺失的历史期次，单系列硬上限 **100 条（最近优先）**；返回 `MaterializationSummary`（`newlyMaterializedOverdueCount`、`hasTruncatedHistory`），供会话级 `OverdueMaterializationBanner` 提示。
  - **Phase 1（自然月对齐前瞻窗口）**：完整物化 `(now, endOfMonth(nowYm + 2)]`（当月 + 未来 2 个完整自然月），**无 `maxKeep = 3` 截断**，单系列设 `120` 条前瞻安全阀（足以覆盖 3 个自然月的每日规则）。
  - **Phase 2（低频保底）**：若 `(now, horizonEnd]` 内无任何待入账 `scheduled` 实例，继续向后探测并保底物化最近 **`minKeep = 1`** 期（如年付规则）。`planned` 系列幂等插入 `'single'`。
- **层二：预算按需虚拟投影（Overlay）与按需落库（Materialize-on-Write）**：
  - 预算读路径（`BudgetDao` / `BudgetRepositoryImpl` / `BudgetCalculator`）在 **Track / Plan**（`targetYm >= nowYm`）下用同一个 `RecurrenceExpander` 展开活跃支出系列，按 `(seriesId, occurrenceKey)` 与物理行叠加：命中 `posted` / `skipped` 则忽略（防重复计算），命中 `scheduled` / `failed` 则按稀疏覆盖列（含跨月 `dateOverride`）计算，未命中则合成虚拟待入账项计入 `pendingMinor` 与贡献列表；**Review**（`targetYm < nowYm`）绝不展开虚拟期次。记账表单实时预算提示（`watchTransactionBudgetHint`）复用同一 Overlay，已彻底移除 `hasHighFrequencyPending` / `isFarFutureMaterializedOnly` 降级标记与提示。
  - 点击预算详情页中的远期虚拟待入账项时，先经 `RecurringService.ensureMaterialized`（`EnsureOccurrenceMaterializedCommand`）在单事务内按 `(seriesId, occurrenceKey)` 幂等落库为标准 `scheduled` UUID 行，随后无缝复用既有 UUID 编辑/跳过路径。
- **桥接事件溯源、创建语义与远过去护栏**：
  - `ConvertScheduledToPostedCommand` 是通往事件溯源的唯一桥：把实例转为 `TransactionRecorded`（携带 `sourceScheduledBillId`）并在同一 append 事务内翻转状态。
  - **周期没有独立管理页**。交易表单模式选择器（`TransactionFormMode`：`defaultMode` / `planned` / `repeating`，`autoPost` 作为 `planned` / `repeating` 上的开关，重复 + 自动入账在 UI 呈现为「订阅」）只在 `canRepeat`（新建 + 非转账 + 非余额用途）时渲染。**新建系列永不把首期直接记为临时交易**：无论 `planned` 还是 `repeating`，保存时只建系列，首期统一经物化与入账流程落账，确保每笔周期实账都带 `sourceScheduledBillId`（预算归类为固定支出）。
  - **远过去起点确认（`DistantPastStartGuard`）**：新建 `repeating` 或 `updateRule` 变更基础排期使 `startDate` 严格早于「今日减 2 个自然月」时，保存前弹出两选项确认框：①「仅从今天起生成（推荐）」（`materializeFrom = startOfDay(now)`）；②「补齐最近 N 天待入账（手动核对）」（默认 30 天，允许 `1..365`，早于 `startOfDay(now)` 的历史期次全部标 `manualOnly = true`）。近过去（2 个月内且早于今日）不弹窗，但落库的历史期次同样标 `manualOnly = true`（仅当日已到期期次可即时自动入账）。
- **启动补课与自动入账熔断**：
  - `RecurringService` 是唯一服务入口（`createSeries` / `updateBill` / `deleteBill` / `restoreSkipped` / `ensureMaterialized` / `postInstance` / `materialize` / `catchUpAutoPosted` / `settleCurrencyBacklog` / `watchSeries` / `watchScheduled`）。
  - `main.dart` 启动时 `await materialize()`，首帧后执行 `catchUpAutoPosted()`（仅当前币种、确定性 `'autopost-<instanceId>'` 幂等键；批量入账结束后统一收尾执行 **1 次** `materialize()`，避免逐笔全库物化）。
  - **两道自动入账熔断**：超过 **`autoPostMaxAge = 30 days`** 的逾期自动入账实例，以及 30 天内待自动入账总数超过 **`autoPostBulkBreakerLimit = 10`** 笔的积压批次，均不静默扣款，直接标为 `manualOnly = true` 交由用户手动核对。
- **二元作用域编辑与删除（`RecurringScope`：`thisOnly` / `updateRule`，ADR-0005）**：
  - `thisOnly`：编辑仅写该 UUID 行的稀疏覆盖列（`amountOverrideMinor` / `dateOverride` / `memoOverride`），不改 UUID 与 `occurrence_key`，修改 `dateOverride` 若与同系列其他非 `skipped` 实例撞同日则拒（`scheduledDateTaken`）；删除置为 `skipped` 墓碑（可经 `RestoreSkippedBillCommand` 恢复）。
  - `updateRule`：编辑在单事务内更新系列模板；当基础排期（频率/起点等）变更时，将 `completed_count_offset` 幂等重算为当前已 `posted` 行数 `k`（校验 `count_limit >= k + 1`），清理未入账与已跳过行并重新物化；删除对 `planned` 物理删除系列与实例，对 `repeating` 置 `isActive = false` 并删除非 `posted` 行（保留历史 `posted` 行与 `sourceScheduledBillId` 关联）。
  - 已入账（`posted`）实例的编辑/删除一律拒（`scheduledAlreadyPosted`）—— 必须走交易冲正入口。
  - **账户归档**：保留已到期未处理账单为一次性 `planned` 待办（`startDate == endDate`、`countLimit == null`），将原系列置 `isActive = false` 并仅删除非 `posted` 行（保留历史 `posted` 行；恢复账户不重新激活停用系列）。
- **待入账不进账户余额、月度快照或搜索**：它在账本列表与预算 Track/Plan 视图中展示，本地提醒按最近到期优先并严格遵守 60 条系统待发通知上限。金额同样遵循正整数最小单位规则（`amountMinor`）。

## 金额约定（重要）

一律是**最小单位整型**，端到端一致。真正的分界不是「有没有符号」，而是**哪一层带符号**：

- **事件与 posting 表**：金额**恒为正**，符号由 `PostingDirection` 承载 —— `TransactionRecorded`
  的 payload 存的是一组 posting（各带 direction），不是带符号的总额。
- **交易实体与余额投影**：仓储装配出的 `TransactionEntity.amount` 带符号（支出为负、收入为正）；
  `accounts_view.balanceMinor`、月度快照同样带符号。
- **周期 / 预约实体**：`recurring_series.amount_minor` 与 `scheduled_transactions_view.amount_minor`
  **恒为正**，kind 由 `type` 列承载 —— `CreateRecurringSeriesCommand` 直接拒绝 ≤0。
  ⚠️ 本节原先声称「包括预约/周期实体」也带符号，与代码相反；`TransactionUiMapper.toPendingTile`
  当时据此依赖「写入方保证为正」而没取绝对值，一行负值就渲染成 `- -500.00`。两处现已对齐，
  mapper 的两个方向都取绝对值（有单测按这条钉住）。
- **唯一的 double 桥接点是表现层输入边界的 `Money.fromDouble`**（经 `parseMinor`）。格式化一律走
  `formatMinor`（int → 两位小数字符串）。
- **转换发生在投喂层，不在组件里。** 组件拿到的是**已写好的字符串**（或它无需转换的 int）。因此
  `formatMinor` / `.abs()` / `.toDouble()` 只允许出现在 `presentation/models/` 与
  `presentation/mappers/` —— 以及两处**输入边界**：`LedgerAmountInput` +
  `account_form_sheet` 的余额框，以及 `TransactionFormViewState`。
  这几处都是可编辑字段的桥：文本进、`parseMinor` 出。
  **交易表单那一处在 `view_model/` 而不在组件里**，因为金额的所有权在视图模型：
  状态存的是**用户敲进去的文本**（`amountText`），`formatMinor` 只在**播种**时用一次
  （`TransactionTileUiModel` → 文本，此时还没有光标），`parseMinor` 只在**用时**用一次
  （`amountMinor`）。中间绝不回流去重新格式化 —— 那会把 `12.` 改写成 `12.00`、
  每一次按键都把光标推到末尾。`LedgerAmountInput` 因此是受控的：它只报原始文本。
  做这件事的模型/映射器：`LedgerDayGroup`（每日收支合计）、`MonthlySummaryUiModel`（月度三个头条数字，
  ledger 与 reports 共用）、`ReportBreakdownMapper`（排序 / Top-5 / 「其他」桶 / 占比）、
  `AccountUiModel`（账户余额，ledger 选择器与 settings 管理页共用）、`TransactionUiMapper`。
  **一个组件里出现 `formatMinor`，就是该问「这个转换该属于谁」的信号。**
- **UI 行上的金额不带符号**：`TransactionTileUiModel.amount` 恒为正，「+ / −」由 `displaySign` 承载、
  由 kind 决定（转账为空串）。符号不是数字的属性，是种类的属性。
  唯一的例外是**余额**：透支的账户余额可以真的是负数，那是关于钱的事实，不是方向约定，所以
  `MonthlySummaryUiModel.displayBalance` 保留负号。
- **带符号的金额，负号在货币符号外面**：`- $12.34`，不是 `$-12.34`。所以有符号要落进文本时用
  **`formatMinorWithSymbol(minor, symbol)`**，不要自己把符号与 `formatMinor` 拼起来 ——
  `formatMinor` 会把负号写在数字前，一旦有人在前面加了货币符号，负号就夹在两者中间了。
  会走到这条路的是三类**真的可以为负**的金额：透支的账户余额（`AccountUiModel`）、月度余额
  （`MonthlySummaryUiModel`）、支出分类合计（`ReportBreakdownMapper` —— 分类合计存的是带符号的
  posting 影响，支出为负）。而收入/支出这类**方向由标签承载**的金额一律取正值，不出现负号。
  只有一类例外并且是刻意的：**可以输入负数的两个输入框** —— `account_form_sheet` 的余额框，以及
  `LedgerAmountInput` 在余额用途页上的形态 —— 它们的内容必须能被 `parseMinor` 解析，所以符号只能留在
  数字里、货币符号画在它前面（渲染成 `$ -12.34`）。输入框不是展示位。
  **为什么只有余额用途的金额框带符号**：收入/支出/转账的方向由 kind 承载，数字再带一个符号就是同一个
  问题第二个、可能互相矛盾的答案；期初余额与余额调整没有这样的 kind —— 符号**就是**方向 ——
  所以那一页的数字框收 `-`（物理键盘的 `+` 以及退格删掉负号则回到正值），
  `TransactionFormViewState.amountMinor` 在那一页是带符号的，`signedAmountMinor` 直接取它。

## 失败处理

- 每个 service 写方法都返回 `Result<T>`（`core/domain/result/result.dart`）：`Success`，或
  `Failure(LedgerErrorCode code, String message)`。命令用抛出 `CommandRejected` 来表示写入被拒；
  service 的 `guard(...)` 包装器是**唯一被认可把异常转成 `Result` 的地方**（意外异常会落到
  `unknownEvent`，并带上原始错误文本）。任何异常都不得越过 service 边界进入视图模型。
- 视图模型用模式匹配 —— `if (result case Failure(:final code))` —— 并用 `code.message(l10n)`
  （`shared/presentation/ledger_error_localizer.dart`）渲染本地化文案，这是表现层唯一的失败渲染点。
  `Failure.message` 是给日志用的英文开发者文案，不是给 UI 的。
- `LedgerErrorCode` 是**封闭集合**。多数 code 有 `error<CodeName>` 形式的 ARB 键；`invalidAmount` 是
  命名上的例外；而缺少 ARB 键的 code 会回落到 `errorPrefix(code.name)` —— 这会把原始枚举名直接展示给
  用户。因此新增一个 code，就意味着在所有语言里补齐它的 ARB 条目。

## 表现层：设计令牌与本地化

- 设计令牌是 `lib/app/theme/app_theme.dart` 里的 `ThemeExtension`，通过 context 扩展取用：
  `context.spacing`（`AppSpacing`）与 `context.colors.income` / `.expense`（`AppSemanticColors`
  —— 收入/支出配色的唯一决定处）。
- 字体排版来自 `AppTheme.textTheme`。ledger 专用角色（`balanceText`、`transactionAmount`、
  `denseLabel`、骨架屏填充色……）是 `features/ledger/presentation/theme/ledger_theme.dart` 里的
  `LedgerTheme` 辅助方法，它们从 `Theme.of(context).textTheme.*` 出发，只叠加字重/颜色 —— 新的字号放
  在那里，不要内联在组件里。
- **全部图标用 `lucide_icons_flutter`**（`LucideIcons.*`）。框架自己画的图标（日期/时间选择器的
  外观、`DropdownButton` 的箭头、`Checkbox`/`Radio` 字形）改不了，除非替换掉那些组件本身；**AppBar 的
  返回箭头属于这一类** —— 默认那个是 Material，所以每个可返回的页面都要显式给 `leading`。
- 用户可选的分类颜色与图标是**数据，不是令牌**：`CategoryTokens`
  （`lib/app/theme/category_tokens.dart`）是调色板 + 图标码点集合，`defaultColor` /
  `defaultIcons.first` 是新分类的默认值。
- **分类图标是持久化数据，换字体就是换数据**：图标码点存在 `iconKey` 里（事件 payload、`categories_view`
  与 `transactions_view` 的写入时快照都有一份）。`category_tokens.dart` 的 `_palette` 是
  **(v1 存的, v2 存的)** 配对表——既是当前调色板，也是 upcaster 的翻译表，一份数据两个用途，
  所以不会各自漂移。渲染只经 `CategoryTokens.iconFor(iconKey)`，它也是唯一知道图标字体名的地方。
- 本地化：ARB 文件在 `lib/app/l10n/`，模板是 `app_en.arb`。共有**四个**：`en`、`zh_Hans`、`zh_Hant`，
  以及一个不带 script 的 `zh` 基础文件 —— 只要存在带 script 的语言，`flutter gen-l10n`
  就**要求**它作为回退（内容镜像简体，需保持同步）。新增键要加进全部四个文件，然后跑
  `flutter gen-l10n`；永远不要手改 `app_localizations*.dart`。
  **ARB 触不到的两处用户可见文案**：一是 Android 启动器名，在
  `android/app/src/main/res/values{,-zh-rCN,-zh-rTW}/strings.xml`，必须与 `appTitle` 保持一致
  （少了 `-zh-rTW`，繁體设备会在桌面上看到英文名）；二是平台文件选择器的类型标签，由调用方把
  `l10n` 文案传进去（provider 没有 context）。iOS 侧（`CFBundleDisplayName` + 尚未存在的
  `.lproj/InfoPlist.strings`）**没有做**。
- `AppLanguages.supportedLocales`（`lib/app/config/app_languages.dart`）是可选语言集合；偏好里存的是
  完整 language tag，因此简体 / 繁體重启后仍保留。不要把它退回成只存 `languageCode`。

## 数据可携带性与恢复（spec 004）

- **表单的逻辑在 `TransactionFormViewModel`**（`presentation/view_model/`，配 `TransactionFormViewState`），屏幕只渲染：字段的状态转移、按 kind 分派写入、超支判断、系列创建、附件导入与丢弃都在视图模型里；打开选择器/日期选择器、弹确认框、显示失败文案留在屏幕 —— 它们要 `BuildContext`。三条容易踩的约定：
  - **`build()` 不 watch 任何会变的东西。** watch 账户/分类流看起来无害，实际是每次流推送都重跑 `build()`、把用户填了一半的表单清空。需要那些列表的规则是 `TransactionFormViewState` 上的纯方法（`activeAccounts` / `transferDestinations`），由屏幕把已经 watch 到的列表喂进来。
  - **表单的参数就是 provider 的参数**：`transactionFormViewModelProvider(transaction)`。notifier 不能在 `initState` 里播种（Riverpod 禁止在组件生命周期里改 provider），而且「下一帧再填」会先闪一帧空表单。这个 family 的参数在表单生命周期内**不变** —— 与 `SearchViewModel` 拒掉的那种「参数每次按键都变」不同。
  - **提交结果是密封类**（`TransactionFormSaved` / `TransactionFormSavedSeriesFailed` / `TransactionFormSaveFailed`）：视图模型从不碰 SnackBar、对话框与路由，失败只带 `LedgerErrorCode`。超支不是结果的一种，而是写入**之前**的问题（`wouldOverdraft()`），所以屏幕问、视图模型判断。
- **三种 kind 共用一个表单**：`transaction_form_screen.dart` 承载收入/支出/转账（用户能选的就这三种，账本自己造的两种余额用途只在这条表单上**以只读形式**出现）。kind 决定**哪些字段存在** —— 转账有两个账户、没有分类；收支有一个账户、一个分类。不适用的字段根本不渲染，因此「带分类的转账」「只有一个账户的转账」不是这个表单能进入的状态。**不要**把它改回按 kind 拆成两个屏幕，也不要让某个 kind 渲染它承载不了的字段。
- 路由只有 `/ledger/add` 与 `/ledger/edit`：kind 由表单**自己的类型选择器**决定，或（编辑时）由 `extra` 里的交易决定。**转账没有独立入口**——账本页右上角的转账按钮已移除，转账在表单里面选。不要为某个 kind 再加一个路由或快捷入口。
- `LedgerTypeSelector` 收一个 `kinds` 列表：交易表单传默认三种（**用户能选的只有这三种**）。模式选择器
  （默认/计划/重复，配 `autoPost` 开关）与「重复」行都**只在 `canRepeat`**（新建 + 非 transfer + 非余额用途）时渲染 ——
  一个系列只有一个账户，transfer 对它不可表达（ADR-0002），编辑不碰系列。频率属于模式（见「周期与预约交易」节）。
- **两种余额用途不是"用户能选的 kind"，所以表单不为它们渲染选择器**：编辑一条 `openingBalance` / `balanceAdjustment` 时，kind 那一行、分类那一行、账户选择器都换成只读的 `LedgerDetailRow`（账户不能改、分类不存在、"重复"也不给）。往一个只认三种的表单里塞第四种会当场炸——`SegmentedButton` 的 `selected` 必须在 `segments` 里。
- 「到」账户的候选按「从」账户的币种过滤，让跨币种组合**不可选**而不是写完再拒。同账户同理（候选排除 + 一条兜底校验）。
- 金额输入框的币种符号：转账用「从」账户的币种（两条腿同币种），收支用全局显示偏好。
- 更正的合法路径由**原交易的 kind** 决定：transfer 原交易只能经 `executeTransfer`，收支原交易只能经 `execute`，两种余额用途另有一条。**这里的 kind 读的是投影**（`transactions_view.kind`），也就是 `projectedTransactionKind` 的解释结果，不是事件 payload 里那个——见 `ledger_events.dart` 上的注释。
- **检索**：`TransactionFilter`（值对象，手写 `==`/`hashCode` —— Riverpod 按 `==` 去重 state）→ `TransactionsDao.watchTransactionsFiltered` → `LedgerRepository.watchTransactionsFiltered`（复用既有的 `_toTransactionEntities`，不写第二个装配器）。两个刻意之处：`isReversed` 在 **SQL** 里过滤（查询层不再过滤第二次），账户/分类筛选用子查询选出**哪些交易**合格、再返回它们的**全部** posting —— 转账因此不会被截成单腿。
- **导出**：`transactionsToCsv` 是纯函数（RFC 4180 转义、ISO 日期、枚举名而非译名、前置 UTF-8 BOM）；`TransactionExportService` 只负责落盘与分享。导出的是**屏幕上那些行**，无结果时按钮禁用。
- **备份**：`VACUUM INTO` 产出一致快照（不是复制文件），连同偏好与 manifest 打成一个 `.flbackup`。恢复是**替换**语义，且**只暂存不就地应用**——数据库整个运行期都被打开，替换只能发生在下次启动、任何东西读取 `db.sqlite` **之前**。
- 暂存区标志是**文件**（`restore/PENDING`）而非 SharedPreferences 键：它必须早于任何 provider 存在时可读，而且恢复本身会覆盖偏好。
- 替换时**必须删除陈旧的 `-wal`/`-shm`/`-journal`**：旧库留下的 `-wal` 会被重放进恢复后的库，静默损坏。
- 校验在写 PENDING **之前**全部完成：容器 format/formatVersion、库的 schemaVersion（读 SQLite 头，不打开文件——打开会跑迁移并改写待校验的那份副本）、`PRAGMA integrity_check`、以及**用真实 DAO 读一次事件表**。最后一项不可省：一个事件溯源迁移**之前**的库 user_version 同样是 1、integrity_check 同样通过，但本 build 根本读不了它。
- **`android:allowBackup="false"` 是刻意的，不是模板残留**：清单不写这一行时默认是 `true`，于是 Android 会把整个 `files/`（含 `db.sqlite`，即全部账本）备份进 Google Drive，**卸载重装时原样倒回来** —— 看起来像「卸载没用」或「播种又跑了一遍」，实际两者都没发生，是系统还原了一个非空事件存储（`firstInstallTime` 是新的，库里的交易却是旧的，这就是判据）。账本的自有备份是 `.flbackup`（用户显式导出、显式恢复），不该再有一份用户没点过头的云端副本。iOS 侧同类问题需要给容器加 `NSURLIsExcludedFromBackupKey`，尚未处理。

## 应用流程

- `main.dart`：手动 `ProviderContainer` → 打开 `db.sqlite`（后台 isolate）→ `seedDatabase`（**只播分类**：CategoryCreated × 15；名称在播种时本地化；以事件存储为空为幂等条件）→ 过期则重建检查 → 周期补课（幂等，失败不阻断启动）→ 应用恢复出的偏好 → `runApp`。
  **首次安装播的是词汇，不是钱**：分类是用户往里装自己的钱的词表，可以预置；**账户和交易不行** —— 账户是钱本身，此刻一分都还没有。曾经播过的 Cash / Bank Card（其中 Bank 带 1000.00 期初余额）会把别人的期初余额显示在主页上，币种还是播种当时的全局默认值。因此全新安装的主页是空的，记账前需要先建一个账户（选择器里有「管理账户」入口），账本页与选择器各自有对应的空态文案。
  **播种里没有系统分类了**：余额用途有自己的 kind（ADR-0003），所以账本自己记的东西不再借用分类，seeder 也就不再预置那两条。老库里它们仍在（`categories_view` 里挂着 `systemCode`，被 `watchCategoriesByType` 从所有选择器与管理页滤掉），**没有生产者、也没有引用者**，但**不能删** —— `reversal*Id` 是 `projectedTransactionKind` 认出老记录的唯一凭据，删了会让历史上每一次余额更正重新变成收入。详见 `CategoryConstants` 上的注释。
  **分类名是播种时写进事件 payload**（`CategoryCreated.name`，并快照进 `transactions_view.category_name`）的，所以改 ARB 只影响新装，已有的库保留旧名。
  **顺序是承重的**：`applyPendingRestore` 必须早于任何 `appDatabaseProvider` 读取，否则替换会在活句柄下失败或更糟——成功。该函数之前不得读数据库或任何会读数据库的 provider。
- **账本的币种由设置里的当前币种决定，不由账户集合决定**（spec 006）：`ledgerCurrencyProvider` 直接取
  `currencyControllerProvider.value ?? default`，头部、列表行、详情抽屉、检索页与报表的货币符号全部经
  `displayCurrencySymbolProvider` 跟它走 —— 不再有第二个答案。账户各自锁定创建时的币种且永不改变，
  所以「账本范围」与「账户集合」是两个不同的维度：切到没有账户的币种时，账本列表与合计显示空态 +
  建账户提示（账户仍可在账户管理里看到），这是刻意的，不是数据丢失。
  **这个答案会变，而且第一次给出来时可能还是错的**：设置尚未解析时 `ledgerCurrencyProvider` 答不出
  「账本的币种」，于是回退到内建默认 USD。所以**任何消费它的流/订阅都必须 `ref.watch`，不能 `ref.read`**
  —— 曾经 `LedgerViewModel` 手工订阅月度合计时 `ref.read` 了一次，于是 zh 语言的全新安装在第一帧抓到
  USD、随后设置解析成 CNY，头部就对着 ¥1000 的账本读 `$0.00`（收入/支出同一个码、同样为 0），**只有
  切换月份能救**，因为那是唯一重新读一次的地方。现在合计是 `ledgerMonthlySummaryProvider(month)`：
  月份与币种都是 `ref.watch`，Riverpod 自己重订阅。它的回归测试是
  `test/unit/features/ledger/presentation/ledger_summary_currency_test.dart`（把 `watch` 改回 `read`
  会失败，已变异验证过）与 `ledger_currency_test.dart`（「the setting decides, not the accounts」钉住
  设置优先于账户集合）。
- 路由：`StatefulShellRoute` 三个 tab —— `/ledger`、`/reports`、`/more`。`/ledger/add`、`/ledger/edit`、`/ledger/search` 推在根导航器上，前两者都指向 `TransactionFormScreen`；账本页的 app bar 只有搜索一个入口（FAB 保持直达 `/ledger/add`，三种 kind 都在那个表单里选）。`/accounts_management`、`/categories_management` 是顶层路由，也是这两种管理页**唯一**的路由（`/more/accounts`、`/more/categories` 已删：选择器里已经能到，More 只是一扇并列的门）。**从 More 点开的每一项都盖在 shell 之上、不共享底部导航栏**：`/more/settings` 与 `/more/about` 带 `parentNavigatorKey: _rootNavigatorKey`（与 `/ledger/add` 同一手法），管理页走的两个顶层路由本来就是。调用一律用 `push`，让返回能回到那个 tab。每项都带一行副标题说明它打开什么（`settingsHint` …）。`test/ui/features/settings/more_screen_test.dart` 用真实 router 跑这条线，**去掉 navigator key 它会失败**（已变异验证过）。
- 账本状态：`LedgerViewModel`（keepAlive notifier）只持有选中月份与各账户余额 —— **月度合计不在它手里**，
  见上面那条；交易列表直接监听 `ledgerMonthlyTransactionsProvider(month)` family（经 `TransactionUiMapper` 映射，并按天分组 —— 两者都在 provider 内部完成，不在组件里；它把该月的**待入账**实例一并合进同一张表，同一天内已入账在前）。头部读 `ledgerMonthlySummaryProvider(month)`。三个头条数字里**只有两个属于该月**：收入与支出来自 `monthly_account_balance_snapshots`（与报表页同源），
而标签写着「全部余额 / Total Balance」的那个数字**是账本当前的实时总额**（`accounts_view` 按币种求和，含已归档账户），
**不随月份变化**。这个语义来回改过一轮，两次都被报成 bug，所以把两边的理由都记下来：
把它读成「该月期末余额」时，投影链只物化到今天（或最后一个未来事件），**未来月份根本没有快照行**，
于是账本明明有钱而头部显示 0；而且除当月外，卡片上那个词都在撒谎。反过来实时总额的代价是：
过去月份显示的是今天的钱 —— 这正是「报表页」的语义，所以报表页那一格现在叫 **期末余额**
（`monthEndBalance`）并继续读该月快照的 `closingBalanceMinor`，两个屏幕从此各说各话、各自诚实。
`WatchMonthlySnapshotQuery` 因此有两个数据源（它同时持有 `MonthlySnapshotDao` 与 `AccountDao`），
并以**账户流**作为触发信号：任何移动余额的写入都会在同一事务里盖账户行的时间戳并重写该月快照行。检索有自己的视图模型（`SearchViewModel`），`RecurringViewModel` 只剩三个写动作。
- 偏好设置走 SharedPreferences（`PreferencesRepository`）：主题模式、语言、币种、余额可见性；另有 `exportAll`/`importAll` 供备份使用，**只针对已知的四个键**。

## 测试布局

- `test/unit/` 对应 `lib/` 的 service、model、events 与 repository；`test/ui/` 放组件行为测试；`test/support/` 放 fake、mock、fixture 以及 service harness。
- 覆盖并不均匀，且缺口是已知的：**没有 `domain/commands/` 测试**（命令只通过 service 测试被间接覆盖）、
  **7 个 DAO 只测了 2 个**（`account_dao`、`transaction_dao`）、`lib/app/**`、`lib/shared/**`、
  `core/presentation/**` 没有测试；还有一个 repository 测试
  （`test/unit/features/settings/data/repositories/account_repository_test.dart`）所在的路径其实什么都不
  对应 —— 它测的是 `core/data/repositories/account_repository.dart`。ledger 切片的覆盖度远高于其他。
- 事件序列化测试走生产注册表（`registerLedgerEvents()`）；不存在仅供测试的工厂注册。

## 必须遵守的实践

- 表现层组件内不放业务逻辑；状态与协调用 Riverpod provider。
- 不得硬编码面向用户的文案、颜色或特性内排版。使用本地化、`Theme.of(context)` 以及上面的令牌。
- 逻辑要有单元测试，UI 行为要有组件测试。
- 每次代码调整后都要运行 `flutter analyze` 并报告失败项。

### 容易踩坑的不变量

- **业务时间靠参数传入。** 命令接收 `occurredAt`（用户选择的日期），不得调用 `DateTime.now()`。仅有的
  两处墙钟读取是 `MonthlySnapshotProjectorImpl` 的「今天」（经由注入的 `DomainClock` ——
  `core/domain/clock/clock.dart`）和 `ProjectRecurringEventsCommand` 的物化时间上限。
- **每个写命令都要 `commandId`** —— 在调用处用 `Uuid().v4()` 生成。去重按 commandId 生效，而更正事件对
  是刻意共用同一个的。
- **被冲销的行是在查询层过滤的**，不是 DAO（`watch_transactions_query.dart`）。新的 DAO 调用方会看到
  被冲销的行；要么显式过滤，要么走 query。
- **余额只在投影路径内计算。** 如果某个组件或查询在做余额算术，那段逻辑应该属于投影器或月度快照投影器。
- **`ref.read` 是一句承诺：「这个值不会再变」。** 用它去喂一个长命的订阅（notifier 的字段、手工
  `listen`、缓存的流），就是在向框架隐藏一条依赖 —— Riverpod 看不见，也就永远不会失效。**派生的、
  可能变的 provider 一律 `ref.watch`**，要的是「变了就重来」就把它写成 provider（`ref.watch` 进
  参数），而不是在 notifier 里手搓 `StreamSubscription` + 手动重订阅。上面 `ledgerCurrencyProvider`
  那条就是这么坏掉的：读一次，然后对着另一个币种的账户读到会话结束。
- **改动事件 payload 或新增事件类型**意味着要动 `register_ledger_events.dart` 里的注册表，并遵守
  constitution VII：一旦发布，payload 变更就要升 `schemaVersion` 并附带 upcaster，而已发布的
  `eventType` 永不改名。**首例就是 `CategoryCreated` v1→v2**（图标从 Material 码点换成 Lucide 码点）
  —— 一个字段的*含义*变了就得升版本，upcaster 负责读旧值。同时把 `ledgerProjectionVersion` 升到 2：
  视图是从事件重建的，**只改投影不改事件会被下一次重建冲掉**，而版本号过期正是启动时触发重建的开关。
  `categories_view.icon_key` 与 `transactions_view.category_icon` 两处都要重新推导，实测迁移路径见
  `test/unit/features/ledger/data/category_icon_migration_test.dart`。
  **反例（同等重要）：能不改已发布的 payload 就别改。** `includeInTotals` 是账户上线后才加的属性，
  但它没有把 `AccountCreated` 升到 v2 —— 「新建时就不计入」走的是**第二个事件**（`AccountCreated` +
  `AccountTotalsInclusionChanged`，`commandId` 派生为 `'$commandId-inclusion'`），与「期初余额 = 建账户
  + 一笔交易」同一手法。列默认值 `true` 覆盖了所有旧账户，于是这里既不需要升版本，也不需要 upcaster：
  **一个常量不值得换来一份永久契约。**
- **Drift `schemaVersion` 与重建版本号是两回事，但改列时两个都要动。** `schemaVersion` 从 1 升到 2 是因为
  `accounts_view` 多了 `include_in_totals`（`onUpgrade` 里 `addColumn`）；`ledgerProjectionVersion` 升到 3
  则是让每一次启动都重推一遍——**迁移因此是自愈的**：不管 ALTER 留下了什么，投影都会从事件重新导出。
  **例外先例（v5、v17）**：`recurring_series` 加 `auto_post`（v5）以及加 `materialize_from` / `completed_count_offset`
  并迁移本地 `occurrence_key`（v17）时只升了 `schemaVersion`，
  **没升** `ledgerProjectionVersion` —— 那两张表是 CRUD 豁免、不从事件重建，重推版本号纯属空转。
  ⚠️ `onUpgrade` **只能用 `addColumn`，绝不能 `deleteTable`/`createTable`**：`LedgerRebuildService.isStale()`
  是四个视图版本号汇成列表后 `.any(...)`，**空表返回 false**，派生表被删空就再也不会触发重建，账本会在事件
  存储完好的情况**永久空白且不报错**。回归测试：`test/unit/core/database/app_database_test.dart` 里那条
  「migrates a v1 database by adding the column, keeping its rows」。
  **恢复校验因此是单向的**：`backup_service` 两道版本闸门（manifest 与 SQLite 头的 `user_version`）都只拒
  **更新**的库，更旧的由 `onUpgrade` + 重建带上来。别把它改回 `!=`，否则用户手上已有的 `.flbackup` 全部作废。
- 加了 Riverpod/Drift/json 注解后跑 `dart run build_runner build -d`；改了 ARB 后跑 `flutter gen-l10n`。

## 常用命令

- `flutter pub get`
- `dart run build_runner build -d`（改动带注解的代码后，重新生成 Riverpod/Drift/json_serializable 的 `.g.dart` 文件）
- `flutter test`
- `flutter analyze`


## Agent skills

### Issue tracker

Issues are tracked as local Markdown under `.scratch/`. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage labels use their default names. See `docs/agents/triage-labels.md`.

### Domain docs

This repository uses a single-context layout. See `docs/agents/domain.md`.
