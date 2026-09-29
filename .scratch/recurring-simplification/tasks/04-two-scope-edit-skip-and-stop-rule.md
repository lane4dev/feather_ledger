# 04: 二元编辑作用域、单期跳过与停止周期规则

**What to build:** 实现极简二元编辑与跳过/恢复/停止链路：`planned` 支持编辑 `autoPost` 开关与物理删除；`repeating` 在 `PendingBillSheet` 溢出菜单提供扁平化「跳过本期」与「停止周期规则」（`isActive = false` 并直接删除该系列下所有 `scheduled`、`failed` 与 `skipped` 行，仅保留 `posted` 历史）；**在账本页按天时间轴内联展示 `skipped`（弱化样式 + 删除线 + 「已跳过」Badge，当天仅 `skipped` 时日期分组照常显示；月份选择器 `pendingBillMonths` 不标记仅含 `skipped` 月份）与 `failed` 账单，并支持在 `PendingBillSheet` 点击「恢复为待入账」（恢复后隐藏记入/编辑/跳过外其余操作；归档/已删账户禁止恢复；恢复已到期 `autoPost` 实例自动置 `manualOnly = true`）**；`RecurringBillFormScreen` 保持 `planned` / `repeating` 形态锁定，复用 `CustomRecurrenceDialog` 与 `autoPost` 开关；`RecurringScopeDialog` 收敛为二元选择（改动分类、账户、`autoPost` 或重复规则时禁用「仅修改本期」）；`thisOnly` 仅写改变列（未改留 `NULL`、删空备注写 `''`）且允许同日碰撞、`failed` 复位为 `scheduled`；`updateRule` 未改基准日期与重复周期时保留既有 `skipped` 与非空单期覆盖列（`K` 计 `posted + skipped`），改基准日期或重复周期（`date`/`frequency`/`interval`/`weekdays`）时更新 `series.startDate`、**删除 `scheduled`/`failed`/`skipped` 仅留 `posted`**（`K` 仅计 `posted`）并重物化；取消 `autoPost: false -> true` 的过去期次拦截（保存后对当前币种当场自动补账）。

**Blocked by:** 01: Schema v15 洁净重构与废旧状态机清除, 02: 三档录入形态、`autoPost` 独立开关记忆与过去起点即时自动入账, 03: 有限前瞻物化窗口与历史回溯补齐 Banner

**Status:** ready-for-agent

## Pre-agreed TDD Seams
1. `RecurringService.updateBill` 接缝：验证 `thisOnly` 稀疏写入、同日碰撞成功、改未来日期清除 `manualOnly`、`failed` 复位为 `scheduled` 且保持原 `manualOnly`；验证 `updateRule` 未改日期/周期时保留 `skipped` 与非空覆盖列（`K` 计 `posted + skipped`）；改基准日期或重复周期（`date`/`frequency`/`interval`/`weekdays`）时重设 `startDate`、**删除 `scheduled`/`failed`/`skipped` 仅留 `posted`**（`K` 仅计 `posted`）重物化并跳过 `posted` 撞期；`countLimit < K + 1` 拒绝；`autoPost: false -> true` 不打 `manualOnly` 拦截且当场对当前币种触发自动入账。
2. `RecurringService.skipOccurrence` / `restoreSkippedOccurrence` / `stopSeries` / `deletePlannedBill` 接缝：验证 `planned` 物理删除、`repeating` 跳过仅改单行 `skipped` 并计入 `countLimit`、`restoreSkippedOccurrence` 将 `skipped` 恢复为 `scheduled`（已到期 `autoPost` 自动置 `manualOnly = true`、归档/已删账户返回对应错误码禁止恢复）、`stopSeries` 置 `isActive = false` 并删除 `scheduled`/`failed`/`skipped`（仅留 `posted`）。
3. `LedgerViewModel`、`TransactionTile`、`RecurringBillFormScreen`、`RecurringScopeDialog`、`PendingBillSheet` UI 接缝：验证月度列表同时渲染 `scheduled`/`failed`/`skipped`（`skipped` 弱化+删除线+「已跳过」Badge，不入小计/合计；仅含 `skipped` 月份不亮 `pendingBillMonths` 标记），`skipped` 弹窗仅提供「恢复为待入账」，形态锁定、`planned` 展示 `autoPost` 开关、修改规则字段禁用 `thisOnly`、扁平化溢出菜单。

## File Changes
- **Delete**:
  - `lib/features/ledger/domain/commands/insert_or_update_scheduled_transaction_command.dart`
  - `lib/features/ledger/domain/commands/insert_or_update_scheduled_transaction_command.g.dart`
- **Modify**:
  - `lib/features/ledger/domain/commands/update_recurring_bill_command.dart`
  - `lib/features/ledger/domain/commands/delete_recurring_bill_command.dart`
  - `lib/features/ledger/domain/services/recurring_service.dart`
  - `lib/features/ledger/presentation/view_model/recurring_view_model.dart`（+ 重新生成 `.g.dart`）
  - `lib/features/ledger/presentation/view_model/ledger_view_model.dart`（+ 重新生成 `.g.dart`）
  - `lib/features/ledger/presentation/models/transaction_tile_ui_model.dart`
  - `lib/features/ledger/presentation/mappers/transaction_ui_mapper.dart`
  - `lib/features/ledger/presentation/widgets/transaction_tile.dart`
  - `lib/features/ledger/presentation/screens/recurring_bill_form_screen.dart`
  - `lib/features/ledger/presentation/widgets/recurring_scope_dialog.dart`
  - `lib/features/ledger/presentation/widgets/pending_bill_sheet.dart`
  - `lib/core/domain/result/result.dart`
  - `lib/shared/presentation/ledger_error_localizer.dart`
  - `lib/app/l10n/app_en.arb`、`lib/app/l10n/app_zh.arb`、`lib/app/l10n/app_zh_Hans.arb`、`lib/app/l10n/app_zh_Hant.arb`（+ `flutter gen-l10n`）
  - `test/unit/features/ledger/domain/services/recurring_series_test.dart`
  - `test/ui/features/ledger/recurring_bill_edit_test.dart`
  - `test/ui/features/ledger/pending_bill_test.dart`

## Acceptance Criteria
- [ ] 无 `thisAndFollowing` / `all` 拆表与日期平移逻辑；
- [ ] `thisOnly` 仅持久化改变列，未改动字段继续随 `updateRule` 继承更新；
- [ ] `updateRule` 复用 `CustomRecurrenceDialog` 且校验 `countLimit >= K + 1`，改基准日期或重复周期时清理 `scheduled`/`failed`/`skipped` 仅留 `posted` 并正确重设 `startDate`；
- [ ] `stopSeries` 置 `isActive = false` 并清理 `scheduled`/`failed`/`skipped`（仅留 `posted`）；
- [ ] 账本列表正确内联渲染 `skipped`（弱化+删除线+Badge，仅含 `skipped` 月份不亮提示点）与 `failed` 行，且 `skipped` 弹窗支持恢复为 `scheduled`（含 `manualOnly` 与归档账户防线）；
- [ ] `dart run build_runner build -d`、`flutter gen-l10n`、`flutter analyze` 零错误、全量测试绿灯。
