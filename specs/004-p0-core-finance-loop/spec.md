# Spec：P0 基础财务能力闭环（004-p0-core-finance-loop）

Status: ready-for-agent

决策来源：`docs/reports/2026-09-21-product-feature-audit.md` 第三节「P0 — 基础财务能力缺口」四个功能项，经用户 2026-09-21 就编辑能力、备份格式、交付形态、系列管理范围四个问题确认。与 `plan.md`、`tasks.md` 冲突时，一律以本文件为准。

> **实施引用基线**：本 spec 只把**已有底层能力接到用户手上**。它不引入新的领域模型、不新增事件类型、不修改任何已发布事件 payload、不新增数据库索引、不动 `AppDatabase.schemaVersion`（保持 1）。收尾以 `git diff lib/features/ledger/domain/events/ledger_events.dart lib/core/data/database/tables.dart` 为空验收。

## Background / 背景与问题陈述

`docs/reports/2026-09-21-product-feature-audit.md` 逐项核对了 Feather Ledger 与 ezBookkeeping，结论是：Feather 已有扎实的本地账本核心（可重建的 Event Store + 同事务 Projection、账户余额与月度快照测试良好），最大的空白不是服务器能力，而是**五个会直接影响日常使用的产品环**。

其中被列为 P0 的四个缺口有共同形状：不是「缺底层能力」，而是**底层已经存在、但用户够不到**。

- **转账**：`Transaction.transfer`、`RecordTransactionCommand.executeTransfer`、`LedgerService.addTransfer`、双 posting 投影与 `ledger_transfer_test.dart` 全都在，但新增表单只提供收入/支出。用户只能把搬钱记成两笔收支，直接污染月度收支合计。更糟的是详情页的编辑按钮对转账一直可点，而 `CorrectTransactionCommand` 拒绝 transfer ——「可见入口与后端能力不一致」。
- **周期/计划交易**：`RecurringSeries`/`ScheduledTransactionsView`、RRULE 物化命令、转正命令、服务层 watch 全都在，但 `RecurringDao.saveSeries` 在 `lib/` 里零调用方、`RecurringRepository` 接口没有它、`ProjectRecurringEventsCommand` 有 provider 但没有任何 `ref.watch`、`main.dart` 从不调用它、`LedgerViewModel.scheduledTransactions` 订阅了一条 Drift 流但没有任何组件读它。
- **检索与数据可携带性**：`lib/` 全库 grep 不到 `search`，`TransactionsDao` 只有一个按月硬切的 watch 方法，没有导出 service、没有 route、没有依赖。
- **备份/恢复**：`lib/` 全库 grep `backup|export|restore|csv` 只命中 Dart 的 `export '...'` 语句。数据库在 `getApplicationSupportDirectory()/db.sqlite`，没有任何机制把用户数据带出应用。这是审计里唯一标 **High** 的项。

对用户而言，这意味着：搬钱要记成收支（数字错）、每月固定的账单要手记（会忘）、历史找不回来（等于没有历史）、手机一丢全没了（等于没有数据）。

## Goals / 目标

- 转账有完整的创建 / 查看 / 编辑 / 删除闭环，同币种，复用既有双 posting 写入路径。
- 修正 `CorrectTransactionCommand` 的 kind 校验漏洞：判据是**原交易的 kind**，不是传入的 `type`。
- 周期系列可创建、可停用；到期实例以「待办」呈现，由用户显式「记入」或「跳过」；应用启动时幂等补课。
- 交易可按关键词 + 类型 + 账户 + 分类 + 日期范围检索，结果可导出为 CSV。
- 账本可一键备份为单个可分享文件，可从中恢复；恢复是**替换**语义，且可被校验与撤销。
- 补齐在此过程中被暴露的既有缺口：`currencyMismatch` / `sameAccountTransfer` 两个错误码的本地化，以及周期状态的编解码一致性。

## Non-goals / 非目标

- **跨币种转账**：需要汇率快照与双金额模型，属于 P2（见审计「汇率、基准币、跨币种转账」）。本 spec 只做同币种，并让不同币种的组合在选择器上不可选。
- **周期系列的就地编辑**：用户已确认范围为「创建 + 停用」。改规则 = 停用旧的 + 建新的。
- **周期实例的自动入账**：不照搬 ezBookkeeping 依赖常驻服务端的「到期自动创建」语义；本地应用一律用户显式确认。
- **本地到期提醒 / 通知**：周期闭环稳定后再做。
- **导入**（CSV/账单）：审计列为 P1。本 spec 只做导出。
- **标签、预算、对账工作流、附件、PIN/生物识别锁、汇率与基准币、账户层级、模板/草稿、拆分交易**：均为 P1/P2，不在本 spec。
- **数据清除**：审计矩阵中有，但不属 P0 四项。ES 语义下「可恢复归档」与「不可逆清除」需要单独定义。
- **报表热力图 `frequency`/`amount` 语义修复、点日期进入已筛选流水**：审计路线图 Phase 1 提到，但不属 P0 四项。后者在 US3 落地后变成一行跳转，可作独立小任务。
- **任何事件 payload / 事件类型 / 表结构 / schemaVersion 变更**：见 Background 的实施引用基线。

## User Stories / 用户故事

### User Story 1 — 转账产品闭环（Priority: P1）

作为记账人，我想在账户之间转账，所以两个账户余额各自变动，而月度收支统计不被污染。我想用还款表达信用卡还款，所以它不被重复计为支出。我记错了金额或账户时想直接改，所以不必删除再重记。

**Why this priority**: 审计列为首项。写路径全部就绪且已测试，只差 UI；而缺它时用户会把搬钱记成收支，**直接产生错误的收支统计**——这是数据正确性问题，不只是便利性问题。

**Independent Test**: 新建一笔转账 → 列表出现中性色、无符号的转账行 → 两个账户余额一增一减 → 详情页编辑金额与账户 → 余额正确、审计链显示 correction → 删除可用。

**Acceptance Scenarios**:

1. **Given** 两个同币种账户 A、B，**When** 用户从 A 向 B 转账 100，**Then** A 余额减 100、B 余额增 100，列表出现一条 kind=transfer 的行，且该行不是收入色也不是支出色。
2. **Given** 一笔已记录的转账，**When** 用户把它改为 150，**Then** 原交易被冲销（`TransactionReversed(correction)`）、新交易被记录，余额等于「一开始就记 150」的情形，两个事件共用同一个 `commandId`。
3. **Given** 一笔已记录的转账，**When** 用户以收入/支出形态提交更正，**Then** 被拒绝为 `invalidTransfer`（转账原交易必须走 `executeTransfer`）。
4. **Given** 一笔已记录的收入，**When** 用户以转账形态提交更正，**Then** 被拒绝为 `invalidTransfer`。
5. **Given** 转账表单，**When** 用户选定了「从」账户，**Then** 「到」的候选中不含该账户本身，也不含与「从」账户币种不同的账户。
6. **Given** 用户把「从」与「到」选成同一账户（例如通过竞态），**When** 提交，**Then** 显示本地化的「同一账户」错误文案，而不是原始枚举名。
7. **Given** 一笔转账，**When** 用户在详情页查看，**Then** 金额为中性色、无 `+`/`-` 前缀，且编辑与删除均可用。

### User Story 2 — 周期账单闭环（Priority: P2）

作为记账人，我想为房租、订阅、工资这类固定账单建一个规则，所以不用每月手记；到期时我想看到待办并决定「记入」或「跳过」，所以余额不会在我没确认时被改动。

**Why this priority**: 周期交易是长期记账的基本场景。底层（RRULE、系列表、实例表、物化命令、转正命令）全部已实现且幂等，缺的只是创建入口、启动补课与呈现。

**Independent Test**: 新建「每月 1 号房租」→ 立即出现在系列列表且待办区出现到期实例 → 「记入」→ 账本页出现该笔交易、状态转 posted → 再建一个 → 「跳过」→ 状态 skipped、账本无变化 → 停用 → 不再新增，既有实例仍在。

**Acceptance Scenarios**:

1. **Given** 尚无任何周期系列，**When** 用户创建「每月 1 号、金额 X、账户 A、分类 C」的系列，**Then** 系列入库，且未来 12 个月内符合规则的实例被物化，状态为 `scheduled`。
2. **Given** 同一系列，**When** 应用再次启动（补课重跑），**Then** 不产生任何重复实例（实例 id 由 `seriesId` 与日期推导，幂等）。
3. **Given** 一个到期的 `scheduled` 实例，**When** 用户点「记入」，**Then** 产生一条 `TransactionRecorded`，且该实例状态在同一次 append 事务里翻为 `posted` 并回填 `transactionId`。
4. **Given** 一个 `scheduled` 实例，**When** 用户点「跳过」，**Then** 状态变为 `skipped`，**不产生任何事件、不改动任何余额**。
5. **Given** 一个已 `posted` 的实例，**When** 用户再次尝试记入或跳过，**Then** 被拒绝并显示「该周期交易已入账」的本地化文案，而不是「交易已被冲销」。
6. **Given** 一个系列，**When** 用户停用它，**Then** `endDate` 被设置、既有实例全部保留、之后不再物化新实例。
7. **Given** 数据库中某实例的 status 列含未知字符串，**When** 界面读取该实例，**Then** 降级为 `scheduled` 而不抛异常。

### User Story 3 — 检索、基础筛选与 CSV 导出（Priority: P3）

作为记账人，我想按关键词、类型、账户、分类、日期范围找到历史交易，并把当前结果导出成 CSV，所以我的数据找得到、带得走。

**Why this priority**: 审计称其「比复杂自定义报表更早成为长期使用门槛」。读投影天然适配，且不触及写模型。

**Independent Test**: 搜索图标 → 输入关键词 → 结果按天分组 → 筛「转账 + 某账户」→ 该账户参与的两条腿的转账都出现且只出现一次 → 导出 → 文件能打开、中文不乱码、逗号被正确转义。

**Acceptance Scenarios**:

1. **Given** 若干历史交易，**When** 用户输入关键词，**Then** 命中备注、分类写入时快照名称或账户名，结果按天分组、按时间倒序。
2. **Given** 关键词筛选结果，**When** 用户再加「类型 = 转账」与某个账户，**Then** 结果同时满足全部条件（AND），且该账户参与的转账**只出现一次**（两条 posting 合并为一条记录）。
3. **Given** 一笔已被冲销的交易，**When** 用户检索，**Then** 它**不出现**在结果中。
4. **Given** 日期范围筛选，**When** 用户把起止设为同一天，**Then** 该天的交易全部命中（两端含端点）。
5. **Given** 筛选结果，**When** 用户点导出，**Then** 生成 CSV，含 UTF-8 BOM，含逗号/引号/换行的备注被 RFC 4180 正确转义。
6. **Given** 结果为空，**When** 用户查看导出按钮，**Then** 它是禁用状态（导出所见即所得，不允许导出为空或与屏幕不一致）。

### User Story 4 — 可靠本地备份与恢复（Priority: P2）

作为记账人，我想把整个账本导出成一个文件并能在换设备或误删后恢复，所以我的数据不会因为一次意外就永久消失。

**Why this priority**: 审计里唯一标 **High** 的项，是本地优先产品的安全底线。它与其它三个故事完全正交，可独立交付。

**Independent Test**: 设置 → 立即备份 → 分享出的文件能被解开且含三个条目 → 改动一些数据 → 从备份恢复 → 确认框显示事件条数对比 → 暂存后退出 → 重新打开 → 数据回到备份时刻。

**Acceptance Scenarios**:

1. **Given** 一个正常账本，**When** 用户执行备份，**Then** 得到一个单文件归档，内含 `manifest.json`、`db.sqlite`（由 `VACUUM INTO` 产出的一致快照）、`preferences.json`。
2. **Given** 一个备份文件，**When** 用户在恢复确认框中看到提示，**Then** 提示写明该备份的事件条数、当前事件条数、以及恢复将丢弃的条数。
3. **Given** 一个来自未来 schemaVersion 或错误 format 的备份，**When** 用户尝试恢复，**Then** 被拒绝，且**不写入**待恢复标记（当前数据不受任何影响）。
4. **Given** 一个内容损坏的备份（zip 合法但内部 `db.sqlite` 截断），**When** 用户尝试恢复，**Then** 完整性校验失败，**不写入**待恢复标记。
5. **Given** 一个已通过校验并暂存的备份，**When** 用户下次启动应用，**Then** 数据库被替换、陈旧的 `-wal`/`-shm`/`-journal` 被清除、待恢复标记被消费、恢复出的偏好被应用。
6. **Given** 替换过程中任一 rename 失败，**When** 启动流程继续，**Then** 原账本完好无损（回滚）。
7. **Given** 恢复成功，**When** 用户检查文件系统，**Then** 恢复前的那份数据库留有 `db.sqlite.replaced`。

### Edge Cases

- 转账的两个账户币种不同 → 聚合根以 `transferCurrency` 拒绝，界面通过选择器过滤让它不可选；错误码必须本地化。
- 转账的「从」与「到」是同一账户 → 聚合根以 `transferSameAccount` 拒绝；错误码必须本地化。
- 编辑一笔已被冲销的交易 → `transactionAlreadyReversed`（既有行为，不变）。
- 周期系列的 `endDate` 早于或等于 `startDate` → 物化出零条实例；系列仍必须**在列表中可见**（这是 `watchAllSeries` 存在的理由）。
- 周期系列的 `startDate` 在未来 → 待办区不显示，系列列表显示下次实例日期。
- 周期补课在中途崩溃 → 留下部分实例集。**这是可接受的**：命令幂等，下次启动补完。不包事务。
- 补课过程中某条系列数据损坏 → 不得阻止应用启动（降级 + 日志）。
- 检索关键词含 `%` 或 `_` → 不得退化为「匹配全部」。
- 检索结果集无上限 → 个人账本规模可接受；到 10^5 行量级时加 keyset 分页（已在代码留 `ponytail:` 标记）。
- 备份目标文件已存在 → `VACUUM INTO` 要求目标不存在，每次备份写新的临时文件，绝不覆盖。
- 恢复时旧库留下 `-wal` → 必须删除，否则 SQLite 会把陈旧 WAL 帧应用到**恢复后的**库上，造成静默损坏。
- 暂存了恢复但用户没有重启 → 下次启动才生效；不得在同一次运行中应用（`SharedPreferences` 按进程内存缓存）。

## Requirements / 需求

### Functional Requirements

- **FR-001**: 用户 MUST 能在两个同币种、不同、且均未归档的账户之间创建转账，无需分类。
- **FR-002**: 系统 MUST 让「到」账户的候选项按「从」账户的币种过滤，使跨币种与同账户组合在选择器上不可达。
- **FR-003**: 用户 MUST 能编辑与删除一笔转账；编辑 MUST 以 `TransactionReversed(correction)` + 新 `TransactionRecorded` 成对落地，且两个事件 MUST 在同一次 append 中写入并共用一个 `commandId`。
- **FR-004**: 更正的合法路径 MUST 由**原交易的 kind** 决定：transfer 原交易只能经 transfer 形态更正，income/expense 原交易只能经 income/expense 形态更正；越界 MUST 以 `invalidTransfer` 拒绝。
- **FR-005**: 转账在列表与详情 MUST 以中性 `onSurface` 配色与空符号前缀渲染，不得复用收入或支出的配色与符号。
- **FR-006**: 用户 MUST 能创建周期系列（类型 ∈ {income, expense}、金额、账户、分类、描述、频率、间隔、开始日期、可选结束日期）；系列类型的取值域 MUST 使 transfer 不可表达。
- **FR-007**: 创建系列时系统 MUST 复用 `PostingContextResolver` 校验账户与分类（存在、未归档、分类 kind 匹配）。
- **FR-008**: 系统 MUST 在应用启动时幂等地物化周期实例；重复执行 MUST NOT 产生重复实例。
- **FR-009**: 物化循环 MUST NOT 因单条系列数据损坏而阻止应用启动（降级 + 日志）。
- **FR-010**: 用户 MUST 能对到期的 `scheduled` 实例执行「记入」或「跳过」；「记入」MUST 产生一条 `TransactionRecorded` 并在同一事务内把状态翻为 `posted`；「跳过」MUST NOT 产生任何事件或余额变动。
- **FR-011**: 系统 MUST 拒绝重复处理已 `posted` 的实例，并以专用错误码而非 `transactionAlreadyReversed` 呈现。
- **FR-012**: 用户 MUST 能停用一个系列；停用 MUST 设置 `endDate`、保留全部既有实例、并停止物化新实例。
- **FR-013**: 周期实例状态的编解码 MUST 由单一定义驱动（枚举名），遇到未知字符串 MUST 降级为 `scheduled` 而非抛异常。
- **FR-014**: 用户 MUST 能按关键词、类型、账户、分类、日期范围检索交易，多条件按 AND 组合。
- **FR-015**: 关键词 MUST 匹配备注、分类写入时快照名称与账户名；用户输入中的 `%` 与 `_` MUST NOT 被当作通配符。
- **FR-016**: 检索 MUST 排除已冲销的交易。
- **FR-017**: 账户筛选 MUST 匹配转账的任一条 posting（两条腿），且结果中该转账 MUST 合并为单条记录并保留 `toAccount`。
- **FR-018**: 日期范围 MUST 两端含端点、按天粒度。
- **FR-019**: 用户 MUST 能把当前筛选结果导出为 CSV；CSV MUST 含 UTF-8 BOM、RFC 4180 转义、ISO 日期、机器可读的 kind 名；金额 MUST 与界面符号约定一致（收支带符号、转账不带）。
- **FR-020**: 检索 MUST NOT 依赖任何新增数据库索引，MUST NOT 变更 `schemaVersion`。
- **FR-021**: 用户 MUST 能把账本备份为单个可分享文件，内含 `manifest.json`、`VACUUM INTO` 产出的一致数据库快照、以及偏好设置。
- **FR-022**: 备份 MUSH 携带容器 format/formatVersion、数据库 schemaVersion、应用版本、导出时间、事件条数与最大 GSN。
- **FR-023**: 恢复 MUST 先校验（format/formatVersion/schemaVersion/`PRAGMA integrity_check`/可打开），校验失败 MUST NOT 留下待恢复标记。
- **FR-024**: 恢复 MUST 是替换语义，确认界面 MUST 明示将丢弃的事件条数；系统 MUST NOT 提供合并路径。
- **FR-025**: 待恢复状态 MUST 以文件系统标记表达（早于任何 provider 与 `SharedPreferences` 可读），替换 MUST 发生在数据库被任何东西打开之前。
- **FR-026**: 替换 MUST 清除陈旧的 `-wal`/`-shm`/`-journal` 副档；任一 rename 失败 MUST 回滚并保持原账本完好。
- **FR-027**: 关闭 `LedgerErrorCode` 中每一个成员都 MUST 有本地化文案；MUST NOT 有成员回落到 `errorPrefix(code.name)`（即把原始枚举名显示给用户）。
- **FR-028**: 新增的每一个用户可见字符串 MUST 出现在全部四个 ARB 文件（`app_en.arb`、`app_zh.arb`、`app_zh_Hans.arb`、`app_zh_Hant.arb`）。

### Key Entities

- **Transaction（聚合根）**：本 spec 不修改。转账复用它既有的两 posting 形态。
- **RecurringSeries**：CRUD-exempt 表，非事件溯源、重建不触碰。本 spec 增加**创建**与**停用**两条写路径。
- **ScheduledTransactionsView**：CRUD-exempt 表，周期实例。本 spec 增加**跳过**写路径，并统一其状态编解码。
- **TransactionFilter**：新增值对象，不落库。六字段（关键词、kind、账户、分类、起、止），手写 `==`/`hashCode`（Riverpod 按 `==` 去重 state）。
- **BackupManifest**：新增值对象，序列化为归档内的 `manifest.json`。

## Success Criteria / 成功标准

### Measurable Outcomes

- **SC-001**: 用户能在 30 秒内、不离开账本页完成一笔转账的创建。
- **SC-002**: 一笔转账**编辑后**的账户余额与「一开始就按新值记录」完全相等（可自动化断言的一致性）。
- **SC-003**: 全部 `LedgerErrorCode` 成员都有本地化文案——由一条遍历封闭集合的单测守护。
- **SC-004**: 同一个周期系列连续物化两次，实例集合完全相同（幂等，可自动化断言）。
- **SC-005**: 「跳过」一个周期实例后，账户余额与事件流**零变化**。
- **SC-006**: 检索结果中的每一笔转账都恰好出现一次，且带完整的 from/to 两侧信息。
- **SC-007**: 导出的 CSV 在 Windows Excel 中打开时中文不乱码，含逗号与引号的备注不破坏列结构。
- **SC-008**: 备份 → 恢复的完整往返后，账本数据与备份时刻**逐字段相等**。
- **SC-009**: `flutter analyze` 零问题；`flutter test` 从 192 项基线只增不减。
- **SC-010**: `git diff lib/features/ledger/domain/events/ledger_events.dart lib/core/data/database/tables.dart` 为空。

## Assumptions

- 无真实用户数据，开发库可丢弃（沿用 `specs/003` 的既定假设）——但这**不**降低备份/恢复的正确性要求，因为该功能本身就是为真实数据而做的。
- 目标平台具备「分享文件」与「选取文件」的系统能力；这是 FR-019/FR-021 的前提。
- 单用户、单设备、本地优先；无同步、无冲突合并需求。
- 用户已确认工作区中未提交的 T077/T080 改动会先收口再开始本 spec（见 tasks.md 的 Phase 1）。
- 周期补课的 12 个月视野与既有的 `ProjectRecurringEventsCommand` 行为保持不变。
