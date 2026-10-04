# 预算持久化表结构、查询聚合与备份边界

Type: grilling
Label: wayfinder:grilling
Status: resolved
Triage: ready-for-human
Blocked by: 01, 02, 03

## Question

结合已锁定的跨月预算规则、固定/弹性计算口径与 Review Note 模型，Drift 持久化表结构、`BudgetDao` 响应式聚合查询、`AppDatabase` 迁移以及 `.flbackup` 兼容边界应如何精确设计？

## Context

已锚定技术边界：
- 采用 **CRUD 豁免表**（不进 `ledger_events`，不触发 `LedgerRebuildService`）；
- 多币种按 `currencyCode` 隔离，金额按 `LedgerAmountUnit`（整型 `int`，`1/100` 货币单位，见 `ADR-0004`）存储；
- 需遵守 `AppDatabase`（当前 `schemaVersion == 15`）迁移规范：新增表不升 `ledgerProjectionVersion`；
- `BackupService` 通过 `VACUUM INTO` 快照整个 `db.sqlite`，因此新增 CRUD 表天然纳入 `.flbackup`。

本票需要锁定以下技术契约：
1. **Drift 表结构与唯一约束**：
   - 依据 [01](01-temporal-budget-rule-and-editing.md) 的时间线/覆盖模型设计预算配置表；
   - 依据 [03](03-review-attribution-and-notes.md) 的作用域设计 `BudgetReviewNotes` 表（主键、唯一索引 `(currencyCode, year, month, categoryId?)` 或独立月度/分类列、`note` 文本、`updatedAt`）；
   - 不对 `categories_view.id` 建数据库硬外键（避免 `LedgerRebuildService` 重建清空 `categories_view` 时触发外键报错或级联误删预算与复盘备注）。
2. **DAO 与高性能响应式查询设计**：
   - `BudgetDao` 需要高效聚合：
     - 单月各分类 `Budget`、`Actual`（及 `sourceScheduledBillId != null` 固定部分 vs 弹性部分）、`Pending`；
     - 近 3 月均值与近 6 个月趋势序列（评估是否单条 SQL `GROUP BY yearMonth, categoryId` 拉取窗口数据在 Dart 层聚合，避免 N+1 查询）；
     - `TransactionFormScreen` 的单分类单月剩余预算实时流（低开销，不能每次输入金额都全库重算 6 个月趋势）。
   - 确保 watch 依赖 `accounts_view`（捕获 `includeInTotals` 与 `deleted` 变更）、`transactions_view`、`transaction_postings_view`、`categories_view`、`scheduled_transactions_view`、`recurring_series` 与新预算表，遵循 `AGENTS.md` 中的 Drift `watch()` 表失效规则。
3. **分类删除/归档与备份恢复边界**：
   - 确认老版本 `.flbackup` 恢复到新 App 时通过 `AppDatabase.onUpgrade` 自动创建空预算表；新备份恢复无需额外 `SharedPreferences` 键或安全水线。

## Answer

经两轮决策，本票锁定以下持久化表结构、查询聚合与备份契约：

1. **Drift 持久化表结构（CRUD 豁免表，不入 `ledger_events`）**：
   - **`BudgetRules`（`budget_rules`）**：
     - 列：`currencyCode (Text)`、`categoryId (Text)`、`effectiveYm (Int, year * 100 + month)`、`amountMinor (Int?, > 0 为设额，null 为显式 unset 断点)`、`updatedAt (DateTime)`。
     - 复合主键：`(currencyCode, categoryId, effectiveYm)`；无外键指向 `categories_view`（避免 `LedgerRebuildService` 重建清空投影表时触发外键失败或级联误删）。
   - **`BudgetReviewNotes`（`budget_review_notes`）**：
     - 列：`currencyCode (Text)`、`ym (Int, year * 100 + month)`、`categoryKey (Text, '' 代表月度总备忘，非空为 categoryId)`、`note (Text, <= 500 chars)`、`updatedAt (DateTime)`。
     - 复合主键：`(currencyCode, ym, categoryKey)`（用 `''` 哨兵消除 SQLite `UNIQUE(..., NULL)` 重复行陷阱）；清空保存时直接 `DELETE` 该行；无外键指向 `categories_view`。
   - **`CategoriesView.archivedAt`（投影增强）**：
     - 在 `CategoriesView` 新增 `archivedAt (DateTime?)`，由 `LedgerProjector._applyCategoryArchived` 从 `envelope.recordedAt` 写入；`AppDatabase.onUpgrade` 执行 `addColumn` 并把 `ledgerProjectionVersion` 升 1，在启动时触发 `LedgerRebuildService` 自愈重推，自动为老库/老备份回填历史已归档分类的 `archivedAt`。

2. **写入事务与时间线断点维护**：
   - 预算规则的所有写操作均在单个 `db.transaction` 内执行：
     - **「仅本月」（`M`）**：读取修改前 `M` 月原本生效的状态 `priorAtM`；若 `M+1` 尚无显式断点，先补写 `(M+1, priorAtM)` 锁定后续月份，再写入 `(M, newValue)`；
     - **「本月及以后」（`M`）**：删除 `effectiveYm > M` 的全部更晚断点，再写入 `(M, newValue)`；
     - **冗余断点裁剪**：在同一事务内自动清理连续相同状态行及无前置规则的开头 `unset` 行，保持时间线表最小化。

3. **`BudgetDao` 响应式查询设计**：
   - 不建额外的预算月度聚合缓存表，改为三条职责隔离的响应式流（均显式引用 `accounts_view`、`categories_view`、`transactions_view`、`transaction_postings_view`、`scheduled_transactions_view`、`recurring_series` 与预算表以保障 `watch()` 实时失效）：
     1. **窗口交易流**：单次 SQL 拉取 `[M-5 .. M]` 窗口内当前币种、`includeInTotals == true && !deleted` 账户的未冲销 `expense` 流水（沿用 `ReportsDao` 同款本地 `DateTime` 月界避免 UTC 时区漂移），在 Dart 侧一次按 `(ym, categoryId)` 聚合出 `Committed Actual`（`sourceScheduledBillId != null`）、`Discretionary Actual`、近 3 月均值 `[M-3 .. M-1]`、近 6 月趋势 `[M-5 .. M]` 及下钻 Top 3 贡献流水（零 N+1 查询）；
     2. **待入账流**：单次 SQL 聚合目标月窗口内 `status IN ('scheduled', 'failed')`（所属账户为当前币种且 `includeInTotals == true && !deleted`）的 `Pending`；
     3. **`TransactionFormScreen` 轻量提示流**：仅查询目标 `(currencyCode, categoryId, ym)` 的有效预算规则与当月 `Actual + Pending` 总额，完全不扫描 6 个月趋势与其他分类，保证记账输入响应速度。
   - **归档分类元数据读取**：直接读取 `categories_view`（不过滤 `archived`，仅排除 `systemCode != null` 与收入分类），在 `targetYm <= archiveYm` 保留历史月预算与元数据（含零支出月份），`> archiveYm` 停止延续预算（仅在存在历史遗留交易/待入账时按无预算发生额展示）。

4. **代码分层、错误契约与 `.flbackup` 兼容**：
   - 表定义与 `BudgetDao` 位于 `lib/core/data/database/`（与 `ReportsDao` 同级），特性内部按 `ledger` 参考切片在 `lib/features/budget/` 组织仓储、命令/查询、`BudgetService` 与 `BudgetViewModel`。
   - 服务层写操作通过 `guard(...)` 统一返回 `Result<T>`（无效预算金额、已归档分类禁设预算、Review Note 超字数限制等纳入 `LedgerErrorCode` 并补齐四语言 ARB）。
   - `AppDatabase.schemaVersion` 升至 `16`；沿用现有 `BackupService` 的 `VACUUM INTO` 与 `BackupManifest` 既有字段（零破坏性变更）：`<= v15` 老备份恢复后自动经 `onUpgrade` 建空预算表并重建回填 `archivedAt`，`v16` 备份完整保留预算规则与复盘备注，无需新增 `PreferencesRepository` 键。
