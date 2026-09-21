# 06: 稳定 UUID 提醒全量对账、深链直达与死代码清理

**What to build:** 通知调度与深链彻底脱离重定向链与旧批次逻辑：`ReminderSchedule` 与 `RecurringReminders` 按 `effectiveDate - reminderMinutes` 与稳定 UUID 对全部有效 `planned` / `repeating`（含 `autoPost`）待处理账单做全量对账；`ReminderResponseHandler` 直接按实例 UUID 查询分发（`scheduled`/`failed` 打开 `PendingBillSheet` 或快捷记入/跳过；`posted` 仅通过 `getTransactionBySourceBill(bill.id)` 打开交易详情；`skipped`/已删或对应交易已冲正给通用「该账单或交易已不可用」轻提示）；清理全工程残留失效 ARB 本地化键与测试替身，完成最终回归验收。

**Blocked by:** 01: Schema v15 洁净重构与废旧状态机清除, 04: 二元编辑作用域、单期跳过与停止周期规则, 05: 自动入账、恢复水线、币种切回补录与 `failed` 失败闭环

**Status:** ready-for-agent

## Pre-agreed TDD Seams
1. `ReminderSchedule` & `RecurringReminders` 接缝：验证同时调度 `planned` 与 `repeating`（含 `autoPost`）、改期覆盖（`dateOverride`）重算触发时刻、payload 为稳定 UUID 且通知 ID 稳定。
2. `ReminderResponseHandler` 接缝：验证点击通知按 UUID 直查分发 4 种状态（`scheduled`/`failed`、`posted` 查 `getTransactionBySourceBill`、`skipped`/缺失、交易已冲正提示不可用），无重定向表查询与 `bill.transactionId` 兜底。

## File Changes
- **Modify**:
  - `lib/features/ledger/domain/notifications/reminder_schedule.dart`
  - `lib/features/ledger/data/notifications/recurring_reminders.dart`
  - `lib/features/ledger/presentation/notifications/reminder_response_handler.dart`
  - `lib/app/l10n/app_en.arb`、`lib/app/l10n/app_zh.arb`、`lib/app/l10n/app_zh_Hans.arb`、`lib/app/l10n/app_zh_Hant.arb` + 重新生成 `lib/app/l10n/app_localizations*.dart`
  - `test/support/fakes/fake_app_localizations.dart`
  - `test/unit/features/ledger/domain/notifications/reminder_schedule_test.dart`
  - `test/unit/features/ledger/data/notifications/recurring_reminders_test.dart`
  - `test/ui/features/ledger/reminder_response_handler_test.dart`
  - `test/unit/features/ledger/presentation/recurring_time_test.dart`

## Acceptance Criteria
- [ ] 提醒调度覆盖含 `autoPost` 在内的所有有效周期/计划待处理账单，点击深链直查 UUID；
- [ ] 无任何 `ScheduledBillRedirects` / 旧全局开关 / 恢复确认批次的残留 ARB 键或死代码；
- [ ] `dart run build_runner build -d`、`flutter gen-l10n`、`flutter analyze` 零问题，`flutter test` 全量一次通过。
