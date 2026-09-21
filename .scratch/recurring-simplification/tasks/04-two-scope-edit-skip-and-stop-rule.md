# 04: 二元编辑作用域、单期跳过与停止周期规则

**What to build:** 实现极简二元编辑与跳过/停止链路：`planned` 支持直接编辑与物理删除；`repeating` 在 `PendingBillSheet` 溢出菜单提供扁平化「跳过本期」与「停止周期规则」（`isActive = false` 并删除待处理行，历史不动）；`RecurringBillFormScreen` 保持 `planned` / `repeating` 形态锁定，复用 `CustomRecurrenceDialog`（含 `countLimit >= K + 1` 下限校验）与 `autoPost` 开关；`RecurringScopeDialog` 收敛为二元选择（改动分类、账户、`autoPost` 或重复规则时禁用「仅修改本期」）；`thisOnly` 仅写改变列（未改留 `NULL`、删空备注写 `''`）且允许同日碰撞、`failed` 复位为 `scheduled`；`updateRule` 未改日期/规则时保留单期覆盖列，改日期/规则时更新 `series.startDate`、清空待办重物化并跳过与历史 `posted`/`skipped` 的 `occurrence_key` 碰撞（`autoPost: false -> true` 时标既有过期项为 `manualOnly`）。

**Blocked by:** 01: Schema v15 洁净重构与废旧状态机清除, 02: 三档录入形态、`autoPost` 开关记忆与创建时间保护, 03: 有限前瞻物化窗口与历史回溯补齐 Banner

**Status:** ready-for-agent

## Pre-agreed TDD Seams
1. `RecurringService.updateBill` 接缝：验证 `thisOnly` 稀疏写入、同日碰撞成功、改未来日期清除 `manualOnly`、`failed` 复位为 `scheduled` 且保持原 `manualOnly`；验证 `updateRule` 继承与保留覆盖列、改日期/规则重设 `startDate` 清空待办重物化并跳过撞期、`countLimit < K + 1` 拒绝、`autoPost: false -> true` 标记既有过期行 `manualOnly = true`。
2. `RecurringService.skipOccurrence` / `stopSeries` / `deletePlannedBill` 接缝：验证 `planned` 物理删除、`repeating` 跳过仅改单行 `skipped` 并计入 `countLimit`、停止规则置 `isActive = false` 并删除待处理行。
3. `RecurringBillFormScreen`、`RecurringScopeDialog`、`PendingBillSheet` UI 接缝：验证形态锁定、`CustomRecurrenceDialog` 集成、修改规则字段禁用 `thisOnly`、扁平化溢出菜单。

## File Changes
- **Delete**:
  - `lib/features/ledger/domain/commands/insert_or_update_scheduled_transaction_command.dart`
  - `lib/features/ledger/domain/commands/insert_or_update_scheduled_transaction_command.g.dart`
- **Modify**:
  - `lib/features/ledger/domain/commands/update_recurring_bill_command.dart`
  - `lib/features/ledger/domain/commands/delete_recurring_bill_command.dart`
  - `lib/features/ledger/domain/services/recurring_service.dart`
  - `lib/features/ledger/presentation/view_model/recurring_view_model.dart`（+ 重新生成 `.g.dart`）
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
- [ ] `updateRule` 复用 `CustomRecurrenceDialog` 且校验 `countLimit >= K + 1`，改期/改规则正确重设 `startDate` 并跳过历史撞期；
- [ ] `dart run build_runner build -d`、`flutter gen-l10n`、`flutter analyze` 零错误、全量测试绿灯。
