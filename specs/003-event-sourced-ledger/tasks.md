# Tasks: CQRS + Event Sourcing 架构迁移

**Input**: 已确认规格 [`.scratch/003-event-sourced-ledger/spec.md`](../../.scratch/003-event-sourced-ledger/spec.md)，现有代码与 [`.specify/memory/constitution.md`](../../.specify/memory/constitution.md)。`plan.md`、`data-model.md`、`contracts/ledger_api.md` 是迁移前文档；其中的 `double`、旧事件名和旧表结构不可作为实现依据。

**测试策略**: 每个逻辑测试只经 `LedgerService` / `AccountService` 和内存 Drift 数据库驱动，断言事件流、投影表与月度快照；不为命令、投影器或 Event Store 建 mock/私有实现测试接缝。每次代码调整后执行 `flutter analyze`。

**组织方式**: US1–US10 对应规格的 P1–P10 纵向迁移切片。每个切片完成时删除所替代的旧路径，禁止双轨写入。

## Phase 1: Setup（迁移护栏）

**Purpose**: 固化新规格为实现基线，并建立可重复的生成、分析和测试入口。

- [X] T001 将 `.scratch/003-event-sourced-ledger/spec.md` 的已确认决策同步为实施引用并标记 `specs/003-event-sourced-ledger/plan.md`、`data-model.md`、`contracts/ledger_api.md` 中的过期 double/旧事件内容，路径为 `specs/003-event-sourced-ledger/`
- [X] T002 [P] 建立迁移风险回归测试目录与共享内存 Drift 服务测试装配，路径为 `test/support/event_sourcing/ledger_service_harness.dart`
- [X] T003 [P] 为本 feature 的 Drift schema、事件 JSON/Riverpod 代码生成和全量测试写出可执行开发者步骤，路径为 `specs/003-event-sourced-ledger/quickstart.md`
- [X] T004 在变更 schema 前记录现有表、旧写入口和待删符号的基线，以供每切片核销，路径为 `specs/003-event-sourced-ledger/tasks.md`

---

## Phase 2: Foundational（共享写入与投影边界）

**Purpose**: 建立所有切片共同依赖的 CQRS 边界、可事务执行的 Event Store 协议与事件化投影接口。

**⚠️ CRITICAL**: 后续用户故事一律经领域服务 → 命令 → 该协议写入；UI、DAO 和 repository 均不得绕过它直接修改事件化投影。

- [X] T005 定义稳定事件信封、EventStore 接口、显式 eventType 注册表和 schema upcaster 注册表，路径为 `lib/core/domain/event_sourcing/`
- [X] T006 [P] 定义不可变 `Money`、币种不一致错误、金额格式化边界与禁止 double 的领域契约，路径为 `lib/core/domain/money/money.dart`
- [X] T007 [P] 定义命令成功/失败、用户可呈现错误码与可注入时钟，路径为 `lib/core/domain/result/result.dart`、`lib/core/domain/clock/clock.dart`
- [X] T008 定义领域 Transaction、Posting、方向、kind 和九种最终事件 payload（全为 int minor units），路径为 `lib/features/ledger/domain/model/`、`lib/features/ledger/domain/events/`
- [X] T009 定义 EventStore 的 append batch、commandId 查重、按 GSN 扫描、按 stream 查询和投影重建契约，路径为 `lib/core/domain/event_sourcing/event_store.dart`
- [X] T010 定义同步投影器、投影游标和 projection version 的端口；明确 projector 只能由同一数据库事务内的 append 驱动，路径为 `lib/features/ledger/domain/projections/ledger_projection.dart`
- [X] T011 为 Money/Result/最终 Transaction+Posting 不变量及稳定事件类型/upcast 行为编写纯领域测试，路径为 `test/unit/core/domain/money/money_test.dart`、`test/unit/core/domain/result/result_test.dart`、`test/unit/features/ledger/domain/events/ledger_event_test.dart`

**Checkpoint**: 领域 API 无 `double` 金额、无 `runtimeType` 持久化约定，后续切片可在一个统一写入边界上实现。

---

## Phase 3: User Story 1 - Money、Result 与 Clock（P1） 🎯 MVP 基础

**Goal**: 全部账务输入、实体与显示边界采用 `Money`/int minor units，命令以 `Result` 返回可处理失败。

**Independent Test**: 不同币种 Money 不能相加；任一失败命令返回带错误码的 `Result.failure`，没有裸异常越过服务边界。

- [X] T012 [P] [US1] 将账户、分类和账务共享枚举改为目标账户类型、交易 kind 与 posting direction，路径为 `lib/core/domain/enums.dart`
- [X] T013 [P] [US1] 将账务实体、定期实体和 UI 映射的金额字段改为 int minor units，并移除生产 `MonthlySummary` 依赖，路径为 `lib/features/ledger/domain/entities/ledger_entities.dart`、`lib/features/ledger/presentation/mappers/transaction_ui_mapper.dart`
- [X] T014 [US1] 将金额输入/格式化集中到 presentation 边界，使服务和命令只接收 Money 或 int，不在业务层执行 `(amount * 100).round()`，路径为 `lib/features/ledger/presentation/widgets/ledger_amount_input.dart`、`lib/features/ledger/presentation/screens/transaction_form_screen.dart`
- [X] T015 [US1] 将 `LedgerService`、`AccountService` 的写方法改为接收 commandId 并返回 `Result`，路径为 `lib/features/ledger/domain/services/ledger_service.dart`、`lib/features/settings/domain/services/account_service.dart`
- [X] T016 [US1] 更新账务和账户服务测试为 Money/Result 外部契约，路径为 `test/unit/features/ledger/domain/services/ledger_service_test.dart`、`test/unit/features/settings/domain/services/account_service_test.dart`
- [X] T017 [US1] 删除生产账务路径中的 double 金额转换和旧 `MonthlySummary` 值对象，路径为 `lib/features/ledger/domain/value_objects/monthly_summary.dart`、`lib/features/ledger/domain/queries/watch_monthly_summary_query.dart`

**Checkpoint**: 账务核心无 double/float；UI 仅负责输入解析与显示格式化。

---

## Phase 4: User Story 2 - Event Store 与生产事件读取（P2）

**Goal**: Event Store 成为可读取、可演进、可幂等的不可变写模型；应用启动时可反序列化全部已注册事件。

**Independent Test**: 同 commandId 的提交只产生一次事件；相同 `(streamId, streamVersion)` 写入失败；生产注册后的 event envelope 序列化/反序列化语义相等且 GSN 单调。

- [X] T018 [US2] 用最终 envelope 字段重建 `ledger_events` Drift 表，并添加 commandId、stream/GSN 查询索引及 `(streamId, streamVersion)` 唯一约束，路径为 `lib/core/data/database/tables.dart`
- [X] T019 [US2] 实现 Event Store Drift DAO：原子 batch append、commandId 命中、按 GSN/stream 读取与行到 envelope 的映射，路径为 `lib/core/data/database/daos/events_dao.dart`
- [X] T020 [US2] 在 ledger data 层实现 `EventStore`，使用显式 eventType、payload schemaVersion 和 upcaster，路径为 `lib/features/ledger/data/event_sourcing/drift_event_store.dart`
- [X] T021 [US2] 在 bootstrap 集中注册九种事件工厂及 upcaster，移除测试专用注册作为运行时前提，路径为 `lib/app/bootstrap/register_ledger_events.dart`、`lib/main.dart`
- [X] T022 [US2] 升级 Drift schema 并实现开发数据破坏性重建分支，保证旧 `db.sqlite` 不会以混合 schema 启动，路径为 `lib/core/data/database/app_database.dart`
- [X] T023 [US2] 用服务层测试覆盖 envelope 往返、生产工厂注册、commandId 幂等、stream version 冲突、GSN 顺序与未知事件失败，路径为 `test/unit/features/ledger/domain/services/event_store_contract_test.dart`
- [X] T024 [US2] 删除旧 `EventRepository` 与依赖 `runtimeType`/测试手动 factory 注册的实现和测试，路径为 `lib/core/domain/repositories/event_repository.dart`、`lib/core/data/repositories/event_repository.dart`、`test/unit/core/data/database/daos/events_dao_test.dart`

**Checkpoint**: Event Store 可作为唯一审计源读取，且不再存在仅测试可读的事件 JSON。

---

## Phase 5: User Story 3 - 账户/分类事件化与事件种子（P3）

**Goal**: 账户和分类生命周期经事件写入，种子数据也由同一写入与投影协议生成。

**Independent Test**: 空库首启产生 Cash、Bank、OpeningBalanceSet 和全部 CategoryCreated 事件，四类账户/分类投影正确；归档账户不能记账，系统分类不能归档。

- [X] T025 [US3] 将 `AccountsView` 和 `Categories` 替换为包含币种、archived、source GSN、projection version 的最终 `accounts_view` 与 `categories_view` 表，路径为 `lib/core/data/database/tables.dart`
- [X] T026 [US3] 实现 AccountCreated/Renamed/Archived、CategoryCreated/Renamed/Archived、OpeningBalanceSet 的同步投影分支和事件游标幂等跳过，路径为 `lib/features/ledger/data/projections/ledger_projector.dart`
- [X] T027 [US3] 将账户命令改为 Create/Rename/Archive 事件命令，开户初始余额转为 OpeningBalanceSet，路径为 `lib/features/settings/domain/commands/create_account_command.dart`、`rename_account_command.dart`、`archive_account_command.dart`
- [X] T028 [US3] 将分类 repository/命令改为 Create/Rename/Archive 事件命令，保留固定系统分类 id/systemCode 并拒绝归档系统分类，路径为 `lib/core/domain/repositories/category_repository.dart`、`lib/core/data/repositories/category_repository.dart`
- [X] T029 [US3] 将账户和分类查询/provider 改为只读新投影，选择器排除 archived 项而历史投影保留，路径为 `lib/core/data/database/daos/account_dao.dart`、`lib/core/presentation/providers/account_providers.dart`、`lib/core/presentation/providers/category_providers.dart`
- [X] T030 [US3] 重写 seedDatabase：以事件表为空为幂等条件，经 AccountService/Category 服务写入本地化默认项与 Bank 100000 开户余额，路径为 `lib/app/bootstrap/seeder.dart`
- [X] T031 [US3] 用内存 Drift 服务测试覆盖账户/分类事件、种子可重放、归档限制和系统分类保护，路径为 `test/unit/core/database/seeder_test.dart`、`test/unit/features/settings/domain/services/account_service_test.dart`
- [X] T032 [US3] 删除账户/分类直写 projection CRUD、`AccountUpdated`/`AccountDeleted` 事件及其生成文件引用，路径为 `lib/core/domain/events/account_event.dart`、`lib/features/settings/domain/commands/update_account_command.dart`、`lib/features/settings/domain/commands/delete_account_command.dart`

**Checkpoint**: 账户与分类没有直写生命周期路径；首次安装数据是可重放事件流。

---

## Phase 6: User Story 4 - 支出与收入记录闭环（P4）

**Goal**: 记录收入/支出通过 `TransactionRecorded` 原子地产生交易、posting、余额和月度基础投影；列表与表单切换至新读写路径。

**Independent Test**: 10.50 支出写入一条 debit posting，余额减 1050；收入产生 credit 与收入统计；未来日期交易仍计当前余额；双击保存仅产生一笔。

- [X] T033 [US4] 定义最终 `transactions_view`、`transaction_postings_view` 和所需查询索引，交易行存 kind、isReversed、分类名/图标写时快照及 source GSN，路径为 `lib/core/data/database/tables.dart`
- [X] T034 [US4] 实现 TransactionRecorded 投影：验证单腿 income/expense，写交易与 posting 行，按 direction 更新唯一账户余额计算点，路径为 `lib/features/ledger/data/projections/ledger_projector.dart`
- [X] T035 [US4] 实现 RecordTransaction 命令的账户/分类存在、归档、类别类型和单币种校验；在一个数据库事务中 append + apply，路径为 `lib/features/ledger/domain/commands/record_transaction_command.dart`
- [X] T036 [US4] 将 LedgerService、LedgerViewModel 和交易表单接到 RecordTransaction/Result；使用 commandId 防重复提交并显示本地化失败，路径为 `lib/features/ledger/domain/services/ledger_service.dart`、`lib/features/ledger/presentation/view_model/ledger_view_model.dart`、`lib/features/ledger/presentation/screens/transaction_form_screen.dart`
- [X] T037 [US4] 将月度交易 DAO/query/UI mapper 改为从交易及 postings 投影读取，不再 join 活跃分类以显示旧交易，路径为 `lib/core/data/database/daos/transaction_dao.dart`、`lib/features/ledger/domain/queries/watch_transactions_query.dart`、`lib/features/ledger/presentation/mappers/transaction_ui_mapper.dart`
- [X] T038 [US4] 用服务测试覆盖支出、收入、未来交易余额、重复 commandId、归档分类历史显示和事务失败全回滚，路径为 `test/unit/features/ledger/domain/services/record_transaction_test.dart`
- [X] T039 [US4] 删除 `PostTransactionCommand`、旧 TransactionPosted 投影器、per-leg 旧 transactions schema 与 `getRunningBalance`，路径为 `lib/features/ledger/domain/commands/post_transaction_command.dart`、`lib/features/ledger/data/event_handlers/ledger_transaction_event_handler.dart`、`lib/core/data/database/daos/transaction_dao.dart`

**Checkpoint**: 支出/收入、余额和交易列表同事务更新；余额包含未来已入账 posting，且全库只有投影器计算余额。

---

## Phase 7: User Story 5 - 转账与信用卡还款（P5）

**Goal**: 转账/还款使用同一 Transaction+Postings 模型，双腿同步变动且完全排除收入和支出统计。

**Independent Test**: A→B 100 写入等额 debit/credit，两账户变动正确且收支为零；同账户/跨币种转账失败；储蓄→信用卡还款不重复计支出。

- [X] T040 [US5] 实现 transfer 两 posting 的领域校验：账户不同、金额正且相等、方向相反、货币相同，并固化 `kind == transfer` 为统计的唯一排除口径，路径为 `lib/features/ledger/domain/model/transaction.dart`、`lib/features/ledger/domain/commands/record_transaction_command.dart`
- [X] T041 [US5] 将转账表单和 LedgerService 改为构造 kind=transfer 的 RecordTransaction 命令，支持信用卡账户但不增加还款专用账务模型，路径为 `lib/features/ledger/domain/services/ledger_service.dart`、`lib/features/ledger/presentation/screens/transaction_form_screen.dart`
- [X] T042 [US5] 更新交易列表/详情，使 transfer 聚合显示为一行、postings 在详情展开，路径为 `lib/features/ledger/presentation/widgets/ledger_transaction_list.dart`、`lib/features/ledger/presentation/widgets/transaction_detail_sheet.dart`
- [X] T043 [US5] 用服务测试覆盖普通转账、信用卡消费、还款、同账户与跨币种拒绝、转账净额零及月度统计排除，路径为 `test/unit/features/ledger/domain/ledger_transfer_test.dart`、`test/unit/features/ledger/domain/liability_logic_test.dart`
- [X] T044 [US5] 删除绕过投影器的 `PostTransferCommand` 及旧 TransactionLeg/TransactionRole 模型，路径为 `lib/features/ledger/domain/commands/post_transfer_command.dart`、`lib/features/ledger/domain/events/transaction_event.dart`

**Checkpoint**: 转账不会污染收入/支出，也没有信用卡还款的第二条支出路径。

---

## Phase 8: User Story 6 - 修改、删除与审计（P6）

**Goal**: 修改以 `TransactionReversed(correction)` + `TransactionRecorded` 配对实现，删除以 userDeleted 冲正实现，审计链永久保留。

**Independent Test**: 修改历史交易使原交易反转并生成新交易；删除从列表隐藏；重复修改/删除已冲正交易被拒绝；重放后原交易与冲正影响相抵。

- [X] T045 [US6] 实现 TransactionReversed 投影：标记交易、反向各 posting 的余额影响并向快照重算发出受影响月份，路径为 `lib/features/ledger/data/projections/ledger_projector.dart`
- [X] T046 [US6] 实现 ReverseTransaction 与 CorrectTransaction 命令，在一次 database transaction 中完成校验、事件 append 和同步投影，路径为 `lib/features/ledger/domain/commands/reverse_transaction_command.dart`、`lib/features/ledger/domain/commands/correct_transaction_command.dart`
- [X] T047 [US6] 将详情、编辑与删除 UI 改为 Result 驱动的冲正写入，并在 UI 上呈现 isReversed 与审计历史，路径为 `lib/features/ledger/presentation/widgets/transaction_detail_sheet.dart`、`lib/features/ledger/presentation/screens/transaction_form_screen.dart`
- [X] T048 [US6] 添加按 transactionId 读取事件审计链的查询，并使读模型默认隐藏已冲正行，路径为 `lib/features/ledger/domain/queries/get_transaction_history_query.dart`、`lib/core/data/database/daos/transaction_dao.dart`
- [X] T049 [US6] 用服务测试覆盖删除、修改配对、已冲正拒绝、余额/投影更新和重放抵消不变量，路径为 `test/unit/features/ledger/domain/services/reverse_and_correct_transaction_test.dart`
- [X] T050 [US6] 删除只 append 不投影的旧 Reverse/Correct 实现与其调用，路径为 `lib/features/ledger/domain/commands/reverse_transaction_command.dart`、`lib/features/ledger/domain/commands/correct_transaction_command.dart`

**Checkpoint**: 没有硬删除交易；每次修改/删除即时更新投影并保留完整事件审计。

---

## Phase 9: User Story 7 - 月度账户余额快照（P7）

**Goal**: 月度快照是事件化投影，可处理空月、历史更改和包含 future posting 的当前余额语义。

**Independent Test**: 首月 opening 为 OpeningBalanceSet；空月存在且净额为零；修改上月交易重算该月及其后的快照；transfer 只进入 transferIn/Out。

- [X] T051 [US7] 新建满足 `(accountId, currencyCode, year, month)` 唯一约束的 `monthly_account_balance_snapshots` 表和 DAO，包含规格全部字段及 isClosed=false 占位，路径为 `lib/core/data/database/tables.dart`、`lib/core/data/database/daos/monthly_snapshot_dao.dart`
- [X] T052 [US7] 实现余额相关事件后的快照增量维护、账户首月锚点和到当前月的连续空月物化，路径为 `lib/features/ledger/data/projections/monthly_snapshot_projector.dart`
- [X] T053 [US7] 实现从最早受影响月到最新物化月的级联重算，覆盖冲正、修改的原/新日期和 OpeningBalanceSet，路径为 `lib/features/ledger/data/projections/monthly_snapshot_projector.dart`
- [X] T054 [US7] 用快照查询替代 `MonthlySummary`，保持 ledger header 的月度收支展示使用 int minor units，路径为 `lib/features/ledger/domain/queries/watch_monthly_snapshot_query.dart`、`lib/features/ledger/presentation/view_model/ledger_view_model.dart`、`lib/features/ledger/presentation/widgets/ledger_header.dart`
- [X] T055 [US7] 用服务测试覆盖 opening/closing 链、空月、转账分栏、历史修改级联与 eventSequenceFrom/To，路径为 `test/unit/features/ledger/domain/services/monthly_snapshot_test.dart`
- [X] T056 [US7] 删除旧 `watchMonthlyTotals`/`MonthlySummary` 聚合和所有以 dollars 表示的报告汇总生产用法，路径为 `lib/core/data/database/daos/transaction_dao.dart`、`lib/features/ledger/domain/value_objects/monthly_summary.dart`

**Checkpoint**: 每月收支、余额与快照同源；历史账务变化不会让之后月份的 opening/closing 漂移。

---

## Phase 10: User Story 8 - Rebuild 与演进安全（P8）

**Goal**: 事件化投影和快照可完整重建，schema 变更自动触发重建，未知事件安全硬失败。

**Independent Test**: 清空事件化投影后重放恢复逐字段等价；rebuild 不触碰 recurring/scheduled/偏好；未知 eventType 报出事件 id；增量写入与全量重放相等。

- [X] T057 [US8] 实现单事务 projection rebuild：仅清空 accounts/transactions/postings/categories/snapshots，按 GSN 重放并写游标与 projection version，路径为 `lib/features/ledger/data/projections/ledger_rebuild_service.dart`
- [X] T058 [US8] 在 Drift schema 升级与启动流程接入强制 rebuild，并保留 recurring_series、scheduled_transactions_view 和 SharedPreferences，路径为 `lib/core/data/database/app_database.dart`、`lib/main.dart`
- [X] T059 [US8] 为设置页加入受保护的开发者手动 rebuild 入口及本地化成功/失败提示，路径为 `lib/features/settings/presentation/screens/settings_screen.dart`、`lib/app/l10n/app_en.arb`、`lib/app/l10n/app_zh_Hans.arb`、`lib/app/l10n/app_zh_Hant.arb`
- [X] T060 [US8] 建立固定和随机操作序列的 golden 等价测试，比较事件、四个投影和快照的逐字段增量/重放结果，路径为 `test/unit/features/ledger/domain/services/projection_rebuild_equivalence_test.dart`
- [X] T061 [US8] 建立账务不变量回归测试：posting 增量=余额变化、transfer 净额零、冲正不计统计、月 opening=前月 closing，路径为 `test/unit/features/ledger/domain/services/ledger_invariants_test.dart`
- [X] T062 [US8] 删除或替换未实现的旧 `rebuildProjections` 入口，确保唯一 rebuild 实现位于新服务，路径为 `lib/features/ledger/data/repositories/ledger_repository.dart`

**Checkpoint**: 删除全部派生表可从 Event Store 恢复，且重放错误不会静默产出错误账目。

---

## Phase 11: User Story 9 - 报表切换到同源投影（P9）

**Goal**: 报表只读取快照与事件化投影，分类归档不破坏历史，转账不计入收支/分类占比。

**Independent Test**: 报表月度数字与账户快照同源；含转账月份的分类图不包括转账；归档分类仍以交易写时快照显示。

- [X] T063 [US9] 重写报表 DAO 查询，以月度快照提供收支/余额，以 transactions/postings 投影提供日期 heatmap 与分类分组，路径为 `lib/core/data/database/daos/reports_dao.dart`
- [X] T064 [US9] 将 ReportsRepository 和 reports entities 改为 int minor units 与投影快照来源，路径为 `lib/features/reports/data/repositories/reports_repository.dart`、`lib/features/reports/domain/entities/reports_entities.dart`
- [X] T065 [US9] 更新报表 provider/widgets 的格式化边界，保留现有 heatmap、饼图和 Material 3 行为而不写业务计算，路径为 `lib/features/reports/presentation/providers/reports_providers.dart`、`lib/features/reports/presentation/widgets/`
- [X] T066 [US9] 添加报告 repository/widget 测试，覆盖快照同源、transfer 排除、已冲正排除和归档分类写时快照，路径为 `test/unit/features/reports/data/repositories/reports_repository_test.dart`、`test/ui/features/reports/reports_screen_test.dart`
- [X] T067 [US9] 删除 reports 对旧 Categories join、double totals 和非投影账务来源的依赖，路径为 `lib/features/reports/data/repositories/reports_repository.dart`、`lib/core/data/database/daos/transaction_dao.dart`

**Checkpoint**: 报表没有独立余额/收支算法，所有金额都与账本投影一致。

---

## Phase 12: User Story 10 - 定期转正、旧代码核销与治理（P10）

**Goal**: 保持定期规则 CRUD 豁免的同时让转正产生真实事件；核销 12 项财务风险并完成迁移治理。

**Independent Test**: 定期实例转正产生 TransactionRecorded 且状态同步；全库不存在 double 账务金额、旧写路径或多个余额计算点；12 项风险每项有测试。

- [X] T068 [US10] 将 recurring_series 和 scheduled_transactions_view 的金额字段与实体改为 int minor units，明确它们不参与 rebuild，路径为 `lib/core/data/database/tables.dart`、`lib/features/ledger/domain/entities/ledger_entities.dart`、`lib/features/ledger/data/repositories/recurring_repository.dart`
- [X] T069 [US10] 将定期转正改为一次事务中的 TransactionRecorded 写入与 scheduled 状态更新，保留其余定期 CRUD 直写例外，路径为 `lib/features/ledger/domain/commands/convert_scheduled_to_posted_command.dart`
- [X] T070 [US10] 更新定期表单、查询和 UI 的 minor-units 显示及转正 Result 处理，路径为 `lib/features/ledger/domain/queries/`、`lib/features/ledger/presentation/`
- [X] T071 [US10] 为定期转正及 rebuild 豁免编写服务测试，路径为 `test/unit/features/ledger/domain/services/convert_scheduled_to_posted_test.dart`
- [X] T072 [US10] 核销并删除所有旧事件、旧 handler、旧 repository、旧 DAO 写方法和过期生成引用，路径为 `lib/features/ledger/data/event_handlers/`、`lib/core/data/repositories/event_repository.dart`、`lib/features/ledger/data/repositories/ledger_repository.dart`
- [X] T073 [US10] 用 `rg` 审计并清除账务 domain/data 中的 double/float、`getRunningBalance`、`availableBalance`、`AccountUpdated`、`TransactionPosted`、`TransactionScheduled` 和 `TransactionPendingAdded`，路径为 `lib/`
- [X] T074 [US10] 将已发布事件的 schemaVersion/upcaster/未知事件纪律写入工程治理文档，并将 AGENTS 的“半迁移状态”更新为实际架构，路径为 `.specify/memory/constitution.md`、`AGENTS.md`
- [X] T075 [US10] 为 12 项风险逐项建立可追溯的 G/W/T 回归矩阵并链接对应测试，路径为 `specs/003-event-sourced-ledger/checklists/financial-risk-regression.md`
- [X] T076 [US10] 运行代码生成、格式化、`flutter analyze` 和完整 `flutter test`，修复所有新增失败并记录验证结果，路径为 `specs/003-event-sourced-ledger/quickstart.md`

**Checkpoint**: 迁移完成：Event Store 是唯一事实来源，所有读模型可重建，且没有双轨账务系统。

---

## 迁移核销基线（T004，schema v1 快照）

在变更 schema 前记录的现状基线，供每个切片完成时核销旧路径。**核销规则**：切片完成时将对应行标 ~~删除线~~；全部切片完成后由 T073 用 `rg` 复审全库。

### 现有表（`lib/core/data/database/tables.dart`，schemaVersion = 1）

| 表 | 现状（待核销点） | 替代任务 |
|---|---|---|
| ~~`ledger_events`~~ | ~~旧信封：eventId、type（`runtimeType.toString()`）、occurredAt、recordedAt、payload、correlationId?、metadata?；无 streamId/streamVersion/commandId，无 `unique(streamId, streamVersion)`~~ | T018 ✅ |
| ~~`accounts_view`~~ | ~~`postedBalance` + `availableBalance` 双余额；无币种、无 archived、无 projection version~~ | T025 ✅ |
| ~~`transactions_view`~~ | ~~逐腿行（id=腿 id、transactionId 分组）、signed amount、无 kind、无分类写时快照、无 postings 拆表~~ | T033 ✅ |
| ~~`categories`~~ | ~~纯 CRUD 直写（isDefault/isArchived/archivedAt/isBuildIn/systemCode）~~ | T025 ✅ |
| ~~`recurring_series`~~ | ~~纯 CRUD（金额已是 int）~~ | T068 ✅（`amountMinor` 列 + rebuild 豁免固化） |
| ~~`scheduled_transactions_view`~~ | ~~纯 CRUD~~ | T068 ✅（`amountMinor` 列 + rebuild 豁免固化） |

### 旧写入口（UI 不得新增调用；每切片落地即删）

| 旧入口 | 现状行为 | 核销任务 |
|---|---|---|
| ~~`PostTransactionCommand` → `LedgerTransactionEventHandler._handleTransactionPosted`~~ | ~~append `TransactionPosted` + 追加 `AccountUpdated` 噪音事件 + 直写投影；无 `db.transaction` 包裹~~ | T039 ✅ |
| ~~`ReverseTransactionCommand`~~ | ~~只 append `TransactionReversed`，不跑投影（删除后余额/列表不更新）~~ | T046/T050 ✅ |
| ~~`PostTransferCommand`~~ | ~~只 append 双腿 `TransactionPosted`，绕过投影器（转账不入账）~~ | T044 ✅ |
| ~~`CorrectTransactionCommand`~~ | ~~Reversed+Posted 两事件经 handler，无事务包裹~~ | T046 ✅ |
| ~~`AdjustAccountBalanceCommand`~~ | ~~合成 `TransactionPosted`（double 输入）经 handler 补账~~ | T036 ✅（改经 RecordTransaction + 系统分类；T072 终审） |
| ~~`CreateAccountCommand` / `UpdateAccountCommand` / `DeleteAccountCommand`~~ | ~~append 旧账户事件 + 直写投影（`lastUpdatedEventId: 0`）~~ | T027/T032 ✅ |
| ~~`CategoryRepositoryImpl` add/update/archive（经 transactionsDao）~~ | ~~直写 CRUD~~ | T028/T032 ✅ |
| ~~`seedDatabase`（`lib/app/bootstrap/seeder.dart`）~~ | ~~直写 categories/accounts 投影~~ | T030 ✅ |
| ~~`EventRepositoryImpl.appendEvent`~~ | ~~全部旧事件的唯一 append 点（runtimeType 持久化）~~ — 已迁移到 `DriftEventStore.append` | T020/T024 ✅ |

### 待删符号清单（T073 `rg` 复审口径）

| 符号 / 模式 | 核销任务 |
|---|---|
| ~~`PostTransactionCommand`~~、~~`PostTransferCommand`~~ | T039 ✅ / T044 ✅ |
| ~~`LedgerTransactionEventHandler`（旧投影器）~~ | T039 ✅ |
| ~~`EventRepository` / `EventRepositoryImpl`（runtimeType + 测试工厂注册）~~ | T024 ✅ |
| ~~旧事件 `TransactionPosted`、`TransactionScheduled`、`TransactionPendingAdded`、`AccountUpdated`、`AccountDeleted`~~（`AccountCreated`/`TransactionReversed` 保留名字、payload 重定义） | T032 ✅ / T044 ✅（T072 终审） |
| ~~`TransactionLeg` / `TransactionRole`~~ | T044 ✅ |
| ~~`getRunningBalance`（「回滚未来」余额算法）~~ | T039 ✅（当前余额 = 账户投影之和，含未来交易） |
| ~~`availableBalance`（双余额之一）~~ | T025 ✅（T073 终审） |
| ~~`MonthlySummary`（double 元 VO）与 `watchMonthlyTotals`（double 聚合）~~ | T017/T056 ✅ |
| ~~生产 double 金额入参：`LedgerService.addTransaction/updateTransaction`、`AccountService.createAccount/updateAccount`、表单 `double.parse`~~ | T014/T015 ✅（全库金额 int minor units，唯一 double 桥接为 `Money.fromDouble` 输入边界） |
| ~~未实现的 `rebuildProjections` 引用~~ | T062 ✅（唯一 rebuild 实现在 `ledger_rebuild_service.dart`） |

---

## Dependencies & Execution Order

- Phase 1 → Phase 2 是所有切片的硬前置。
- US1（Money/Result）必须先完成，US2（Event Store）建立可写可读的基础。
- US3（账户/分类）完成后，US4（收支）才能对账户/分类投影执行完整校验。
- US5（转账）依赖 US4 的 TransactionRecorded 投影；US6（冲正）依赖 US4/US5。
- US7（快照）依赖所有余额事件（US3–US6）；US8（rebuild）依赖完整事件化投影与快照。
- US9（报表）依赖 US7；US10 在全部功能完成后执行核销。定期 CRUD 的字段迁移可以在 US4 后并行准备，但其转正切换须等待 US4。

## Parallel Opportunities

- T002 与 T003 可并行；T006、T007 可并行，随后汇入 T008–T010。
- 在 US3 中，账户和分类事件 payload/命令可分文件并行，但 T026 的统一 projector 需在两者接口确定后进行。
- US4 的 schema/projector（T033–T034）与 UI 映射准备（T037）可并行；命令接线（T035–T036）随后进行。
- US7 的表/DAO（T051）可与快照查询 UI 准备（T054）并行；T052–T053 是其共同依赖。
- US8 的等价测试（T060）与不变量测试（T061）可并行；US9 的 repository/展示层任务可在 T063 契约稳定后分工。

## Implementation Strategy

### MVP first

1. 完成 Phase 1–2。
2. 交付 US1–US4：精确金额、可读 Event Store、事件化账户/分类，以及收入/支出闭环。
3. 在真实 UI 上独立验证“新增收入/支出 → 事件、列表、余额一致”，再继续。

### Incremental delivery

1. US5：安全转账和信用卡还款。
2. US6：可审计修改/删除。
3. US7–US8：月度快照与可证明正确的 rebuild。
4. US9：同源报表。
5. US10：定期转正与全库风险核销。

## Format Validation

所有任务均采用 `- [ ] T### [P?] [US#?] 描述 + 精确路径` 格式；Setup、Foundational 和跨切片任务没有 US 标签，故事任务均带 US 标签。

---

## Phase 13: Convergence

- [ ] T077 CRITICAL 将迁移涉及的 ledger、reports 与 settings presentation 组件改为 ThemeExtension token 和统一 DS wrappers，移除直接 palette/typography/spacing/radius 原语，以满足 Constitution III（contradicts），路径为 `lib/features/ledger/presentation/`、`lib/features/reports/presentation/`、`lib/features/settings/presentation/`、`lib/app/design_system/`
- [X] T078 让月度 ledger 汇总和 reports 汇总按 `currencyCode` 分组并在 UI 分币种展示或筛选，禁止跨币种相加且不引入汇率换算，以满足 Spec 多币种硬约束与 US9（contradicts），路径为 `lib/features/ledger/domain/queries/watch_monthly_snapshot_query.dart`、`lib/features/reports/data/repositories/reports_repository.dart`、`lib/core/data/database/daos/reports_dao.dart`、`lib/features/ledger/presentation/`、`lib/features/reports/presentation/`
- [X] T079 保持每日交易汇总和 UI 模型使用 int minor units，直到 `formatMinor` 的最终显示边界，移除 `LedgerTimeline` 的 double 金额累加/除法，以满足 Spec Money 值对象与 US26（contradicts），路径为 `lib/features/ledger/presentation/widgets/ledger_timeline.dart`、`test/ui/features/ledger/ledger_timeline_test.dart`
- [ ] T080 将 Event Store 的行为验收迁移为 `LedgerService`/`AccountService` 加内存 Drift harness 的外部可观察测试，并将直接 EventStore 测试限缩为结构性适配器测试，以满足 Spec Testing Strategy（contradicts），路径为 `test/unit/features/ledger/domain/services/event_store_contract_test.dart`、`test/support/event_sourcing/ledger_service_harness.dart`、`test/unit/features/ledger/domain/services/`
