# 01: Schema v15 洁净重构与废旧状态机清除

**What to build:** 彻底移除 3 套全局自动入账开关、毫秒级资格边界（`enabledSince` / `currencyActiveSince` / `lastSeenWallClock`）、`AutomaticPostingPolicy`、自动入账批次表、恢复确认批次表与通知重定向表；将 `AppDatabase` 升级至 v15（`onUpgrade` 仅清理重建 CRUD 豁免周期表，严禁触碰 `ledger_events` 与 4 张事件溯源投影视图）；确立 `RecurringSeriesMode` 两档（`planned` / `repeating`）、`RecurringScope` 二元枚举（`thisOnly` / `updateRule`）、UUID 主键 + `UNIQUE(series_id, occurrence_key)`、单期覆盖列、`manualOnly` 与 `isActive`，保持全工程 `flutter analyze` 与测试基线绿灯。

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

## Pre-agreed TDD Seams
1. `AppDatabase` (`v14 -> v15`) 升级接缝：验证升级后 4 张废表被删除、`RecurringSeries` 与 `ScheduledTransactionsView` 按 v15 重建，且 `ledger_events` 与 4 张事件溯源投影视图表数据完好无损。
2. `PreferencesRepository` 接缝：验证旧全局开关与时钟边界 API 已清除；新增本机偏好 `lastRecurringAutoPost`（默认 `false` 且不进入 `exportAll`/`importAll`）。
3. `AccountLifecycleCommand` archive 接缝：验证账户归档将已到期账单转为 UUID + `occurrenceKey: 'single'` 的一次性 `planned` 账单。

## File Changes
- **Delete**:
  - `lib/features/ledger/domain/services/automatic_posting_policy.dart`
  - `lib/features/ledger/domain/entities/automatic_posting_batch.dart`
  - `lib/features/settings/domain/models/restore_confirmation_batch.dart`
  - `test/unit/features/ledger/domain/services/automatic_posting_policy_test.dart`
  - `test/unit/features/ledger/domain/services/automatic_posting_batch_test.dart`
  - `test/unit/features/settings/domain/restore_confirmation_test.dart`
  - `test/ui/features/settings/auto_post_settings_test.dart`
  - `test/ui/features/settings/restore_confirmation_screen_test.dart`
- **Modify**:
  - `lib/core/domain/enums.dart`
  - `lib/core/data/database/tables.dart`
  - `lib/core/data/database/app_database.dart`（+ 重新生成 `app_database.g.dart`）
  - `lib/core/data/database/daos/recurring_dao.dart`（+ 重新生成 `recurring_dao.g.dart`）
  - `lib/core/domain/repositories/preferences_repository.dart`
  - `lib/core/data/repositories/preferences_repository.dart`（+ 重新生成 `.g.dart`）
  - `lib/core/presentation/providers/currency_provider.dart`
  - `lib/features/ledger/domain/entities/ledger_entities.dart`
  - `lib/features/ledger/domain/repositories/recurring_repository.dart`
  - `lib/features/ledger/data/repositories/recurring_repository.dart`（+ 重新生成 `.g.dart`）
  - `lib/features/ledger/domain/services/recurring_service.dart`（+ 重新生成 `.g.dart`）
  - `lib/features/ledger/domain/commands/create_recurring_series_command.dart`
  - `lib/features/ledger/domain/commands/project_recurring_events_command.dart`
  - `lib/features/ledger/domain/commands/update_recurring_bill_command.dart`
  - `lib/features/ledger/domain/commands/delete_recurring_bill_command.dart`
  - `lib/features/ledger/domain/commands/convert_scheduled_to_posted_command.dart`
  - `lib/features/ledger/presentation/view_model/transaction_form_view_state.dart`
  - `lib/features/ledger/presentation/view_model/transaction_form_view_model.dart`
  - `lib/features/ledger/presentation/screens/transaction_form_screen.dart`
  - `lib/features/ledger/presentation/screens/recurring_bill_form_screen.dart`
  - `lib/features/ledger/presentation/widgets/recurring_mode_label.dart`
  - `lib/features/ledger/presentation/widgets/recurring_scope_dialog.dart`
  - `lib/features/ledger/presentation/widgets/pending_bill_sheet.dart`
  - `lib/features/ledger/presentation/mappers/transaction_ui_mapper.dart`
  - `lib/features/ledger/presentation/notifications/reminder_response_handler.dart`
  - `lib/features/settings/domain/commands/account_lifecycle_command.dart`
  - `lib/features/settings/presentation/screens/settings_screen.dart`（+ 重新生成 `.g.dart`）
  - `lib/app/bootstrap/pending_restore.dart`
  - `lib/main.dart`
  - `test/unit/core/database/app_database_test.dart`
  - `test/unit/core/data/repositories/preferences_repository_backup_test.dart`
  - `test/unit/features/settings/domain/services/account_lifecycle_test.dart`
  - `test/unit/features/ledger/domain/entities/scheduled_status_test.dart`
  - `test/support/fakes/recording_services.dart` 及受枚举/Entity 变更影响的既有测试编译适配

## Acceptance Criteria
- [ ] 4 张废表（`AutomaticPostingBatches`、`AutomaticPostingBatchMembers`、`RestoreConfirmationBatches`、`ScheduledBillRedirects`）及 3 套全局自动入账开关/时间边界彻底删除；
- [ ] `AppDatabase` 升至 v15，`v14 -> v15` 升级单测验证周期 CRUD 表干净重建且 `ledger_events` 与 4 张事件溯源视图数据零损失；
- [ ] `PreferencesRepository` 新增 `lastRecurringAutoPost` 本机偏好（默认 `false`，不入备份）；
- [ ] `dart run build_runner build -d`、`flutter analyze` 零错误、`flutter test` 全量绿灯。
