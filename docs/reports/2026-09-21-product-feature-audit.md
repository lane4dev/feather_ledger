# Accounted For 产品功能审查与 ezBookkeeping 对比

**审查日期：** 2026-09-21  
**范围：** 当前工作区的 Flutter/Dart 实现、测试与规格文档；ezBookkeeping 的官方 README、功能清单、使用/API/导入导出文档。  
**结论口径：** `✅ 已实现` 必须同时有持久化/业务路径和可到达的用户流程（除纯底层指标外）；只存在表、Event、Command、Repository 或测试的一律不自动算完成。

## 审查方法与证据边界

- 本地逐项检查了 `lib/` 的 ledger/reports/settings、Drift 表与 DAO、Event Store、Projector/Rebuild、路由、ARB、服务/命令/查询及测试。README 仍是 Flutter 初始模板，不能用作功能依据。
- ezBookkeeping 以其[官方功能清单](https://ezbookkeeping.mayswind.net/features/)、[基本使用说明](https://ezbookkeeping.mayswind.net/basic_usage/)、[交易 API](https://ezbookkeeping.mayswind.net/httpapi/transaction_api)、[导入导出说明](https://ezbookkeeping.mayswind.net/export_and_import/)和[官方 README](https://github.com/mayswind/ezbookkeeping/blob/main/README.md)为准。功能清单包含标注到 2.0.0 的能力，而 GitHub 当时最新 Release 为 1.6.1；故本文的“ez 有”表示当前官方文档已声明，而非保证每个旧版本均有。
- 质量核验：`flutter test` 通过（192 项），`flutter analyze` 为 `No issues found`。它们支持事件/投影逻辑的可信度，但不证明 UI 产品闭环。
- 不把 Docker、Server、多用户、OIDC、HTTP API、CLI、管理员后台、NAS 或对象存储列为 Accounted For 缺口；它们属于 ezBookkeeping 自托管产品边界。

## 一、执行摘要

Accounted For 已有扎实但仍偏 MVP 的本地账本核心：收入/支出记账、账户与一级收支分类管理、交易编辑/删除、按月流水、分类饼图和活动热力图；写路径是可重建的 Event Store + 同事务 Projection，账户余额与月度快照也有良好测试。对于个人本地优先产品，这是比“功能数量”更难补的可靠基础。

最大空白不是服务器能力，而是以下五个会直接影响日常使用的产品环：

1. **转账没有 UI。** `Transaction.transfer`、`addTransfer` 和双 posting 投影已存在并被单测覆盖，但新增表单只提供收入/支出；用户无法创建转账。
2. **周期交易没有闭环。** 有 RRULE、系列/实例表、未来实例物化命令和“转正”命令，却没有系列创建/管理、启动 catch-up、列表展示或用户确认入口。
3. **检索与数据可携带性为零。** 没有搜索、筛选、导入、导出、备份恢复或数据清除；这比复杂自定义报表更早成为长期使用门槛。
4. **账户能力尚浅。** 没有层级、对账、账户余额趋势/资产分布，且所谓多币种只是每账户保存币种；没有汇率、基准币或跨币种转账。
5. **预算和报告尚未进入计划/分析产品。** 月度分类汇总与热力图存在，但没有预算、趋势、时间范围、同比环比或资产分析。值得注意的是：ezBookkeeping 官方资料也**未**证明有预算或原生拆分交易，因此这些是 Accounted For 自主产品选择，不是机械补齐。

不影响当前定位的缺口包括多用户、部署、服务端认证、Web API/CLI、常驻调度服务、AI/MCP、对象存储和多地图服务。相反，最高价值的本地功能是：转账 UI、轻量周期账单、搜索/筛选、CSV 导出与受保护备份、对账、预算和账户/资产趋势。

## 二、完整功能差异矩阵

| 领域功能 | ezBookkeeping | Accounted For | 状态 | Accounted For 代码证据 | 说明 |
| --- | --- | --- | --- | --- | --- |
| **核心记账：收入/支出** | 有 | 表单可新增 | ✅ 已实现 | `features/ledger/presentation/screens/transaction_form_screen.dart`；`domain/commands/record_transaction_command.dart` | 表单、校验、事件 `TransactionRecorded`、投影和月列表均接通。 |
| 交易时间 | 有日期、时间、时区/UTC offset | 可选日期与时分 | ✅ 已实现 | `transaction_form_screen.dart:_pickDateTime`；`domain/model/transaction.dart:occurredAt` | 保存业务时间；无用户可配时区，见国际化行。 |
| 备注/自由文本描述 | 有 description/note | 一个 Note 输入 | ✅ 已实现 | `transaction_form_screen.dart`；`record_transaction_command.dart` | Note 同时写入 description/notes/posting memo；不是独立商户字段。 |
| 编辑交易 | 有 | 收支交易可编辑 | ✅ 已实现 | `transaction_detail_sheet.dart`；`correct_transaction_command.dart` | 以 reversal + 新记录保存审计链，已在 UI 可达。 |
| 删除交易 | 有 | 可删除 | ✅ 已实现 | `ledger_transaction_list.dart`；`reverse_transaction_command.dart` | UI 确认后写 `TransactionReversed(userDeleted)`，而非物理删除。 |
| 收入/支出审计历史 | 未作为主要卖点 | 交易详情可看记录/冲销链 | ✅ 已实现 | `transaction_detail_sheet.dart`；`get_transaction_history_query.dart` | ES 的用户可见收益。 |
| 账户间转账 | 有，支持源/目标金额 | 领域/服务可写，UI 不可建 | 🟡 部分实现 | `domain/model/transaction.dart:Transaction.transfer`；`ledger_service.dart:addTransfer`；`ledger_type_selector.dart` | 表单只列 income/expense，未选择源/目标账户；不能视为用户功能。 |
| 双边 posting / 转账语义 | 双侧 transfer，不应误称完整会计总账 | 两个相等反向 posting | 🟡 部分实现 | `domain/model/transaction.dart`；`ledger_projector.dart` | 模型可靠、投影会同时改余额；欠缺转账创建、编辑 UX 和跨币种策略。 |
| 转账编辑 | 可修改交易 | 详情会露出编辑按钮但命令拒绝 transfer | 🟡 部分实现 | `transaction_detail_sheet.dart`；`correct_transaction_command.dart` | 这是可见入口与后端能力不一致的缺口；删除可用。 |
| 批量操作 | Insights Explorer 可批改 | 无 | ❌ 未实现 | `transaction_dao.dart` 仅按月 watch；路由无批量页 | 无选择模式、批量命令或筛选集合。 |
| 交易模板 | 有 | 无 | ❌ 未实现 | `tables.dart` 无模板表；`transaction_form_screen.dart` 无模板入口 | 适合常用账目，但不必先做复杂模板变量。 |
| 草稿自动保存 | 有 | 无 | ❌ 未实现 | `transaction_form_screen.dart` 仅在 `_submit` 写入 | 退出/崩溃会丢失输入。 |
| 周期/计划交易 | 有；服务器持续运行时自动创建 | 数据/命令存在，产品流程未完成 | 🟡 部分实现 | `tables.dart:RecurringSeries/ScheduledTransactionsView`；`project_recurring_events_command.dart`；`convert_scheduled_to_posted_command.dart`；`main.dart` | 无创建系列 API/UI、无启动物化调用、无到期列表/确认控件；本地版应采用启动 catch-up/通知，不照搬常驻服务。 |
| 原生拆分交易 | 官方未证明；IIF split 会拆成多笔导入 | 无 | ❌ 未实现 | `Transaction.validate` 限制收支恰一 posting、transfer 恰两 posting | 不应以 ez “功能差”驱动；若做，需要新的 aggregate/event/projection/UI。 |
| **分类/扩展：账户类型** | 现金、支票、信用、债务等 | cash/bank/credit/other | ✅ 已实现 | `core/domain/enums.dart:AccountType`；`account_form_sheet.dart` | 可创建、显示并投影；信用账户允许负余额。 |
| 多账户 | 有 | 有 | ✅ 已实现 | `account_management_screen.dart`；`accounts_view`；`account_providers.dart` | 账户管理和记账选账户均可达。 |
| 账户层级/子账户 | 两级 | 无 parent 字段或 UI | ❌ 未实现 | `core/domain/entities/account.dart`；`tables.dart:AccountsView` | 仅平铺账户。 |
| 账户图标/颜色/排序/描述/额度/账单日 | 有多项元数据 | 仅名称、类型、币种、余额、归档 | ❌ 未实现 | `AccountEntity`、`AccountsView` | 信用卡账单日/额度不是当前 P0。 |
| 收入/支出分类 | 有 | 有 | ✅ 已实现 | `category_management_screen.dart`；`CategoryCreated`；`CategoriesView` | 创建、重命名、归档及交易选择接通。 |
| 多级分类 | 两级 | 无 parentId | ❌ 未实现 | `CategoryEntity`、`CategoriesView` | 仅一级；先以标签补横向维度通常更轻量。 |
| 分类归档 | 有 | 有 | ✅ 已实现 | `archive_category_command.dart`；`category_form_sheet.dart` | 历史交易有写入时分类快照。 |
| 标签 | 有，多标签/组/布尔筛选 | 无 | ❌ 未实现 | `TransactionRecorded`/`TransactionsView` 无 tags 字段 | 高价值检索与分析维度。 |
| 图片/票据附件 | 有，含识别能力 | 无 | ❌ 未实现 | `pubspec.yaml` 与交易模型/表均无附件存储 | 移动端很有价值；AI 识别可后置。 |
| 地理位置 | 有经纬度与地图 | 无 | ⚪ 不适用 / 不建议实现 | 交易模型/表无 location | 对轻量账本不是核心，除非用户研究消费地点。 |
| 商户/Payee | 官方也没有独立结构字段 | 无独立字段 | ⚪ 不适用 / 不建议实现 | `Transaction` 仅 description/notes；表单仅 Note | 先把 note 全文搜索做好；有证据后再升格为实体。 |
| 自定义字段 | 官方未证明 | 无 | ⚪ 不适用 / 不建议实现 | 交易事件/schema 无扩展字段 | 会显著扩大迁移、查询与 UI 复杂度。 |
| 交易状态（pending/cleared） | 官方未证明 | 无 | ⚪ 不适用 / 不建议实现 | `TransactionsView` 仅 `isReversed` | 若先实现对账，再评估 cleared。 |
| 搜索 | 有关键词/description 等 | 无 | ❌ 未实现 | `TransactionsDao.watchTransactionsByMonth` 只有月份范围 | 没有搜索 UI、Query 或索引。 |
| 筛选/排序 | 有账户/分类/标签/金额等及高级条件 | 仅固定按月、时间倒序 | ❌ 未实现 | `transaction_dao.dart:watchTransactionsByMonth` | 月份翻页不是通用筛选；也无金额/账户/分类筛选。 |
| 高级查询/多视图 | Insights Explorer、日历/图库等 | 无 | ⚪ 不适用 / 不建议实现 | 仅 `LedgerScreen` 月流水 | 先提供简单筛选；表达式查询器会造成 feature creep。 |
| **账户与资产：当前余额** | 有 | 有 | ✅ 已实现 | `AccountsView.balanceMinor`；`ledger_projector.dart`；`account_tile.dart` | Projector 是唯一余额计算点。 |
| 历史余额/月度快照 | 面向用户有余额/趋势，内部机制未声明 | 每账户每币种月快照已维护，UI 只消费月汇总 | 🟡 部分实现 | `MonthlyAccountBalanceSnapshots`；`monthly_snapshot_projector.dart`；`reports_dao.dart:watchMonthlyTotals` | 底层强，但没有账户历史余额浏览/钻取。 |
| 账户余额趋势 | 有 | 无 | ❌ 未实现 | 快照没有对应 query/provider/chart | 已有可复用快照，成本相对低。 |
| 账户对账/Reconciliation | 有流水余额、期末调整、statement | 仅“改余额→普通调整交易” | 🟡 部分实现 | `account_form_sheet.dart:_save`；`account_service.dart:adjustAccountBalance` | 有调整原语，但没有 statement、cleared 状态、差异计算或对账流程。 |
| 账户归档 | 有 | 有 | ✅ 已实现 | `archive_account_command.dart`；`account_form_sheet.dart` | 归档后不在选择器，但保留历史与余额。 |
| 资产/负债分布 | 有 | 无 | ❌ 未实现 | `reports_dao.dart` 只做分类与月汇总 | 账户 type 有基础，缺 query 和图表。 |
| 多币种账户 | 有账户币种、汇率和默认币换算 | 账户存币种，但创建/展示围绕全局偏好 | 🟡 部分实现 | `AccountEntity.currencyCode`；`AppCurrencies`；`account_form_sheet.dart` | 可持久化币种；新账户币种由全局 setting 决定，展示还使用全局符号。 |
| 跨币种转账 | 有源/目标金额 | 明确拒绝不同币种 | ❌ 未实现 | `Transaction.validate:transferCurrency` | 需要汇率快照和双金额模型，不能只放宽校验。 |
| **预算与计划：月度/分类/总预算** | 官方当前未证明预算 | 无 | ❌ 未实现 | `tables.dart`、路由、features 均无 budget | 自主价值高，但非 ez parity。 |
| 预算进度/历史 | 官方当前未证明 | 无 | ❌ 未实现 | 无预算 Projection/Report | 预算实体应与类别、周期和月度实际支出相连。 |
| 周期账单 | 有 scheduled transaction | 同“周期交易”未闭环 | 🟡 部分实现 | `RecurringSeries`、`ScheduledTransactionsView` | 需要创建/查看/到期处理。 |
| 到期提醒 | 官方未见明确提醒功能 | 无 | ❌ 未实现 | 无通知依赖、后台任务或本地通知服务 | 周期功能稳定后再做本地提醒。 |
| **报表：月度收支总览** | 有 | 有 | ✅ 已实现 | `reports_screen.dart`；`reports_dao.dart:watchMonthlyTotals` | 读同一快照投影，避免第二套余额算法。 |
| 分类收入/支出占比 | 有 | 有月度饼图 | ✅ 已实现 | `report_breakdown_view.dart`；`watchCategoryBreakdown` | 排除 transfer、reversed，使用分类写时快照。 |
| 收支趋势 | 有多时间趋势 | 仅三个月日热力图，无趋势线 | 🟡 部分实现 | `report_heatmap_view.dart`；`reports_dao.dart:watchDailyTransactionAmounts` | 有按日聚合数据但不是月/年趋势报表。 |
| 热力图“频次/金额”切换 | 有丰富图表 | 两种模式目前返回同一金额聚合 | 🟡 部分实现 | `reports_providers.dart:heatmapData` | `frequency` 与 `amount` 都调 `watchHeatmapData`/相同 DAO 方法，标签与数据语义不闭合。 |
| 账户占比、资产趋势 | 有 | 无 | ❌ 未实现 | 报表仅 Categories/Monthly snapshots 汇总 | 使用账户类型和快照可实现。 |
| 日/周/月/年聚合 | 有 | 日热力、月总额；无周/年选择 | 🟡 部分实现 | `ReportsDao`；`ReportsScreen` 只选月 | “日”和“月”有，粒度选择不完整。 |
| 同比/环比 | 有 | 无 | ❌ 未实现 | 无前期比较 Query/UI | 可在趋势之后加入。 |
| 自定义时间范围 | 有 | 只月份选择 | ❌ 未实现 | `FeatherMonthPicker`；`SelectedDate` | 无起止日期。 |
| 标签分析/自定义分析 | 有标签图、Explorer | 无标签，也无自定义分析 | ❌ 未实现 | 交易 schema 与 reports 均无 tags/dimensions | 标签先于标签分析。 |
| 图表/筛选结果导出 | 有 CSV/TSV/Markdown 等 | 无 | ❌ 未实现 | 无导出 service/dependency/route | 先做筛选交易 CSV 即可。 |
| **数据管理：CSV / Excel / OFX / QFX / QIF / 第三方 / 支付账单导入** | 有广泛格式与多产品导入 | 无 | ❌ 未实现 | `pubspec.yaml`、路由、commands 无导入路径 | 先 CSV 字段映射，再按目标用户选择支付宝/微信账单。 |
| 导入字段映射/预览/规则 | 有自动识别、映射、预览、批改 | 无 | ❌ 未实现 | 无 import staging 表或 UI | CSV 仍需预览及可逆的错误处理。 |
| 导入重复交易检测 | 官方资料未证明 import dedup | 无 | ❌ 未实现 | Event Store 只有 commandId 幂等，不是数据重复检测 | 这是导入产品机会，不能称 ez 已有。 |
| CSV/TSV 导出 | 有 | 无 | ❌ 未实现 | 无 exporter | 应比导入更早，可用于用户数据所有权。 |
| 按筛选条件导出 | 有 | 无筛选也无导出 | ❌ 未实现 | 无 query/export workflow | 依赖搜索筛选。 |
| 完整备份/恢复 | 官方文档未证明完整一包恢复 | 无 | ❌ 未实现 | `AppDatabase` 本地 `db.sqlite`；无 backup service | 本地优先产品应优先提供加密归档，覆盖 DB、偏好及附件。 |
| 数据清除 | 有清空账户/所有数据 | 无 | ❌ 未实现 | 设置页无 data-management action | ES 下应定义“可恢复归档”与“不可逆清除”语义。 |
| **国际化：多语言** | 多语言 | en、zh_Hans、zh_Hant，但偏好只存 languageCode | 🟡 部分实现 | `AppLanguages`；`app_*.arb`；`preferences_repository.dart:get/setLocale` | 当次选择可用，重启会丢失 Hans/Hant script，无法保证繁简偏好持久。 |
| 多币种/汇率/基准货币 | 有全局币种、自动/手动汇率、默认币分析 | 仅有限币种清单与显示偏好 | 🟡 部分实现 | `AppCurrencies`；`currency_provider.dart` | 没有 rates、基准币换算或混币种资产汇总。 |
| 时区 | 可配时区 | 无 | ❌ 未实现 | 偏好与 DB 无 timezone 字段 | 日期使用设备本地时间；海外用户/跨时区导入需明确语义。 |
| 日期/数字/货币格式 | 可自定义/本地化 | 用 `intl` 格式日期、minor money formatter，不能自定义 | 🟡 部分实现 | `transaction_form_screen.dart`；`money_format.dart` | 全局货币符号还可能与账户币种不一致。 |
| **隐私安全：本地数据** | 服务器权限与安全体系 | 原生 SQLite 置于应用 support directory，无显式加密 | 🟡 部分实现 | `app_database.dart:_openConnection` | 本地优先减少服务端暴露，但设备/备份保护尚不足。 |
| PIN/生物识别锁 | 有 app lock/PIN/WebAuthn | 无 | ❌ 未实现 | `pubspec.yaml` 无 biometric/security package；路由无 gate | PIN/biometric 是与本地产品直接可比的安全能力。 |
| 敏感金额遮蔽 | 未重点核验 | 有余额显示开关 | ✅ 已实现 | `balance_visibility_provider.dart`；`ledger_header.dart` | 适合肩窥防护，不是静态数据加密。 |
| 备份保护 | 服务端/部署能力不直接可比 | 无备份 | ❌ 未实现 | 无 backup/export implementation | 应与完整备份/恢复一起设计。 |
| **用户体验：快速记账** | 有 | FAB 直达金额优先表单 | ✅ 已实现 | `ledger_screen.dart`；`transaction_form_screen.dart` | 收支记一笔路径短。 |
| 最近使用分类、默认账户、自动补全 | 有模板/更成熟筛选体验 | 无 | ❌ 未实现 | 选择器直接全量 `accountListProvider/categoryListProvider` | 可先做“上次账户/最近分类”，无需复杂 AI。 |
| 空状态 | 有成熟多视图 | 有 | ✅ 已实现 | `ledger_empty.dart`；`LedgerTransactionList` | 月流水为空有专用界面。 |
| Dashboard / Overview | 有可自定义 Overview | 月度 ledger header + reports，非全局总览 | 🟡 部分实现 | `ledger_header.dart`；`reports_screen.dart` | 没有资产、待办/账单、预算和跨月洞察的一页总览。 |
| 自定义首页 | 有 | 无 | ⚪ 不适用 / 不建议实现 | 路由固定三 tab | 当前阶段不值得引入布局编辑器。 |
| 深色模式 / Material 3 | 有深色模式 | 有深色主题、M3 | ✅ 已实现 | `AppTheme`；`settings_screen.dart`；`pubspec.yaml` | UI 质量规则也由 constitution 约束。 |
| **产品边界：Server、Docker、NAS、DB server、多用户、OIDC、HTTP API、CLI、管理员** | ez 的核心自托管能力 | 本地 Flutter app 无 | ⚪ 不适用 / 不建议实现 | `main.dart` + `AppDatabase` 为本地 SQLite | 除非未来明确做同步/共享，否则不是功能缺口。 |
| AI 收据识别、MCP、外部对象存储、多地图服务 | ez 有/声明相关整合 | 无 | ⚪ 不适用 / 不建议实现 | 无对应依赖或 feature | 附件本体可独立于 AI 和云存储先做。 |

## 三、真正值得 Accounted For 增加的功能

### P0 — 基础财务能力缺口

| 功能 | ezBookkeeping 如何实现 | Feather 当前状态 | 用户价值 / 复杂度 / ES 兼容性 | 推荐落点 |
| --- | --- | --- | --- | --- |
| 转账产品闭环 | 单交易有源/目标账户；可跨币种的双金额 | 底层同币种双 posting 已有，新增/编辑 UI 缺失 | 避免把账户搬钱误记为收支。**Medium**；同币种路径与现有 `TransactionRecorded` 完全自然兼容。 | `ledger` 的专用 transfer form；复用 `RecordTransactionCommand.executeTransfer`。先定义 transfer correction UX。 |
| 周期账单/计划交易闭环 | schedule 到期自动创建（依赖常驻 server） | 规则/实例/转正命令有，但无创建、物化调用或界面 | 房租、订阅、工资是长期记账的基本场景。**Medium**；CRUD-exempt 系列表已是现有架构选择。 | `ledger` 新 Scheduled/Recurring presentation + service；应用启动时 catch-up，用户确认“记入/跳过”，后续加本地通知。 |
| 搜索、基础筛选、导出当前结果 CSV | 关键词/条件筛选及 CSV/TSV 导出 | 完全没有 | 让历史数据可找、可带走；比自定义图表优先。**Medium**；读投影天然适配。 | `ledger/domain/queries` 新 `TransactionFilter`；DAO 建索引；`data/export` 和筛选页。 |
| 可靠本地备份/恢复 | ez 有交易导出，但完整一包恢复未被官方证实 | 无 | 设备更换/误删的安全底线。**High**；ES 很适合导出 canonical events，但必须版本化并含 recurring/preferences/附件。 | `settings` 的 Backup service/UI；导出带 manifest+schemaVersion 的归档；导入到 staging/新库后校验再切换。 |

### P1 — 高价值增强

| 功能 | ezBookkeeping 如何实现 | Feather 当前状态 | 用户价值 / 复杂度 / ES 兼容性 | 推荐落点 |
| --- | --- | --- | --- | --- |
| 标签 + 标签筛选/分析 | 多标签、组、逻辑条件及图表 | 无 schema | 打破一级分类限制，支持“出差/报销/家庭”等横向视图。**Medium**；自然兼容，但事件 payload 需 schemaVersion/upcaster。 | 新 `Tag` aggregate/projection、transaction event 的 tag ids、`reports` tags query。先不做复杂 tag group。 |
| 对账工作流 | running balance、statement、期末调整 | 只有余额差额被写成调整交易 | 对银行卡/信用卡账单的信任感提升。**Medium**；现有调整交易和月快照可复用。 | `ledger` 的 account statement/reconciliation session；明确是否引入 cleared 状态。 |
| 预算（总额+分类月预算） | ez 官方未证明，属自主增强 | 无 | 让应用从回顾变成决策。**Medium**；预算可为独立 CRUD aggregate，实际额读快照/交易投影。 | 新 `budget` feature 或 `reports/domain`；以 `BudgetPeriod` + category allocation，不污染 ledger 交易 aggregate。 |
| 账户历史/资产分布/趋势 | 有资产比例、趋势、净值概念 | 快照存在，查询/UI缺 | 用户可看钱如何变化，而非仅当月分类。**Medium**；非常自然：复用 `MonthlyAccountBalanceSnapshots`。 | `reports` 的账户快照查询、趋势线、按账户 type 分布；混币种先分币种展示。 |
| CSV 导入（字段映射、预览、指纹提示） | 支持映射、预览及多格式 | 无 | 降低迁移门槛，先覆盖 CSV/目标区域账单。**High**；写入仍应走一次一笔的 command/event，不允许直写 projection。 | `data-import` 适配层；staging schema、mapping profile、重复候选 fingerprint；复用 Record/Transfer commands。 |
| 附件（本地票据） | 交易 images，可进一步识别 | 无 | 报销/凭证场景价值高。**High**；需明确定义 attachment 不进 event payload（事件存 metadata/hash，二进制独立可备份）或受版本化引用。 | `ledger` attachment model + app-private file store；Settings backup 包含附件。 |
| PIN/生物识别与受保护备份 | 有 app lock 等 | 无 | 本地财务数据的合理保护。**Medium**；与 ES 无耦合。 | app bootstrap/route lock gate、platform secure storage、backup encryption key 方案。 |

### P2 — 高级功能

| 功能 | ezBookkeeping 如何实现 | Feather 当前状态 | 用户价值 / 复杂度 / ES 兼容性 | 推荐落点 |
| --- | --- | --- | --- | --- |
| 汇率、基准币、跨币种转账 | 自动/手动 rates，默认币分析 | 账户有币种，跨币种 transfer 被拒绝 | 国际用户和净资产汇总需要。**High**；需在交易事件锁定 rate/两侧金额，避免历史报告随实时汇率漂移。 | `core` Currency/Rate value objects；`ledger` transfer model/event v2；`reports` conversion projection/query。 |
| 多级账户/分类 | ez 为两级 | 平铺 | 复杂账户和分类管理。**Medium**；应先确定只支持 parent/child，避免任意树。 | Account/Category aggregate 加 parentId；投影加层级约束。 |
| 报表时间范围、周/年趋势、同比环比 | ez 有多图表和比较 | 仅月选取 + 分类饼图/热力 | 丰富回顾能力。**Medium**；读侧扩展，不修改写模型。 | `reports` 统一 `DateRange` 与聚合 query；先趋势/对比，后图表导出。 |
| 原生拆分交易 | ez 并非可验证标杆 | 无，当前 aggregate 明确不支持 | 适合一次消费分多类。**High**；可兼容但会改变 income/expense posting invariant、category snapshot 和 UI。 | 仅在标签/预算后仍有明确需求时，设计 TransactionRecorded schema v2 和 projector upcast。 |
| 模板、草稿、最近使用/默认账户 | ez 有模板/草稿 | 无 | 明显提升高频录入。**Low–Medium**；模板/草稿为 CRUD 偏好，正式提交仍走既有 command。 | `ledger/presentation` + Preferences 或独立 Template repository。 |
| 本地提醒 | ez schedule 自动创建；提醒未明确 | 无 | 防漏账。**Medium**；与实例 catch-up 配合。 | 本地通知 adapter，Schedule query 仅安排提醒，不直接更改账本。 |

### Not Recommended

- **Server/self-hosted、Docker、NAS、MySQL/PostgreSQL、多用户、OIDC、2FA、API、CLI、后台管理：** 这是 ezBookkeeping 的部署/协作模型，不是本地优先 Flutter 记账的必要能力。
- **Insights Explorer 式任意逻辑查询器、完全自定义 Dashboard：** 在基础搜索、标签、时间范围尚未完成前成本高且认知负担大。
- **地理位置、地图供应商、AI/MCP、收据 OCR、外部对象存储：** 附件本身可有价值；这些整合应等真实使用数据证明必要性后再做。
- **现在就做任意自定义字段、无限级分类、完整复式会计：** 会削弱“轻量、简洁”的定位，并显著增加事件兼容与报告复杂度。

## 四、已有底层能力但缺少产品闭环

| 功能 | 已完成部分 | 缺失部分 | 建议下一步 |
| --- | --- | --- | --- |
| 转账 | `Transaction.transfer` 约束两条等额反向 posting；`executeTransfer`、Projector、月快照和 `ledger_transfer_test.dart` 均覆盖。 | `LedgerTypeSelector` 不提供 transfer，`TransactionFormScreen` 没有 from/to account；`CorrectTransactionCommand` 还拒绝转账编辑。 | 单独设计转账表单、详情、删除/冲正/更正策略；先同币种上线，跨币种独立设计。 |
| 周期交易 | `RecurringSeries`/`ScheduledTransactionsView`、RRULE 物化、转正同事务写 Event 与状态、服务层 watch 已存在。 | `saveSeries` 只停在 DAO；没有 series 写服务/UI；`main.dart` 没有执行物化；`LedgerViewModel.scheduledTransactions` 被订阅但没有任何 widget 读取。 | 先补系列 CRUD 与“即将到期”页面；启动时 idempotent catch-up；用户明确记入/跳过。 |
| 月度账户快照 | Projector 按账户重算连续月 opening/closing、income/expense/transfer，并有等价重建测试。 | Reports 仅汇总成当月收入、支出、余额；无账户历史曲线、资产分布、对账钻取。 | 在 `reports` 加按账户/币种时间序列 query 和资产面板，保持 projector 单写者。 |
| 账户对账/余额调整 | 编辑账户余额会让 `AccountService.adjustAccountBalance` 生成系统分类的正常交易，保留审计。 | 没有账单期间、逐笔 running balance、期末目标余额、差异说明或 cleared 标记。 | 将现有“调整”保留为对账完成的唯一写入动作，新增只读 reconciliation session/projection。 |
| 报表热力图模式 | UI 有 frequency/amount 下拉与 provider state。 | 两种分支均读取相同按金额聚合，频率从未计算；点击日期只留 `Future` 注释。 | 分离 `count` 与 `amount` DAO query，并让点击衔接按日筛选流水。 |
| 账户币种与全局货币设置 | AccountEvent/Projection 存 `currencyCode`，可选 USD/CNY/JPY/EUR/GBP。 | Account 新建以全局显示设置作币种来源；余额、交易和报告普遍用全局 symbol；无 rate/base-currency。 | 短期：账户表单独立选择并按账户格式化；长期：再加基准币/汇率。 |
| 繁简中文偏好 | ARB 与 `AppLanguages` 定义 zh_Hans/zh_Hant。 | Preferences 仅存 `locale.languageCode`，重启后 Hans/Hant script 丢失。 | 存完整 locale tag（例如 `zh_Hant`）并添加重启 widget test。 |
| 余额隐私 | `BalanceVisibilityController` 已持久化，Ledger header 可切换并遮蔽数字。 | Settings 无集中安全/隐私页，且无 app lock/DB 或备份加密。 | 将它纳入 Privacy 设置；在 PIN/biometric 和备份方案中统一设计。 |

## 五、建议产品 Roadmap

### Phase 1：完善核心记账闭环

- 交付同币种转账的独立创建/详情/删除/更正流程。
- 补搜索、账户/分类/日期/金额基础筛选和 CSV 导出当前结果。
- 修复热力图 frequency/amount 语义，并让日期点击进入已筛选流水。

### Phase 2：账户 / 预算 / 周期交易

- 建立周期账单的系列 CRUD、启动 catch-up、到期“记入/跳过”清单；再决定本地提醒。
- 把余额调整升级为可理解的对账流程。
- 做月总额和分类预算（实际数复用现有投影），不要先引入预测或复杂滚动规则。

### Phase 3：搜索、筛选与数据管理

- 标签（先简单多标签，不做标签组表达式）。
- CSV 导入的预览/字段映射/候选重复提示，所有正式写入走 Command/Event。
- 版本化、可校验、可恢复的本地备份；随后加入 PIN/生物识别与备份保护。

### Phase 4：统计与资产分析

- 基于已有月度快照完成账户余额趋势、按账户类型资产/负债分布和净资产总览。
- 加自定义日期范围、月/年趋势与环比；混币种先分组展示，避免虚假汇总。

### Phase 5：高级能力

- 基准币、历史汇率快照和跨币种转账。
- 多级账户/分类、模板/草稿/最近使用自动填充。
- 仅在用户需求证据充分时评估拆分交易、附件 OCR、原生提醒和更高级报表。

## 最终回答

若目标是“完整但轻量”的本地个人记账应用，Accounted For **不需要**复制 ezBookkeeping 的服务端体系。它真正欠缺的是：可用的转账、可用的周期账单、历史检索和可携带数据、可靠的本地恢复与保护、账户对账/资产视图，以及适度的预算和趋势分析。现有事件溯源与月度快照并不是障碍，反而为这些功能提供了可靠基础；接下来的优先级应当从“把已有底层能力接到用户手上”开始，而不是继续添加只存在于模型或表中的新名词。

### 附：ezBookkeeping 研究原始证据

详细逐项官方资料记录见 [ezBookkeeping feature evidence audit](../research/ezbookkeeping-feature-audit.md)。其中特别核实了：预算、原生拆分、导入交易去重、完整备份/恢复并不是其当前官方功能清单已证明的能力；计划交易的自动创建依赖常驻服务器，这一语义不能直接套用到移动端本地优先应用。
