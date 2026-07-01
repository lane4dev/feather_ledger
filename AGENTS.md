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
  `data/repositories/reports_repository.dart`，且 `report_breakdown_view.dart` 在组件内自己做排序 /
  Top-5 截断 / “Other” 分桶聚合。
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
  按天分组展示：降透明度 + 时钟图标 + 「待入账」标签，点开是记入 / 删除。`RecurringViewModel`
  只持有这两个写动作，没有状态 —— 实例本身经 `ledgerMonthlyTransactionsProvider` 进列表。
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
- **待入账是「还没发生」**：它不进入余额、月度合计或搜索（搜索只读 `transactions_view`，实例不在其中），
  只在展示层出现。它变成真实交易的唯一路径仍是 `ConvertScheduledToPostedCommand`。

## 金额约定（重要）

数据库行与事件一律使用有符号的整数最小单位（支出为负、收入为正），端到端一致 —— 包括预约/周期实体
（`amountMinor`）。唯一的 double 桥接点是表现层输入边界的 `Money.fromDouble`；格式化一律走
`formatMinor`。

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
- 用户可选的分类颜色与图标是**数据，不是令牌**：`CategoryTokens`
  （`lib/app/theme/category_tokens.dart`）是调色板 + 图标码点集合，`defaultColor` /
  `defaultIcons.first` 是新分类的默认值。
- 本地化：ARB 文件在 `lib/app/l10n/`，模板是 `app_en.arb`。共有**四个**：`en`、`zh_Hans`、`zh_Hant`，
  以及一个不带 script 的 `zh` 基础文件 —— 只要存在带 script 的语言，`flutter gen-l10n`
  就**要求**它作为回退（内容镜像简体，需保持同步）。新增键要加进全部四个文件，然后跑
  `flutter gen-l10n`；永远不要手改 `app_localizations*.dart`。
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

## 应用流程

- `main.dart`：手动 `ProviderContainer` → 打开 `db.sqlite`（后台 isolate）→ `seedDatabase`（事件溯源：AccountCreated/OpeningBalanceSet/CategoryCreated × N，含 2 个内置系统分类；名称在播种时本地化；以事件存储为空为幂等条件）→ 过期则重建检查 → 周期补课（幂等，失败不阻断启动）→ 应用恢复出的偏好 → `runApp`。
  **顺序是承重的**：`applyPendingRestore` 必须早于任何 `appDatabaseProvider` 读取，否则替换会在活句柄下失败或更糟——成功。该函数之前不得读数据库或任何会读数据库的 provider。
- 路由：`StatefulShellRoute` 三个 tab —— `/ledger`、`/reports`、`/more`。`/ledger/add`、`/ledger/edit`、`/ledger/search` 推在根导航器上，前两者都指向 `TransactionFormScreen`；账本页的 app bar 只有搜索一个入口（FAB 保持直达 `/ledger/add`，三种 kind 都在那个表单里选）。`/accounts_management`、`/categories_management` 是顶层路由。
- 账本状态：`LedgerViewModel`（keepAlive notifier）持有选中月份、快照来源的月度合计、各账户余额；交易列表直接监听 `ledgerMonthlyTransactionsProvider(month)` family（经 `TransactionUiMapper` 映射，并按天分组 —— 两者都在 provider 内部完成，不在组件里；它把该月的**待入账**实例一并合进同一张表，同一天内已入账在前）。月度收入/支出合计来自 `monthly_account_balance_snapshots`；顶部的 `balanceMinor` 则折叠实时的 `accounts_view` 投影。检索有自己的视图模型（`SearchViewModel`），`RecurringViewModel` 只剩三个写动作。
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
  `eventType` 永不改名。
- 加了 Riverpod/Drift/json 注解后跑 `dart run build_runner build -d`；改了 ARB 后跑 `flutter gen-l10n`。

## 常用命令

- `flutter pub get`
- `dart run build_runner build -d`（改动带注解的代码后，重新生成 Riverpod/Drift/json_serializable 的 `.g.dart` 文件）
- `flutter test`
- `flutter analyze`
