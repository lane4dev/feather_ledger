# 月度预算与复盘功能实施任务拆解（Tasks）

> **依据规格**：[spec.md](spec.md)  
> **实施约束**：遵循 `.specify/memory/constitution.md`、`AGENTS.md`（Riverpod `@riverpod` codegen、Drift codegen、`Result<T>` 边界、禁止组件内直接 `formatMinor` 或业务逻辑、四语言 ARB 同步）。

---

## Phase 1：Schema、投影自愈与 BudgetDao 数据层

- [x] **T1.1 Drift 表定义与数据库迁移（`schemaVersion: 15 -> 16`）**
  - 在 `lib/core/data/database/tables.dart` 新增 `BudgetRules`（PK `(currencyCode, categoryId, effectiveYm)`，可空 `amountMinor`）与 `BudgetReviewNotes`（PK `(currencyCode, ym, categoryKey)`），并在 `CategoriesView` 新增可空 `archivedAt` 列。
  - 在 `lib/core/data/database/app_database.dart` 将 `schemaVersion` 升至 `16`，`onUpgrade` 使用 `addColumn` + `createTable`（禁止 `deleteTable/createTable`），并注册新表与 `BudgetDao`。
  - 运行 `dart run build_runner build -d`。
- [x] **T1.2 分类归档投影时间戳与自愈重建**
  - 将 `ledgerProjectionVersion` 从 `7` 升至 `8`（`lib/features/ledger/domain/projections/ledger_projection.dart`）。
  - 修改 `lib/features/ledger/data/projections/ledger_projector.dart` 的 `_applyCategoryArchived`，从 `EventEnvelope.recordedAt` 写入 `CategoriesView.archivedAt`（计算 `archiveYm` 时统一 `.toLocal()`）。
- [x] **T1.3 实现 `BudgetDao` 三流与事务写操作**
  - 在 `lib/core/data/database/daos/budget_dao.dart` 实现：
    - `watchMonthBudgetSummary`（规则 + 6 个月本地 `DateTime` 半开区间支出汇总 + `systemCode == null` & `includeInTotals == true & deleted == false` 过滤 + 归档信息 + Review Notes + `earliestTxYm`）；
    - `watchMonthPendingExpenses`（`scheduled`/`failed` 且 `includeInTotals == true & deleted == false`，解析 `coalesce(amountOverrideMinor, amountMinor)` 与 `coalesce(dateOverride, scheduledDate)`）；
    - `watchCategoryBudgetHint`（单分类轻量流，接收表单锁定的 `currencyCode`）；
    - `upsertBudgetRule`（单事务 `M+1` 保护性锚定 / 清未来断点 / 沿 `M -> M_next` 升序冗余裁剪）与 `upsertReviewNote`、`hasFutureRulesAfter`。
- [x] **T1.4 Phase 1 测试**
  - `test/unit/core/database/app_database_v16_migration_test.dart`：验证 v15 → v16 迁移保留历史行且 `archivedAt` 由 `LedgerRebuildService` 自愈回填。
  - `test/unit/core/database/daos/budget_dao_test.dart`：验证三流、本地时间边界、`includeInTotals`/`deleted`/`systemCode` 过滤、`amountOverrideMinor`、复合主键及升序连续冗余裁剪。

---

## Phase 2：领域引擎、仓储、Service 与本地化

- [x] **T2.1 领域模型与纯计算内核（`lib/features/budget/domain/`）**
  - 定义 `YearMonth`、`BudgetEditScope`、`BudgetMode`、`BudgetRule`、`BudgetReviewNote`、`CategoryBudgetSummary`、`MonthBudgetSummary`、`BudgetAttribution`、`CategoryBudgetHint` 等类型。
  - 实现纯函数领域计算器：时间线生效解析、`.toLocal()` 归档次月截断、固定 vs 弹性拆解、冷启动近 3 月均值、已设预算主执行口径与全盘旁注拆分、达标率与 `At Risk` 判定、异常波动双门槛、TOP 3 归因与未设预算提醒。
- [x] **T2.2 仓储与 CQRS 命令 / 查询 / Service**
  - 实现 `BudgetRepository` 接口与 `BudgetRepositoryImpl`（通过 `CategoriesDao` / `BudgetDao` 校验分类存在、归档状态与 `expense` 类型）。
  - 实现 `SetCategoryBudgetCommand`、`ClearCategoryBudgetCommand`、`SaveReviewNoteCommand`、`WatchMonthBudgetQuery`、`WatchTransactionBudgetHintQuery`，全部经由 `BudgetService` + `guard(...)` 返回 `Result<T>`。
  - 将 `TransactionFormScreen` 所需轻量提示接缝注入 Riverpod provider。
- [x] **T2.3 错误码与四语言 ARB**
  - 在 `lib/core/domain/result/result.dart` 新增 `LedgerErrorCode.budgetNoteTooLong`，并在 `lib/shared/presentation/ledger_error_localizer.dart` 补齐映射。
  - 同步补充 `app_en.arb`、`app_zh.arb`、`app_zh_Hans.arb`、`app_zh_Hant.arb` 全部预算/复盘词条，运行 `flutter gen-l10n`。
- [x] **T2.4 Phase 2 测试**
  - `test/unit/features/budget/domain/budget_calculator_test.dart`（时间轴三模式、阶跃继承、归档次月截断、冷启动 3 月均值、分母为 0 达标率、固定/弹性、`At Risk`、异常波动、归因排序）。
  - `test/unit/features/budget/domain/services/budget_service_test.dart`（校验拒绝、`Result.failure` 映射、双作用域、`500` 字上限、归档拦截、轻量提示流）。

---

## Phase 3：Budget Tab 主屏、下钻与编辑交互

- [x] **T3.1 Presentation Mappers 与 ViewModels**
  - 实现 `BudgetUiMapper`（所有 `formatMinor` / `formatMinorWithSymbol` / 百分比格式化集中在此）。
  - 实现 `BudgetViewModel`（按 `YearMonth` 管理切换、复盘预览切换、趋势折叠态与编排写操作）。
- [x] **T3.2 主屏与核心组件（严格对齐 `AppTheme` 与 `prototype-budget-ui.html`）**
  - 替换 `lib/features/budget/presentation/screens/budget_screen.dart` 占位实现：顶部 `< YYYY年MM月 ▾ >`（`FeatherMonthPicker`）+ 复盘预览切换 + `+` 入口。
  - 实现 `BudgetOverviewCard`（主执行率/双段进度条/达标率严格对齐已设预算分母，底部单行旁注全部支出含未设预算支出、遗留及未完全物化排期轻提示）、`BudgetAttributionCard`（超支/结余 TOP 3 + 未设提醒 + 月度 Review Note）、`BudgetTrendChart`（`fl_chart` 近 6 月柱线图 + Note 节点点标）。
  - 实现三段分类列表组件（含底部默认折叠的「其余分类（点击设预算 · N）」）及空币种/无账户空态。
- [x] **T3.3 分类下钻 BottomSheet 与编辑预算 BottomSheet**
  - `BudgetDrilldownSheet`（~88% 高屏占比 Modal BottomSheet，`sheetRadius = 28px`）：6 月对比柱线图、固定/弹性/待入账拆解、TOP 3 流水（已入账行可点进 `/ledger/edit`）、分类 Review Note 编辑器（归档只读）。
  - `BudgetEditSheet`：参考基线一键填入芯片（上月实际 / 近 3 月均值 / 固定底线）、`LedgerAmountInput` 金额输入（空/`0` 时禁用保存并提示）、作用域选择（`effectiveBudget == null && !hasFutureRulesAfter(M)` 时才静默 `thisAndFollowing`）与清除操作。

---

## Phase 4：`TransactionFormScreen` 记账即时预算提示

- [x] **T4.1 轻量只读预算提示条**
  - 新增 `transactionBudgetHintProvider`（监听表单锁定币种 `formState.currencyCode`、所选分类与日期月份的 `watchCategoryBudgetHint`）。
  - 在 `lib/features/ledger/presentation/screens/transaction_form_screen.dart` 仅当 `type == expense` 且选中分类时嵌入 `TransactionBudgetHintBanner`：正确处理 `includeInTotals == false` 提示、`planned` 模式与历史月提示、编辑态仅当 `original` 原先贡献给同一 `(targetYm, categoryId)` 时才扣减原金额，以及 4 态预览，绝不阻塞提交。

---

## Phase 5：Widget 测试、备份回归与整体验证

- [x] **T5.1 UI 组件行为测试（`test/ui/features/budget/`）**
  - `budget_screen_test.dart`：覆盖 Plan / Track(+复盘预览) / Review 三态切换、已设预算主卡 vs 未设预算旁注、底部折叠展开、归档分类只读历史。
  - `budget_sheets_test.dart`：覆盖高屏占比下钻 Sheet、点击 TOP 3 交易跳转 `/ledger/edit`、Review Note 保存与 500 字报错、编辑预算基线芯片/输入 `0` 禁用态/未来断点存在时不静默跳过弹窗。
  - `transaction_form_budget_hint_test.dart`：覆盖记账表单锁定币种、`includeInTotals == false`、`planned` 模式、编辑改月改类及超支仍可正常保存。
- [x] **T5.2 备份恢复回归测试**
  - 验证包含 `budget_rules` 与 `budget_review_notes` 的 `.flbackup` 导出导入完整性，以及旧 v15 `.flbackup` 恢复后自愈升级。
- [x] **T5.3 全量静态分析与测试**
  - 运行 `dart run build_runner build -d`、`flutter gen-l10n`、`flutter analyze` 与 `flutter test`，确保全部通过且零新增警告。
  - 附带修复：`backup_service_test.dart` 的 `v1Database()` fixture 需同时剥掉 v16 新增的 `categories_view.archived_at` 与两张预算表（否则 `onUpgrade` 的 `addColumn` 撞上已存在的列）；三个账本表单 widget 测试需覆盖 `transactionBudgetHintProvider` 为空流，否则提示条会在没有预算 fixture 的测试里打开真实数据库并留下 Drift 流的 pending timer；`ledger_month_switch_test.dart` 的 `chevronRight` 查找需限定在 `LedgerMonthSwitcher` 内（余额卡也画了一枚指向报表的同一图标）。
