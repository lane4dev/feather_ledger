# Implementation Plan: P0 基础财务能力闭环

**Branch**: `004-p0-core-finance-loop` | **Date**: 2026-09-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/004-p0-core-finance-loop/spec.md`

## Summary

把四个已经存在于底层、但用户够不到的能力接到 UI 上：同币种转账的完整闭环、周期账单的创建/停用/到期确认、交易检索与 CSV 导出、单文件本地备份与恢复。

技术路线的核心判断是**零写模型变更**：转账走已有的 `TransactionRecorded`/`TransactionReversed`；周期表是宪章 VII 明文豁免的 CRUD 表，命令直接写表不发事件；备份不写事件。因此不新增事件类型、不修改任何 payload、不加索引、不动 `schemaVersion`。

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x（与 003 一致）
**Primary Dependencies**: `flutter_riverpod` + `riverpod_annotation`（状态）、`drift` + `sqlite3_flutter_libs`（持久化）、`go_router`（路由）、`rrule`（周期规则）、`uuid`、`intl`（CSV 日期）、`package_info_plus`（备份 manifest 的应用版本）、`path_provider`、`shared_preferences`
**新增依赖**: `share_plus`（导出与备份分享）、`cross_file`（显式声明，因为直接 import 其 `XFile`）、`archive`（打包归档）、`file_selector`（选取备份文件）
**Storage**: SQLite（`getApplicationSupportDirectory()/db.sqlite`，drift 后台 isolate）；备份归档为 zip 单文件
**Testing**: `flutter test`，逻辑测试只经 `LedgerService`/`AccountService`/`RecurringService` + 内存 Drift（`test/support/event_sourcing/ledger_service_harness.dart`）；不为命令、投影器或 Event Store 建 mock 接缝
**Target Platform**: 本地优先移动端（Android/iOS），桌面可用
**Constraints**: 金额端到端 int minor units；余额只在投影路径内计算；四语 ARB 同步；`flutter analyze` 阻塞门禁

## Constitution Check

*GATE: 实现前与实现后各检查一次。*

| 原则 | 本 plan 的合规性 |
|---|---|
| **I. 严格 MVVM** | 组件 → view model（`@riverpod` notifier）→ service → 命令/查询。新增 `RecurringViewModel`、`SearchViewModel` 承载状态；组件内不放业务逻辑。✅ |
| **II. Riverpod** | 全部经 `@riverpod` codegen；状态类不可变（`TransactionFilter` 手写 `==`/`hashCode`，因为这个相等性本身是 Riverpod 去重的前提）。✅ |
| **III. Material 3 极简** | 新 UI 一律用 `context.spacing`、`context.colors`、`AppTheme.textTheme`、`AppButton`/`AppCard`/`AppTextField`。搜索框需要 `onChanged` 时**扩展 `AppTextField` 的可选参数**（宪章 III 明文允许「以命名 DS 变体」扩展），不绕过 DS 用裸 `TextField`。⚠️ 不以 `transaction_detail_sheet.dart` / `ledger_selection_sheet.dart` 为样式范本——这两个文件本身就是 T077 要迁移的对象。 |
| **IV. 国际化优先** | 每个新字符串进全部四个 ARB（`en`/`zh`/`zh_Hans`/`zh_Hant`）后跑 `flutter gen-l10n`；不手改 `app_localizations*.dart`。FR-027 额外要求补齐封闭集合中每一个错误码的文案。✅ |
| **V. 代码质量** | `flutter analyze` 零问题为门禁。注意 `unawaited_futures`（每一个 `VACUUM INTO`/打包/分享/解压/选取文件都要 await）、`empty_catches`（启动补课的 catch 需要 `debugPrint`）、`prefer_const_constructors`。✅ |
| **VI. 全面测试** | 每个故事的命令/服务/仓库/视图模型都有单测；新组件与关键屏有组件测试。见 tasks.md 每行的「测试」列。✅ |
| **VII. 事件溯源治理** | **本 plan 不新增事件类型、不修改任何 payload、不重命名 `eventType`、不加 upcaster。** 周期表属该原则明文声明的 CRUD 豁免；转账复用既有九种事件；备份不写事件。`schemaVersion` 保持 1。收尾以 SC-010 验收。✅ |

**Gate 结论**：通过，且是七项原则中约束最强的一项（VII）驱动了本 plan 的整体形状。

## Project Structure

### Documentation

```
specs/004-p0-core-finance-loop/
├── spec.md      # 需求理解、当前现状、验收标准（已写）
├── plan.md      # 本文件：技术路线
└── tasks.md     # 依赖有序的任务列表
```

### Source Code

按仓库既有的 feature-first 结构（`lib/features/{ledger,reports,settings}` + `lib/core` + `lib/shared`），**不新增技术分层目录**。

```
lib/app/
├── bootstrap/pending_restore.dart              # 新增：启动替换（纯 dart:io，可纯单测）
├── router/app_router.dart                      # 改：transfer / search / recurring 路由 + edit 分流
└── design_system/app_text_field.dart           # 改：加可选 onChanged / controller

lib/core/
├── data/database/daos/transaction_dao.dart     # 改：watchTransactionsFiltered
├── data/database/daos/recurring_dao.dart       # 改：watchAllSeries
├── data/repositories/preferences_repository.dart  # 改：exportAll / importAll
├── domain/result/result.dart                   # 改：+ scheduledAlreadyPosted
└── presentation/…                              # 不改

lib/features/ledger/
├── domain/commands/correct_transaction_command.dart   # 改：transfer 路径 + kind 守卫
├── domain/commands/create_recurring_series_command.dart      # 新增
├── domain/commands/deactivate_recurring_series_command.dart  # 新增
├── domain/commands/skip_scheduled_transaction_command.dart   # 新增
├── domain/services/ledger_service.dart         # 改：+ updateTransfer
├── domain/services/recurring_service.dart      # 新增
├── domain/services/transaction_export_service.dart  # 新增
├── domain/repositories/recurring_repository.dart + data 版   # 改：+ saveSeries / watchAllSeries
├── domain/repositories/ledger_repository.dart + data 版      # 改：+ watchTransactionsFiltered
├── domain/queries/search_transactions_query.dart            # 新增
├── domain/value_objects/transaction_filter.dart             # 新增
├── domain/export/transaction_csv.dart          # 新增：纯函数
├── domain/entities/ledger_entities.dart        # 改：状态编解码单一来源
└── presentation/
    ├── screens/transfer_form_screen.dart       # 新增
    ├── screens/search_screen.dart              # 新增
    ├── screens/recurring_list_screen.dart      # 新增
    ├── widgets/recurring_series_form_sheet.dart # 新增
    ├── widgets/transaction_detail_sheet.dart   # 改：配色 + displaySign
    ├── widgets/ledger_amount_input.dart        # 改：三路配色
    ├── view_model/ledger_view_model.dart       # 改：+ addTransfer / updateTransfer，删死订阅
    ├── view_model/recurring_view_model.dart    # 新增
    ├── view_model/search_view_model.dart       # 新增
    └── screens/ledger_screen.dart              # 改：app bar actions

lib/features/settings/
├── domain/models/backup_manifest.dart          # 新增
├── domain/services/backup_service.dart         # 新增
└── presentation/screens/settings_screen.dart   # 改：数据区
└── presentation/screens/more_screen.dart       # 改：周期账单入口

lib/shared/presentation/ledger_error_localizer.dart  # 改：补三个 case
lib/app/l10n/app_{en,zh,zh_Hans,zh_Hant}.arb         # 改：全部新字符串

test/
├── unit/features/ledger/domain/services/transfer_correction_test.dart   # 新增
├── unit/features/ledger/domain/services/recurring_series_test.dart      # 新增
├── unit/core/database/daos/transaction_dao_filter_test.dart            # 新增
├── unit/features/settings/data/backup_service_test.dart                # 新增
├── unit/app/bootstrap/pending_restore_test.dart                        # 新增
├── unit/shared/presentation/ledger_error_localizer_test.dart           # 新增
└── support/event_sourcing/ledger_service_harness.dart                  # 改：+ recurringService
```

## 技术路线

### 总原则

1. 新特性一律照 ledger 的形态：组件 → view model（`@riverpod` notifier）→ service → 命令/查询。组件内不放业务逻辑。
2. 金额端到端 int 最小单位；`formatMinor`（`lib/shared/presentation/money_format.dart`）是唯一 minor→显示串的转换点。它已是 `(minor/100).toStringAsFixed(2)`——无千分位、locale 无关，**直接就是 CSV 安全形式，不需要新格式化器**。
3. 余额只在投影路径内算。四个故事都不得新增余额算术。
4. 写用例抛 `CommandRejected`，service 用 `guard(...)` 收成 `Result<T>`；视图模型用 `if (result case Failure(:final code))` + `code.message(l10n)` 渲染。

### US1 — 转账

**命令层**（`correct_transaction_command.dart`）：把既有尾巴抽成 `_loadCorrectable(String)` 与 `_appendCorrection({originalTransactionId, replacement, commandId})`，形状对齐 `RecordTransactionCommand._append`。`execute` 的 `type == transfer` 守卫是**死码**（`resolveForKind` 已拒绝 transfer），替换为按**原交易 kind** 判定。新增 `executeTransfer(...)`：约 28 行，append 逻辑零重复。

**服务/视图模型**：`LedgerService.updateTransfer(...)` = `guard(_correctTransactionCommand.executeTransfer(...))`；`addTransfer` 原样复用。`LedgerViewModel` 加 `addTransfer`/`updateTransfer`，各自 `Uuid().v4()`。**不新建 `TransferFormViewModel`**——写方法本来就在 `LedgerViewModel`。

**表单与入口**：新建 `transfer_form_screen.dart`（金额、日期时间、从账户、到账户、备注；复用 `LedgerAmountInput`、`LedgerSelectionSheet`、`AppButton`）。「到」的候选按「从」账户的币种过滤——同币种是聚合根不变量，让非法状态**不可表达**优于写完再拒（ADR-0002 的精神）。路由新增 `/ledger/transfer`；`/ledger/edit` 的 builder 按 `extra.type` 分流，这样一个「编辑这个东西」的 URL 同时服务两种形态，调用方一行不改。**不给 `LedgerTypeSelector` 加第三个 segment**——那会让 436 行的收支表单需要表达非法状态，并与 T077 在同一区域冲突。`ledger_screen.dart` 的 `SliverAppBar` 加搜索与转账两个 action；FAB 保持直达 `/ledger/add`（不回退「快速记账」）。

**展示修正**：`transaction_detail_sheet.dart` 的配色扩为三路（transfer → `onSurface`）、符号改用 `displaySign`；`ledger_amount_input.dart` 同理。这两处是「第二处推导同一件事」的清除。

### US2 — 周期账单

**写路径**（对齐既有先例 `InsertOrUpdateScheduledTransactionCommand`：无事件、无投影器、无 `commandId`）：三个新命令。`create_recurring_series_command` 收**具名参数而非 Drift companion**（视图模型不碰 Drift，且能让 `PostingContextResolver` 跑与其它写入方相同的红线），写到 CRUD-exempt 表；`deactivate_recurring_series_command` 设 `endDate` 并保留既有实例；`skip_scheduled_transaction_command` 置 `'skipped'`。

**仓库层**：`RecurringDao.watchAllSeries()`（2 行）+ 接口/实现的 `saveSeries`/`watchAllSeries`。`saveSeries` 已存在、零调用方，就此转正。**要 `watchAllSeries` 的理由**：`endDate ≤ startDate` 的系列、或还没物化出第一个实例的系列，产生零条 scheduled 行，否则完全不可见——包括刚创建完的那一刻。

**状态编解码**：在枚举旁定义 `toStorage()` 与 `decodeScheduledStatus(raw)`（带 `orElse: () => scheduled`），替换全部 5 处（3 处解码 + 2 处写入）。只修解码会重新制造它消除的那个错配。

**服务**：新建 `RecurringService`，承载 `createSeries`（命令 → `materialize()`）、`deactivateSeries`、`postInstance`、`skipInstance`、`materialize`、`watchSeries`、`watchScheduled`。没有这一层，视图模型要 `ref.read` 四个命令 provider，而宪章 VI 的单测要自己接四个；有了它，`LedgerServiceHarness` 只多一个字段。把 `convertScheduledToPosted` 与 `watchScheduledTransactions` 从 `LedgerService` 迁过来，消除「同一件事两个入口」。

> **B4 与 B6 必须同时落地，或 B4 保留一个转发。** `watchScheduledTransactions` 在 `LedgerViewModel._subscribeScheduledTransactions`（那条无人读取的死订阅，B6 才删）里还有一个调用方；B4 先删会编译不过。

**启动补课**（`main.dart`，重建门禁之后、`setupEdgeToEdge()` 之前）：`try { await recurringService.materialize(); } catch (e) { debugPrint(...); }`。要 await——它不写事件也不写投影行，首帧不依赖它，但周期页的待办列表否则要和自己竞争；它幂等，await 无正确性风险。代价有界（每实例一次 `getScheduled` 点查）。`try/catch` 不是装饰：一条坏系列行不能让账本打不开。

**界面**：新建 `RecurringViewModel`（形态照 `LedgerViewModel`）与 `recurring_list_screen.dart`（上半「待办」含记入/跳过，下半「系列」含停用）+ `recurring_series_form_sheet.dart`（照 `account_form_sheet.dart`）。**删掉** `LedgerViewState.scheduledTransactions` 与 `LedgerViewModel._subscribeScheduledTransactions`——零读者，且那条流的异常今天无人观察；不要「为以后」留着。路由照 `accounts`/`categories` 的双注册方式（`/more` 分支 + 顶层 `/recurring_management`）。

### US3 — 检索 / 筛选 / CSV

**`TransactionFilter`**（`domain/value_objects/`）：六字段，手写 `==`/`hashCode`（**承重**：`SearchViewModel` 的 state 就是它，Riverpod 按 `==` 去重）、`static const empty`、`isEmpty`。**不做 `copyWith`**（可空字段的 `copyWith` 需要哨兵值，经典陷阱——筛选表单自己持可变草稿，点「应用」时构造一个 VO）；**不做金额区间**；**不做 `limit`**（有上限的分页会让「导出当前结果」导出的比屏幕少）。

**DAO**（`transaction_dao.dart`）：`watchTransactionsFiltered({...})` 收**基本类型不收 VO**（`core/data` 不能 import `features/ledger/domain`，那是分层倒置；`watchTransactionsByMonth` 已立先例）。要点：

- **`isReversed` 过滤写进 SQL**（照 `ReportsDao` 的做法），不依赖查询层的 Dart 过滤——否则新的 DAO 调用方会看到冲销行。
- 账户/分类筛选直接筛 `transactionPostingsView`，让仓库既有的 `_toTransactionEntities` 把两条腿合并回去——「匹配任一条腿」白拿，且**避免把转账截成一条 posting**（`_toTransactionEntity` 对 transfer 用 `firstWhere(debit)`/`firstWhere(credit)`，截断会直接抛）。
- 日期两端含端点、按天粒度。
- 关键词匹配 `description` / `categoryName`（写入时快照）/ `accountsView.name`，转义用户输入里的 `%` 与 `_`。
- **不加索引**：`LIKE '%x%'` 用不上，`idx_transactions_view_occurred_at` 已覆盖范围。

**仓库/查询/视图模型**：`LedgerRepository.watchTransactionsFiltered` → 调 DAO → **走既有的私有 `_toTransactionEntities`**（最大的复用点：腿合并、`toAccount` 解析、金额取自 debit 腿、分类快照全部已存在且有测试；不要写第二个装配器）。新建 `SearchTransactionsQuery`（不再做 Dart 侧 `isReversed` 过滤）+ `SearchViewModel`（**不用 family provider**：筛选状态在 VM 里，省掉 family key 的相等性体操；不用 `keepAlive`，离开搜索页即重置）。日分组直接复用 `ledger_view_model.dart` 里已公开的顶层 `groupTransactionsByDay`。

**CSV**：`domain/export/transaction_csv.dart` 一个纯函数。表头 `date,kind,amount,currency,account,toAccount,category,note`；`date` 用 `DateFormat('yyyy-MM-dd')`；`kind` 用枚举 **name**；`amount` 用 `formatMinor`，收支带符号、转账不带（与 UI 的 `displaySign` 一致）；**RFC 4180 转义**；**前置 UTF-8 BOM**（三语应用 + 中文备注，否则 Windows Excel 乱码）。`TransactionExportService` 写临时文件后交给 `share_plus`。**不为 share 抽接口**——纯函数是逻辑、拿单测；那几行平台调用是 IO。

### US4 — 备份 / 恢复

**`VACUUM INTO`**（不是复制文件）：在 drift 的后台 isolate 上作为普通语句执行，**不能在 `db.transaction` 内**（`VACUUM` 不允许）。目标文件**必须不存在**，每次写新的临时文件。它产出干净快照（单文件、无 journal、已整理碎片），这正是它优于「直接复制 `db.sqlite`」的原因——后者可能撞上在途的 journal。

**归档**：`manifest.json` + `db.sqlite` + `preferences.json` 打成一个 zip（`.flbackup`）。必须打成一个文件，因为 `share_plus` 分享的是**文件**不是目录；三个散文件意味着接收方要逐个重选、且没人阻止配错。`manifest` 携带容器 `format`/`formatVersion`、数据库 `schemaVersion`、应用版本、导出时间、事件条数与最大 GSN。**不做 sha256、不引入 `crypto`**——zip 条目自带 CRC32，真正的校验是**打开**暂存的库跑 `PRAGMA integrity_check`。`eventCount`/`lastGlobalSequenceNumber` 不是装饰：它们让恢复确认框能说清将丢弃多少条（FR-024）。

**恢复**：待恢复状态用**文件系统标记**（`restore/PENDING`）而非 `SharedPreferences` 键——它必须在 `main()` 最顶端、`ProviderContainer` 存在之前、`appDatabaseProvider` 被读之前用纯 `dart:io` 可读；而且恢复本身会覆盖偏好，把标记存在偏好里就是鸡生蛋。替换逻辑放 `lib/app/bootstrap/pending_restore.dart`（只依赖 `dart:io`，因此可用临时目录纯单测）。步骤：改名旧库 → **删除陈旧的 `-wal`/`-shm`/`-journal`** → 改名新库 → 删 `restore/`；任一步失败回滚并保持原账本完好。

**`main.dart` 接线**：放在 `ProviderContainer()`/`container.read(appDatabaseProvider)` **之前**（`appDatabaseProvider` 是 `keepAlive` + `LazyDatabase`，一旦有东西先读了它，文件就被打开，改名会失败或在活句柄下成功）。

**三个交互已核对**：`seedDatabase` 以「事件存储为空」幂等，恢复后的库有事件故跳过播种；替换发生在 provider 被读之前，将来打开该文件的 isolate 尚不存在；恢复来的库带着备份版本的 `projectionVersion`，旧于当前则下次启动 `isStale()` 为真、`rebuild()` 重放——**所以备份不需要额外的「恢复后重建」步骤，也不需要排除投影表**。

**不为恢复做应用内重启**：keepAlive 容器 + 后台 isolate 的 DB，干净重启做不到；用户已确认「下次启动替换」，就照此执行，收尾对话框明确告知。

## Complexity Tracking

无宪章违规需要豁免。三个值得记录的取舍：

| 取舍 | 为什么接受 |
|---|---|
| 周期表继续不走事件溯源 | 宪章 VII 明文豁免，且 003 已把「规则/实例表保持纯 CRUD」定为非目标。给它们补事件是另一个 spec。 |
| `RecurringRepository` 接口继续暴露 Drift 类型 | 接口**已经**在暴露 `RecurringSeriesRow`/`ScheduledTransactionViewRow`/`ScheduledTransactionsViewCompanion`。本 plan 照既有惯例，修这个泄漏是独立的一件事。 |
| 新增四个依赖 | 其中两个（`share_plus`/`file_selector`）纯粹用于把字节挪出/挪进应用边界——而那**就是** P0 第 3、4 项要交付的东西。排除的替代见下。 |

**排除的依赖与替代方案**：`csv`（`formatMinor` + 15 行 RFC 4180 转义已足够）、`crypto`（zip 自带 CRC32 + 打开库时的 `integrity_check`）、`permission_handler`（`share_plus`/`file_selector` 不需要）、`restart_app`（改为下次启动生效）、`equatable`（`TransactionFilter` 手写 12 行）、`file_picker`（改用 flutter.dev 维护、返回 `XFile` 的 `file_selector`）。

## Risks and Mitigations

| # | 风险 | 缓解 |
|---|---|---|
| 1 | **重复计数余额** — 转账更正的「冲销 + 替换」若被重构成两次 append，账目会翻倍 | A1 的测试断言单个 `commandId` 与单次 append；`_appendCorrection` 的抽取是唯一改动点 |
| 2 | **周期实例重复** — 幂等性**只**由 `'${seriesId}_${date.millisecondsSinceEpoch}'` 保证；id 或日期归一化一变，每个实例都重复 | B4 断言连续两次 `materialize()` 结果集完全相同（SC-004） |
| 3 | **冲销行泄漏进检索** — 今天冲销行在**查询层**用 Dart 过滤，新 DAO 调用方会看到它们 | C2 的 `isReversed` 过滤写进 SQL；测试显式断言冲销行被排除 |
| 4 | **转账被筛选截断** — `_toTransactionEntity` 对 transfer 用 `firstWhere(debit/credit)`，单腿行会抛 | 筛选筛 posting 表后由既有分组逻辑合并；C2/C3 断言一条腿筛选仍返回完整转账 |
| 5 | **恢复时旧 WAL 污染新库** — 漏删 `-wal` 会静默损坏，几周后以余额错误浮现 | D5 显式断言三个副档已消失 |
| 6 | **启动顺序无自动化守卫** — `applyPendingRestore` 必须早于任何 `appDatabaseProvider` 读取 | D5 覆盖文件舞蹈；`main.dart` 两处放醒目注释。这是全 plan 唯一无自动化测试的接线点 |
| 7 | **周期补课失败阻断启动** | FR-009：`try/catch` + `debugPrint` 降级 |
| 8 | **脏工作区导致 ARB 冲突** | Phase 1 先收口并提交 T077/T080；四个 ARB 文件已被其修改 |
| 9 | **`flutter analyze` 回归** | `unawaited_futures`/`empty_catches`/`prefer_const_constructors` 是新增代码最易踩的三条；每个任务收尾跑一次 |
| 10 | **既有的两个错误码漏网** | FR-027/SC-003：一条遍历封闭集合的单测守护「不得回落到 `errorPrefix`」 |
| 11 | **`ProjectRecurringEventsCommand` 的启动代价随系列数无界增长** | 留 `ponytail:` 注释与升级路径（一次 `select` 取 id 集合）；当前规模有界 |
| 12 | **物化不是跨系列单一事务** | 接受：命令幂等，下次启动补完。不包事务（会握写锁做上百次插入且无收益） |

## Further Notes

- 本 plan 相对 `specs/003` 的关键差异：003 把「同步 / 备份 / 多设备」列为**非目标**，本 spec 的 US4 正是其中的备份/恢复。这不是推翻 003——003 的非目标是**划出当次迁移的范围**，而审计已把备份提升为 P0。实现时不要在 003 的文档里改这句话，只在 004 里声明范围。
- 未决定项（实现时不要自行拍板，需回到 spec）：转账「从账户透支」是否要确认框（v1 不做）；周期系列的就地编辑（用户已选「创建 + 停用」）；周期入口最终放 More 还是账本页（本 plan 取 More，与账户/分类管理同级；挪到账本页是一行的事）。
