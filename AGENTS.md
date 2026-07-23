# Feather Ledger —— Agent 指南

## 项目背景

- 个人记账应用：账户、收入/支出交易、周期计划、月度报表。三语（en / zh_Hans / zh_Hant），Material 3。
- Flutter/Dart，严格 MVVM、Riverpod（codegen）、Drift/SQLite、GoRouter、基于 ARB 的本地化、报表用 fl_chart。
- 权威工程原则见 `.specify/memory/constitution.md`，改代码前必须先阅读并遵守。
- 特性规格与计划位于 `specs/`。当前的事件溯源工作见 `specs/003-event-sourced-ledger/`。
- `CONTEXT.md`（仓库根目录）是统一语言（ubiquitous language）——命名新概念或新类型前先读它。已决策记录在 `docs/adr/`（0001：聚合根跑在写路径上；0002：posting context 是独立接缝）；审计与研究在 `docs/reports/` 和 `docs/research/`。

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

- `domain/commands/` —— 写用例。发出领域事件，经 `DriftEventStore.append` 持久化，并由 `LedgerProjectorImpl` 在同一个数据库事务内投影。**例外**：周期链路的两个命令（创建系列/删除账单）直接写 CRUD 豁免表、不发事件、因此也没有 `commandId`。
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
  若干 `Posting`（分录）。三种 kind：`income`、`expense`、`transfer`。分录金额**永远为正**，符号由
  `PostingDirection` 承载（credit 使账户余额增加，debit 使其减少 —— 个人记账语义，仅定义在
  `core/domain/enums.dart`）。
- 聚合根有两扇门（ADR-0001）：面向意图的构造器（`Transaction.income` / `.expense` / `.transfer`）供
  写入方使用，`rehydrate` 供重放使用。**写入方一旦动用 `rehydrate`，就是在宣告它要绕过校验。**
- `validate()` 校验形状：分录非空、金额为正、income/expense 恰好一条方向匹配的分录、transfer 是两条
  金额相等方向相反的分录且落在**不同**账户、**同一**币种上。`validateOrThrow()` 把
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

- `ledger_events` 是写模型：每个事件一个 JSON payload（内嵌 `schemaVersion`），自增 id 即全局序列号（GSN），`unique(streamId, streamVersion)`，commandId 去重 —— 最后一项是在 append 时由代码校验（插入前查询）实现的，并非唯一索引。九种事件类型：`TransactionRecorded`、`TransactionReversed`（userDeleted | correction）、`AccountCreated/Renamed/Archived`、`CategoryCreated/Renamed/Archived`、`OpeningBalanceSet`。事件工厂在生产环境于 bootstrap 时注册（`register_ledger_events.dart`）；upcasting 走注册表读取，未注册的 `eventType` 也由注册表拒绝（持有信封的调用方会把事件 id 传进去，让报错点名到具体事件）。
- 读模型是写入时投影出来的 Drift 表：`accounts_view`（单个 `balanceMinor` + archived + `lastUpdatedEventId` 游标）、`transactions_view`（一笔交易一行，含 kind、isReversed、写入时的分类快照）+ `transaction_postings_view`（分录级行）、`categories_view`、`monthly_account_balance_snapshots`。`recurring_series` 与 `scheduled_transactions_view` 豁免于 CRUD 之外（重建永不触碰）。
- `LedgerProjectorImpl` 是唯一的投影写入方；每次 append 都在同一个数据库事务里驱动它。余额计算全部位于投影路径内部，由两个协作者分担：投影器维护 `accounts_view.balanceMinor`，`MonthlySnapshotProjectorImpl` 从锚点月份起按账户重算各月收入/支出/转账与期初、期末余额。投影路径之外任何地方都不重算余额。
- `LedgerRebuildService` 在一个事务内从事件存储重建五个事件溯源视图（启动时若某视图的 projectionVersion 过期就执行；设置页有长按开发者入口）。过期判定只覆盖带 `projectionVersion` 列的四个视图 —— `transaction_postings_view` 没有该列，它的过期只能经由 `transactions_view` 间接发现。未知事件类型硬失败，并报出事件 id。
- 更正 = `TransactionReversed(correction)` + `TransactionRecorded`，成对出现在一个命令/一个事务里；UI 删除是 `TransactionReversed(userDeleted)`。被冲销的行对读模型隐藏；审计链留在事件存储中。
- **新建账户时的「期初余额」也是一笔更正交易**（`AccountService.createAccount`）：`CreateAccountCommand` 只发 `AccountCreated`，账户永远从 0 开始；非零起始余额接着以 `TransactionRecorded` 落账，走与「改余额」完全相同的路径（同一个系统分类、`note` 由调用方本地化传入，`commandId` 用 `'$commandId-opening'` 派生以便整对重试去重），因此会出现在账本里、也会计入当月收入/支出合计 —— 这是刻意的：账本对「这笔钱哪来的」只有一个答案。两个副作用要知道：其一，起始余额从此**计入当月收入**而不是期初；其二，`OpeningBalanceSet` 不再有生产者，但事件类型、注册表与投影分支**全部保留**（旧事件流仍需重放），`abs()` 那条老毛病（负的期初被记成正的）也随之消失 —— 符号现在由 kind 承载。

## 周期与预约交易

这是账本中唯一**刻意不做**事件溯源的部分，也是重建存在豁免名单的原因。

- `recurring_series` 存规则（frequency、interval、start/end、count）；`scheduled_transactions_view`
  存物化出来的实例，状态为 `scheduled | posted | skipped | failed`。两者都是 CRUD 表 —— 直接写入，
  永不重建，投影器永不触碰。
- `ProjectRecurringEventsCommand` 用 `package:rrule` 按**滚动 90 天窗口、夹在 [3, 12]** 物化实例：
  填满窗口；窗口内不足 3 个就继续向后取到 3 个（上限再放 3 年，兜住每年规则）；任何时候不物化超过 12 个。
  于是 每月→3、每周→12、每年→3、每日→12，不需要按频率写规则。id 形如
  `'${series.id}_${date.millisecondsSinceEpoch}'`，因此重复执行是幂等的 —— **不要改这个 id，也不要改
  日期归一化方式**，否则每次运行都会凭空多出一整套账单。已经被用户 posted / skipped 的实例既不计数、
  也不复活。**`getInstances` 的 `before:` 必须传**：它只在 `before` / `until` / `count` / 年份 9999
  处停止，改用 `.where` 过滤会让一个今年开始的月度系列跑 ~95,600 步才产出视野内的 ~20 个实例（实测
  每系列 ~37 秒，而本命令跑在启动路径上）。生成器还断言 `before >= start`，起始日晚于上界的系列必须短路。
- `ConvertScheduledToPostedCommand` 是通往事件溯源世界的桥：一个实例变成真正的 `TransactionRecorded`，
  **并且**它的状态在同一个 append 事务里翻转。
- 这里的金额与币种代码同样遵循最小单位规则（`amountMinor`）。
- `RecurringService` 是这条链路唯一的服务入口（`createSeries` / `deleteBill` /
  `postInstance` / `materialize` / `watchSeries` / `watchScheduled`）；
  三个写命令直接写 CRUD 表，不发事件，因此也**没有 `commandId`**（幂等键没有消费者）。
- 创建系列后立刻物化，`main.dart` 启动时也物化一次（幂等，且失败不阻断启动）。
- **周期没有自己的页面。** 规则在交易表单里设置（非转账的新建交易上有一行「重复」，`interval` 固定为 1，
  保存时「先记账、后建系列」，`startDate` 取所选日期的下一次发生），待入账账单直接**混在账本列表里**
  按天分组展示：降透明度 + 时钟图标 + 「待入账」标签，点开是记入 / 编辑 / 删除。编辑是右上角的铅笔、
  删除是它旁边的**溢出菜单**，与已入账交易的详情抽屉**共用同一个 `LedgerDeleteMenu`** —— 同一个手势、
  同一个角落、同一个错误色，两者的入口因此不会各自漂移。`RecurringViewModel`
  只持有这些写动作，没有状态 —— 实例本身经 `ledgerMonthlyTransactionsProvider` 进列表。
  曾经存在的 `/more/recurring`、`/recurring_management`、`RecurringListScreen`、
  `RecurringSeriesFormSheet` 都已删除。
- **删除有三个作用域**（`DeleteRecurringBillCommand`），区别不在「删掉哪一行」而在**对系列做了什么**——
  因为账单是由规则重新推导出来的，只删行的话下次物化会让它原样长回来：
  - `thisOnly` 把实例置为 `skipped`。那个状态就是**物化拒绝复活的墓碑**，规则继续走，被删的那一期不会
    再出现。
  - `thisAndFollowing` 把系列的 `endDate` 设到**该账单的前一天**（`until` 是闭区间，同一天会让它当场
    长回来），再硬删从该日起的 `scheduled` 实例。已入账的实例不动 —— 那笔钱真的动了。
  - `all` 删掉系列本身连同它全部实例行。**已入账的交易不受影响**：它们是 `TransactionRecorded` 事件、
    自成一体的账，跟着消失的只是包在它们外面的排期外壳。
  - 三个作用域都不写事件、不动钱，所以也没有 `commandId`。删除一个**已入账**的实例会被拒
    （`scheduledAlreadyPosted`）—— 那是冲正，是另一件事、另一个入口。
  - 曾经的「停用」与「跳过」已被这三个作用域吸收：跳过的语义就是 `thisOnly`，停用的语义就是
    `thisAndFollowing` 少删几行，两个入口并存等于同一件事说两遍。
- **编辑与删除共用同一组作用域**（`RecurringScope`：`thisOnly` / `thisAndFollowing` / `all`），
  由同一个 `RecurringScopeDialog` 提问。删除没有表单，所以**先问后做**；编辑**先编辑、保存时才问**
  （问的是「这次改动影响到哪」）。
  一行实例只存 `date` 与 `amountMinor`；分类 / 账户 / 描述属于系列、读取时才解析出来。于是编辑表单
  **永远给全部字段**（保存前还不知道答案，不能按未定的答案藏字段），而对话框在用户改过那三个字段时
  **把「仅该项记录」置灰并说明原因** —— 而不是收下改动再丢掉一半。这是 Google Calendar 遇到同一个
  墙时的做法（「不能只改这一次的日历」）。
  - `thisOnly` 改金额就地改；改日期则在新日期上新建一行、并在**原日期留一个 `skipped` 墓碑**
    （否则规则下次物化会把它放回去）。若新日期上这条规则本来就有账单一律拒绝（`scheduledDateTaken`）——
    否则会变成同一天两笔，其中一笔还瞒着物化。
  - `thisAndFollowing` 是**拆分**：旧系列结束在该账单前一天，从新值起一条新系列，并把旧系列已入账的
    日期在新系列里补成墓碑（那天的钱已经动过，不能再出一笔）。
  - `all` 重写系列模板，并**删掉待入账行重新物化**——行的 id 编码了日期，档期一平移旧 id 就全过期，
    而过期的 id 在物化看来就是「缺失」，会把每个日期再记一遍。
  - 编辑**已入账**的实例同样被拒（`scheduledAlreadyPosted`）：那是冲正，另一个入口。
- **待入账是「还没发生」**：它不进入余额、月度合计或搜索（搜索只读 `transactions_view`，实例不在其中），
  只在展示层出现。它变成真实交易的唯一路径仍是 `ConvertScheduledToPostedCommand`。
- 实例 id 由 `scheduledInstanceId(seriesId, date)` 唯一决定（`domain/entities/ledger_entities.dart`）。
  物化与编辑都靠它幂等 / 判重，**改它的形状等于把每一笔账单翻倍**。

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
  `presentation/mappers/` —— 以及两个**输入边界**组件：`LedgerAmountInput` 与
  `account_form_sheet` 的余额框。这两个是可编辑字段，用十进制文本作初值、用 `parseMinor` 读回，
  是同一枚硬币的两面，属于 AGENTS 已承认的输入桥接，不是漏网的展示转换。
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
  只有一处例外并且是刻意的：`account_form_sheet` 的余额**输入框**，其内容必须能被 `parseMinor` 解析，
  所以符号只能留在数字里、货币符号作为 `prefixText` 装饰（渲染成 `$ -12.34`）。输入框不是展示位。

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

- **三种 kind 共用一个表单**：`transaction_form_screen.dart` 承载收入/支出/转账。kind 决定**哪些字段存在** —— 转账有两个账户、没有分类；收支有一个账户、一个分类。不适用的字段根本不渲染，因此「带分类的转账」「只有一个账户的转账」不是这个表单能进入的状态。**不要**把它改回按 kind 拆成两个屏幕，也不要让某个 kind 渲染它承载不了的字段。
- 路由只有 `/ledger/add` 与 `/ledger/edit`：kind 由表单**自己的类型选择器**决定，或（编辑时）由 `extra` 里的交易决定。**转账没有独立入口**——账本页右上角的转账按钮已移除，转账在表单里面选。不要为某个 kind 再加一个路由或快捷入口。
- `LedgerTypeSelector` 收一个 `kinds` 列表：交易表单传默认三种；「重复」行只在非 transfer 时才渲染 —— 一个系列只有一个账户，transfer 对它不可表达（ADR-0002）。
- 「到」账户的候选按「从」账户的币种过滤，让跨币种组合**不可选**而不是写完再拒。同账户同理（候选排除 + 一条兜底校验）。
- 金额输入框的币种符号：转账用「从」账户的币种（两条腿同币种），收支用全局显示偏好。
- 更正的合法路径由**原交易的 kind** 决定：transfer 原交易只能经 `executeTransfer`，收支原交易只能经 `execute`。
- **检索**：`TransactionFilter`（值对象，手写 `==`/`hashCode` —— Riverpod 按 `==` 去重 state）→ `TransactionsDao.watchTransactionsFiltered` → `LedgerRepository.watchTransactionsFiltered`（复用既有的 `_toTransactionEntities`，不写第二个装配器）。两个刻意之处：`isReversed` 在 **SQL** 里过滤（查询层不再过滤第二次），账户/分类筛选用子查询选出**哪些交易**合格、再返回它们的**全部** posting —— 转账因此不会被截成单腿。
- **导出**：`transactionsToCsv` 是纯函数（RFC 4180 转义、ISO 日期、枚举名而非译名、前置 UTF-8 BOM）；`TransactionExportService` 只负责落盘与分享。导出的是**屏幕上那些行**，无结果时按钮禁用。
- **备份**：`VACUUM INTO` 产出一致快照（不是复制文件），连同偏好与 manifest 打成一个 `.flbackup`。恢复是**替换**语义，且**只暂存不就地应用**——数据库整个运行期都被打开，替换只能发生在下次启动、任何东西读取 `db.sqlite` **之前**。
- 暂存区标志是**文件**（`restore/PENDING`）而非 SharedPreferences 键：它必须早于任何 provider 存在时可读，而且恢复本身会覆盖偏好。
- 替换时**必须删除陈旧的 `-wal`/`-shm`/`-journal`**：旧库留下的 `-wal` 会被重放进恢复后的库，静默损坏。
- 校验在写 PENDING **之前**全部完成：容器 format/formatVersion、库的 schemaVersion（读 SQLite 头，不打开文件——打开会跑迁移并改写待校验的那份副本）、`PRAGMA integrity_check`、以及**用真实 DAO 读一次事件表**。最后一项不可省：一个事件溯源迁移**之前**的库 user_version 同样是 1、integrity_check 同样通过，但本 build 根本读不了它。
- **`android:allowBackup="false"` 是刻意的，不是模板残留**：清单不写这一行时默认是 `true`，于是 Android 会把整个 `files/`（含 `db.sqlite`，即全部账本）备份进 Google Drive，**卸载重装时原样倒回来** —— 看起来像「卸载没用」或「播种又跑了一遍」，实际两者都没发生，是系统还原了一个非空事件存储（`firstInstallTime` 是新的，库里的交易却是旧的，这就是判据）。账本的自有备份是 `.flbackup`（用户显式导出、显式恢复），不该再有一份用户没点过头的云端副本。iOS 侧同类问题需要给容器加 `NSURLIsExcludedFromBackupKey`，尚未处理。

## 应用流程

- `main.dart`：手动 `ProviderContainer` → 打开 `db.sqlite`（后台 isolate）→ `seedDatabase`（**只播分类**：CategoryCreated × 17，含 2 个固定 id/systemCode 的反冲正系统分类；名称在播种时本地化；以事件存储为空为幂等条件）→ 过期则重建检查 → 周期补课（幂等，失败不阻断启动）→ 应用恢复出的偏好 → `runApp`。
  **首次安装播的是词汇，不是钱**：分类是用户往里装自己的钱的词表，可以预置；**账户和交易不行** —— 账户是钱本身，此刻一分都还没有。曾经播过的 Cash / Bank Card（其中 Bank 带 1000.00 期初余额）会把别人的期初余额显示在主页上，币种还是播种当时的全局默认值。因此全新安装的主页是空的，记账前需要先建一个账户（选择器里有「管理账户」入口），账本页与选择器各自有对应的空态文案。唯一的两条系统分类由 seeder 建：`AccountService` 的 `adjustAccountBalance` 与 `createAccount`（非零起始余额）都按 `systemCode` 查它们，查不到就拒绝，不会就地造一个 —— 缺了它意味着这个事件流早于那次播种。
  **系统分类的标识符与显示名刻意不同名**：显示名是「余额更正」（en: `Balance correction`），而 `CategoryConstants.reversal*Code`、`reversal*Id` 与持久化的 `systemCode` 一律不动 —— 显示名给人看、随时可改，`systemCode` 是上面那条查询的键，改了就查不到。另注意分类名是**播种时写进事件 payload**（`CategoryCreated.name`，并快照进 `transactions_view.category_name`）的，所以改 ARB 只影响新装，已有的库保留旧名。
  **顺序是承重的**：`applyPendingRestore` 必须早于任何 `appDatabaseProvider` 读取，否则替换会在活句柄下失败或更糟——成功。该函数之前不得读数据库或任何会读数据库的 provider。
- **账本的币种由账户决定，不由显示偏好决定**：`ledgerCurrencyProvider` 取账户的币种（账户只有一个币种时
  就是它，混合时才回退到偏好），头部与列表的货币符号都跟它走。原因是**账户在建的时候跟随当时的偏好，
  而偏好之后会变，且全程没有汇率换算** —— 按偏好去过滤总额，会把全部账户滤掉，于是账本明明有钱却显示
  全 0（zh 语言环境下尤其容易：账户建的时候跟随偏好，`CurrencyController` 之后按系统 locale 解析出
  另一个币种）。
- 路由：`StatefulShellRoute` 三个 tab —— `/ledger`、`/reports`、`/more`。`/ledger/add`、`/ledger/edit`、`/ledger/search` 推在根导航器上，前两者都指向 `TransactionFormScreen`；账本页的 app bar 只有搜索一个入口（FAB 保持直达 `/ledger/add`，三种 kind 都在那个表单里选）。`/accounts_management`、`/categories_management` 是顶层路由，也是这两种管理页**唯一**的路由（`/more/accounts`、`/more/categories` 已删：选择器里已经能到，More 只是一扇并列的门）。**从 More 点开的每一项都盖在 shell 之上、不共享底部导航栏**：`/more/settings` 与 `/more/about` 带 `parentNavigatorKey: _rootNavigatorKey`（与 `/ledger/add` 同一手法），管理页走的两个顶层路由本来就是。调用一律用 `push`，让返回能回到那个 tab。每项都带一行副标题说明它打开什么（`settingsHint` …）。`test/ui/features/settings/more_screen_test.dart` 用真实 router 跑这条线，**去掉 navigator key 它会失败**（已变异验证过）。
- 账本状态：`LedgerViewModel`（keepAlive notifier）持有选中月份、快照来源的月度合计、各账户余额；交易列表直接监听 `ledgerMonthlyTransactionsProvider(month)` family（经 `TransactionUiMapper` 映射，并按天分组 —— 两者都在 provider 内部完成，不在组件里；它把该月的**待入账**实例一并合进同一张表，同一天内已入账在前）。头部的三个头条数字里**只有两个属于该月**：收入与支出来自 `monthly_account_balance_snapshots`（与报表页同源），
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
- **改动事件 payload 或新增事件类型**意味着要动 `register_ledger_events.dart` 里的注册表，并遵守
  constitution VII：一旦发布，payload 变更就要升 `schemaVersion` 并附带 upcaster，而已发布的
  `eventType` 永不改名。**首例就是 `CategoryCreated` v1→v2**（图标从 Material 码点换成 Lucide 码点）
  —— 一个字段的*含义*变了就得升版本，upcaster 负责读旧值。同时把 `ledgerProjectionVersion` 升到 2：
  视图是从事件重建的，**只改投影不改事件会被下一次重建冲掉**，而版本号过期正是启动时触发重建的开关。
  `categories_view.icon_key` 与 `transactions_view.category_icon` 两处都要重新推导，实测迁移路径见
  `test/unit/features/ledger/data/category_icon_migration_test.dart`。
- 加了 Riverpod/Drift/json 注解后跑 `dart run build_runner build -d`；改了 ARB 后跑 `flutter gen-l10n`。

## 常用命令

- `flutter pub get`
- `dart run build_runner build -d`（改动带注解的代码后，重新生成 Riverpod/Drift/json_serializable 的 `.g.dart` 文件）
- `flutter test`
- `flutter analyze`
